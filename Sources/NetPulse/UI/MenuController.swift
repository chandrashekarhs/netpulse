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

        let header = NSMenuItem(title: "\(Constants.appName)  —  \(host)", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

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
