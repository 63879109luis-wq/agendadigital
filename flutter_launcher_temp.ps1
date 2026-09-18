$MobileAppPath = "C:\Users\msi_u\Desktop\mi proyecto\mobile_app"
Set-Location "$MobileAppPath"

Write-Host "Esperando que el emulador Pixel 7 arranque (max 4 minutos)..." -ForegroundColor Yellow

$timeout  = 240
$elapsed  = 0
$interval = 5
$deviceId = $null

while ((-not $deviceId) -and ($elapsed -lt $timeout)) {
    $out = flutter devices 2>&1
    $match = $out | Select-String -Pattern "(emulator-\d+)"
    if ($match) {
        $deviceId = $match.Matches[0].Groups[1].Value
        Write-Host "Dispositivo Android listo: $deviceId" -ForegroundColor Green
    } else {
        Write-Host "Esperando emulador... ($elapsed s / $timeout s)" -ForegroundColor Gray
        Start-Sleep -Seconds $interval
        $elapsed += $interval
    }
}

if (-not $deviceId) {
    Write-Host "Tiempo agotado esperando el emulador. Abortando." -ForegroundColor Red
    Read-Host "Presiona Enter para cerrar"
    exit 1
}

Write-Host "Ejecutando flutter run en $deviceId ..." -ForegroundColor Cyan
flutter run -d $deviceId
