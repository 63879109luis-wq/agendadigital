# ============================================================
# iniciar_panel_admin.ps1
# Inicia el backend + abre Flutter Chrome con el Panel Admin
# Uso: clic derecho → "Ejecutar con PowerShell"
# ============================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SISTEMA ACADÉMICO - Panel Administrativo" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Directorio raíz del proyecto
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir  = Join-Path $projectRoot "backend"
$flutterDir  = Join-Path $projectRoot "mobile_app"

# 0. Limpiar puertos ocupados de ejecuciones anteriores
Write-Host "▶ Liberando puertos 3001 y 5000..." -ForegroundColor DarkGray
foreach ($port in @(3001, 5000)) {
    $pids = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess
    foreach ($p in $pids) {
        Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
    }
}
Start-Sleep -Seconds 1

# 1. Iniciar backend en ventana separada
Write-Host "▶ Iniciando backend Node.js (puerto 3001)..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList `
    "-NoExit", `
    "-Command", `
    "cd '$backendDir'; Write-Host 'BACKEND CORRIENDO' -ForegroundColor Green; node server.js"

Start-Sleep -Seconds 2

# 2. Lanzar Flutter web
Write-Host "▶ Lanzando Flutter Web (puerto 5000)..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Abriendo navegador en: http://localhost:5000" -ForegroundColor Green
Write-Host ""
Write-Host "  Teclas útiles:" -ForegroundColor Gray
Write-Host "   r = Hot reload   R = Restart   q = Salir" -ForegroundColor Gray
Write-Host ""

# Abrir el navegador automáticamente después de 4 segundos
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 4
    Start-Process "http://localhost:5000"
} | Out-Null

Set-Location $flutterDir
flutter run -d web-server --web-port 5000 --web-hostname localhost
