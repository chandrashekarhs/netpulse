import Foundation
import UserNotifications

class AlertService {
    var alertThreshold: Double
    var onAlert: ((PingResult) -> Void)?
    private var isInBadRun = false

    init(alertThreshold: Double) {
        self.alertThreshold = alertThreshold
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func reset() {
        isInBadRun = false
    }

    func evaluate(result: PingResult) {
        let isBad: Bool
        if let ms = result.latency {
            isBad = ms > alertThreshold
        } else {
            isBad = true
        }

        if isBad {
            guard !isInBadRun else { return }
            isInBadRun = true
            fire(result: result)
        } else {
            isInBadRun = false
        }
    }

    private func fire(result: PingResult) {
        onAlert?(result)
        // onAlert is set only in tests; skip OS notification in that context
        // since UNUserNotificationCenter.current() requires an app bundle
        guard onAlert == nil else { return }
        let content = UNMutableNotificationContent()
        content.title = "NetPulse — Network Alert"
        content.sound = .default
        if let ms = result.latency {
            content.body = String(format: "High latency: %.0f ms (threshold: %.0f ms)", ms, alertThreshold)
        } else {
            content.body = "Ping timed out — host may be unreachable."
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
