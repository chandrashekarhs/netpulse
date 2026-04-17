import Testing
@testable import NetPulseCore

@Suite("PingService.parseLatency")
struct ParseLatencyTests {

    // MARK: - Successful parses

    @Test("parses standard decimal output")
    func standardDecimal() {
        let output = "64 bytes from 8.8.8.8: icmp_seq=0 ttl=118 time=12.3 ms"
        #expect(PingService.parseLatency(from: output) == 12.3)
    }

    @Test("parses integer latency with no decimal")
    func integerLatency() {
        let output = "64 bytes from 1.1.1.1: icmp_seq=0 ttl=59 time=8 ms"
        #expect(PingService.parseLatency(from: output) == 8.0)
    }

    @Test("parses sub-millisecond latency (loopback)")
    func subMillisecond() {
        let output = "64 bytes from 127.0.0.1: icmp_seq=0 ttl=64 time=0.123 ms"
        #expect(PingService.parseLatency(from: output) == 0.123)
    }

    @Test("parses high latency")
    func highLatency() {
        let output = "64 bytes from 8.8.8.8: icmp_seq=0 ttl=118 time=987.6 ms"
        #expect(PingService.parseLatency(from: output) == 987.6)
    }

    // MARK: - Returns nil

    @Test("returns nil for timeout line")
    func timeout() {
        #expect(PingService.parseLatency(from: "Request timeout for icmp_seq 0") == nil)
    }

    @Test("returns nil for empty string")
    func emptyString() {
        #expect(PingService.parseLatency(from: "") == nil)
    }

    @Test("returns nil for ping header line")
    func headerLine() {
        #expect(PingService.parseLatency(from: "PING 8.8.8.8 (8.8.8.8): 56 data bytes") == nil)
    }

    @Test("returns nil for statistics summary line")
    func statisticsLine() {
        #expect(PingService.parseLatency(from: "round-trip min/avg/max/stddev = 11.0/11.0/11.0/0.0 ms") == nil)
    }
}
