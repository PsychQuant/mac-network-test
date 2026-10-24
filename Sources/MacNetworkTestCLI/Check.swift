import ArgumentParser
import Foundation
import NetworkDiagnosis

struct CheckError: Error, CustomStringConvertible {
    let description: String
}

/// Steps 1, 2, 5 and 6 of the README. Prints no identifiers: no gateway IP, SSID or BSSID.
struct Check: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Quick check: Wi-Fi link, hop-by-hop ping, MTU, this Mac's own traffic (about 30 s)."
    )

    static let internetHost = "1.1.1.1"
    static let pingCount = 50
    /// Descending ICMP payloads; 1472 + 28 header bytes = a full 1500-byte packet.
    static let mtuPayloads = [1472, 1444, 1416, 1396, 1372]
    static let busyTrafficMbps = 5.0

    func run() throws {
        print("mac-network-test \(Version.current) — quick check, about 30 seconds")
        guard let route = RouteParser.parseDefault(try runCommand("/sbin/route", ["-n", "get", "default"])) else {
            throw CheckError(description: "no default route: this Mac is not connected to a network")
        }
        let wifi = readWiFiLink()
        let onWiFi = wifi?.interfaceName == route.interface

        print("\nTraffic goes through \(route.interface) (\(onWiFi ? "Wi-Fi" : "wired or other")).")
        if let wifi { reportWiFi(wifi, inUse: onWiFi) }
        reportOwnTraffic(interface: route.interface)
        try reportHops(gateway: route.gateway)
        try reportMTU()

        print("\nNot in this version yet: throughput (steps 3–4).")
        if onWiFi { print("If there is an Ethernet port, plug in and rerun to compare (step 7).") }
    }

    private func reportWiFi(_ wifi: WiFiLink, inUse: Bool) {
        print("\n[1] Wi-Fi link\(inUse ? "" : " (connected, not carrying traffic)")")
        print("    \(wifi.rssiDBm) dBm, noise \(wifi.noiseDBm) dBm (SNR \(wifi.rssiDBm - wifi.noiseDBm) dB), "
            + "link rate \(Int(wifi.transmitRateMbps)) Mbps")
        print("    \(wifi.phyMode), channel \(wifi.channel) (\(wifi.band), \(wifi.width))")
        let strong = WiFiAssessment.isStrong(rssiDBm: wifi.rssiDBm, noiseDBm: wifi.noiseDBm)
        print(strong
            ? "    → strong signal: signal strength is not the problem"
            : "    → weak or noisy signal: move closer to the access point, or use Ethernet")
    }

    private func reportOwnTraffic(interface: String) {
        print("\n[6] This Mac's own traffic on \(interface) (5 s)")
        let clock = ContinuousClock()
        guard let before = readByteCounters(interface: interface) else {
            print("    → could not read interface counters")
            return
        }
        let start = clock.now
        Thread.sleep(forTimeInterval: 5)
        let elapsed = clock.now - start
        guard let after = readByteCounters(interface: interface) else {
            print("    → could not read interface counters")
            return
        }
        let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) * 1e-18
        let down = TrafficRate.mbps(fromBytes: before.received, toBytes: after.received, seconds: seconds) ?? 0
        let up = TrafficRate.mbps(fromBytes: before.sent, toBytes: after.sent, seconds: seconds) ?? 0
        print("    \(format(down)) Mbps down / \(format(up)) Mbps up")
        print(down + up > Self.busyTrafficMbps
            ? "    → busy: something on this Mac is syncing or downloading; pause it and rerun"
            : "    → quiet: this Mac is not loading the network")
    }

    private func reportHops(gateway: String) throws {
        print("\n[2] Hop-by-hop ping (\(Self.pingCount) each, one after the other)")
        let gatewayStats = try ping(gateway)
        let internetStats = try ping(Self.internetHost)
        print(pingLine("gateway ", gatewayStats))
        print(pingLine("internet", internetStats) + "  (\(Self.internetHost))")
        guard let gatewayStats, let internetStats else {
            print("    → ping output not recognised")
            return
        }
        print("    → " + explain(HopDiagnosis.locate(gateway: gatewayStats, internet: internetStats)))
    }

    private func reportMTU() throws {
        print("\n[5] Path MTU (don't-fragment pings to \(Self.internetHost))")
        switch MTUAnalysis.verdict(try probeMTU()) {
        case .noBlackHole:
            print("    → 1500-byte packets pass: no MTU black hole")
        case .blackHole(let mtu):
            print("    → black hole: packets over \(mtu) bytes vanish silently. "
                + "TCP usually copes; VPN and video (UDP) may stall")
        case .undetermined:
            print("    → no don't-fragment ping got through (ICMP probably blocked): MTU unknown")
        }
    }

    private func ping(_ host: String) throws -> PingStats? {
        PingParser.parse(try runCommand("/sbin/ping", ["-c", String(Self.pingCount), "-i", "0.2", "-q", host]))
    }

    /// Probes from the largest payload down and stops at the first that passes.
    private func probeMTU() throws -> [MTUProbeResult] {
        try Self.mtuPayloads.reduce(into: [MTUProbeResult]()) { results, payload in
            guard results.last?.passed != true else { return }
            let output = try runCommand(
                "/sbin/ping", ["-D", "-c", "2", "-t", "2", "-s", String(payload), Self.internetHost]
            )
            let passed = (PingParser.parse(output)?.received ?? 0) > 0
            results.append(MTUProbeResult(payloadBytes: payload, passed: passed))
        }
    }
}

private func pingLine(_ label: String, _ stats: PingStats?) -> String {
    guard let stats else { return "    \(label)  no result" }
    let latency = stats.roundTrip.map { "avg \(format($0.avgMs)) ms, max \(format($0.maxMs)) ms" } ?? "no replies"
    return "    \(label)  loss \(format(stats.lossPercent))%, \(latency)"
}

private func explain(_ verdict: HopVerdict) -> String {
    switch verdict {
    case .healthy:
        "both hops clean: no meaningful loss, low latency"
    case .localCongestion:
        "trouble starts at the gateway: crowded Wi-Fi or an overloaded local network (compare on Ethernet, step 7)"
    case .upstreamProblem:
        "gateway clean, internet not: the problem is past the gateway, and nothing on this Mac fixes it"
    case .gatewayDeprioritizesICMP:
        "gateway is slow to answer or skips pings, but traffic through it is clean: "
            + "the router deprioritizes pings to itself"
    }
}

private func format(_ value: Double) -> String {
    String(format: "%.1f", value)
}
