<div align="center">

# Boss Agent

### 24/7 Multi-Session Controller for opencode + Windows MCP

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078D4?logo=windows)](https://github.com/cryxservices-glitch/watchdog-agent)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell)](https://github.com/cryxservices-glitch/watchdog-agent)
[![GitHub Repo](https://img.shields.io/badge/Repo-watchdog--agent-181717?logo=github)](https://github.com/cryxservices-glitch/watchdog-agent)

**[Install](#-quick-install) · [How It Works](#-how-it-works) · [Setup](#-setup) · [Usage](#-usage) · [Configuration](#%EF%B8%8F-configuration) · [License](#-license)**

---

Turn **one opencode window connected to Windows MCP** into a fully autonomous **boss agent** that monitors, controls, and re-prompts every other opencode and AI model session on your machine — **24 hours a day, 7 days a week**.

**Zero cloud dependency. Zero API costs. Zero configuration.**

</div>

---

## 📦 Quick Install

```powershell
# Clone the repo
git clone https://github.com/cryxservices-glitch/watchdog-agent.git
cd watchdog-agent

# Start the background watchdog (runs 24/7)
.\launcher.ps1

# In a second terminal, open the boss agent in opencode
opencode
```

<details>
<summary><b>📋 Prerequisites</b></summary>

| Requirement | Notes |
|------------|-------|
| Windows 10 or 11 | x64 recommended |
| PowerShell 5.1+ | Ships with Windows |
| [opencode](https://opencode.ai) | `npm install -g @opencode/cli` |
| [Windows MCP](https://github.com/Windows-MCP/windows-mcp) | Install via `uv tools` or your package manager |

</details>

---

## ⚡ What It Does

AI sessions stall. Models get stuck mid-thought, hit API rate limits, drift into infinite loops, or sit idle indefinitely. Without supervision, a 10‑minute task becomes a 10‑hour wait.

The Boss Agent solves this by watching every opencode and AI session on your machine. When one stalls, it:

| Step | Action |
|------|--------|
| 1 | **Detects** the stall — CPU drops below 1% for ~30 seconds |
| 2 | **Switches** to the stalled window |
| 3 | **Types** a recovery prompt — `continue`, `y`, `proceed`, `keep going` |
| 4 | **Verifies** the session resumed — CPU returns to normal |
| 5 | **Escalates** if unrecoverable — sends a Windows notification |

It never sleeps. It never forgets. It works with any AI tool that runs in a terminal.

---

## 🧠 How It Works

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        YOUR MACHINE                              │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              BOSS WINDOW (opencode + MCP)                  │    │
│  │                                                           │    │
│  │  ┌────────────────────────┐  ┌────────────────────────┐  │    │
│  │  │  boss-watchdog.ps1     │  │  opencode agent        │  │    │
│  │  │  (PowerShell daemon)   │  │  (interactive control) │  │    │
│  │  └───────────┬────────────┘  └───────────┬────────────┘  │    │
│  │              │                           │                │    │
│  │              │  Windows MCP Toolchain     │                │    │
│  │              │  Process · App · Type ·    │                │    │
│  │              │  Snapshot · Notification   │                │    │
│  └──────────────┼───────────────────────────┼────────────────┘    │
│                 │                           │                     │
│       ┌─────────┼──────┬──────────┬─────────┼──────┐              │
│       │         │      │          │         │      │              │
│    ┌──▼──┐  ┌───▼───┐ ┌──▼───┐ ┌──▼───┐ ┌──▼───┐ ┌──▼───┐        │
│    │OC:1 │  │OC:2   │ │OC:3  │ │Hermes│ │OJI   │ │More  │        │
│    │Port │  │Port   │ │Port  │ │Agent │ │Agent │ │...   │        │
│    │5173 │  │5175   │ │5174  │ │      │ │      │ │      │        │
│    └─────┘  └───────┘ └──────┘ └──────┘ └──────┘ └──────┘        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Two Layers of Control

**Layer 1 — PowerShell Watchdog** (`boss-watchdog.ps1`)

Runs as a hidden background process. Zero user interaction required. Every 15 seconds it:

1. **Scans** every running process on the machine
2. **Matches** processes that look like opencode and AI sessions
3. **Measures** CPU consumption per session
4. **Classifies** each session: `ALIVE` (CPU > 1%), `STALLED` (CPU < 1% for 30s+), `DEAD` (process terminated)
5. **Nudges** stalled sessions via the Windows COM `SendKeys` API — activates the window, types a recovery prompt, presses Enter
6. **Persists** state to `boss-state.json` and a rotating log file
7. **Repeats** indefinitely

**Layer 2 — Opencode Boss Agent** (`opencode.json` + `.opencode/instructions.md`)

When you open opencode inside the repo directory, it automatically loads as the **boss agent** with full Windows MCP tool access:

| Command | What it does |
|---------|-------------|
| `"status"` | Lists all sessions with CPU, memory, and state |
| `"check session 2"` | Takes a screenshot and visually inspects the session |
| `"nudge session 3"` | Manually switches to and re-prompts a session |
| `"monitor everything"` | Starts a visual monitoring loop using Snapshot |
| `"alert me if anything stalls"` | Watches and sends toast notifications |

### Capability Comparison

| Feature | PowerShell Watchdog | opencode Boss Agent |
|---------|:---:|:---:|
| Runs 24/7 without input | ✅ | — |
| Auto-discovers sessions | ✅ | ✅ |
| CPU monitoring | ✅ | ✅ |
| SendKeys nudges | ✅ | ✅ |
| Visual checks (screenshots) | — | ✅ |
| Intelligent stall diagnosis | — | ✅ |
| Windows toast notifications | — | ✅ |
| Click-based interaction | — | ✅ |

Run **both** for maximum power. The PowerShell watchdog provides always‑on background supervision; the opencode agent adds visual diagnostics and manual override when you need it.

---

## 🚀 Setup

### Step 1: Clone & Launch

```powershell
git clone https://github.com/cryxservices-glitch/watchdog-agent.git
cd watchdog-agent
.\launcher.ps1
```

The launcher starts `boss-watchdog.ps1` as a hidden PowerShell process. You'll see console output confirming startup:

```
[2026-05-26 10:30:00] [SYSTEM] BOSS WATCHDOG v3 STARTED
[2026-05-26 10:30:00] [SYSTEM] Interval: 15s | Threshold: 1%
[2026-05-26 10:30:15] [STATUS] --- Cycle 1 — 3 sessions found ---
[2026-05-26 10:30:17] [STATUS] Session 1: PID 2316 CPU 45.2% MEM 320MB
[2026-05-26 10:30:17] [STATUS] Session 2: PID 8652 CPU 0.3% MEM 280MB
[2026-05-26 10:30:19] [STALL]  Session 2 STALLED
[2026-05-26 10:30:20] [NUDGE]  NUDGED session 2 (PID 8652) with 'continue'
[2026-05-26 10:30:20] [STATUS] Summary: 2 alive, 1 stalled, 0 dead | Uptime 0m
```

### Step 2: Open the Boss Agent

In a **second** terminal window:

```powershell
cd watchdog-agent
opencode
```

The directory's `opencode.json` and `.opencode/instructions.md` are loaded automatically, granting the agent Windows MCP access and informing it of its role. Try:

> *"Check all sessions and report status"*
>
> *"Watch session 2 and nudge it if it stalls"*
>
> *"Start a continuous monitoring loop"*

### Step 3: Auto-Start on Boot (Optional)

```powershell
$w = "$env:USERPROFILE\watchdog-agent"
$s = (New-Object -ComObject WScript.Shell).CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Boss Agent.lnk")
$s.TargetPath = "powershell.exe"
$s.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$w\launcher.ps1`""
$s.WorkingDirectory = $w
$s.Save()
```

---

## 📊 Usage

### Check Watchdog Status

```powershell
.\status.ps1
```

Example output:

```
Watchdog: RUNNING (PID 1234)

--- Last State ---
uptimeMin    : 45.2
cycle        : 181
sessionCount : 3

Session 1: PID 2316 | ALIVE  | CPU 45.2% | 0 nudges
Session 2: PID 8652 | ALIVE  | CPU 12.1% | 3 nudges
Session 3: PID 4412 | STALLED | CPU 0.1% | 8 nudges
```

### View Live Log

```powershell
Get-Content .\boss-watchdog.log -Tail 20
```

### Stop the Watchdog

```powershell
.\stop.ps1
```

---

## ⚙️ Configuration

All tuning parameters are at the top of `boss-watchdog.ps1`:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `Interval` | 15 seconds | Polling frequency |
| `StallThreshold` | 1.0% CPU | Below this = candidate for stall |
| Stall confirmation | 2 consecutive samples | ~30 seconds before a nudge is sent |

### Customizing Nudge Prompts

The watchdog rotates through these prompts:

```
continue → y → proceed → keep going → next → go → run → yes
```

Edit the `$NudgeTexts` array in `boss-watchdog.ps1` to add or change prompts:

```powershell
$NudgeTexts = @('continue', 'y', 'proceed', 'your custom prompt here')
```

---

## 🔧 Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "No sessions found" | AI tool uses a process name not in the match list | Edit `FindSessions` in `boss-watchdog.ps1` to include your tool's process name |
| "Can't activate window" | Window doesn't respond to COM `AppActivate` | Use the opencode agent with `windows-mcp_App` (mode: switch) instead |
| Watchdog stopped | Process was killed or crashed | Run `.\launcher.ps1` to restart |
| Nudges not reaching the model | Keystrokes going to wrong window | Ensure the stalled window has keyboard focus; no other window grabs it |
| High false positives | CPU threshold too aggressive | Raise `$StallThreshold` in `boss-watchdog.ps1` |

---

## 🧪 Why This Is Powerful

- **Fully local.** No cloud dependency. No API costs. No data leaves your machine.
- **Model‑agnostic.** Works with opencode, Codex CLI, Claude Code, Hermes, OpenJarvis — any AI tool running in a terminal.
- **Multi‑session.** Monitors any number of AI models simultaneously. Let one model work on feature A while another works on feature B.
- **Self‑healing.** Detects crashes within seconds and logs them for review.
- **Extensible.** Add kill‑and‑restart logic, Telegram alerts, screenshot capture, or rate‑limit detection.
- **Two control layers.** The PowerShell watchdog runs unattended 24/7 in the background. The opencode agent gives you full MCP‑powered interactive control.
- **Completely free.** No subscriptions, no metered APIs, no credits. Your hardware, your rules.

---

## 💡 Use Cases

| Scenario | How the Boss Agent Helps |
|----------|--------------------------|
| Running 3 opencode sessions on different codebases | Monitors all three; if one gets stuck on a rate limit, re‑prompts it |
| Long‑running code generation | Detects silent model stalls and re‑activates it |
| Multi‑model orchestration | One boss agent coordinates many worker agents |
| Overnight batch processing | Runs all night; logs every stall and nudge for morning review |
| Training / fine‑tuning workflows | Detects when training scripts hang or crash |

---

## 📁 File Reference

| File | Purpose |
|------|---------|
| `boss-watchdog.ps1` | Background watchdog — session discovery, CPU monitoring, stall nudging |
| `boss-state.json` | Live JSON state, updated every 15 seconds |
| `boss-heartbeat.json` | Heartbeat for external monitoring |
| `boss-watchdog.log` | Rotating log with timestamped entries |
| `boss-halt.flag` | Create this file to trigger a graceful shutdown |
| `opencode.json` | Opencode agent configuration with Windows MCP auto‑approval |
| `.opencode/instructions.md` | Agent instructions that define the boss agent role |
| `launcher.ps1` | One‑click background watchdog launcher |
| `status.ps1` | Quick health check and state summary |
| `stop.ps1` | Graceful watchdog termination |
| `LICENSE` | MIT license |

---

## 🤝 Contributing

Issues and pull requests are welcome. The entire watchdog is ~120 lines of PowerShell — modify it freely to fit your workflow.

---

## 📄 License

[MIT](LICENSE) — do what you want with it.

---

<div align="center">

**Built for opencode · Powered by Windows MCP**

</div>
