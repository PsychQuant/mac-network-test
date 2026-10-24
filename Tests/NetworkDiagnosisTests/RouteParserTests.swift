import Testing
@testable import NetworkDiagnosis

struct RouteParserTests {
    @Test func `Reads gateway and interface of the default route`() throws {
        let output = """
               route to: default
            destination: default
                   mask: default
                gateway: 192.0.2.254
              interface: en14
                  flags: <UP,GATEWAY,DONE,STATIC,PRCLONING,GLOBAL>
            """
        let route = try #require(RouteParser.parseDefault(output))
        #expect(route == DefaultRoute(gateway: "192.0.2.254", interface: "en14"))
    }

    @Test func `No default route returns nil`() {
        #expect(RouteParser.parseDefault("route: writing to routing socket: not in table") == nil)
    }
}
