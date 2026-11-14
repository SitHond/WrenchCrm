# WrenchCRM installer for Windows. Needs Docker Desktop or Podman Desktop.
# Run: powershell -ExecutionPolicy Bypass -File install.ps1
$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

function Test-Command($command) {
    try { Invoke-Expression "$command version" *> $null; return $LASTEXITCODE -eq 0 } catch { return $false }
}

if (Test-Command "docker compose") { $compose = "docker compose" }
elseif (Test-Command "podman compose") { $compose = "podman compose" }
else {
    Write-Error "Docker Desktop или Podman Desktop не найден. Установите Docker Desktop: https://www.docker.com/products/docker-desktop/"
}

function New-RandomHex([int]$bytes) {
    $buffer = New-Object byte[] $bytes
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($buffer)
    -join ($buffer | ForEach-Object { $_.ToString("x2") })
}

if (-not (Test-Path ".env")) {
    $adminEmail = Read-Host "Email администратора [admin@example.com]"
    if (-not $adminEmail) { $adminEmail = "admin@example.com" }
    $secure = Read-Host "Пароль администратора (пусто — сгенерировать)" -AsSecureString
    $adminPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
    $generated = $false
    if (-not $adminPassword) { $adminPassword = New-RandomHex 6; $generated = $true }
    $shopName = Read-Host "Название сервиса для печатных форм [Автосервис]"
    if (-not $shopName) { $shopName = "Автосервис" }

    $text = [IO.File]::ReadAllText("$PSScriptRoot\env.example", [Text.Encoding]::UTF8)
    $text = $text -replace "(?m)^POSTGRES_PASSWORD=.*$", "POSTGRES_PASSWORD=$(New-RandomHex 24)"
    $text = $text -replace "(?m)^SECRET_KEY_BASE=.*$", "SECRET_KEY_BASE=$(New-RandomHex 64)"
    $text = $text -replace "(?m)^ADMIN_EMAIL=.*$", "ADMIN_EMAIL=$adminEmail"
    $text = $text -replace "(?m)^ADMIN_PASSWORD=.*$", "ADMIN_PASSWORD=$adminPassword"
    $text = $text -replace "(?m)^SHOP_NAME=.*$", "SHOP_NAME=$shopName"
    # UTF-8 without BOM: compose cannot read the first variable after a BOM.
    [IO.File]::WriteAllText("$PSScriptRoot\.env", $text, (New-Object Text.UTF8Encoding $false))
    Write-Host "Создан файл .env"
    if ($generated) { Write-Host "Пароль администратора: $adminPassword" }
} else {
    Write-Host "Файл .env уже есть, использую его."
}

Invoke-Expression "$compose pull"
Invoke-Expression "$compose up -d"

$port = (Select-String -Path ".env" -Pattern "^APP_PORT=(.*)$").Matches.Groups[1].Value
if (-not $port) { $port = "3000" }
Write-Host ""
Write-Host "Готово. Откройте http://localhost:$port"
Write-Host "Первый запуск занимает до минуты, пока создаётся база."
