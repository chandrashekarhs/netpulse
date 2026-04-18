import AppKit

class MenuController {
    private let menu = NSMenu()
    private weak var target: AnyObject?

    init(target: AnyObject) {
        self.target = target
    }

    func attach(to statusItem: NSStatusItem) {
        statusItem.menu = menu
    }

    func rebuild(host: String, history: [PingResult], isLoginEnabled: Bool) {
        menu.removeAllItems()

        let loss      = packetLossPercent(from: history)
        let lossSuffix = history.isEmpty ? "" : String(format: "   %d%% loss", loss)
        let header    = NSMenuItem(title: "\(Constants.appName)  —  \(host)\(lossSuffix)", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        menu.addItem(statsSummaryItem(for: history))
        addHistoryItems(history)

        menu.addItem(.separator())
        menu.addItem(action(title: "Launch at Login",
                            sel: #selector(AppDelegate.toggleLaunchAtLogin),
                            state: isLoginEnabled ? .on : .off))
        menu.addItem(action(title: "Settings…",
                            sel: #selector(AppDelegate.showSettings),
                            key: ","))
        menu.addItem(action(title: "About \(Constants.appName)…",
                            sel: #selector(AppDelegate.showAbout)))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit \(Constants.appName)",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
    }

    // MARK: - Private

    private func action(
        title: String,
        sel: Selector,
        key: String = "",
        state: NSControl.StateValue = .off
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: sel, keyEquivalent: key)
        item.target = target
        item.state  = state
        return item
    }

    private func packetLossPercent(from history: [PingResult]) -> Int {
        guard !history.isEmpty else { return 0 }
        let timeouts = history.filter { !$0.isSuccess }.count
        return Int((Double(timeouts) / Double(history.count)) * 100)
    }

    private func statsSummaryItem(for history: [PingResult]) -> NSMenuItem {
        let latencies = history.compactMap { $0.latency }
        let title: String
        if latencies.isEmpty {
            title = "min: —   avg: —   max: —"
        } else {
            let mn  = latencies.min()!
            let mx  = latencies.max()!
            let avg = latencies.reduce(0, +) / Double(latencies.count)
            title = String(format: "min: %.0f ms   avg: %.0f ms   max: %.0f ms", mn, avg, mx)
        }
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func addHistoryItems(_ history: [PingResult]) {
        guard !history.isEmpty else {
            let item = NSMenuItem(title: "Waiting for first ping…", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            return
        }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        for result in history.reversed() {
            let time  = fmt.string(from: result.timestamp)
            let label = result.latency.map { String(format: "\(time)   %5.1f ms", $0) }
                     ?? "\(time)   ✗  timeout"
            let item = NSMenuItem(title: label, action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }
    }
}
