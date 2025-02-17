require 'telegram/bot'
require_relative 'lib/redmine_telegram_notifications/listener'

Redmine::Plugin.register :redmine_telegram_notifications do
  name 'Redmine Telegram Notifications'
  author 'Gyhyry'
  description 'Отправка уведомлений о задачах в Telegram'
  version '0.1'
  url 'https://github.com/gyhyry/redmine_telegram_notifications'
  settings default: {
    'telegram_bot_token' => '',
    'telegram_chat_id' => '',
    'projects' => []
  }, partial: 'settings/telegram_settings'
end
