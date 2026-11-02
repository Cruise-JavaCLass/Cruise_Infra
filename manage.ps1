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
$EnvFile = ".env"

function Show-Help {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " Cruise Management System - Infra Manager (PowerShell)   " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "Usage: .\manage.ps1 [command]`n"
    Write-Host "Commands:"
    Write-Host "  init     - Copy .env.example to .env and generate secure unique credentials"
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
        if (-not (Test-Path $EnvFile)) {
            try {
                $content = Get-Content ".env.example" -Raw
                # Generate unique cryptographically strong passwords for placeholders
                $pgPass = -join ((1..32) | ForEach-Object { [char]((65..90) + (97..122) + (48..57) | Get-Random) })
                $redisPass = -join ((1..32) | ForEach-Object { [char]((65..90) + (97..122) + (48..57) | Get-Random) })
                $replPass = -join ((1..32) | ForEach-Object { [char]((65..90) + (97..122) + (48..57) | Get-Random) })
                $grafanaPass = -join ((1..32) | ForEach-Object { [char]((65..90) + (97..122) + (48..57) | Get-Random) })

                $content = $content -replace 'POSTGRES_PASSWORD=cruise_secret_password_change_me', "POSTGRES_PASSWORD=$pgPass"
                $content = $content -replace 'REDIS_PASSWORD=redis_secret_password_change_me', "REDIS_PASSWORD=$redisPass"
                $content = $content -replace 'POSTGRES_REPL_PASSWORD=repl_secret_password_change_me', "POSTGRES_REPL_PASSWORD=$replPass"
                $content = $content -replace 'GRAFANA_ADMIN_PASSWORD=grafana_admin_password_change_me', "GRAFANA_ADMIN_PASSWORD=$grafanaPass"

                [System.IO.File]::WriteAllText((Join-Path (Get-Location) $EnvFile), $content, [System.Text.Encoding]::UTF8)
                Write-Host "[OK] Created $EnvFile with auto-generated secure credentials." -ForegroundColor Green
            } catch {
                Write-Error "[ERROR] Failed to initialize $EnvFile`: $_"
                exit 1
            }
        } else {
            Write-Host "[INFO] $EnvFile already exists." -ForegroundColor Yellow
        }
    }
    "up" {
        if (Test-Path $EnvFile) {
            $rawEnv = Get-Content $EnvFile -Raw
            if ($rawEnv -match 'POSTGRES_PASSWORD=.*change_me' -or $rawEnv -match 'REDIS_PASSWORD=.*change_me') {
                Write-Error "[ERROR] Default placeholder passwords detected in $EnvFile. Please configure secure unique credentials or re-run '.\manage.ps1 init' before starting the stack."
                exit 1
            }
        }
        Write-Host "[INFO] Starting core infrastructure containers..." -ForegroundColor Cyan
        docker compose --env-file $EnvFile -f $BaseCompose up -d
        exit $LASTEXITCODE
    }
    "down" {
        Write-Host "[INFO] Stopping infrastructure containers..." -ForegroundColor Cyan
        docker compose --env-file $EnvFile -f $BaseCompose down
        exit $LASTEXITCODE
    }
    "restart" {
        Write-Host "[INFO] Restarting infrastructure containers..." -ForegroundColor Cyan
        docker compose --env-file $EnvFile -f $BaseCompose down
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        docker compose --env-file $EnvFile -f $BaseCompose up -d
        exit $LASTEXITCODE
    }
    "status" {
        docker compose --env-file $EnvFile -f $BaseCompose ps
        exit $LASTEXITCODE
    }
    "logs" {
        docker compose --env-file $EnvFile -f $BaseCompose logs -f --tail=100
        exit $LASTEXITCODE
    }
    "clean" {
        docker compose --env-file $EnvFile -f $BaseCompose down --remove-orphans
        exit $LASTEXITCODE
    }
    Default {
        Show-Help
    }
}
