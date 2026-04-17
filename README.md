# NetPulse

A lightweight macOS menu bar app that monitors network latency in real time. Pings a configurable host every few seconds and displays the result — color-coded — directly in your status bar.

![macOS 12+](https://img.shields.io/badge/macOS-12%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- Live latency display in the menu bar (green / orange / red)
- Last 10 ping results in the dropdown
- Configurable host and ping interval
- Launch at Login support
- No Dock icon — lives entirely in the menu bar

## Installation

1. Download **NetPulse.dmg** from the [latest release](https://github.com/chandrashekarhs/netpulse/releases/latest)
2. Open the DMG and drag **NetPulse.app** to Applications
3. Launch from Spotlight or Applications

> **First launch:** Right-click → Open to bypass Gatekeeper (ad-hoc signed build)

## Latency indicators

| Color | Meaning |
|---|---|
| Green | < 50 ms |
| Orange | 50 – 150 ms |
| Red | > 150 ms or timeout |
| Gray | No network |

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
| `/review` | Reviews uncommitted Swift changes for AppKit best practices |
| `/debug` | Diagnoses runtime issues (ping failures, duplicate instances, menu bugs) |

See `CLAUDE.md` for full project context and agent details.

CI runs `swift build -c release` on every PR. Squash merge only.

## Releasing

Push a version tag after merging to `main`:

```bash
git tag v1.0.0 && git push origin v1.0.0
```

GitHub Actions builds and publishes `NetPulse.dmg` automatically as a release asset.
