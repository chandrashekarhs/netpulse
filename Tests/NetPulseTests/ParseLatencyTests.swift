import XCTest
@testable import NetPulseCore

final class ParseLatencyTests: XCTestCase {

    // MARK: - Successful parses

    func testStandardDecimal() {
        let output = "64 bytes from 8.8.8.8: icmp_seq=0 ttl=118 time=12.3 ms"
        XCTAssertEqual(PingService.parseLatency(from: output), 12.3)
    }

    func testIntegerLatency() {
        let output = "64 bytes from 1.1.1.1: icmp_seq=0 ttl=59 time=8 ms"
        XCTAssertEqual(PingService.parseLatency(from: output), 8.0)
    }

    func testSubMillisecond() {
        let output = "64 bytes from 127.0.0.1: icmp_seq=0 ttl=64 time=0.123 ms"
        XCTAssertEqual(PingService.parseLatency(from: output), 0.123)
    }

    func testHighLatency() {
        let output = "64 bytes from 8.8.8.8: icmp_seq=0 ttl=118 time=987.6 ms"
        XCTAssertEqual(PingService.parseLatency(from: output), 987.6)
    }

    // MARK: - Returns nil

    func testTimeout() {
        XCTAssertNil(PingService.parseLatency(from: "Request timeout for icmp_seq 0"))
    }

    func testEmptyString() {
        XCTAssertNil(PingService.parseLatency(from: ""))
    }

    func testHeaderLine() {
        XCTAssertNil(PingService.parseLatency(from: "PING 8.8.8.8 (8.8.8.8): 56 data bytes"))
    }

    func testStatisticsLine() {
        XCTAssertNil(PingService.parseLatency(from: "round-trip min/avg/max/stddev = 11.0/11.0/11.0/0.0 ms"))
    }
}
