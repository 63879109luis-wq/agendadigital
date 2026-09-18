# abrir_panel_admin.ps1
# Uso: clic derecho -> Ejecutar con PowerShell
# O desde terminal: powershell -ExecutionPolicy Bypass -File abrir_panel_admin.ps1

$projectRoot   = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir    = Join-Path $projectRoot "backend"
$webAdminDir   = Join-Path $projectRoot "web-admin"
$PORT_BACKEND  = 3001
$PORT_WEBADMIN = 8090

Write-Host ""
Write-Host "==========================================="-ForegroundColor Cyan
Write-Host "  SISTEMA ACADEMICO - Panel Administrativo" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Liberar puertos anteriores
Write-Host "[1] Liberando puertos $PORT_BACKEND y $PORT_WEBADMIN..." -ForegroundColor DarkGray
foreach ($port in @($PORT_BACKEND, $PORT_WEBADMIN)) {
    $pids = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty OwningProcess
    foreach ($p in $pids) {
        Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
    }
}
Start-Sleep -Seconds 1

# 2. Iniciar Backend
Write-Host "[2] Iniciando Backend Node.js (puerto $PORT_BACKEND)..." -ForegroundColor Yellow
$backendScript = "cd '$backendDir'; node server.js"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendScript
Start-Sleep -Seconds 2

# 3. Iniciar Panel Web Admin
Write-Host "[3] Iniciando Panel Web Admin (puerto $PORT_WEBADMIN)..." -ForegroundColor Cyan
$webScript = "cd '$webAdminDir'; node server.js"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $webScript
Start-Sleep -Seconds 2

# 4. Verificar que el panel este corriendo
$conn = Get-NetTCPConnection -LocalPort $PORT_WEBADMIN -ErrorAction SilentlyContinue
if ($conn) {
    Write-Host ""
    Write-Host "[OK] Servidor activo en http://localhost:$PORT_WEBADMIN" -ForegroundColor Green
    Write-Host ""
    Start-Process "http://localhost:$PORT_WEBADMIN/login.html"
} else {
    Write-Host ""
    Write-Host "[AVISO] El servidor tarda en iniciar. Abriendo navegador de todas formas..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    Start-Process "http://localhost:$PORT_WEBADMIN/login.html"
}

Write-Host ""
Write-Host "-------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Los servidores corren en ventanas separadas." -ForegroundColor Gray
Write-Host "  NO cierres esas ventanas mientras uses el panel." -ForegroundColor Gray
Write-Host "-------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Read-Host "Presiona Enter para cerrar esta ventana"
