import AppKit
import Foundation

/// Executes saved shell source unchanged, away from the UI thread.
enum CommandRunner {
    struct Result: Sendable {
        let status: Int32
        let error: String
    }

    static func isValid(_ command: String) -> Bool {
        !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !command.contains("\0")
    }

    static func run(_ command: String) -> Result {
        guard isValid(command) else { return Result(status: -1, error: "Empty command or NUL character.") }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]
        process.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        let errors = Pipe()
        process.standardError = errors
        do {
            try process.run()
            // Drain continuously so large stderr output cannot block the child.
            // Retain only the tail to keep memory bounded.
            try? errors.fileHandleForWriting.close()
            var tail = Data()
            while let chunk = try errors.fileHandleForReading.read(upToCount: 4096), !chunk.isEmpty {
                tail.append(chunk)
                tail = Data(tail.suffix(8192))
            }
            process.waitUntilExit()
            return Result(status: process.terminationStatus, error: String(decoding: tail, as: UTF8.self))
        } catch {
            return Result(status: -1, error: error.localizedDescription)
        }
    }

    @MainActor
    static func perform(_ command: String, opensTerminal: Bool = false) {
        if opensTerminal {
            TerminalCommandLauncher.perform(command)
            return
        }
        Task {
            let result = await Task.detached(priority: .userInitiated) { run(command) }.value
            guard result.status != 0 else { return }
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = L10n.t("command.failed.title")
            alert.informativeText = String(format: L10n.t("command.failed.message"), result.status)
                + (result.error.isEmpty ? "" : "\n\n" + result.error)
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }
}
