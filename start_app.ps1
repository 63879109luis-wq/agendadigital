$BackendPath   = Join-Path $PSScriptRoot "backend"
$OCRPath       = Join-Path $PSScriptRoot "ocr-service"
$MobileAppPath = Join-Path $PSScriptRoot "mobile_app"
$AndroidSdk      = "$env:LOCALAPPDATA\Android\Sdk"
$EmulatorExe     = "$AndroidSdk\emulator\emulator.exe"
$PlatformTools   = "$AndroidSdk\platform-tools"
$AdbExe          = "$PlatformTools\adb.exe"

# Agregar platform-tools al PATH de esta sesion para que adb sea detectable
if ($env:PATH -notlike "*$PlatformTools*") {
    $env:PATH = "$PlatformTools;$env:PATH"
    Write-Host "ADB agregado al PATH: $AdbExe" -ForegroundColor Green
}

# --- Matar procesos congelados anteriores ---
Write-Host "Limpiando procesos previos..." -ForegroundColor Yellow
Stop-Process -Name "java"                -Force -ErrorAction SilentlyContinue
Stop-Process -Name "dart"                -Force -ErrorAction SilentlyContinue
Stop-Process -Name "flutter"             -Force -ErrorAction SilentlyContinue
Stop-Process -Name "node"                -Force -ErrorAction SilentlyContinue
Stop-Process -Name "qemu-system-x86_64"  -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
Write-Host "Procesos limpiados." -ForegroundColor Green

# --- Backend (Node.js) ---
Write-Host "Iniciando Backend..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$BackendPath'; npm start"
Start-Sleep -Seconds 3

# --- OCR Service (Python) ---
Write-Host "Iniciando Servicio OCR..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$OCRPath'; .\venv\Scripts\activate.ps1; python main.py"
Start-Sleep -Seconds 2

# --- Emulador Pixel 7 ---
Write-Host "Iniciando Emulador Pixel 7..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "& '$EmulatorExe' -avd Pixel_7 -gpu host -no-snapshot-load -memory 3072 -cores 4 -no-boot-anim -adb-path '$AdbExe'"

Start-Sleep -Seconds 5

# --- Flutter Launcher Script (siempre lo genera de nuevo) ---
$tempScript = Join-Path $PSScriptRoot "flutter_launcher_temp.ps1"

$flutterScript = @"
`$MobileAppPath = "$MobileAppPath"
Set-Location "`$MobileAppPath"

Write-Host "Esperando que el emulador Pixel 7 arranque (max 4 minutos)..." -ForegroundColor Yellow

`$timeout  = 240
`$elapsed  = 0
`$interval = 5
`$deviceId = `$null

while ((-not `$deviceId) -and (`$elapsed -lt `$timeout)) {
    `$out = flutter devices 2>&1
    `$match = `$out | Select-String -Pattern "(emulator-\d+)"
    if (`$match) {
        `$deviceId = `$match.Matches[0].Groups[1].Value
        Write-Host "Dispositivo Android listo: `$deviceId" -ForegroundColor Green
    } else {
        Write-Host "Esperando emulador... (`$elapsed s / `$timeout s)" -ForegroundColor Gray
        Start-Sleep -Seconds `$interval
        `$elapsed += `$interval
    }
}

if (-not `$deviceId) {
    Write-Host "Tiempo agotado esperando el emulador. Abortando." -ForegroundColor Red
    Read-Host "Presiona Enter para cerrar"
    exit 1
}

Write-Host "Ejecutando flutter run en `$deviceId ..." -ForegroundColor Cyan
flutter run -d `$deviceId
"@

$flutterScript | Out-File -FilePath $tempScript -Encoding UTF8

Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", $tempScript

Write-Host ""
Write-Host "=== Todos los servicios iniciados ===" -ForegroundColor Green
Write-Host "  Backend  -> http://localhost:3001" -ForegroundColor White
Write-Host "  OCR      -> http://localhost:5000" -ForegroundColor White
Write-Host "  Pixel 7  -> Iniciando (espera 2-3 min, la app aparece automaticamente)" -ForegroundColor White
Write-Host ""
