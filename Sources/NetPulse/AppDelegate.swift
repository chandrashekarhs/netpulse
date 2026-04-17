import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var menuController: MenuController!
    private var pingService: PingService!
    private var networkMonitor: NetworkMonitor!

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard Self.isFirstInstance() else { NSApp.terminate(nil); return }
        NSApp.setActivationPolicy(.accessory)

        let (host, interval) = Self.loadSettings()

        pingService      = PingService(host: host, interval: interval)
        networkMonitor   = NetworkMonitor()
        statusBarController = StatusBarController()
        menuController   = MenuController(target: self)
        menuController.attach(to: statusBarController.statusItem)

        // Build initial menu immediately (shows "Waiting for first ping…")
        rebuildMenu()

        // Network down: update status bar right away; reconnect: let next ping show result
        networkMonitor.onStatusChange = { [weak self] connected in
            guard let self else { return }
            if !connected {
                self.statusBarController.update(latency: nil, isConnected: false)
            }
            self.rebuildMenu()
        }

        pingService.onResult = { [weak self] _ in
            guard let self else { return }
            let latency: Double? = self.pingService.history.last.flatMap { $0.latency }
            self.statusBarController.update(latency: latency, isConnected: self.networkMonitor.isConnected)
            self.rebuildMenu()
        }

        networkMonitor.start()
        pingService.start()
    }

    // MARK: - Menu actions

    @objc func showSettings() {
        SettingsPanel.show(host: pingService.host, interval: pingService.interval) { [weak self] newHost, newInterval in
            guard let self else { return }
            UserDefaults.standard.set(newHost,     forKey: Constants.UserDefaultsKey.pingHost)
            UserDefaults.standard.set(newInterval, forKey: Constants.UserDefaultsKey.pingInterval)
            self.pingService.restart(host: newHost, interval: newInterval)
            self.rebuildMenu()
        }
    }

    @objc func showAbout() {
        SettingsPanel.showAbout(host: pingService.host, interval: pingService.interval)
    }

    @objc func toggleLaunchAtLogin() {
        LoginItemManager.toggle()
        rebuildMenu()
    }

    // MARK: - Private

    private static func isFirstInstance() -> Bool {
        guard let id = Bundle.main.bundleIdentifier else { return true }  // unbundled dev run
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: id)
            .filter { $0 != .current }
        return others.isEmpty
    }

    private func rebuildMenu() {
        menuController.rebuild(
            host: pingService.host,
            history: pingService.history,
            isLoginEnabled: LoginItemManager.isEnabled
        )
    }

    private static func loadSettings() -> (host: String, interval: Double) {
        let defaults = UserDefaults.standard
        let host = {
            let h = defaults.string(forKey: Constants.UserDefaultsKey.pingHost) ?? ""
            return h.isEmpty ? Constants.Defaults.pingHost : h
        }()
        let interval = {
            let i = defaults.double(forKey: Constants.UserDefaultsKey.pingInterval)
            return i >= 1 ? i : Constants.Defaults.pingInterval
        }()
        return (host, interval)
    }
}
