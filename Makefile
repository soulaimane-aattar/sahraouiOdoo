# Makefile for managing Odoo Docker environment

# Variables
COMPOSE = docker compose
SERVICES = saharawi-odoo saharawi-db

.PHONY: all build up down logs shell-db shell-odoo ps clean init-db reset-db

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
	$(COMPOSE) up -d saharawi-db saharawi-odoo
	$(COMPOSE) exec -T saharawi-db sh -lc 'psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -c "ALTER ROLE \"$$POSTGRES_USER\" WITH PASSWORD '\''$$POSTGRES_PASSWORD'\'';"'
	$(COMPOSE) exec -T saharawi-odoo /entrypoint.sh odoo -d "$$DATABASE" -i base -u base,web --without-demo=all --stop-after-init

reset-db:
	$(COMPOSE) up -d saharawi-db
	$(COMPOSE) exec -T saharawi-db sh -lc 'psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='\''$$POSTGRES_DB'\'';"'
	$(COMPOSE) exec -T saharawi-db sh -lc 'psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d postgres -c "DROP DATABASE IF EXISTS \"$$POSTGRES_DB\";"'
	$(COMPOSE) exec -T saharawi-db sh -lc 'psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d postgres -c "CREATE DATABASE \"$$POSTGRES_DB\" OWNER \"$$POSTGRES_USER\";"'
	$(MAKE) init-db

clean:
	$(COMPOSE) down -v --remove-orphans
