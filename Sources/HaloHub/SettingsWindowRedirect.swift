import AppKit
import SwiftUI

/// SwiftUI's built-in Settings command and the status menu must open the same
/// resizable window, including when macOS restores the Settings scene itself.
struct SettingsWindowRedirect: NSViewRepresentable {
    func makeNSView(context: Context) -> RedirectView { RedirectView() }
    func updateNSView(_ nsView: RedirectView, context: Context) {}

    final class RedirectView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            DispatchQueue.main.async { [weak window] in
                window?.close()
                SettingsWindowController.shared.show()
            }
        }
    }
}
