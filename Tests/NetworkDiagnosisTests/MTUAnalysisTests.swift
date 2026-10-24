import Testing
@testable import NetworkDiagnosis

struct MTUAnalysisTests {
    @Test func `Full-size packets passing means no black hole`() {
        let results = [1472, 1444, 1416].map { MTUProbeResult(payloadBytes: $0, passed: true) }
        #expect(MTUAnalysis.verdict(results) == .noBlackHole)
    }

    @Test func `Large packets silently dropped means a black hole at the largest passing size`() {
        let results = [
            MTUProbeResult(payloadBytes: 1416, passed: true),
            MTUProbeResult(payloadBytes: 1472, passed: false),
            MTUProbeResult(payloadBytes: 1444, passed: false),
        ]
        // 1416-byte payload + 8-byte ICMP header + 20-byte IPv4 header
        #expect(MTUAnalysis.verdict(results) == .blackHole(largestPassingMTU: 1444))
    }

    @Test func `Nothing passing is undetermined, not a black hole`() {
        // Usually ICMP is blocked outright; that says nothing about MTU.
        let results = [1472, 1444].map { MTUProbeResult(payloadBytes: $0, passed: false) }
        #expect(MTUAnalysis.verdict(results) == .undetermined)
    }
}
