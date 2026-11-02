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

init: ## Initialize environment from template (.env) with restricted permissions and unique passwords
	@if [ ! -f .env ]; then \
		(umask 077 && cp .env.example .env && chmod 0600 .env) && \
		PG_PASS=$$(openssl rand -hex 16 2>/dev/null || od -vN 16 -An -tx1 /dev/urandom | tr -d ' \n') && \
		REDIS_PASS=$$(openssl rand -hex 16 2>/dev/null || od -vN 16 -An -tx1 /dev/urandom | tr -d ' \n') && \
		REPL_PASS=$$(openssl rand -hex 16 2>/dev/null || od -vN 16 -An -tx1 /dev/urandom | tr -d ' \n') && \
		GRAF_PASS=$$(openssl rand -hex 16 2>/dev/null || od -vN 16 -An -tx1 /dev/urandom | tr -d ' \n') && \
		sed -i "s/POSTGRES_PASSWORD=cruise_secret_password_change_me/POSTGRES_PASSWORD=$$PG_PASS/" .env 2>/dev/null || \
		sed -i '' "s/POSTGRES_PASSWORD=cruise_secret_password_change_me/POSTGRES_PASSWORD=$$PG_PASS/" .env 2>/dev/null || true; \
		sed -i "s/REDIS_PASSWORD=redis_secret_password_change_me/REDIS_PASSWORD=$$REDIS_PASS/" .env 2>/dev/null || \
		sed -i '' "s/REDIS_PASSWORD=redis_secret_password_change_me/REDIS_PASSWORD=$$REDIS_PASS/" .env 2>/dev/null || true; \
		sed -i "s/POSTGRES_REPL_PASSWORD=repl_secret_password_change_me/POSTGRES_REPL_PASSWORD=$$REPL_PASS/" .env 2>/dev/null || \
		sed -i '' "s/POSTGRES_REPL_PASSWORD=repl_secret_password_change_me/POSTGRES_REPL_PASSWORD=$$REPL_PASS/" .env 2>/dev/null || true; \
		sed -i "s/GRAFANA_ADMIN_PASSWORD=grafana_admin_password_change_me/GRAFANA_ADMIN_PASSWORD=$$GRAF_PASS/" .env 2>/dev/null || \
		sed -i '' "s/GRAFANA_ADMIN_PASSWORD=grafana_admin_password_change_me/GRAFANA_ADMIN_PASSWORD=$$GRAF_PASS/" .env 2>/dev/null || true; \
		echo "Created .env with mode 0600 and generated secure unique credentials."; \
	else \
		echo ".env already exists."; \
	fi
	@echo "Infrastructure skeleton ready."

up: ## Start core infrastructure services (Database & Cache)
	@if [ -f .env ] && grep -E 'POSTGRES_PASSWORD=.*change_me|REDIS_PASSWORD=.*change_me' .env >/dev/null 2>&1; then \
		echo "[ERROR] Default placeholder passwords detected in .env. Please configure secure unique credentials or re-run 'make init' before starting the stack." >&2; \
		exit 1; \
	fi
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
