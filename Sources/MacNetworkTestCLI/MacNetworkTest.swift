import ArgumentParser

@main
struct MacNetworkTest: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mac-network-test",
        abstract: "Find where a Mac's network bottleneck is: Wi-Fi, gateway, or upstream.",
        subcommands: [Check.self, Version.self],
        defaultSubcommand: Check.self
    )
}
