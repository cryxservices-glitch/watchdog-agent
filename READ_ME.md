# 🐾 Boss Agent — 24/7 Multi-Session Controller

Turn **one opencode window connected to Windows MCP** into a fully autonomous **boss agent** that monitors, controls, and prompts every other opencode/AI model session on your machine — **24 hours a day, 7 days a week**.

No cloud dependency. No paid API. Just PowerShell + Windows MCP running locally.

---

## ⚡ What It Does

The Boss Agent solves one problem: **AI sessions stall**. Models get stuck mid-thought, hit API rate limits, drift into long loops, or just go idle. Without supervision, a 10-minute task becomes a 10-hour wait.

The Boss Agent watches every opencode/AI session on your machine. When one stalls, it:

1. **Detects** it via CPU monitoring (0% CPU for 60s = stalled)
2. **Switches** to its window
3. **Types** a prompt (`continue`, `y`, `proceed`, etc.)
4. **Verifies** it resumed (CPU goes back up)
5. **Escalates** if it won't recover (Windows notification)

It never sleeps. It never forgets.

---

## 🧠 How It Works

### Architecture

```
┌──────────────────────────────────────────────────────────┐
│                      YOUR MACHINE                         │
│                                                           │
│  ┌──────────────────────────────────────────────────┐    │
│  │  BOSS WINDOW (opencode + Windows MCP)             │    │
│  │                                                    │    │
│  │  ┌─────────────────────┐  ┌───────────────────┐   │    │
│  │  │ boss-watchdog.ps1   │  │ opencode agent     │   │    │
│  │  │ (PowerShell,        │  │ (manual control,   │   │    │
│  │  │  runs 24/7)         │  │  visual checks)    │   │    │
│  │  └──────────┬──────────┘  └─────────┬─────────┘   │    │
│  │             │                       │              │    │
│  │             │  Windows MCP tools:   │              │    │
│  │             │  Process, App, Type,  │              │    │
│  │             │  Snapshot, Notification               │    │
│  └─────────────┼───────────────────────┼──────────────┘    │
│                │                       │                   │
│     ┌──────────┼───────────┬───────────┼──────────┐        │
│     │          │           │           │          │        │
│  ┌──▼──┐  ┌───▼───┐  ┌───▼───┐  ┌───▼───┐  ┌───▼───┐    │
│  │OC:1 │  │OC:2   │  │OC:3   │  │Hermes │  │OJI    │    │
│  │Port │  │Port   │  │Port   │  │Agent  │  │Agent  │    │
│  │5173 │  │5175   │  │5174   │  │       │  │       │    │
│  └─────┘  └───────┘  └───────┘  └───────┘  └───────┘    │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

### Two Layers of Control

**Layer 1: PowerShell Watchdog (`boss-watchdog.ps1`)**  
Runs in the background. Zero user interaction needed. Every 15 seconds it:

1. **Scans** all running processes for opencode/AI sessions
2. **Measures** each session's CPU usage
3. **Tags** sessions as: `ALIVE` (CPU > 1%), `STALLED` (CPU < 1% for 60s+), or `DEAD` (process gone)
4. **Nudges** stalled sessions using Windows COM (`WScript.Shell.SendKeys`):
   - Activates the stalled window
   - Types `continue`, `y`, `proceed`, `keep going`, etc. (rotates through list)
   - Presses Enter
5. **Logs** everything to `boss-state.json` and `boss-watchdog.log`
6. **Repeats** — forever

**Layer 2: opencode Boss Agent (opencode.json + .opencode/instructions.md)**  
When you open opencode in this directory, it loads as the **boss agent** with full Windows MCP access. You can:

- Ask `"status"` — shows all sessions with CPU, memory, state
- Ask `"check session 2"` — takes a screenshot and visually checks it
- Ask `"nudge session 3"` — manually switches and types a prompt
- Ask `"monitor everything"` — starts a visual monitoring loop using Snapshot
- The agent can use all Windows MCP tools: Process, Snapshot, App, Type, Click, Notification

### Why Two Layers?

| Feature | PowerShell Watchdog | opencode Boss Agent |
|---------|-------------------|-------------------|
| Runs 24/7 without input | ✅ | ❌ (needs opencode open) |
| Auto-discovers sessions | ✅ | ✅ |
| CPU monitoring | ✅ | ✅ |
| SendKeys nudges | ✅ | ✅ |
| Visual checks (screenshots) | ❌ | ✅ (via Snapshot) |
| Complex decision making | ❌ ("is it stuck?") | ✅ ("why is it stuck?") |
| User notifications | ✅ (log only) | ✅ (Windows toast) |
| Window management | ✅ (switch + type) | ✅ (switch + type + click) |

Run **both** for full power: the PowerShell watchdog runs 24/7 in the background, and when you open opencode you get full visual control.

---

## 🚀 Setup

### Requirements

- **Windows 10 or 11**
- **PowerShell 5.1+** (comes with Windows)
- **opencode** installed (`npm install -g @opencode/cli` or your install method)
- **Windows MCP** installed and configured in opencode

### Step 1: Clone

```powershell
git clone https://github.com/cryxservices-glitch/watchdog-agent.git
cd watchdog-agent
```

### Step 2: Start the Background Watchdog

```powershell
.\launcher.ps1
```

Or directly:

```powershell
.\boss-watchdog.ps1
```

You'll see output like:

```
[2026-05-26 10:30:00] [SYSTEM] BOSS WATCHDOG v3 STARTED
[2026-05-26 10:30:00] [SYSTEM] Interval: 15s | Threshold: 1%
[2026-05-26 10:30:15] [STATUS] --- Cycle 1 — 3 sessions ---
[2026-05-26 10:30:17] [STATUS] Session 1: PID 2316 CPU 45.2% MEM 320MB
[2026-05-26 10:30:17] [STATUS] Session 2: PID 8652 CPU 0.3% MEM 280MB
[2026-05-26 10:30:19] [STALL]  Session 2 STALLED
[2026-05-26 10:30:20] [NUDGE]  NUDGED session 2 (PID 8652) with 'continue'
[2026-05-26 10:30:20] [STATUS] Summary: 2 alive, 1 stalled, 0 dead | Uptime 0m
```

### Step 3: Open the Boss Agent in opencode

In a **second** terminal:

```powershell
opencode
```

Since you're in the `watchdog-agent` directory, opencode will:
- Load `opencode.json` which grants auto-approval for Windows MCP tools
- Read `.opencode/instructions.md` so it knows its job
- The agent will understand it's the "boss" and knows how to monitor/nudge

Try saying:

> "check all sessions and report status"
>
> "monitor session 2 and let me know if it stalls"
>
> "start the watchdog loop"

### Step 4: (Optional) Auto-Start on Boot

Add `launcher.ps1` to Windows Task Scheduler or Startup folder:

```powershell
# Create a shortcut in the startup folder
$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Boss Agent.lnk")
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$env:USERPROFILE\watchdog-agent\launcher.ps1`""
$shortcut.Save()
```

---

## 📊 Monitoring

### Check Status

```powershell
.\status.ps1
```

Output:

```
Watchdog: RUNNING (PID 1234)

--- Last State ---
timestamp    : 2026-05-26T10:30:00
uptimeMin    : 45.2
cycle        : 181
sessionCount : 3
sessions     : {@{id=1; pid=2316; title=opencode; status=ALIVE; cpu=45.2; nudges=0},
                @{id=2; pid=8652; title=opencode; status=ALIVE; cpu=12.1; nudges=3},
                @{id=3; pid=4412; title=opencode; status=STALLED; cpu=0.1; nudges=8}}
```

### Live Log

```powershell
Get-Content .\boss-watchdog.log -Tail 20
```

### Stop the Watchdog

```powershell
.\stop.ps1
```

---

## ⚙️ Configuration

All config is at the top of `boss-watchdog.ps1`:

| Parameter | Default | What it does |
|-----------|---------|-------------|
| `Interval` | 15 seconds | How often to check sessions |
| `StallThreshold` | 1.0% CPU | CPU below this = session might be stalled |
| Stall detection | 2 consecutive checks below threshold | ~30s before nudging |

### Nudge Text Cycle

The watchdog rotates through: `continue`, `y`, `proceed`, `keep going`, `next`, `go`, `run`, `yes`

Edit `$NudgeTexts` in the script to customize.

---

## 🔧 Troubleshooting

### "No sessions found"
The watchdog looks for processes named `powershell`, `pwsh`, or `node` whose command line or window title matches `opencode`, `codex`, `hermes`, or `openjarvis`. If your AI tool uses a different name, edit `FindSessions` in `boss-watchdog.ps1`.

### "Can't activate window"
Some windows don't respond to COM `AppActivate`. The watchdog silently skips those. The opencode boss agent can use `windows-mcp_App` mode:switch instead, which is more reliable.

### "Watchdog stopped working"
Check the log: `.\status.ps1`. If the process is dead, just restart: `.\launcher.ps1`.

### "The nudges aren't reaching my model"
SendKeys sends keystrokes to the **active window**. Make sure:
1. The window isn't minimized
2. The window has a text input focused
3. No other window steals focus between activation and typing

---

## 🧪 Why This Is Powerful

1. **Fully local** — Zero cloud dependency. No API costs. No data leaves your machine.
2. **Model-agnostic** — Works with any AI tool that runs in a terminal: opencode, Codex CLI, Claude Code, Hermes, OpenJarvis, etc.
3. **Session-agnostic** — Monitors multiple models simultaneously. Let GPT-4 work on feature A while Claude works on feature B.
4. **Self-healing** — If a session crashes, it's detected within 15 seconds and logged.
5. **Extensible** — Add custom actions per session. Kill and restart hung processes. Take screenshots. Send Telegram alerts.
6. **Two control layers** — The PowerShell watchdog runs unattended 24/7. The opencode agent gives you full MCP-powered control when you want it.
7. **Completely free** — No subscriptions, no metered API, no "credits." Your hardware, your rules.

---

## 📁 File Reference

| File | Purpose |
|------|---------|
| `boss-watchdog.ps1` | Main background watchdog — auto-discovers sessions, monitors CPU, nudges stalled ones |
| `boss-state.json` | Live JSON state — updated every 15 seconds with session status |
| `boss-heartbeat.json` | Heartbeat for monitoring if the watchdog itself is alive |
| `boss-watchdog.log` | Full log with timestamps |
| `boss-halt.flag` | Flag file — create this to gracefully stop the watchdog |
| `opencode.json` | opencode agent configuration with Windows MCP auto-approval |
| `.opencode/instructions.md` | Instructions that tell opencode it's the boss agent |
| `launcher.ps1` | One-click start the background watchdog |
| `status.ps1` | Quick status check — is watchdog running? What's the latest state? |
| `stop.ps1` | Graceful stop — sets halt flag, then force-kills if needed |

---

## 🔄 How Sessions Are Discovered

The watchdog does NOT use hardcoded PIDs or ports. It dynamically scans every `powershell`, `pwsh`, and `node` process on your machine and checks:

1. **Command line** — Does it contain `opencode`, `codex`, `hermes`, `openjarvis`?
2. **Window title** — Does the title match these names?
3. **Fallback** — Any PowerShell with a non-empty window title (for manual terminals running AI tools)

This means you can start/stop sessions freely. The watchdog adapts automatically.

---

## 💡 Use Cases

| Scenario | How the Boss Agent helps |
|----------|------------------------|
| Running 3 opencode sessions for different tasks | Monitors all 3. If one gets stuck on a rate limit, nudges it. |
| Long-running code generation | Detects when the model goes silent (stalls) and re-prompts it. |
| Multi-model orchestration | One agent controls others. Let the boss coordinate. |
| Overnight batch processing | Runs all night. Nudges stalled sessions. Logs everything for morning review. |
| Training/fine-tuning monitoring | Detects when training scripts hang or crash. |

---

## 🧩 Extending

The watchdog is designed to be extended. Here are things you can add:

- **Kill and restart** completely hung sessions
- **Send Telegram/Discord alerts** when all sessions are dead
- **Take screenshots** of stalled sessions (via opencode agent)
- **Route traffic** between sessions (e.g., pass outputs from one to another)
- **Rate limit detection** — if a session returns errors repeatedly, pause it
- **Schedule** specific tasks at specific times

The `boss-watchdog.ps1` script is ~120 lines of pure PowerShell. Modify freely.
