module RedmineTelegramNotifications
  class Listener < Redmine::Hook::Listener
    def controller_issues_new_after_save(context = {})
      issue = context[:issue]
      return unless should_notify?(issue)
      
      message = build_issue_message(issue)
      send_telegram_message(message)
      
      # Отправляем прикрепленные файлы
      send_attachments(issue) if issue.attachments.any?
    end

    def controller_issues_edit_after_save(context = {})
      issue = context[:issue]
      journal = context[:journal]
      return unless should_notify?(issue)
      
      message = build_journal_message(issue, journal)
      send_telegram_message(message)
      
      # Отправляем новые прикрепленные файлы
      new_attachments = journal.details.select { |d| d.property == 'attachment' }
      send_attachments(issue, new_attachments) if new_attachments.any?
    end

    private

    def convert_markup(text)
      return '' if text.blank?
      
      # Разбиваем текст на строки для обработки каждой отдельно
      lines = text.split("\n").map do |line|
        # Конвертация жирного текста (учитываем пробелы и переносы)
        line = line.gsub(/\*\*(.+?)\*\*/, '<b>\1</b>')
        
        # Конвертация курсива (учитываем пробелы и переносы)
        line = line.gsub(/\*(.+?)\*/, '<i>\1</i>')
        line = line.gsub(/_(.+?)_/, '<i>\1</i>')
        
        # Конвертация зачеркнутого текста
        line = line.gsub(/~~(.+?)~~/, '<s>\1</s>')
        line = line.gsub(/-(.+?)-/, '<s>\1</s>')
        
        # Конвертация кода
        line = line.gsub(/`(.+?)`/, '<code>\1</code>')
        
        # Конвертация ссылок
        line = line.gsub(/\[(.+?)\]\((.+?)\)/, '<a href="\2">\1</a>')
        
        # Экранирование специальных HTML-символов в остальном тексте
        line = CGI.escapeHTML(line) unless line.include?('<b>') || 
                                          line.include?('<i>') || 
                                          line.include?('<s>') || 
                                          line.include?('<code>') || 
                                          line.include?('<a')
        
        line
      end
      
      # Собираем текст обратно с переносами строк
      lines.join("\n")
    end

    def build_issue_message(issue)
      message = []
      message << "🆕 <b>Новая задача создана</b>"
      message << "<b>Проект:</b> #{issue.project.name}"
      message << "#{issue.tracker.name} ##{issue.id}: <a href=\"#{issue_url(issue)}\">#{issue.subject}</a>"
      message << "<b>Статус:</b> #{issue.status.name}"
      message << "<b>Приоритет:</b> #{issue.priority.name}"
      message << "<b>Назначена:</b> #{issue.assigned_to&.name || '-'}"
      message << "<b>Автор:</b> #{issue.author.name}"
      
      if issue.description.present?
        message << "\n<b>Описание:</b>"
        description_lines = convert_markup(issue.description).split("\n")
        message.concat(description_lines)
      end
      
      if issue.attachments.any?
        message << "\n<b>Прикрепленные файлы:</b>"
        issue.attachments.each do |attachment|
          message << "📎 #{attachment.filename} (#{number_to_human_size(attachment.filesize)})"
        end
      end
      
      message.join("\n")
    end

    def build_journal_message(issue, journal)
      message = []
      message << "📝 <b>Задача обновлена</b>"
      message << "<b>Проект:</b> #{issue.project.name}"
      message << "#{issue.tracker.name} ##{issue.id}: <a href=\"#{issue_url(issue)}\">#{issue.subject}</a>"
      
      if journal.details.any?
        message << "\n<b>Изменения:</b>"
        journal.details.each do |detail|
          if detail.property == 'attachment'
            message << "• Добавлен файл: <b>#{detail.value}</b>"
          else
            old_value = detail.old_value.present? ? detail.old_value : "пусто"
            new_value = detail.value.present? ? detail.value : "пусто"
            message << "• <b>#{detail.prop_key}:</b> #{old_value} → <b>#{new_value}</b>"
          end
        end
      end
      
      if journal.notes.present?
        message << "\n<b>Комментарий:</b>"
        comment_lines = convert_markup(journal.notes).split("\n")
        message.concat(comment_lines)
      end
      
      message << "\n<b>Обновил:</b> #{journal.user.name}"
      message.join("\n")
    end

    def send_attachments(issue, attachments = nil)
      settings = Setting.plugin_redmine_telegram_notifications
      token = settings['telegram_bot_token']
      chat_id = settings['telegram_chat_id']
      
      attachments_to_send = attachments ? 
        attachments.map { |d| issue.attachments.find_by_id(d.prop_key) } :
        issue.attachments
      
      attachments_to_send.compact.each do |attachment|
        begin
          file_path = attachment.diskfile
          if File.exist?(file_path)
            Telegram::Bot::Client.run(token) do |bot|
              bot.api.send_document(
                chat_id: chat_id,
                document: Faraday::UploadIO.new(file_path, attachment.content_type),
                caption: "#{issue.tracker.name} ##{issue.id}: #{attachment.filename}"
              )
            end
          end
        rescue => e
          Rails.logger.error "Ошибка отправки файла в Telegram: #{e.message}"
        end
      end
    end

    def number_to_human_size(size)
      if size < 1024
        "#{size} B"
      elsif size < 1024*1024
        "#{(size.to_f/1024).round(1)} KB"
      elsif size < 1024*1024*1024
        "#{(size.to_f/1024/1024).round(1)} MB"
      else
        "#{(size.to_f/1024/1024/1024).round(1)} GB"
      end
    end

    def should_notify?(issue)
      settings = Setting.plugin_redmine_telegram_notifications
      return false if settings['telegram_bot_token'].blank?
      return false if settings['telegram_chat_id'].blank?
      
      projects = settings['projects'] || []
      projects.include?(issue.project_id.to_s)
    end

    def send_telegram_message(message)
      settings = Setting.plugin_redmine_telegram_notifications
      token = settings['telegram_bot_token']
      chat_id = settings['telegram_chat_id']

      begin
        Telegram::Bot::Client.run(token) do |bot|
          bot.api.send_message(
            chat_id: chat_id,
            text: message,
            parse_mode: 'HTML',
            disable_web_page_preview: true
          )
        end
      rescue => e
        Rails.logger.error "Ошибка отправки в Telegram: #{e.message}"
      end
    end

    def issue_url(issue)
      "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue.id}"
    end
  end
end 