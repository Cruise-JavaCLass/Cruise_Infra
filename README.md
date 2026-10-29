# Cruise Infrastructure (Cruise-infra)

> **Centralized Infrastructure as Code (IaC), Container Orchestration, Reverse Proxy, High Availability (HA) & Observability for the Cruise Management System.**

---

## 🏗️ Architecture Overview

The infrastructure layer coordinates containerized services across both shipboard edge environments (local offline-first deployment) and cloud data synchronization:

```
Cruise-infra/
├── compose/                    # Modular Docker Compose configurations
│   ├── docker-compose.base.yml # Core data store: PostgreSQL Primary & Redis Cache
│   ├── docker-compose.app.yml  # Application layer: Cruise-api, Cruise-web, Cruise-pos
│   └── docker-compose.ha.yml   # High Availability: PostgreSQL Standby & HAProxy
├── proxy/                      # Nginx Gateway & Reverse Proxy
│   ├── nginx.conf              # Unified port 80/443 router & SSL termination
│   └── conf.d/                 # Sub-domain and routing rules
├── db/                         # Database initialization, replication & backup
│   ├── init/                   # Base DDL and bootstrap seed scripts
│   └── backup/                 # Automated pg_dump snapshot daemons
├── monitoring/                 # Prometheus & Grafana telemetry
│   ├── prometheus/             # Metric scraping endpoints (JVM, Node, Postgres)
│   └── grafana/                # Pre-built monitoring dashboards
├── scripts/                    # Maintenance & failover drill scripts
├── .env.example                # Centralized environment variable template
├── Makefile                    # Linux/macOS command runner
└── manage.ps1                  # Windows PowerShell command runner
```

---

## 🚀 Quickstart

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop) (Docker Engine 24+ & Docker Compose v2+)
- Git 2.40+

### 1. Initialize Configuration
Copy the sample environment variables:
```bash
# On Linux / macOS:
make init

# On Windows (PowerShell):
.\manage.ps1 init
```

### 2. Port Allocation Matrix

| Service | Container Name | Host Port | Internal Port | Purpose |
|---|---|---|---|---|
| **PostgreSQL Primary** | `cruise-db-primary` | `5432` | `5432` | Core relational data store |
| **Redis Cache** | `cruise-redis` | `6379` | `6379` | Distributed session & cache |
| **Cruise Gateway / API** | `cruise-api` | `8080` | `8080` | Spring Boot API Gateway |
| **Cruise Web** | `cruise-web` | `3000` | `80` | Passenger & Crew Web Portal |
| **Cruise POS** | `cruise-pos` | `3001` | `80` | Mobile Point of Sale Terminal |
| **Nginx Reverse Proxy** | `cruise-proxy` | `80, 443` | `80, 443` | SSL Gateway & Host Router |
| **Grafana** | `cruise-grafana` | `3002` | `3000` | Observability & Metrics UI |
| **Prometheus** | `cruise-prometheus` | `9090` | `9090` | Time-series Telemetry Scraper |

---

## 🛠️ Common Operations

```bash
# Start Core Infrastructure (Postgres + Redis)
make up              # or: .\manage.ps1 up

# Inspect Service Health
make status          # or: .\manage.ps1 status

# Stream Live Container Logs
make logs            # or: .\manage.ps1 logs

# Stop Infrastructure Safely
make down            # or: .\manage.ps1 down
```

---

## 🔐 Security & Compliance Note
- **Secrets Isolation**: Never commit `.env` or production credentials to source control.
- **PCI-DSS & Maritime Hardening**: Production containers run as non-root users (`uid 10001`) with read-only root filesystems where applicable.
