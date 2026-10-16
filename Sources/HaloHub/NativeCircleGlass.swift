import AppKit
import SwiftUI

/// A native glass container with SwiftUI controls in its documented contentView.
@available(macOS 26.0, *)
struct NativeCircleGlass<Content: View>: NSViewRepresentable {
    let size: CGFloat
    let style: HaloGlassStyle
    let content: Content

    func makeNSView(context: Context) -> NSGlassEffectView {
        let glass = NSGlassEffectView()
        applyStyle(to: glass)
        glass.cornerRadius = size / 2
        let hosting = NSHostingView(rootView: AnyView(content.frame(width: size, height: size)))
        hosting.sizingOptions = []
        glass.contentView = hosting
        return glass
    }

    func updateNSView(_ glass: NSGlassEffectView, context: Context) {
        applyStyle(to: glass)
        glass.cornerRadius = size / 2
        if let hosting = glass.contentView as? NSHostingView<AnyView> {
            hosting.rootView = AnyView(content.frame(width: size, height: size))
        }
    }
    private func applyStyle(to glass: NSGlassEffectView) {
        // The public API exposes material variants, not a blur-radius control.
        // Leave tint unset so AppKit owns luminosity and system preferences.
        glass.style = style == .clear ? .clear : .regular
        glass.tintColor = nil
    }
}
