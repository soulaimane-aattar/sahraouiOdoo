# Makefile for managing Odoo Docker environment

# Variables
COMPOSE = docker-compose
SERVICES = odoo db

.PHONY: all build up down logs shell-db shell-odoo ps clean

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

clean:
	$(COMPOSE) down -v --remove-orphans
