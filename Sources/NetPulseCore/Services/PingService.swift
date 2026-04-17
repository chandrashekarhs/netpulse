import Foundation

class PingService {
    var host: String
    var interval: Double
    var onResult: ((PingResult) -> Void)?

    private(set) var history: [PingResult] = []
    private var timer: Timer?

    init(host: String, interval: Double) {
        self.host     = host
        self.interval = interval
    }

    func start() {
        runPing()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.runPing()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func restart(host: String, interval: Double) {
        stop()
        self.host     = host
        self.interval = interval
        history.removeAll()
        start()
    }

    private func runPing() {
        let host = self.host  // capture before async; user may change via Settings mid-flight
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/sbin/ping")
        proc.arguments     = ["-c", "1", "-t", "2", host]

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError  = pipe

        proc.terminationHandler = { [weak self] _ in
            let data    = pipe.fileHandleForReading.readDataToEndOfFile()
            let output  = String(data: data, encoding: .utf8) ?? ""
            let latency = Self.parseLatency(from: output)
            DispatchQueue.main.async { self?.record(latency: latency) }
        }
        try? proc.run()
    }

    static func parseLatency(from output: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: #"time=(\d+\.?\d*)\s*ms"#),
              let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
              let range = Range(match.range(at: 1), in: output) else { return nil }
        return Double(output[range])
    }

    private func record(latency: Double?) {
        let result = PingResult(latency: latency, timestamp: Date())
        history.append(result)
        if history.count > Constants.Defaults.historyLimit { history.removeFirst() }
        onResult?(result)
    }
}
