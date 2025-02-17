# Redmine Telegram Notifications Plugin

Плагин для Redmine, который отправляет уведомления о изменениях в задачах в Telegram канал.

## Описание

Данный плагин автоматически отслеживает все изменения в назначенных проектах Redmine и отправляет уведомления через Telegram бота в указанный канал. 

### Функциональность

- 📝 Уведомления о создании новых задач
- 🔄 Уведомления об изменениях в существующих задачах
- 📎 Отправка прикрепленных файлов
- 🔍 Мониторинг всех назначенных проектов
- 🤖 Интеграция с Telegram ботом

## Установка

1. Скопируйте плагин в директорию `plugins` вашего Redmine сервера
2. Установите необходимые гемы:
   ```
   cd plugins/redmine_telegram_notifications
   bundle install
   ```
3. Выполните миграции базы данных:
   ```bash
   # Если Redmine запущен от пользователя www-data (стандартная установка):
   sudo -u www-data bundle exec rake redmine:plugins:migrate RAILS_ENV=production
   
   # Если Redmine запущен от другого пользователя, замените www-data на вашего пользователя:
   sudo -u YOUR_REDMINE_USER bundle exec rake redmine:plugins:migrate RAILS_ENV=production
   
   # Если вы запускаете Redmine в Docker:
   docker exec -it YOUR_REDMINE_CONTAINER bundle exec rake redmine:plugins:migrate RAILS_ENV=production
   ```
4. Перезапустите Redmine

## Настройка

1. Создайте Telegram бота через @BotFather
2. Получите токен бота
3. Создайте Telegram канал и добавьте в него бота с правами администратора
4. В настройках плагина укажите:
   - Токен Telegram бота
   - ID канала для отправки уведомлений

## Требования

- Redmine версии 4.0.0 или выше
- Ruby 2.7 или выше

## Зависимости

Плагин использует следующие гемы:
- telegram-bot-ruby (~> 0.19.0) - для работы с Telegram Bot API
- thread_safe (~> 0.3.6) - для обеспечения потокобезопасности
- descendants_tracker (~> 0.0.4) - для отслеживания наследования классов
- bigdecimal (~> 3.0.0) - для работы с числами высокой точности

## Лицензия

MIT 