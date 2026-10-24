import Testing
@testable import NetworkDiagnosis

struct PingParserTests {
    @Test func `Parses loss and round-trip statistics`() throws {
        let output = """
            PING 192.0.2.1 (192.0.2.1): 56 data bytes

            --- 192.0.2.1 ping statistics ---
            30 packets transmitted, 29 packets received, 3.3% packet loss
            round-trip min/avg/max/stddev = 3.145/84.417/325.348/85.338 ms
            """
        let stats = try #require(PingParser.parse(output))
        #expect(stats.transmitted == 30)
        #expect(stats.received == 29)
        #expect(stats.lossPercent == 3.3)
        #expect(stats.roundTrip == RoundTrip(minMs: 3.145, avgMs: 84.417, maxMs: 325.348, stddevMs: 85.338))
    }

    @Test func `Total loss has no round-trip statistics`() throws {
        let output = "2 packets transmitted, 0 packets received, 100.0% packet loss\n"
        let stats = try #require(PingParser.parse(output))
        #expect(stats.received == 0)
        #expect(stats.lossPercent == 100.0)
        #expect(stats.roundTrip == nil)
    }

    @Test func `Duplicates do not shift the counts`() throws {
        let output = """
            30 packets transmitted, 30 packets received, +2 duplicates, 0.0% packet loss
            round-trip min/avg/max/stddev = 9.931/59.101/396.315/78.144 ms
            """
        let stats = try #require(PingParser.parse(output))
        #expect(stats.received == 30)
        #expect(stats.lossPercent == 0.0)
    }

    @Test func `Output without a summary returns nil`() {
        #expect(PingParser.parse("ping: cannot resolve example.invalid: Unknown host") == nil)
    }
}
