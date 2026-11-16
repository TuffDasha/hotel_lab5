# Лабораторна робота №5: Керування БД, оптимізація продуктивності та автоматизація

Предметна область: система бронювання готелів (Roomly hub). База даних `hotel_booking` продовжує лабораторну роботу №4.

**Автор:** Матяш Дарія Сергіївна
**Група:** ІПЗ-31
**Рівень виконання:** 3
**Звіт:** [docs/report_lab05.md](docs/report_lab05.md)

## Що реалізовано

- **Рівень 1:** аналіз трьох запитів через `EXPLAIN ANALYZE`, три індекси з порівнянням «до/після», два представлення, тригер логування, користувач з обмеженими правами
- **Рівень 2:** представлення з `RULE`, тригер валідації, `audit_log` для INSERT/UPDATE/DELETE, часткові індекси, резервне копіювання `pg_dump` і відновлення
- **Рівень 3:** матеріалізоване представлення з автооновленням, каскадні тригери, ієрархія ролей, процедура обслуговування, скрипти моніторингу

## Структура репозиторію

```
lab5/
├── README.md
├── docker-compose.yml
├── docs/
│   ├── report_lab05.md          # звіт
│   └── screenshots/             # скріншоти до звіту
└── database/
    ├── 01_create_tables.sql     # база з лабораторної №4
    ├── 02_insert_data.sql
    ├── 03_create_procedures.sql
    ├── 04_create_triggers.sql
    ├── 05_create_views.sql
    └── lab05/                   # скрипти лабораторної №5
        ├── 01_bulk_data.sql
        ├── 02_explain.sql
        ├── 03_indexes.sql
        ├── 04_views.sql
        ├── 05_audit.sql
        ├── 06_users.sql
        ├── 07_level2.sql
        ├── 08_rules_partial.sql
        ├── 09_level3_triggers.sql
        ├── 10_roles.sql
        ├── 11_maintenance.sql
        └── 12_monitoring.sql
```

## Вимоги

- Docker Desktop
- Термінал (PowerShell, bash)

## Запуск

### 1. База даних

```bash
docker compose up -d
```

Скрипти `database/01-05` виконуються автоматично при першому запуску й створюють базу `hotel_booking` з даними лабораторної №4. Файл `docker-compose.yml` підключає `pg_stat_statements` для моніторингу.

Параметри підключення: `localhost:5432`, база `hotel_booking`, користувач `postgres`, пароль `password`.

Щоб скинути базу й створити її заново:

```bash
docker compose down -v
docker compose up -d
```

### 2. Скрипти лабораторної №5

Скрипти з `database/lab05/` Docker автоматично не виконує. Скопіюйте їх у контейнер:

```bash
docker exec hotel_db mkdir -p /tmp/lab05
docker cp database/lab05/. hotel_db:/tmp/lab05/
```

Виконуйте по порядку:

```bash
docker exec hotel_db psql -U postgres -d hotel_booking -f /tmp/lab05/01_bulk_data.sql
docker exec hotel_db psql -U postgres -d hotel_booking -f /tmp/lab05/04_views.sql
docker exec hotel_db psql -U postgres -d hotel_booking -f /tmp/lab05/05_audit.sql
docker exec hotel_db psql -U postgres -d hotel_booking -f /tmp/lab05/06_users.sql
docker exec hotel_db psql -U postgres -d hotel_booking -f /tmp/lab05/07_level2.sql
docker exec hotel_db psql -U postgres -d hotel_booking -f /tmp/lab05/08_rules_partial.sql
docker exec hotel_db psql -U postgres -d hotel_booking -f /tmp/lab05/09_level3_triggers.sql
docker exec hotel_db psql -U postgres -d hotel_booking -f /tmp/lab05/10_roles.sql
docker exec hotel_db psql -U postgres -d hotel_booking -f /tmp/lab05/11_maintenance.sql
docker exec hotel_db psql -U postgres -d hotel_booking -f /tmp/lab05/12_monitoring.sql
```

Файли `02_explain.sql` і `03_indexes.sql` виконуються в `psql` інтерактивно, щоб порівняти плани запитів до та після створення індексів:

```bash
docker exec -it hotel_db psql -U postgres -d hotel_booking
```

Скрипти виконуються один раз: повторний запуск дасть помилку «already exists».

Перший скрипт (`01_bulk_data.sql`) додає близько 180 тисяч бронювань і виконується до хвилини. Без нього індекси не дають видимого ефекту, бо на малих таблицях оптимізатор обирає послідовне сканування.

## Резервне копіювання

```bash
docker exec hotel_db pg_dump -U postgres -d hotel_booking -F c -f /tmp/hotel_backup.dump
docker exec hotel_db createdb -U postgres test_restore
docker exec hotel_db pg_restore -U postgres -d test_restore /tmp/hotel_backup.dump
```

Файли `*.dump` у репозиторій не додаються (`.gitignore`).

## Технології

PostgreSQL 17, Docker, `pg_stat_statements`
