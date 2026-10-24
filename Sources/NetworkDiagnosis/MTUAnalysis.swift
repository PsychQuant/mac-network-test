public struct MTUProbeResult: Equatable, Sendable {
    /// ICMP payload size passed to `ping -s`.
    public let payloadBytes: Int
    public let passed: Bool

    public init(payloadBytes: Int, passed: Bool) {
        self.payloadBytes = payloadBytes
        self.passed = passed
    }
}

public enum MTUVerdict: Equatable, Sendable {
    case noBlackHole
    case blackHole(largestPassingMTU: Int)
    /// Nothing passed, which usually means ICMP is blocked, not that the MTU is tiny.
    case undetermined
}

public enum MTUAnalysis {
    /// 20-byte IPv4 header + 8-byte ICMP header.
    public static let headerBytes = 28
    /// Largest payload that fits a standard 1500-byte Ethernet MTU.
    public static let fullPayloadBytes = 1500 - headerBytes

    public static func verdict(_ results: [MTUProbeResult]) -> MTUVerdict {
        guard let largest = results.filter(\.passed).map(\.payloadBytes).max() else { return .undetermined }
        return largest >= fullPayloadBytes ? .noBlackHole : .blackHole(largestPassingMTU: largest + headerBytes)
    }
}
