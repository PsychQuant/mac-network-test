import Foundation

struct CommandError: Error, CustomStringConvertible {
    let executable: String
    let underlying: Error

    var description: String { "could not run \(executable): \(underlying.localizedDescription)" }
}

/// Runs a system command and returns stdout and stderr combined.
/// A non-zero exit is not an error here: `ping` exits 2 on total loss but still prints its summary.
func runCommand(_ executable: String, _ arguments: [String]) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    do {
        try process.run()
    } catch {
        throw CommandError(executable: executable, underlying: error)
    }
    // Drain the pipe before waiting, or a full pipe buffer deadlocks the child.
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return String(decoding: data, as: UTF8.self)
}
