import XCTest
@testable import NetPulseCore

final class AlertServiceTests: XCTestCase {

    // MARK: - Helpers

    private func makeService(threshold: Double = 100.0) -> AlertService {
        AlertService(alertThreshold: threshold)
    }

    private func ping(latency: Double?) -> PingResult {
        PingResult(latency: latency, timestamp: Date())
    }

    private func alertCount(from service: AlertService, pings: [PingResult]) -> Int {
        var count = 0
        service.onAlert = { _ in count += 1 }
        pings.forEach { service.evaluate(result: $0) }
        return count
    }

    // MARK: - First bad ping fires

    func testFirstHighLatencyFiresAlert() {
        let svc = makeService(threshold: 100)
        XCTAssertEqual(alertCount(from: svc, pings: [ping(latency: 150)]), 1)
    }

    func testFirstTimeoutFiresAlert() {
        let svc = makeService(threshold: 100)
        XCTAssertEqual(alertCount(from: svc, pings: [ping(latency: nil)]), 1)
    }

    // MARK: - Anti-spam latch

    func testConsecutiveBadPingsSuppressed() {
        let svc = makeService(threshold: 100)
        XCTAssertEqual(alertCount(from: svc, pings: [
            ping(latency: 200),
            ping(latency: 300),
            ping(latency: 400),
        ]), 1)
    }

    func testMixedTimeoutsAndHighLatencySuppressed() {
        let svc = makeService(threshold: 100)
        XCTAssertEqual(alertCount(from: svc, pings: [
            ping(latency: 200),
            ping(latency: nil),
            ping(latency: 500),
        ]), 1)
    }

    // MARK: - Good ping resets latch

    func testGoodPingDoesNotFire() {
        let svc = makeService(threshold: 100)
        XCTAssertEqual(alertCount(from: svc, pings: [ping(latency: 50)]), 0)
    }

    func testRecoveryThenBadFiresAgain() {
        let svc = makeService(threshold: 100)
        XCTAssertEqual(alertCount(from: svc, pings: [
            ping(latency: 200),  // fires (1st bad run)
            ping(latency: 50),   // recovery — latch reset
            ping(latency: 300),  // fires (2nd bad run)
        ]), 2)
    }

    func testMultipleRecoveryCycles() {
        let svc = makeService(threshold: 100)
        XCTAssertEqual(alertCount(from: svc, pings: [
            ping(latency: 200),  // fires
            ping(latency: 50),   // recovery
            ping(latency: 300),  // fires
            ping(latency: 50),   // recovery
            ping(latency: 400),  // fires
        ]), 3)
    }

    // MARK: - Threshold boundary

    func testLatencyExactlyAtThresholdIsNotBad() {
        let svc = makeService(threshold: 100)
        XCTAssertEqual(alertCount(from: svc, pings: [ping(latency: 100)]), 0)
    }

    func testLatencyJustAboveThresholdIsBad() {
        let svc = makeService(threshold: 100)
        XCTAssertEqual(alertCount(from: svc, pings: [ping(latency: 100.001)]), 1)
    }

    // MARK: - reset()

    func testResetRearmslatch() {
        let svc = makeService(threshold: 100)
        var count = 0
        svc.onAlert = { _ in count += 1 }
        svc.evaluate(result: ping(latency: 200))  // fires, latch set
        svc.evaluate(result: ping(latency: 200))  // suppressed
        svc.reset()                                // re-arm
        svc.evaluate(result: ping(latency: 200))  // fires again
        XCTAssertEqual(count, 2)
    }

    // MARK: - alertThreshold change

    func testUpdatedThresholdIsRespected() {
        let svc = makeService(threshold: 100)
        var count = 0
        svc.onAlert = { _ in count += 1 }
        svc.evaluate(result: ping(latency: 50))   // good (< 100)
        svc.alertThreshold = 30
        svc.evaluate(result: ping(latency: 50))   // now bad (> 30), fires
        XCTAssertEqual(count, 1)
    }
}
