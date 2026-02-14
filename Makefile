# Makefile for managing Odoo Docker environment

# Variables
COMPOSE = docker compose
SERVICES = saharawi-odoo saharawi-db

.PHONY: all build up down logs shell-db shell-odoo ps clean init-db reset-db bootstrap

all: build up

build:
	$(COMPOSE) build

up:
	$(COMPOSE) up -d

stop:
	$(COMPOSE) down 

down:
	$(COMPOSE) down

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f saharawi-odoo

shell-db:
	$(COMPOSE) exec saharawi-db sh

shell-odoo:
	$(COMPOSE) exec saharawi-odoo bash

init-db:
	$(COMPOSE) up -d saharawi-db
	$(COMPOSE) exec -T saharawi-db sh -lc 'until pg_isready -h 127.0.0.1 -U "$$POSTGRES_USER" >/dev/null 2>&1; do sleep 1; done'
	$(COMPOSE) stop saharawi-odoo
	$(COMPOSE) exec -T saharawi-db sh -lc 'psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -c "ALTER ROLE \"$$POSTGRES_USER\" WITH PASSWORD '\''$$POSTGRES_PASSWORD'\'';"'
	$(COMPOSE) exec -T saharawi-db sh -lc 'if [ "$$(psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -tAc "SELECT to_regclass('\''public.ir_module_module'\'');")" = "public.ir_module_module" ]; then echo "Odoo schema detected in $$POSTGRES_DB"; else echo "Odoo schema missing in $$POSTGRES_DB, recreating database"; psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='\''$$POSTGRES_DB'\'';"; psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d postgres -c "DROP DATABASE IF EXISTS \"$$POSTGRES_DB\";"; psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d postgres -c "CREATE DATABASE \"$$POSTGRES_DB\" OWNER \"$$POSTGRES_USER\";"; fi'
	$(COMPOSE) run --rm saharawi-odoo /entrypoint.sh odoo -d "$$DATABASE" -i base -u base,web --without-demo=all --stop-after-init
	$(COMPOSE) up -d saharawi-odoo

bootstrap: init-db

reset-db:
	$(COMPOSE) stop saharawi-odoo
	$(COMPOSE) up -d saharawi-db
	$(COMPOSE) exec -T saharawi-db sh -lc 'psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='\''$$POSTGRES_DB'\'';"'
	$(COMPOSE) exec -T saharawi-db sh -lc 'psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d postgres -c "DROP DATABASE IF EXISTS \"$$POSTGRES_DB\";"'
	$(COMPOSE) exec -T saharawi-db sh -lc 'psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d postgres -c "CREATE DATABASE \"$$POSTGRES_DB\" OWNER \"$$POSTGRES_USER\";"'
	$(MAKE) init-db

clean:
	$(COMPOSE) down -v --remove-orphans
