import AppKit
import SwiftUI

/// A native glass container with SwiftUI controls in its documented contentView.
@available(macOS 26.0, *)
struct NativeCircleGlass<Content: View>: NSViewRepresentable {
    let size: CGFloat
    let strength: Double
    let content: Content

    func makeNSView(context: Context) -> NSGlassEffectView {
        let glass = NSGlassEffectView()
        glass.style = .clear
        applyTint(to: glass)
        glass.cornerRadius = size / 2
        let hosting = NSHostingView(rootView: AnyView(content.frame(width: size, height: size)))
        hosting.sizingOptions = []
        glass.contentView = hosting
        return glass
    }

    func updateNSView(_ glass: NSGlassEffectView, context: Context) {
        applyTint(to: glass)
        glass.cornerRadius = size / 2
        if let hosting = glass.contentView as? NSHostingView<AnyView> {
            hosting.rootView = AnyView(content.frame(width: size, height: size))
        }
    }
    private func applyTint(to glass: NSGlassEffectView) {
        let amount = strength.isFinite ? min(max(strength, 0), 1) : 0
        // Native tint only: do not change the opacity of the view or its content,
        // add a solid overlay, or blend multiple glass styles.
        glass.tintColor = amount == 0 ? nil : NSColor.black.withAlphaComponent(amount * 0.75)
    }
}
