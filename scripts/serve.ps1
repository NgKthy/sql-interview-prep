# ============================================================
# scripts/serve.ps1
# Chay local server de mo index.html voi fetch() hoat dong
# ============================================================

param(
    [int]$Port = 8000
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host ""
Write-Host "=== SQL Interview Prep - Local Server ===" -ForegroundColor Cyan
Write-Host "Repo : $root"
Write-Host "Port : $Port"
Write-Host ""

# Thu Python
$py = Get-Command python -ErrorAction SilentlyContinue
if ($py) {
    Write-Host "-> Dung Python HTTP server" -ForegroundColor Green
    Write-Host "-> Mo: http://localhost:$Port" -ForegroundColor Yellow
    Write-Host ""
    Start-Process "http://localhost:$Port"
    python -m http.server $Port
    exit
}

$py3 = Get-Command python3 -ErrorAction SilentlyContinue
if ($py3) {
    Write-Host "-> Dung Python 3 HTTP server" -ForegroundColor Green
    Write-Host "-> Mo: http://localhost:$Port" -ForegroundColor Yellow
    Write-Host ""
    Start-Process "http://localhost:$Port"
    python3 -m http.server $Port
    exit
}

# Thu Node/npx
$npx = Get-Command npx -ErrorAction SilentlyContinue
if ($npx) {
    Write-Host "-> Dung npx serve" -ForegroundColor Green
    Write-Host "-> Mo: http://localhost:$Port" -ForegroundColor Yellow
    Write-Host ""
    Start-Process "http://localhost:$Port"
    npx --yes serve -l $Port
    exit
}

# Khong tim thay Python / Node
Write-Host "[X] Khong tim thay Python hoac Node.js." -ForegroundColor Red
Write-Host ""
Write-Host "Cai 1 trong 2:" -ForegroundColor Yellow
Write-Host "  - Python : https://www.python.org/downloads/"
Write-Host "  - Node.js: https://nodejs.org/"
Write-Host ""
Write-Host "Hoac dung extension VS Code 'Live Server' -> chuot phai vao index.html -> Open with Live Server."
