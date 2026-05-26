$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Content "$dir\boss-halt.flag" "stop"
Write-Host "Halt flag set. Stopping..." -ForegroundColor Yellow
Start-Sleep 3
Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {
    try { (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine -match "boss-watchdog" } catch { $false }
} | ForEach-Object {
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    Write-Host "Killed PID $($_.Id)" -ForegroundColor Red
}
Remove-Item "$dir\boss-halt.flag" -Force -ErrorAction SilentlyContinue
Write-Host "Stopped" -ForegroundColor Green
