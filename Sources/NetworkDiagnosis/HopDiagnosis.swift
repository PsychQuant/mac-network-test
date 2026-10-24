public enum HopVerdict: Equatable, Sendable {
    case healthy
    /// Loss or latency spikes already at the gateway: crowded Wi-Fi or an overloaded local network.
    case localCongestion
    /// Gateway is clean, the internet hop is not: the problem is past the gateway.
    case upstreamProblem
    /// Gateway is slow to answer or skips pings, but traffic through it is clean.
    case gatewayDeprioritizesICMP
}

public enum HopDiagnosis {
    /// One lost ping in 50 is 2%: noise, not a finding.
    public static let lossThresholdPercent = 2.0
    /// Average minus minimum round trip: time spent queueing on top of the hop's best case.
    /// Unlike max or stddev, a single spike barely moves it; sustained contention does.
    public static let queueingThresholdMs = 20.0

    /// Locates where trouble starts from idle pings to the gateway and to an internet host.
    /// Both inputs must be idle measurements: pings taken during a throughput test measure loaded latency.
    ///
    /// Internet pings cross the gateway hop, so a real problem at that hop shows up on them too.
    /// A gateway that looks bad while the path through it is clean is only slow to answer its own pings.
    public static func locate(gateway: PingStats, internet: PingStats) -> HopVerdict {
        let gatewayDegraded = isDegraded(gateway)
        let pathDegraded = isDegraded(internet)

        if gatewayDegraded { return pathDegraded ? .localCongestion : .gatewayDeprioritizesICMP }
        return pathDegraded ? .upstreamProblem : .healthy
    }

    private static func isDegraded(_ stats: PingStats) -> Bool {
        let queueing = stats.roundTrip.map { $0.avgMs - $0.minMs > queueingThresholdMs } ?? false
        return queueing || stats.lossPercent > lossThresholdPercent
    }
}
