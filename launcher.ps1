$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$watchdog = "$dir\boss-watchdog.ps1"
$existing = Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {
    try { (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine -match "boss-watchdog" } catch { $false }
}
if ($existing) {
    Write-Host "Watchdog already running PID $($existing.Id)" -ForegroundColor Green
} else {
    Write-Host "Starting watchdog..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$watchdog`""
    Write-Host "Started" -ForegroundColor Green
}
Write-Host "`nCommands:" -ForegroundColor Cyan
Write-Host "  .\status.ps1   — Check status" -ForegroundColor Gray
Write-Host "  .\stop.ps1     — Stop watchdog" -ForegroundColor Gray
Write-Host "  opencode        — Open boss agent" -ForegroundColor Gray
