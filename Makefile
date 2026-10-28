# ==============================================================================
# Cruise Infrastructure Management Automation (Makefile)
# Convenient short commands for local development and fleet operations
# ==============================================================================

COMPOSE := docker compose --env-file .env -f compose/docker-compose.base.yml

.PHONY: help init up down restart status logs clean prune test-conn

help: ## Show this help message
	@echo "Cruise Management System - Infrastructure CLI"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

init: ## Initialize environment from template (.env) and verify prerequisites
	@if [ ! -f .env ]; then cp .env.example .env && echo "Created .env from .env.example"; else echo ".env already exists."; fi
	@echo "Infrastructure skeleton ready."

up: ## Start core infrastructure services (Database & Cache)
	$(COMPOSE) up -d

down: ## Stop all active infrastructure containers
	$(COMPOSE) down

restart: ## Restart all infrastructure containers
	$(COMPOSE) down
	$(COMPOSE) up -d

status: ## Inspect runtime status and health probes of containers
	$(COMPOSE) ps

logs: ## Follow real-time container log output
	$(COMPOSE) logs -f --tail=100

clean: ## Stop and remove containers, networks, and orphaned resources
	$(COMPOSE) down --remove-orphans

prune: ## DANGER: Clean system and purge unused Docker volumes
	docker system prune -f --volumes
