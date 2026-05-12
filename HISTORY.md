# LLM Chat History

Данный файл содержит историю работы с Claude Code (claude-sonnet-4-6) при разработке тестового задания.

---

## Сессия 1 — 2026-05-12

### Пользователь
Получил текст задания (Junior+ Ruby on Rails Developer). Нужно создать API приложение на Ruby on Rails с PostgreSQL, OpenAPI спецификацией, следуя SOLID, DRY и TDD.

### Ассистент
Проверил окружение: Ruby 3.4.1, Rails 7.2.2.1, PostgreSQL 14 (локально), Docker 27.3.1.

Предложил архитектуру:
- Хранение правил повторения в JSONB (без прегенерации)
- `task_occurrences` как sparse-хранилище переопределений
- Генерация экземпляров на лету через генераторы (Strategy Pattern)
- rswag для TDD + автогенерации Swagger
- Blueprinter для сериализации

### Выполненные шаги

1. `rails new task_tracker --api --database=postgresql --skip-test`
2. Добавлены gems: `rspec-rails`, `factory_bot_rails`, `faker`, `rswag-specs`, `rswag-api`, `rswag-ui`, `shoulda-matchers`, `blueprinter`, `rack-cors`
3. Установлен RSpec (`rails generate rspec:install`), rswag
4. Настроены: `database.yml`, `cors.rb`, `routes.rb`, `docker-compose.yml`, `Dockerfile`
5. Созданы миграции: `tags`, `tasks`, `task_tags`, `task_occurrences` с индексами и ограничениями
6. Созданы модели с валидациями и защитой системных тегов
7. Реализованы сервисы повторений: `DailyGenerator`, `MonthlyGenerator`, `SpecificDatesGenerator`, `EvenOddGenerator`, `GeneratorFactory`
8. Реализованы сервисы: `Tasks::CreateService`, `Tasks::UpdateService`, `Occurrences::ListService`, `Occurrences::UpdateService`
9. Созданы Blueprinter сериализаторы: `TaskBlueprint`, `TagBlueprint`, `OccurrenceBlueprint`
10. Реализованы контроллеры: `TasksController`, `TagsController`, `TaskTagsController`, `TaskOccurrencesController`
11. Написаны RSpec тесты: модельные, сервисные, request specs с rswag-аннотациями
12. Исправлены баги: lazy `let` в тестах тегов → `let!`; datetime формат Blueprinter → ISO8601 через `config.datetime_format`
13. Сгенерирована Swagger документация (`rake rswag:specs:swaggerize`)

### Результат

- **86 тестов** — все зелёные (59 unit + 27 request)
- Swagger YAML: `swagger/v1/swagger.yaml`
- Swagger UI: `http://localhost:3000/api-docs`

### Ключевые архитектурные решения и их обоснование

**Q: Как решить проблему бесконечности периодических задач?**

A: Хранить только правило (recurrence_type + recurrence_params JSONB), генерировать экземпляры на лету при запросе с датовым диапазоном. Это позволяет задачам без `ends_on` существовать "вечно" без миллионов записей в БД.

**Q: Как хранить независимое состояние экземпляров?**

A: Таблица `task_occurrences` — sparse store. Запись создаётся только при явном изменении экземпляра (PATCH /occurrences/:date). Неизменённые экземпляры получают дефолтный статус `pending` и данные из шаблона задачи при генерации.

**Q: Как реализовать "отрыв" экземпляра (бонус)?**

A: `task_occurrences` содержит поля `title`, `description`, `cancelled` — они переопределяют данные шаблона для конкретной даты. `cancelled: true` отменяет только этот день.

**Q: Как структурировать генераторы?**

A: Strategy Pattern через базовый класс `Recurrence::BaseGenerator` и `GeneratorFactory` как фабрику. Каждый тип повторения — отдельный класс с методом `dates_in_range(date_from, date_to)`. Это соответствует OCP (открыт/закрыт) — добавление нового типа не меняет существующий код.
