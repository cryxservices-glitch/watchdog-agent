# Boss Agent — 24/7 Multi-Session Controller for opencode + Windows MCP

One opencode window connected to Windows MCP monitors, controls, and prompts all other opencode/AI model sessions on your machine. Runs 24/7 with auto-recovery.

## How It Works

```
BOSS AGENT (opencode + Windows MCP)
  - Runs PowerShell watchdog in background
  - Discovers all opencode/AI sessions dynamically
  - Monitors CPU - detects stalls
  - Switches windows, types prompts
  - Alerts via Windows notifications
  - Logs everything
       |
  +----+----+----+
  |    |    |    |
  S1   S2   S3  S4  (opencode/AI worker sessions)
```

## Quick Start

### Option 1: PowerShell Watchdog (Background)

```powershell
.\boss-watchdog.ps1
```

### Option 2: opencode + Windows MCP (Full Control)

```powershell
opencode
```
Then tell the boss agent: `"start the watchdog loop"` or `"check all sessions"`

### Option 3: Combined

```powershell
# Terminal 1: Start the PowerShell watchdog
.\launcher.ps1

# Terminal 2: Open opencode as the boss
opencode
```

## Files

| File | Purpose |
|------|---------|
| `boss-watchdog.ps1` | Background watchdog - auto-discovers sessions, monitors CPU, nudges |
| `opencode.json` | opencode agent config with Windows MCP tools |
| `.opencode/instructions.md` | Instructions for opencode boss agent |
| `launcher.ps1` | One-click starter |
| `status.ps1` | Check if watchdog is running + state |
| `stop.ps1` | Gracefully stop the watchdog |
| `boss-state.json` | Live state |
| `boss-heartbeat.json` | Heartbeat for meta-monitoring |
