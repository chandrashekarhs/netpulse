# NetPulse — Claude Code Guide

macOS menu bar app that monitors network latency by pinging configurable WAN and LAN hosts, displaying results in the status bar with color coding, stats, and alert notifications. Written in Swift, built with Swift Package Manager. No Xcode project.

## Build & Run

```bash
make build      # swift build -c release → .build/release/NetPulse
make run        # swift run (debug, dev loop)
make package    # compiles + generates icon + creates signed .app + .dmg
make clean
```

## Project Structure

```
Sources/NetPulse/
  main.swift               # entry point only — wires NSApplication
Sources/NetPulseCore/
  AppDelegate.swift        # coordinator: owns all services, wires callbacks
  Constants.swift          # appName, version, UserDefaults keys, defaults
  Models/PingResult.swift  # latency: Double?, timestamp: Date
  Services/
    PingService.swift      # ping timer, history (capped at 10), onResult callback
    NetworkMonitor.swift   # NWPathMonitor wrapper, onStatusChange callback
    AlertService.swift     # UNUserNotification alerts with anti-spam latch
  UI/
    StatusBarController.swift  # NSStatusItem, dotImage(), color thresholds
    MenuController.swift       # rebuilds NSMenu on every ping/network event
    SettingsPanel.swift        # NSAlert-based settings (4 fields) + about panel
    LoginItemManager.swift     # LaunchAgent plist in ~/Library/LaunchAgents/
Scripts/
  make_icon.swift   # generates AppIcon.iconset via AppKit drawing
  package.sh        # bundles .build/release/NetPulse into .app + .dmg
```

## Key Conventions

- **No Xcode project** — `Package.swift` is the sole build manifest.
- **No third-party dependencies** — AppKit + Network + UserNotifications frameworks only.
- **Ping via `/sbin/ping`** — avoids raw ICMP socket privileges. Latency parsed with regex `time=(\d+\.?\d*)\s*ms`.
- **Status bar only** — `NSApp.setActivationPolicy(.accessory)` + `LSUIElement=true` hides from Dock.
- **Menu rebuilt on every event** — `MenuController.rebuild()` is called after each ping result and each network state change. Simple and correct; not a performance concern at this scale.
- **Callback pattern** — `PingService.onResult` and `NetworkMonitor.onStatusChange` deliver events to `AppDelegate` on the main queue.
- **Two PingService instances** — `pingService` (WAN) drives the status bar, alert evaluation, and menu; `lanPingService` (LAN) drives only the compact LAN summary line. Both share the same ping interval.
- **GatewayDetector** — `Services/GatewayDetector.swift` runs `/sbin/route get default` on a background queue and returns the active gateway IP via callback. Called inside `NetworkMonitor.onStatusChange(connected: true)` so LAN host auto-updates on every network change (Wi-Fi switch, hotspot, VPN). Falls back to last known host if detection fails.
- **AlertService anti-spam latch** — fires one `UNUserNotification` per bad run; resets on recovery. `onAlert` callback enables unit testing without triggering `UNUserNotificationCenter` (requires app bundle).
- **Sparkline** — `MenuController.sparklineItem(for:)` maps each `PingResult` to one of 8 Unicode block chars (`▁`–`█`) using absolute latency thresholds (20/40/60/80/100/150/200 ms); timeouts render as `·`. A thin `▏` block appended at the right acts as a "now" playhead marker. Left=oldest, right=newest.
- **Menu history rows** — `addHistoryItems` displays only the 5 most recent pings (newest first). Internal `PingService` history buffer remains 10 samples so stats and alerts use the full window.
- **WAN/LAN header symmetry** — Menu header is two items: `NetPulse` (app name) + `WAN: host   N% loss`. LAN section mirrors the same format.
- **Two-line stats** — Both WAN (`addStatsItems`) and LAN (`addLanItems`) show identical two-line stats: `avg: X ms   jitter: X ms` then `min: X ms   max: X ms`. avg+jitter = typical experience; min+max = range. LAN lines are indented with leading spaces.

## UserDefaults Keys

| Key | Default | Description |
|---|---|---|
| `pingHost` | `8.8.8.8` | WAN ping target |
| `pingInterval` | `3.0` | Seconds between pings (shared by WAN + LAN) |
| `alertThreshold` | `200.0` | Latency (ms) above which a notification fires |
| `lanPingHost` | `192.168.1.1` | LAN ping target |

## Latency Color Thresholds

| Range     | Color  |
|-----------|--------|
| < 50 ms   | Green  |
| < 150 ms  | Orange |
| ≥ 150 ms  | Red    |
| Timeout   | Red    |
| No network| Gray   |

## Claude Agents & Commands

### Agents (`.claude/agents/`)
Specialized sub-agents Claude can spin up automatically:

| Agent | When it's used |
|---|---|
| `swift-reviewer` | Reviews Swift/AppKit code — weak self, main thread, memory leaks |
| `release` | Walks through the full release process step by step |
| `debug` | Diagnoses runtime issues — ping failures, duplicate instances, menu bugs |

### Slash Commands (`.claude/commands/`)
Type these directly in Claude Code:

| Command | What it does |
|---|---|
| `/release` | Starts the release agent — checks version, walks through tagging |
| `/swift-review` | Runs swift-reviewer on all uncommitted Swift changes |
| `/diagnose` | Starts the debug agent — asks for symptoms, works through failure modes |

## Releasing

Push a git tag to trigger GitHub Actions (`.github/workflows/release.yml`):

```bash
git tag v1.4.0
git push origin v1.4.0
```

The workflow runs on `macos-latest`, calls `make build` + `bash Scripts/package.sh`, and publishes `NetPulse.dmg` as a GitHub Release asset. Free on public repos; costs 10× minutes on private repos (2 000 min/month free tier).

The binary is ad-hoc signed (`codesign --sign -`). Users must right-click → Open on first launch to bypass Gatekeeper. Proper notarization requires Apple Developer Program ($99/year).
