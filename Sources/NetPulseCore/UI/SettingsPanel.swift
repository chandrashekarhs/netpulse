import AppKit

enum SettingsPanel {
    static func show(
        host: String,
        interval: Double,
        completion: @escaping (String, Double) -> Void
    ) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText    = "\(Constants.appName) Settings"
        alert.informativeText = "Changes apply immediately."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 310, height: 70))

        func makeLabel(_ text: String, y: CGFloat) -> NSTextField {
            let f = NSTextField(labelWithString: text)
            f.frame     = NSRect(x: 0, y: y, width: 110, height: 20)
            f.alignment = .right
            return f
        }

        let hostField = NSTextField(string: host)
        hostField.frame             = NSRect(x: 118, y: 40, width: 192, height: 24)
        hostField.placeholderString = "e.g. 1.1.1.1 or google.com"

        let intervalField = NSTextField(string: String(Int(interval)))
        intervalField.frame             = NSRect(x: 118, y: 8, width: 60, height: 24)
        intervalField.placeholderString = "3"

        [makeLabel("Host / IP:", y: 42), makeLabel("Interval (sec):", y: 10),
         hostField, intervalField].forEach { container.addSubview($0) }
        alert.accessoryView = container

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let newHost     = hostField.stringValue.trimmingCharacters(in: .whitespaces)
        let newInterval = max(1.0, Double(intervalField.stringValue) ?? Constants.Defaults.pingInterval)
        guard !newHost.isEmpty else { return }

        completion(newHost, newInterval)
    }

    static func showAbout(host: String, interval: Double) {
        NSApp.activate(ignoringOtherApps: true)
        let credits = NSAttributedString(
            string: "Monitors network latency from your menu bar.\n"
                  + "Pings \(host) every \(Int(interval))s.\n\n"
                  + "Green < 50ms · Orange < 150ms · Red = slow/timeout",
            attributes: [
                .font:            NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]
        )
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName:    Constants.appName,
            .applicationVersion: Constants.appVersion,
            .credits:            credits,
        ])
    }
}
