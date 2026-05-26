param(
    [int]$Interval = 15,
    [double]$StallThreshold = 1.0,
    [string]$Dir = ""
)

$ErrorActionPreference = "Continue"
if (-not $Dir) { $Dir = Split-Path -Parent $MyInvocation.MyCommand.Path }

$StateFile  = "$Dir\boss-state.json"
$HBeatFile  = "$Dir\boss-heartbeat.json"
$LogFile    = "$Dir\boss-watchdog.log"
$HaltFlag   = "$Dir\boss-halt.flag"
$script:Cycle = 0
$script:StartTime = Get-Date
$NudgeTexts = @('continue','y','proceed','keep going','next','go','run','yes')

function Log($M, $L="INFO") {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] [$L] $M"
    Write-Host $line
    try { Add-Content $LogFile $line -ErrorAction SilentlyContinue } catch {}
}

function FindSessions {
    $sessions = @()
    $seen = @{}
    $targets = Get-Process powershell,pwsh,node -ErrorAction SilentlyContinue
    foreach ($p in $targets) {
        if ($seen[$p.Id]) { continue }
        $seen[$p.Id] = $true
        try {
            $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId = $($p.Id)").CommandLine
        } catch { $cmd = "" }
        $isTarget = $cmd -match "opencode|codex|hermes|openjarvis|open -ai" -or $p.MainWindowTitle -match "opencode|codex|hermes"
        if ($isTarget -or ($p.MainWindowTitle -and $p.MainWindowTitle -ne "" -and $cmd -match "powershell|pwsh")) {
            $sessions += [PSCustomObject]@{
                Id=($sessions.Count+1); Pid=$p.Id; Title=[regex]::Replace($p.MainWindowTitle, '[^\x20-\x7E]','')
                Status="ALIVE"; CPU=0.0; StallC=0; NudgeC=0
            }
        }
    }
    return $sessions
}

function Nudge($S) {
    try {
        $w = New-Object -ComObject WScript.Shell
        $ok = $false
        try { $ok = $w.AppActivate($S.Pid) } catch {}
        if (-not $ok) { try { $ok = $w.AppActivate($S.Title) } catch {} }
        if (-not $ok) { return $false }
        Start-Sleep -Milliseconds 800
        $txt = $NudgeTexts[$S.NudgeC % $NudgeTexts.Count]
        $w.SendKeys($txt)
        Start-Sleep -Milliseconds 200
        $w.SendKeys("{ENTER}")
        Log "NUDGED session $($S.Id) (PID $($S.Pid)) with '$txt'" "NUDGE"
        return $true
    } catch { return $false }
}

function CPU($Pid) {
    try {
        $p1 = Get-Process -Id $Pid -ErrorAction SilentlyContinue
        if (-not $p1) { return $null,0 }
        $c1 = $p1.CPU
        Start-Sleep 2
        $p2 = Get-Process -Id $Pid -SilentlyContinue
        if (-not $p2) { return $null,0 }
        $c2 = $p2.CPU
        $d = [Math]::Max(0, $c2-$c1)
        return $p2, [Math]::Round($d/2*100,1)
    } catch { return $null,0 }
}

Log "BOSS WATCHDOG v3 STARTED" "SYSTEM"
Log "Interval: ${Interval}s | Threshold: ${StallThreshold}%" "SYSTEM"

while ($true) {
    if (Test-Path $HaltFlag) { Log "Halt flag - stopping" "SYSTEM"; Remove-Item $HaltFlag -Force; break }
    $script:Cycle++
    $sessions = FindSessions
    if ($sessions.Count -eq 0) { Log "No sessions found" "WARN"; Start-Sleep 10; continue }

    Log "--- Cycle $($script:Cycle) — $($sessions.Count) sessions ---" "STATUS"
    foreach ($s in $sessions) {
        $p, $cpu = CPU $s.Pid
        $s.CPU = $cpu
        $mem = if ($p) { [Math]::Round($p.WorkingSet64/1MB,0) } else {0}
        if (-not $p) { $s.Status="DEAD"; Log "Session $($s.Id) PID $($s.Pid): DEAD" "CRIT"; continue }
        Log "Session $($s.Id): PID $($s.Pid) CPU ${cpu}% MEM ${mem}MB" "STATUS"

        if ($cpu -lt $StallThreshold) {
            $s.StallC++
            if ($s.StallC -ge 2) {
                $s.Status="STALLED"
                Log "Session $($s.Id) STALLED" "STALL"
                if (Nudge $s) { $s.NudgeC++ }
            }
        } else { $s.Status="ALIVE"; $s.StallC=0 }
    }

    $a = ($sessions|?{$_.Status-eq"ALIVE"}).Count
    $st = ($sessions|?{$_.Status-eq"STALLED"}).Count
    $d = ($sessions|?{$_.Status-eq"DEAD"}).Count
    $up = [Math]::Round(((Get-Date)-$script:StartTime).TotalMinutes)
    Log "Summary: ${a} alive, ${st} stalled, ${d} dead | Uptime ${up}m | Next in ${Interval}s" "STATUS"

    $data = @{timestamp=(Get-Date).ToString("o"); uptimeMin=$up; cycle=$script:Cycle; sessions=@($sessions|%{@{id=$_.Id;pid=$_.Pid;title=$_.Title;status=$_.Status;cpu=$_.CPU;nudges=$_.NudgeC}})}
    try { Set-Content $StateFile ($data|ConvertTo-Json -Compress -Depth 3) -Force } catch {}
    try { Set-Content $HBeatFile (@{ts=(Get-Date).ToString("o"); alive=$a; stalled=$st; dead=$d}|ConvertTo-Json -Compress) -Force } catch {}

    Start-Sleep $Interval
}
Log "Stopped" "SYSTEM"
