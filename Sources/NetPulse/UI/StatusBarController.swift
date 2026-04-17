import AppKit

class StatusBarController {
    let statusItem: NSStatusItem

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.image         = dotImage(color: .gray)
        button.title         = "  …"
        button.imagePosition = .imageLeft
        button.font          = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    }

    func update(latency: Double?, isConnected: Bool) {
        guard let button = statusItem.button else { return }
        let (label, color) = display(latency: latency, isConnected: isConnected)
        button.image         = dotImage(color: color)
        button.title         = "  \(label)"
        button.imagePosition = .imageLeft
    }

    func dotImage(color: NSColor, size: CGFloat = 10) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            color.setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1)).fill()
            return true
        }
        img.isTemplate = false
        return img
    }

    private func display(latency: Double?, isConnected: Bool) -> (String, NSColor) {
        guard isConnected else { return ("no network", .gray) }
        guard let ms = latency else { return ("timeout", .systemRed) }
        let label = String(format: "%.0f ms", ms)
        switch ms {
        case ..<50:  return (label, NSColor(red: 0.18, green: 0.78, blue: 0.35, alpha: 1))
        case ..<150: return (label, .systemOrange)
        default:     return (label, .systemRed)
        }
    }
}
