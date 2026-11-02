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

function New-CryptographicPassword([int]$length = 32) {
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    $bytes = [byte[]]::new($length)
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    } finally {
        $rng.Dispose()
    }
    $pass = [char[]]::new($length)
    for ($i = 0; $i -lt $length; $i++) {
        $pass[$i] = $chars[$bytes[$i] % $chars.Length]
    }
    return [string]::new($pass)
}

function Assert-NoPlaceholderPasswords {
    if (Test-Path $EnvFile) {
        $rawEnv = Get-Content $EnvFile -Raw
        if ($rawEnv -match 'POSTGRES_PASSWORD=.*change_me' -or $rawEnv -match 'REDIS_PASSWORD=.*change_me') {
            Write-Error "[ERROR] Default placeholder passwords detected in $EnvFile. Please configure secure unique credentials or re-run '.\manage.ps1 init' before starting the stack."
            exit 1
        }
    }
}

function Set-RestrictedFilePermissions([string]$filePath) {
    if ($PSVersionTable.Platform -eq "Unix") {
        try {
            & chmod 600 $filePath 2>$null
        } catch {
            Write-Warning "Could not apply chmod 600 to $filePath`: $_"
        }
    } else {
        try {
            $acl = Get-Acl -Path $filePath
            $acl.SetAccessRuleProtection($true, $false)
            $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($currentUser, "FullControl", "Allow")
            $acl.AddAccessRule($rule)
            Set-Acl -Path $filePath -AclObject $acl
        } catch {
            Write-Warning "Could not apply restricted Windows ACL on $filePath`: $_"
        }
    }
}

switch ($Command) {
    "init" {
        if (-not (Test-Path $EnvFile)) {
            try {
                $fullPath = Join-Path (Get-Location) $EnvFile
                # Create empty file and establish restrictive access before writing sensitive content
                [System.IO.File]::WriteAllText($fullPath, "")
                Set-RestrictedFilePermissions $fullPath

                $content = Get-Content ".env.example" -Raw
                # Generate unique cryptographically strong passwords
                $pgPass = New-CryptographicPassword 32
                $redisPass = New-CryptographicPassword 32
                $replPass = New-CryptographicPassword 32
                $grafanaPass = New-CryptographicPassword 32

                $content = $content -replace 'POSTGRES_PASSWORD=cruise_secret_password_change_me', "POSTGRES_PASSWORD=$pgPass"
                $content = $content -replace 'REDIS_PASSWORD=redis_secret_password_change_me', "REDIS_PASSWORD=$redisPass"
                $content = $content -replace 'POSTGRES_REPL_PASSWORD=repl_secret_password_change_me', "POSTGRES_REPL_PASSWORD=$replPass"
                $content = $content -replace 'GRAFANA_ADMIN_PASSWORD=grafana_admin_password_change_me', "GRAFANA_ADMIN_PASSWORD=$grafanaPass"

                [System.IO.File]::WriteAllText($fullPath, $content, [System.Text.Encoding]::UTF8)
                Write-Host "[OK] Created $EnvFile with restricted permissions and cryptographically secure credentials." -ForegroundColor Green
            } catch {
                Write-Error "[ERROR] Failed to initialize $EnvFile`: $_"
                exit 1
            }
        } else {
            Write-Host "[INFO] $EnvFile already exists." -ForegroundColor Yellow
        }
    }
    "up" {
        Assert-NoPlaceholderPasswords
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
        Assert-NoPlaceholderPasswords
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
