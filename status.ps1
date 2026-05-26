$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$state = "$dir\boss-state.json"
$procs = Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {
    try { (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine -match "boss-watchdog" } catch { $false }
}
if ($procs) {
    Write-Host "Watchdog: RUNNING (PID $($procs.Id))" -ForegroundColor Green
} else {
    Write-Host "Watchdog: STOPPED" -ForegroundColor Red
}
if (Test-Path $state) {
    Write-Host "`n--- Last State ---" -ForegroundColor Cyan
    Get-Content $state -Raw | ConvertFrom-Json | Format-List
}
