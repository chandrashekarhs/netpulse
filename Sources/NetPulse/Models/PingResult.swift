import Foundation

struct PingResult {
    let latency: Double?
    let timestamp: Date
    var isSuccess: Bool { latency != nil }
}
