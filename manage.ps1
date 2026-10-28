<#
.SYNOPSIS
    Cruise Infrastructure Management PowerShell Utility.
.DESCRIPTION
    Native Windows / Cross-platform helper script to manage Cruise-infra docker containers.
.EXAMPLE
    .\manage.ps1 init
    .\manage.ps1 up
    .\manage.ps1 status
#>

param (
    [Parameter(Position = 0, Mandatory = $false)]
    [ValidateSet("init", "up", "down", "restart", "status", "logs", "clean", "help")]
    [string]$Command = "help"
)

$BaseCompose = "compose/docker-compose.base.yml"

function Show-Help {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " Cruise Management System - Infra Manager (PowerShell)   " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "Usage: .\manage.ps1 [command]`n"
    Write-Host "Commands:"
    Write-Host "  init     - Copy .env.example to .env if not present"
    Write-Host "  up       - Start core infrastructure (PostgreSQL & Redis)"
    Write-Host "  down     - Stop running containers"
    Write-Host "  restart  - Restart infrastructure services"
    Write-Host "  status   - View container health and status"
    Write-Host "  logs     - Stream container logs"
    Write-Host "  clean    - Tear down stack and remove orphan containers"
    Write-Host "  help     - Show this help message"
}

switch ($Command) {
    "init" {
        if (-not (Test-Path ".env")) {
            Copy-Item ".env.example" ".env"
            Write-Host "[OK] Created .env from .env.example" -ForegroundColor Green
        } else {
            Write-Host "[INFO] .env file already exists." -ForegroundColor Yellow
        }
    }
    "up" {
        Write-Host "[INFO] Starting core infrastructure containers..." -ForegroundColor Cyan
        docker compose -f $BaseCompose up -d
    }
    "down" {
        Write-Host "[INFO] Stopping infrastructure containers..." -ForegroundColor Cyan
        docker compose -f $BaseCompose down
    }
    "restart" {
        Write-Host "[INFO] Restarting infrastructure containers..." -ForegroundColor Cyan
        docker compose -f $BaseCompose down
        docker compose -f $BaseCompose up -d
    }
    "status" {
        docker compose -f $BaseCompose ps
    }
    "logs" {
        docker compose -f $BaseCompose logs -f --tail=100
    }
    "clean" {
        docker compose -f $BaseCompose down --remove-orphans
    }
    Default {
        Show-Help
    }
}
