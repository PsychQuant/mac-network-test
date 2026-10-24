import Testing
@testable import NetworkDiagnosis

/// Fixtures are real idle measurements (2026-09 and 2026-10), identifiers removed,
/// except where a comment says the case is constructed.
struct HopDiagnosisTests {
    @Test func `Jittery gateway with lossy internet is local congestion`() {
        // Crowded shared Wi-Fi: gateway answers every ping but spikes to 413 ms.
        let gateway = PingStats(transmitted: 30, received: 30, lossPercent: 0.0,
                                roundTrip: RoundTrip(minMs: 4.378, avgMs: 68.079, maxMs: 413.034, stddevMs: 83.837))
        let internet = PingStats(transmitted: 30, received: 28, lossPercent: 6.7,
                                 roundTrip: RoundTrip(minMs: 10.070, avgMs: 109.736, maxMs: 437.429, stddevMs: 104.233))
        #expect(HopDiagnosis.locate(gateway: gateway, internet: internet) == .localCongestion)
    }

    @Test func `Unanswered gateway pings with clean forwarding is ICMP deprioritization`() {
        // Same venue on Ethernet: 6% of gateway pings unanswered, 0% loss through it.
        let gateway = PingStats(transmitted: 50, received: 47, lossPercent: 6.0,
                                roundTrip: RoundTrip(minMs: 0.247, avgMs: 7.118, maxMs: 17.615, stddevMs: 5.384))
        let internet = PingStats(transmitted: 50, received: 50, lossPercent: 0.0,
                                 roundTrip: RoundTrip(minMs: 5.443, avgMs: 15.151, maxMs: 22.501, stddevMs: 4.801))
        #expect(HopDiagnosis.locate(gateway: gateway, internet: internet) == .gatewayDeprioritizesICMP)
    }

    @Test func `Clean gateway with lossy internet is an upstream problem`() {
        // Home router WAN dropping packets at peak hours; LAN side perfect.
        let gateway = PingStats(transmitted: 50, received: 50, lossPercent: 0.0,
                                roundTrip: RoundTrip(minMs: 2.1, avgMs: 3.0, maxMs: 5.2, stddevMs: 0.6))
        let internet = PingStats(transmitted: 50, received: 44, lossPercent: 12.0,
                                 roundTrip: RoundTrip(minMs: 6.0, avgMs: 9.5, maxMs: 40.0, stddevMs: 6.0))
        #expect(HopDiagnosis.locate(gateway: gateway, internet: internet) == .upstreamProblem)
    }

    @Test func `Queueing on both hops without loss is local congestion`() {
        // Same shared Wi-Fi the next morning: no loss, but both hops queue ~35 ms over their best case.
        let gateway = PingStats(transmitted: 50, received: 50, lossPercent: 0.0,
                                roundTrip: RoundTrip(minMs: 4.394, avgMs: 39.383, maxMs: 274.311, stddevMs: 51.486))
        let internet = PingStats(transmitted: 50, received: 50, lossPercent: 0.0,
                                 roundTrip: RoundTrip(minMs: 11.318, avgMs: 47.919, maxMs: 159.470, stddevMs: 35.494))
        #expect(HopDiagnosis.locate(gateway: gateway, internet: internet) == .localCongestion)
    }

    @Test func `Slow gateway replies with a fast path through it is ICMP deprioritization`() {
        // Constructed case: internet pings cross the same hop yet return faster than the gateway answers.
        let gateway = PingStats(transmitted: 50, received: 50, lossPercent: 0.0,
                                roundTrip: RoundTrip(minMs: 4.0, avgMs: 60.0, maxMs: 210.0, stddevMs: 50.0))
        let internet = PingStats(transmitted: 50, received: 50, lossPercent: 0.0,
                                 roundTrip: RoundTrip(minMs: 10.0, avgMs: 14.0, maxMs: 30.0, stddevMs: 4.0))
        #expect(HopDiagnosis.locate(gateway: gateway, internet: internet) == .gatewayDeprioritizesICMP)
    }

    @Test func `One latency spike at the gateway is not congestion`() {
        // 49 replies near 3 ms and one at 400 ms: stddev jumps to ~56 ms, average barely moves.
        let gateway = PingStats(transmitted: 50, received: 50, lossPercent: 0.0,
                                roundTrip: RoundTrip(minMs: 2.5, avgMs: 10.9, maxMs: 400.0, stddevMs: 55.6))
        let internet = PingStats(transmitted: 50, received: 50, lossPercent: 0.0,
                                 roundTrip: RoundTrip(minMs: 8.0, avgMs: 10.0, maxMs: 15.0, stddevMs: 1.5))
        #expect(HopDiagnosis.locate(gateway: gateway, internet: internet) == .healthy)
    }

    @Test func `Gateway that never answers pings with clean internet is ICMP deprioritization`() {
        let gateway = PingStats(transmitted: 50, received: 0, lossPercent: 100.0, roundTrip: nil)
        let internet = PingStats(transmitted: 50, received: 50, lossPercent: 0.0,
                                 roundTrip: RoundTrip(minMs: 8.0, avgMs: 10.0, maxMs: 15.0, stddevMs: 1.5))
        #expect(HopDiagnosis.locate(gateway: gateway, internet: internet) == .gatewayDeprioritizesICMP)
    }

    @Test func `Clean and fast on both hops is healthy`() {
        let gateway = PingStats(transmitted: 50, received: 50, lossPercent: 0.0,
                                roundTrip: RoundTrip(minMs: 1.0, avgMs: 2.0, maxMs: 4.0, stddevMs: 0.5))
        let internet = PingStats(transmitted: 50, received: 50, lossPercent: 0.0,
                                 roundTrip: RoundTrip(minMs: 8.0, avgMs: 10.0, maxMs: 15.0, stddevMs: 1.5))
        #expect(HopDiagnosis.locate(gateway: gateway, internet: internet) == .healthy)
    }
}
