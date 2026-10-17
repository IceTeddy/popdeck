import AppKit
import Foundation

enum TerminalCommandLauncher {
    static func shellArgument(_ source: String) -> String {
        "'" + source.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    static func script(for command: String) -> String {
        """
        #!/bin/zsh
        /bin/rm -f -- "$0"
        cd -- "$HOME" || exit 1
        /bin/zsh -lc \(shellArgument(command))
        _popdeck_status=$?
        printf '\\n[PopDeck] Exit status: %d\\n' "$_popdeck_status"
        exec /bin/zsh -l

        """
    }

    @MainActor
    static func perform(_ command: String) {
        guard CommandRunner.isValid(command) else { return }
        Task {
            var scriptURL: URL?
            do {
                guard let terminal = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") else {
                    throw CocoaError(.fileNoSuchFile)
                }
                let directory = FileManager.default.temporaryDirectory
                    .appendingPathComponent(AppIdentity.cacheDirectoryName + "-commands", isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                       attributes: [.posixPermissions: 0o700])
                let url = directory.appendingPathComponent(UUID().uuidString + ".command")
                scriptURL = url
                try Data(script(for: command).utf8).write(to: url, options: .atomic)
                try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
                let configuration = NSWorkspace.OpenConfiguration()
                configuration.activates = true
                // Hand off an executable document; no AppleScript/Automation permission.
                _ = try await NSWorkspace.shared.open([url], withApplicationAt: terminal, configuration: configuration)
            } catch {
                if let scriptURL { try? FileManager.default.removeItem(at: scriptURL) }
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = L10n.t("command.failed.title")
                alert.informativeText = error.localizedDescription
                NSApp.activate(ignoringOtherApps: true)
                alert.runModal()
            }
        }
    }
}
