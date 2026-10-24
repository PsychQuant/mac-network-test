import Foundation

public struct RoundTrip: Equatable, Sendable {
    public let minMs: Double
    public let avgMs: Double
    public let maxMs: Double
    public let stddevMs: Double

    public init(minMs: Double, avgMs: Double, maxMs: Double, stddevMs: Double) {
        self.minMs = minMs
        self.avgMs = avgMs
        self.maxMs = maxMs
        self.stddevMs = stddevMs
    }
}

public struct PingStats: Equatable, Sendable {
    public let transmitted: Int
    public let received: Int
    public let lossPercent: Double
    /// nil when no reply came back.
    public let roundTrip: RoundTrip?

    public init(transmitted: Int, received: Int, lossPercent: Double, roundTrip: RoundTrip?) {
        self.transmitted = transmitted
        self.received = received
        self.lossPercent = lossPercent
        self.roundTrip = roundTrip
    }
}

public enum PingParser {
    /// Parses the summary macOS `ping` prints after its last reply.
    public static func parse(_ output: String) -> PingStats? {
        let countsPattern = #/(\d+) packets transmitted, (\d+) packets received,.*?([\d.]+)% packet loss/#
        guard let counts = output.firstMatch(of: countsPattern),
              let transmitted = Int(counts.1),
              let received = Int(counts.2),
              let loss = Double(counts.3)
        else { return nil }

        let roundTripPattern = #/round-trip min/avg/max/stddev = ([\d.]+)/([\d.]+)/([\d.]+)/([\d.]+) ms/#
        let roundTrip = output.firstMatch(of: roundTripPattern).flatMap { match -> RoundTrip? in
            guard let min = Double(match.1), let avg = Double(match.2),
                  let max = Double(match.3), let stddev = Double(match.4)
            else { return nil }
            return RoundTrip(minMs: min, avgMs: avg, maxMs: max, stddevMs: stddev)
        }
        return PingStats(transmitted: transmitted, received: received, lossPercent: loss, roundTrip: roundTrip)
    }
}
