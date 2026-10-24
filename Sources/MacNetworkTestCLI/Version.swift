import ArgumentParser

struct Version: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Print version"
    )

    static let current = "0.1.0"

    func run() {
        print("mac-network-test \(Version.current)")
    }
}
