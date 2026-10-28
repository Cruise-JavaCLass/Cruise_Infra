# ==============================================================================
# Cruise Infrastructure Management Automation (Makefile)
# Convenient short commands for local development and fleet operations
# ==============================================================================

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
	docker compose -f compose/docker-compose.base.yml up -d

down: ## Stop all active infrastructure containers
	docker compose -f compose/docker-compose.base.yml down

restart: down up ## Restart all infrastructure containers

status: ## Inspect runtime status and health probes of containers
	docker compose -f compose/docker-compose.base.yml ps

logs: ## Follow real-time container log output
	docker compose -f compose/docker-compose.base.yml logs -f --tail=100

clean: ## Stop and remove containers, networks, and orphaned resources
	docker compose -f compose/docker-compose.base.yml down --remove-orphans

prune: ## DANGER: Clean system and purge unused Docker volumes
	docker system prune -f --volumes
