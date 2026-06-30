#!/usr/bin/env make

.PHONY: help up down restart logs test migrate migrate-fresh seed refresh lint lint-fix tinker shell status

help:
	@echo "Использование: make [команда]"
	@echo ""
	@echo "Docker:"
	@echo "  up              - Запустить контейнеры"
	@echo "  down            - Остановить контейнеры"
	@echo "  restart         - Перезагрузить контейнеры"
	@echo "  logs            - Просмотр логов"
	@echo "  status          - Показать статус"
	@echo ""
	@echo "База данных:"
	@echo "  migrate         - Выполнить миграции"
	@echo "  migrate-fresh   - Сброс и переваполнение"
	@echo "  seed            - Заполнить БД"
	@echo "  refresh         - Fresh + seed"
	@echo ""
	@echo "Код:"
	@echo "  test            - Запустить тесты"
	@echo "  lint            - Проверить стиль"
	@echo "  lint-fix        - Исправить стиль"
	@echo ""
	@echo "Инструменты:"
	@echo "  tinker          - Laravel REPL"
	@echo "  shell           - Shell контейнера"

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f app

status:
	docker compose ps

migrate:
	docker compose exec -T app php artisan migrate

migrate-fresh:
	docker compose exec -T app php artisan migrate:fresh

seed:
	docker compose exec -T app php artisan db:seed

refresh: migrate-fresh seed

test:
	docker compose exec -T app php artisan test

lint:
	docker compose exec -T app ./vendor/bin/pint --test

lint-fix:
	docker compose exec -T app ./vendor/bin/pint

tinker:
	docker compose exec app php artisan tinker

shell:
	docker compose exec app sh
