# NetPulse — Claude Code Guide

macOS menu bar app that monitors network latency by pinging a host and displaying results in the status bar. Written in Swift, built with Swift Package Manager. No Xcode project.

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
  AppDelegate.swift        # coordinator: owns services, wires callbacks
  Constants.swift          # appName, version, UserDefaults keys, defaults
  Models/PingResult.swift  # latency: Double?, timestamp: Date
  Services/
    PingService.swift      # ping timer, history (capped at 10), onResult callback
    NetworkMonitor.swift   # NWPathMonitor wrapper, onStatusChange callback
  UI/
    StatusBarController.swift  # NSStatusItem, dotImage(), color thresholds
    MenuController.swift       # rebuilds NSMenu on every ping/network event
    SettingsPanel.swift        # NSAlert-based settings + about panel
    LoginItemManager.swift     # LaunchAgent plist in ~/Library/LaunchAgents/
Scripts/
  make_icon.swift   # generates AppIcon.iconset via AppKit drawing
  package.sh        # bundles .build/release/NetPulse into .app + .dmg
```

## Key Conventions

- **No Xcode project** — `Package.swift` is the sole build manifest.
- **No third-party dependencies** — AppKit + Network frameworks only.
- **Ping via `/sbin/ping`** — avoids raw ICMP socket privileges. Latency parsed with regex `time=(\d+\.?\d*)\s*ms`.
- **Status bar only** — `NSApp.setActivationPolicy(.accessory)` + `LSUIElement=true` hides from Dock.
- **Menu rebuilt on every event** — `MenuController.rebuild()` is called after each ping result and each network state change. Simple and correct; not a performance concern at this scale.
- **Callback pattern** — `PingService.onResult` and `NetworkMonitor.onStatusChange` deliver events to `AppDelegate` on the main queue.

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
| `/review` | Runs swift-reviewer on all uncommitted Swift changes |
| `/debug` | Starts the debug agent — asks for symptoms, works through failure modes |

## Releasing

Push a git tag to trigger GitHub Actions (`.github/workflows/release.yml`):

```bash
git tag v1.0.0
git push origin v1.0.0
```

The workflow runs on `macos-latest`, calls `make build` + `bash Scripts/package.sh`, and publishes `NetPulse.dmg` as a GitHub Release asset. Free on public repos; costs 10× minutes on private repos (2 000 min/month free tier).

The binary is ad-hoc signed (`codesign --sign -`). Users must right-click → Open on first launch to bypass Gatekeeper. Proper notarization requires Apple Developer Program ($99/year).
