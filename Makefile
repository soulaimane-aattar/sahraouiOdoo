# Makefile for managing Odoo Docker environment

# Variables
COMPOSE = docker compose
SERVICES = odoo db

.PHONY: all build up down logs shell-db shell-odoo ps clean init-db

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
	$(COMPOSE) logs -f odoo

shell-db:
	$(COMPOSE) exec db sh

shell-odoo:
	$(COMPOSE) exec odoo bash

init-db:
	$(COMPOSE) exec -T odoo odoo -c /etc/odoo/odoo.conf -d odoo -i base --without-demo=all --stop-after-init

clean:
	$(COMPOSE) down -v --remove-orphans
