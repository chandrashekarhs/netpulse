import AppKit

public class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var menuController: MenuController!
    private var pingService: PingService!
    private var lanPingService: PingService!
    private var networkMonitor: NetworkMonitor!
    private var alertService: AlertService!

    public func applicationDidFinishLaunching(_ notification: Notification) {
        guard Self.isFirstInstance() else { NSApp.terminate(nil); return }
        NSApp.setActivationPolicy(.accessory)

        let (host, interval, alertThreshold, lanHost) = Self.loadSettings()

        pingService         = PingService(host: host, interval: interval)
        lanPingService      = PingService(host: lanHost, interval: interval)
        networkMonitor      = NetworkMonitor()
        statusBarController = StatusBarController()
        menuController      = MenuController(target: self)
        alertService        = AlertService(alertThreshold: alertThreshold)
        menuController.attach(to: statusBarController.statusItem)
        alertService.requestPermission()

        // Build initial menu immediately (shows "Waiting for first ping…")
        rebuildMenu()

        // Network down: stop services; reconnect: auto-detect gateway then resume LAN
        networkMonitor.onStatusChange = { [weak self] connected in
            guard let self else { return }
            if !connected {
                self.statusBarController.update(latency: nil, isConnected: false)
                self.lanPingService.stop()
                self.rebuildMenu()
            } else {
                GatewayDetector.detect { [weak self] gateway in
                    guard let self else { return }
                    let host = gateway ?? self.lanPingService.host
                    self.lanPingService.restart(host: host, interval: self.pingService.interval)
                    self.rebuildMenu()
                }
            }
        }

        pingService.onResult = { [weak self] result in
            guard let self else { return }
            let latency: Double? = self.pingService.history.last.flatMap { $0.latency }
            self.statusBarController.update(latency: latency, isConnected: self.networkMonitor.isConnected)
            self.alertService.evaluate(result: result)
            self.rebuildMenu()
        }

        lanPingService.onResult = { [weak self] _ in
            self?.rebuildMenu()
        }

        networkMonitor.start()
        pingService.start()
        lanPingService.start()
    }

    // MARK: - Menu actions

    @objc func showSettings() {
        SettingsPanel.show(
            host: pingService.host,
            interval: pingService.interval,
            alertThreshold: alertService.alertThreshold,
            lanHost: lanPingService.host
        ) { [weak self] newHost, newInterval, newThreshold, newLanHost in
            guard let self else { return }
            UserDefaults.standard.set(newHost,      forKey: Constants.UserDefaultsKey.pingHost)
            UserDefaults.standard.set(newInterval,  forKey: Constants.UserDefaultsKey.pingInterval)
            UserDefaults.standard.set(newThreshold, forKey: Constants.UserDefaultsKey.alertThreshold)
            UserDefaults.standard.set(newLanHost,   forKey: Constants.UserDefaultsKey.lanPingHost)
            self.alertService.alertThreshold = newThreshold
            self.alertService.reset()
            self.pingService.restart(host: newHost, interval: newInterval)
            self.lanPingService.restart(host: newLanHost, interval: newInterval)
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
            lanHost: lanPingService.host,
            lanHistory: lanPingService.history,
            isLoginEnabled: LoginItemManager.isEnabled
        )
    }

    private static func loadSettings() -> (host: String, interval: Double, alertThreshold: Double, lanHost: String) {
        let defaults = UserDefaults.standard
        let host = {
            let h = defaults.string(forKey: Constants.UserDefaultsKey.pingHost) ?? ""
            return h.isEmpty ? Constants.Defaults.pingHost : h
        }()
        let interval = {
            let i = defaults.double(forKey: Constants.UserDefaultsKey.pingInterval)
            return i >= 1 ? i : Constants.Defaults.pingInterval
        }()
        let alertThreshold = {
            let t = defaults.double(forKey: Constants.UserDefaultsKey.alertThreshold)
            return t >= 1 ? t : Constants.Defaults.alertThreshold
        }()
        let lanHost = {
            let h = defaults.string(forKey: Constants.UserDefaultsKey.lanPingHost) ?? ""
            return h.isEmpty ? Constants.Defaults.lanPingHost : h
        }()
        return (host, interval, alertThreshold, lanHost)
    }
}
