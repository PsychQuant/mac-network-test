import Foundation

public struct DefaultRoute: Equatable, Sendable {
    public let gateway: String
    public let interface: String

    public init(gateway: String, interface: String) {
        self.gateway = gateway
        self.interface = interface
    }
}

public enum RouteParser {
    /// Parses `route -n get default`. nil when there is no default route or it has no gateway.
    public static func parseDefault(_ output: String) -> DefaultRoute? {
        let pairs = output.split(separator: "\n").compactMap { line -> (String, String)? in
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            return (parts[0].trimmingCharacters(in: .whitespaces), parts[1].trimmingCharacters(in: .whitespaces))
        }
        let fields = Dictionary(pairs, uniquingKeysWith: { first, _ in first })
        guard let gateway = fields["gateway"], let interface = fields["interface"] else { return nil }
        return DefaultRoute(gateway: gateway, interface: interface)
    }
}
