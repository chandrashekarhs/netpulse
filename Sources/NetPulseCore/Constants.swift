import Foundation

enum Constants {
    static let appName    = "NetPulse"
    static let appVersion = "1.2.0"
    static let bundleID   = "com.\(NSUserName()).netpulse"

    enum Defaults {
        static let pingHost       = "8.8.8.8"
        static let pingInterval   = 3.0
        static let historyLimit   = 10
        static let alertThreshold = 200.0
        static let lanPingHost    = "192.168.1.1"
    }

    enum UserDefaultsKey {
        static let pingHost       = "pingHost"
        static let pingInterval   = "pingInterval"
        static let alertThreshold = "alertThreshold"
        static let lanPingHost    = "lanPingHost"
    }
}
