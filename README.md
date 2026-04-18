# NetPulse

A lightweight macOS menu bar app that monitors network latency in real time. Pings configurable WAN and LAN hosts every few seconds and displays results — color-coded — directly in your status bar, with stats, packet loss, jitter, and smart alert notifications.

![macOS 12+](https://img.shields.io/badge/macOS-12%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-green) ![Version](https://img.shields.io/badge/version-1.3.1-blue)

## Features

- Live latency display in the menu bar (green / orange / red)
- Last 5 ping results in the dropdown (10-sample window used internally for stats)
- **WAN / LAN symmetric headers** — both sections use the same `WAN: host   N% loss` / `LAN: host   N% loss` format
- **Packet loss %** shown in both WAN and LAN headers
- **Sparkline graph** — `▁▂▃▄▅▆▇█▏` Unicode bar chart with a thin playhead marker at the right (newest); timeouts shown as `·`; bars use absolute latency thresholds
- **Min / avg / max / jitter** stats summary above the ping history
- **LAN two-line summary** — host + loss on one line, avg + jitter stats indented below
- **Latency alerts** — macOS notification when latency exceeds a configurable threshold (default 200 ms); smart anti-spam: one alert per bad run, suppressed until recovery
- Configurable WAN host, LAN host, ping interval, and alert threshold
- Launch at Login support
- No Dock icon — lives entirely in the menu bar

## Installation

1. Download **NetPulse.dmg** from the [latest release](https://github.com/chandrashekarhs/netpulse/releases/latest)
2. Open the DMG and drag **NetPulse.app** to Applications
3. Launch from Spotlight or Applications

> **First launch:** Right-click → Open to bypass Gatekeeper (ad-hoc signed build)

---

## Reading the menu

### Status bar dot

The colored dot in your menu bar gives you an instant signal:

| Dot color | What it means | Example |
|---|---|---|
| Green | Latency < 50 ms — excellent | `● 14 ms` |
| Orange | Latency 50–150 ms — acceptable | `● 87 ms` |
| Red | Latency > 150 ms or timeout — degraded | `● 210 ms` / `● timeout` |
| Gray | No network connection | `● no network` |

---

### Menu header — app name + WAN status

```
NetPulse
WAN: 8.8.8.8   2% loss
```

The header is two lines. The app name sits at the top; directly below it is the WAN status in the same format as the LAN line, making them easy to compare at a glance.

| Part | Meaning |
|---|---|
| `8.8.8.8` | The WAN host being pinged (configurable) |
| `2% loss` | 2 out of the last 10 pings timed out |
| `0% loss` | All recent pings succeeded |
| `100% loss` | All recent pings timed out — host unreachable or no internet |

**Example scenarios:**

- `WAN: 8.8.8.8   0% loss` — everything is fine
- `WAN: 8.8.8.8   30% loss` — intermittent packet loss; video calls will suffer
- `WAN: 8.8.8.8   100% loss` — no internet (check LAN section below to determine if it's your router or ISP)

---

### Sparkline graph

```
▁▂▃▄▃▂▄▅▇█▏
```

A Unicode bar chart of the last 10 pings, read left (oldest) to right (newest). The thin `▏` at the right is a "now" marker — it sits at the present moment, like a playhead. Each bar is one ping result.

| Symbol | Meaning |
|---|---|
| `▁` `▂` `▃` `▄` `▅` `▆` `▇` `█` | Relative latency — taller bar = higher latency |
| `·` | Ping timed out |

Bars are scaled **relative to your current window** — the tallest bar always represents your worst recent ping, the shortest your best. This makes spikes immediately visible even on a generally fast connection.

**Example patterns:**

| Sparkline | What it looks like | Interpretation |
|---|---|---|
| `▂▂▂▂▂▂▂▂▂▂` | Flat low line | Stable, fast connection |
| `▄▄▄▄▄▄▄▄▄▄` | Flat mid line | Stable but slower, or all pings identical |
| `▁▁▁▂▄▇█▇▄▂` | Mountain shape | Latency spiked and recovered |
| `▂▂▂▂▂▂▂▂▂█` | Sudden spike at right | Latest ping was anomalously slow |
| `▁▂▃▅▇▇▅▃▂▁` | Rounded hill | Gradual degradation then recovery |
| `·▂·▃·▂·▂·▂` | Alternating dots | Intermittent packet loss every other ping |
| `··········` | All dots | Complete outage — host unreachable |
| `▄▄▄▄▄▄▄▄▄·` | Flat then dot | Connection just dropped |

**Note:** Because bars are relative, a flat `▄▄▄▄▄▄▄▄▄▄` line can mean either consistently good latency or consistently bad — check the stats line below it for the actual numbers.

---

### Stats lines — avg / jitter / min / max

```
avg: 18 ms   jitter: 4 ms
min: 12 ms   max: 34 ms
```

Two lines, computed from the last 10 successful pings. Same format shown for both WAN and LAN sections.

| Metric | What it measures | Good | Concerning |
|---|---|---|---|
| `avg` | Typical latency you experience | < 50 ms | > 150 ms |
| `jitter` | Standard deviation — how *stable* the connection is | < 10 ms | > 30 ms |
| `min` | Best-case latency — the floor | < 20 ms | > 100 ms |
| `max` | Worst-case spike in the window | < 100 ms | > 300 ms |

**Jitter explained:**
Jitter measures variability, not speed. A connection with `avg: 20 ms, jitter: 2 ms` is very stable — latency barely moves. One with `avg: 20 ms, jitter: 40 ms` is erratic — latency swings wildly even though the average looks fine. High jitter causes choppy audio and video even when average latency seems acceptable.

**Example scenarios:**

| Stats line | Interpretation |
|---|---|
| `min: 8 ms   avg: 12 ms   max: 18 ms   jitter: 2 ms` | Excellent — fast and rock-solid |
| `min: 45 ms   avg: 80 ms   max: 200 ms   jitter: 45 ms` | High jitter — connection is unstable, expect choppy calls |
| `min: —   avg: —   max: —   jitter: —` | All recent pings timed out, no successful results to compute |
| `min: 5 ms   avg: 6 ms   max: 8 ms   jitter: 1 ms` | LAN-like numbers on a WAN host — unusually good, possibly VPN with local exit |

---

### Ping history

```
12:01:08      34.2 ms
12:01:05      12.3 ms
12:01:02   ✗  timeout
11:01:59      18.1 ms
```

The last 10 pings in reverse chronological order (newest first). Each line shows:
- **Timestamp** — when the ping completed (`HH:mm:ss`)
- **Latency** — round-trip time in milliseconds, or `✗  timeout` if no response within 2 seconds

A single timeout is usually noise. Three or more timeouts in a row indicates a real problem.

---

### LAN summary

```
LAN: 192.168.1.1   0% loss
     avg: 2 ms   jitter: 0 ms
```

A two-line view of your secondary (LAN) host — typically your router. Use this line together with the WAN header to diagnose where a problem lives:

| WAN | LAN | Likely cause |
|---|---|---|
| High latency / loss | Low latency / no loss | ISP or upstream problem — your router is fine |
| High latency / loss | High latency / loss | Local network problem — router, Wi-Fi, or Ethernet |
| Timeout | Low latency / no loss | DNS or internet outage — LAN is healthy |
| Timeout | Timeout | Total network failure — check physical connection |

**Example — ISP problem:**
```
NetPulse
WAN: 8.8.8.8   40% loss
·▂·▅·▇·█·▃▏
avg: 210 ms   jitter: 190 ms
min: 80 ms    max: 890 ms
LAN: 192.168.1.1   0% loss
     avg: 1 ms   jitter: 0 ms
     min: 1 ms   max: 2 ms
```
Router responds instantly (LAN clean), but WAN is dropping packets and spiking. Call your ISP.

**Example — Wi-Fi problem:**
```
NetPulse
WAN: 8.8.8.8   20% loss
▂▄·▅▃·▆▄·▅▏
avg: 120 ms   jitter: 80 ms
min: 30 ms    max: 450 ms
LAN: 192.168.1.1   20% loss
     avg: 45 ms   jitter: 35 ms
     min: 2 ms    max: 180 ms
```
Both WAN and LAN are struggling. The problem is between your Mac and the router — try moving closer or switching to Ethernet.

---

### Latency alert notifications

When latency exceeds your configured threshold (default: 200 ms) or a ping times out, NetPulse fires a macOS notification:

> **NetPulse — Network Alert**
> High latency: 310 ms (threshold: 200 ms)

**Anti-spam behaviour:** Only one notification fires per "bad run." Subsequent bad pings are silenced. Once latency recovers below the threshold, the latch resets and the next bad run will notify again.

This means you get alerted when things go wrong, not every 3 seconds while they stay wrong.

---

## Settings

Open via the menu → **Settings…** (or `⌘,`).

| Field | Default | Description |
|---|---|---|
| LAN Host | `192.168.1.1` | Secondary ping target — usually your router |
| WAN Host / IP | `8.8.8.8` | Primary ping target — use an IP or hostname |
| Interval (sec) | `3` | Seconds between pings (minimum: 1) |
| Alert (ms) | `200` | Latency threshold that triggers a notification |

Changes apply immediately — no restart needed.

**Tip:** Set WAN Host to `1.1.1.1` (Cloudflare) as an alternative to `8.8.8.8` (Google). Both are reliable global DNS servers with minimal latency.

---

## Latency color thresholds

| Color | Range |
|---|---|
| Green | < 50 ms |
| Orange | 50 – 150 ms |
| Red | > 150 ms or timeout |
| Gray | No network |

---

## Building from source

No Xcode required — uses Swift Package Manager.

```bash
git clone https://github.com/chandrashekarhs/netpulse.git
cd netpulse
make build        # → .build/release/NetPulse
make run          # build + run (dev)
make package      # → NetPulse.dmg
make clean
```

**Requirements:** macOS 12+, Swift 5.9+

---

## Contributing

All changes go through pull requests — `main` is a protected branch.

```bash
git checkout -b feature/your-change
# make changes
git push origin feature/your-change
# open PR on GitHub
```

### Claude Code

This project includes Claude Code agents and slash commands for common dev tasks:

| Command | What it does |
|---|---|
| `/release` | Walks through version bump → PR → tag step by step |
| `/swift-review` | Reviews uncommitted Swift changes for AppKit best practices |
| `/diagnose` | Diagnoses runtime issues (ping failures, duplicate instances, menu bugs) |

See `CLAUDE.md` for full project context and agent details.

CI runs `swift build -c release` on every PR. Squash merge only.

## Releasing

Push a version tag after merging to `main`:

```bash
git tag v1.2.0 && git push origin v1.2.0
```

GitHub Actions builds and publishes `NetPulse.dmg` automatically as a release asset.
