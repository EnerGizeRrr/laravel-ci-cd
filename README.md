# Laravel 12 Docker + GitHub Actions

Production-ready приложение Laravel с Docker, GitHub Actions CI/CD pipeline и полной инфраструктурой развертывания.

## Быстрый старт

```bash
make up
docker compose exec app php artisan migrate
curl http://localhost/up
```

## Что включено

### Docker
- Multi-stage Dockerfile (dev & prod)
- docker-compose.yml: Nginx, PHP-FPM, MySQL 8.0, Redis 7
- Healthchecks на всех сервисах
- Named volumes для persisten данных

### Make команды
```bash
make up              # Запустить контейнеры
make down            # Остановить контейнеры
make test            # Запустить тесты
make migrate         # Выполнить миграции
make seed            # Заполнить БД тестовыми данными
make lint            # Проверить стиль кода
make lint-fix        # Исправить стиль кода
```

### CI/CD Pipeline
3-этапный GitHub Actions:
1. Lint & Static Analysis (Pint, PHPStan)
2. Tests (PHPUnit с MySQL & Redis)
3. Собрать Docker image для GHCR

## Структура проекта

```
.
├── .github/workflows/
│   ├── ci.yml              # GitHub Actions CI
│   └── deploy.yml          # CD развертывание
├── docker/
│   ├── nginx/
│   ├── mysql/
│   └── php/
├── Dockerfile              # Multi-stage
├── docker-compose.yml      # Сервисы
├── Makefile                # Команды
├── phpstan.neon            # Статический анализ
└── tests/
```

## Сервисы

| Сервис | Порт | Image |
|--------|------|-------|
| Web | 80 | nginx:alpine |
| App | 9000 | php:8.4-fpm-alpine |
| БД | 3306 | mysql:8.0 |
| Cache | 6379 | redis:7-alpine |

## Особенности

- Multi-stage Docker сборка
- Окружения для разработки и production
- Автоматизированное тестирование и проверка стиля
- Сборка Docker image и push в registry
- Rate limiting & security headers
- Структурированное JSON логирование
- Health endpoints (/health, /ready)
- Отслеживание Request-ID
- Сбор метрик

## Настройка

1. Запустить контейнеры
```bash
make up
```

2. Выполнить миграции
```bash
make migrate
```

3. Запустить тесты
```bash
make test
```

4. Развернуть
```bash
git push origin main
```

Смотрите GitHub Actions pipeline автоматически.

## CLI Команды

Доступны через Make:

- `make up` - Запустить Docker
- `make down` - Остановить Docker
- `make restart` - Перезагрузить контейнеры
- `make logs` - Просмотр логов
- `make test` - Запустить тесты
- `make lint` - Проверить стиль кода
- `make lint-fix` - Исправить стиль кода
- `make migrate` - Выполнить миграции
- `make migrate-fresh` - Сброс и переваполнение
- `make seed` - Заполнить БД
- `make refresh` - Fresh + seed
- `make tinker` - Laravel REPL
- `make shell` - Shell контейнера
- `make status` - Показать статус

## Развертывание

Автоматизировано через GitHub Actions:

1. Push на main ветку
2. CI pipeline запускается (lint, tests, build)
3. Docker image собирается и push в GHCR
4. CD workflow разворачивает на VPS через SSH

См. `.github/workflows/` для деталей.

## Health Checks

```bash
curl http://localhost/api/health     # Процесс живой
curl http://localhost/api/ready      # БД & Redis готовы
curl http://localhost/api/metrics    # Метрики производительности
```

## Тестирование

```bash
make test              # Запустить все тесты
make lint              # Проверить стиль
make lint-fix          # Авто-исправить стиль
```

Отчеты о coverage хранятся в `./coverage/` после тестов.

## Production Ready

- Non-root пользователь в prod
- Настроены security headers
- OPcache + JIT включены
- Rate limiting (nginx + Laravel)
- Структурированное логирование
- Health probes
- Автоматические backup при развертывании
- Автоматический rollback при ошибке

## Лицензия

MIT
