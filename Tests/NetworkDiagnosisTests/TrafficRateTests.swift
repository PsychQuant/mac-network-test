import Testing
@testable import NetworkDiagnosis

struct TrafficRateTests {
    @Test func `Converts a byte delta to megabits per second`() throws {
        let mbps = try #require(TrafficRate.mbps(fromBytes: 1_000_000, toBytes: 1_786_000, seconds: 5))
        #expect(abs(mbps - 1.2576) < 1e-9)
    }

    @Test func `Survives a 32-bit counter wrap`() throws {
        // if_data byte counters are UInt32 and wrap at 4 GiB.
        let mbps = try #require(TrafficRate.mbps(fromBytes: UInt32.max - 999, toBytes: 1_000, seconds: 1))
        #expect(abs(mbps - 0.016) < 1e-9)  // 2,000 bytes
    }

    @Test func `Rejects a non-positive interval`() {
        #expect(TrafficRate.mbps(fromBytes: 0, toBytes: 100, seconds: 0) == nil)
    }
}
