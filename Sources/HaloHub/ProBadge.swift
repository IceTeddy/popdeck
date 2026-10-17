import SwiftUI

/// Gold entitlement marker, shown for paid features even after activation.
struct ProBadge: View {
    var body: some View {
        Text("PRO").font(.system(size: 9, weight: .heavy, design: .rounded))
            .foregroundStyle(Color(red: 0.28, green: 0.17, blue: 0.04))
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(LinearGradient(colors: [Color(red: 1, green: 0.88, blue: 0.57), Color(red: 0.86, green: 0.64, blue: 0.26)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 0.5))
            .fixedSize().accessibilityLabel("PRO")
    }
}

struct ProFeatureLabel: View {
    let title: String
    var systemImage: String? = nil
    var body: some View {
        HStack(spacing: 6) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title)
            ProBadge()
        }
        .accessibilityElement(children: .combine)
    }
}

/// Native macOS menus flatten custom SwiftUI label backgrounds, so give them
/// a non-template gold badge image rather than relying on a Capsule view.
struct ProMenuLabel: View {
    let title: String
    var body: some View {
        Label { Text(title) } icon: { Image(nsImage: Self.image) }
            .accessibilityLabel(title + " PRO")
    }
    private static var image: NSImage {
        NSImage(size: NSSize(width: 32, height: 16), flipped: false) { rect in
            NSColor(calibratedRed: 0.96, green: 0.77, blue: 0.37, alpha: 1).setFill()
            NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 7, yRadius: 7).fill()
            let text = "PRO" as NSString
            let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 9, weight: .heavy), .foregroundColor: NSColor(calibratedRed: 0.28, green: 0.17, blue: 0.04, alpha: 1)]
            let size = text.size(withAttributes: attributes)
            text.draw(at: NSPoint(x: (rect.width - size.width) / 2, y: (rect.height - size.height) / 2), withAttributes: attributes)
            return true
        }
    }
}
