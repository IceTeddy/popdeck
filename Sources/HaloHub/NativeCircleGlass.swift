import AppKit
import SwiftUI

/// A native glass container with SwiftUI controls in its documented contentView.
@available(macOS 26.0, *)
struct NativeCircleGlass<Content: View>: NSViewRepresentable {
    let size: CGFloat
    let style: HaloGlassStyle
    let content: Content
    var isInteractionEnabled = true

    func makeNSView(context: Context) -> NSGlassEffectView {
        let glass = CircularGlassEffectView()
        applyStyle(to: glass)
        glass.cornerRadius = size / 2
        glass.isInteractionEnabled = isInteractionEnabled
        let hosting = NSHostingView(rootView: AnyView(content.frame(width: size, height: size)))
        hosting.sizingOptions = []
        glass.contentView = hosting
        return glass
    }

    func updateNSView(_ glass: NSGlassEffectView, context: Context) {
        applyStyle(to: glass)
        glass.cornerRadius = size / 2
        (glass as? CircularGlassEffectView)?.isInteractionEnabled = isInteractionEnabled
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

/// Let the ring behind receive events outside this native circular surface.
@available(macOS 26.0, *)
private final class CircularGlassEffectView: NSGlassEffectView {
    var isInteractionEnabled = true
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard isInteractionEnabled else { return nil }
        let local = convert(point, from: superview)
        guard hypot(local.x - bounds.midX, local.y - bounds.midY) <= min(bounds.width, bounds.height) / 2 else { return nil }
        return super.hitTest(point)
    }
}
