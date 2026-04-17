#!/usr/bin/env swift
import AppKit

let _ = NSApplication.shared // initialise AppKit drawing subsystem

func makeIcon(pixels: Int) -> Data? {
    let s = CGFloat(pixels)

    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ), let gc = NSGraphicsContext(bitmapImageRep: rep) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = gc
    defer { NSGraphicsContext.restoreGraphicsState() }

    let rect   = NSRect(x: 0, y: 0, width: s, height: s)
    let corner = s * 0.22

    // ── 1. Clip to rounded rect ──────────────────────────────────────────────
    NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner).addClip()

    // ── 2. Gradient background: deep navy (top-left) → rich teal (bottom-right)
    NSGradient(
        starting: NSColor(srgbRed: 0.07, green: 0.13, blue: 0.27, alpha: 1),
        ending:   NSColor(srgbRed: 0.03, green: 0.43, blue: 0.55, alpha: 1)
    )!.draw(from: NSPoint(x: 0, y: s), to: NSPoint(x: s, y: 0), options: [])

    // ── 3. Subtle top-edge sheen ─────────────────────────────────────────────
    NSColor(white: 1, alpha: 0.07).setFill()
    NSBezierPath(roundedRect: NSRect(x: 0, y: s * 0.58, width: s, height: s * 0.42),
                 xRadius: corner, yRadius: corner).fill()

    // ── 4. ECG pulse waveform ────────────────────────────────────────────────
    let xL   = s * 0.10
    let xR   = s * 0.85
    let span = xR - xL
    let yMid = s * 0.50

    let wave = NSBezierPath()
    wave.lineWidth     = max(1.5, s * 0.048)
    wave.lineCapStyle  = .round
    wave.lineJoinStyle = .round
    wave.move(to: NSPoint(x: xL,             y: yMid))
    wave.line(to: NSPoint(x: xL + span*0.28, y: yMid))
    wave.line(to: NSPoint(x: xL + span*0.40, y: yMid + s*0.23))  // spike up
    wave.line(to: NSPoint(x: xL + span*0.50, y: yMid - s*0.16))  // dip
    wave.line(to: NSPoint(x: xL + span*0.60, y: yMid))            // recover
    wave.line(to: NSPoint(x: xR,             y: yMid))

    let waveGlow = NSShadow()
    waveGlow.shadowColor      = NSColor(srgbRed: 0.25, green: 0.9, blue: 0.5, alpha: 0.5)
    waveGlow.shadowBlurRadius = s * 0.05
    waveGlow.shadowOffset     = .zero
    waveGlow.set()
    NSColor(white: 1, alpha: 0.92).setStroke()
    wave.stroke()
    NSShadow().set()

    // ── 5. Glowing green dot at end of waveform ──────────────────────────────
    let dotR = s * 0.065
    let dotGlow = NSShadow()
    dotGlow.shadowColor      = NSColor(srgbRed: 0.2, green: 0.9, blue: 0.45, alpha: 0.9)
    dotGlow.shadowBlurRadius = s * 0.08
    dotGlow.shadowOffset     = .zero
    dotGlow.set()
    NSColor(srgbRed: 0.18, green: 0.88, blue: 0.44, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: xR - dotR, y: yMid - dotR,
                                width: dotR * 2, height: dotR * 2)).fill()
    NSShadow().set()

    return rep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
}

let entries: [(String, Int)] = [
    ("icon_16x16.png",        16),
    ("icon_16x16@2x.png",     32),
    ("icon_32x32.png",        32),
    ("icon_32x32@2x.png",     64),
    ("icon_128x128.png",     128),
    ("icon_128x128@2x.png",  256),
    ("icon_256x256.png",     256),
    ("icon_256x256@2x.png",  512),
    ("icon_512x512.png",     512),
    ("icon_512x512@2x.png", 1024),
]

let iconset = "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)

for (filename, size) in entries {
    if let data = makeIcon(pixels: size) {
        FileManager.default.createFile(atPath: "\(iconset)/\(filename)", contents: data)
        print("  ✓  \(filename)")
    } else {
        fputs("  ✗  failed: \(filename)\n", stderr)
    }
}
