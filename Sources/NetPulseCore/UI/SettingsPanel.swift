import AppKit

enum SettingsPanel {
    static func show(
        host: String,
        interval: Double,
        alertThreshold: Double,
        lanHost: String,
        completion: @escaping (String, Double, Double, String) -> Void
    ) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText     = "\(Constants.appName) Settings"
        alert.informativeText = "Changes apply immediately."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 310, height: 136))

        func makeLabel(_ text: String, y: CGFloat) -> NSTextField {
            let f = NSTextField(labelWithString: text)
            f.frame     = NSRect(x: 0, y: y, width: 110, height: 20)
            f.alignment = .right
            return f
        }

        let lanHostField = NSTextField(string: lanHost)
        lanHostField.frame             = NSRect(x: 118, y: 104, width: 192, height: 24)
        lanHostField.placeholderString = "e.g. 192.168.1.1"

        let hostField = NSTextField(string: host)
        hostField.frame             = NSRect(x: 118, y: 72, width: 192, height: 24)
        hostField.placeholderString = "e.g. 1.1.1.1 or google.com"

        let intervalField = NSTextField(string: String(Int(interval)))
        intervalField.frame             = NSRect(x: 118, y: 40, width: 60, height: 24)
        intervalField.placeholderString = "3"

        let alertField = NSTextField(string: String(Int(alertThreshold)))
        alertField.frame             = NSRect(x: 118, y: 8, width: 60, height: 24)
        alertField.placeholderString = "200"

        [makeLabel("LAN Host:", y: 106), makeLabel("WAN Host / IP:", y: 74),
         makeLabel("Interval (sec):", y: 42), makeLabel("Alert (ms):", y: 10),
         lanHostField, hostField, intervalField, alertField].forEach { container.addSubview($0) }
        alert.accessoryView = container

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let newHost      = hostField.stringValue.trimmingCharacters(in: .whitespaces)
        let newInterval  = max(1.0, Double(intervalField.stringValue) ?? Constants.Defaults.pingInterval)
        let newThreshold = max(1.0, Double(alertField.stringValue) ?? Constants.Defaults.alertThreshold)
        let newLanHost   = lanHostField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !newHost.isEmpty else { return }

        completion(newHost, newInterval, newThreshold, newLanHost.isEmpty ? lanHost : newLanHost)
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
