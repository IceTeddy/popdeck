import SwiftUI

struct HaloGlassSurface<Content: View>: View {
    @AppStorage(AppPreferences.glassStyleKey) private var glassStyle = HaloGlassStyle.regular.rawValue
    let size: CGFloat
    var isInteractionEnabled = true
    @ViewBuilder var content: Content

    var body: some View {
        if #available(macOS 26.0, *) {
            NativeCircleGlass(size: size, style: HaloGlassStyle(rawValue: glassStyle) ?? .regular, content: content, isInteractionEnabled: isInteractionEnabled)
                .frame(width: size, height: size)

        } else {
            content.background {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                    .clipShape(Circle())
                    .frame(width: size, height: size)
                    .overlay {
                        Circle().strokeBorder(.white.opacity(0.20), lineWidth: 1)
                    }
            }
        }
    }
}

struct HaloCenterGlassBackground: View {
    let size: CGFloat

    var body: some View {
        if #available(macOS 26.0, *) {
            // The center shares the outer glass instead of stacking glass on glass.
            Circle()
                .fill(.clear)
                .overlay {
                    Circle().strokeBorder(.primary.opacity(0.12), lineWidth: 1)
                }
                .frame(width: size, height: size)
                .contentShape(Circle())
        } else {
            VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
                .clipShape(Circle())
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .fill(Color.black.opacity(0.06))
                )
        }
    }
}

struct RingSector: Shape {
    let startAngle: Double
    let endAngle: Double
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let angularInset: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let start = startAngle + angularInset
        let end = endAngle - angularInset

        var path = Path()
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: Angle(radians: start),
            endAngle: Angle(radians: end),
            clockwise: false
        )
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: Angle(radians: end),
            endAngle: Angle(radians: start),
            clockwise: true
        )
        path.closeSubpath()
        return path
    }
}

struct HaloMenuButton: View {
    let item: HaloMenuItem
    let angle: Double
    let radius: CGFloat
    let span: Double
    let isHovered: Bool
    let showItemName: Bool
    let iconSizePreference: HaloIconSizePreference
    let appIconStyle: HaloAppIconStyle
    let action: () -> Void
    var availableThickness: CGFloat? = nil

    var body: some View {
        Button(action: action) {
            LauncherItemLabel(item: item, angle: angle, radius: radius, isHovered: isHovered,
                              showItemName: showItemName, iconSizePreference: iconSizePreference, appIconStyle: appIconStyle, span: span,
                              radialLength: availableThickness.map { $0 * 0.8 }, availableThickness: availableThickness)
            .contentShape(Circle())

        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
    }
}

struct HaloMenuIconView: View {
    let icon: HaloMenuIcon
    let isHovered: Bool
    let appIconStyle: HaloAppIconStyle
    let size: CGFloat
    let symbolSize: CGFloat
    var appearance = HaloIconAppearance()

    var body: some View {
        if let data = appearance.normalized.customImageData, let image = CustomIconImageCache.shared.image(for: data) {
            Image(nsImage: image)
                .resizable().interpolation(.high).aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .saturation(appIconStyle == .monochrome && !isHovered ? 0 : 1)
                .scaleEffect(isHovered ? 1.04 : 1)
        } else if let emoji = appearance.normalized.emoji {
            Text(emoji).font(.system(size: size * 0.85))
                .frame(width: size, height: size)
                .scaleEffect(isHovered ? 1.04 : 1)
        } else {
            originalIcon
        }
    }

    @ViewBuilder
    private var originalIcon: some View {
        switch icon {
        case .symbol(let symbolName):
            Image(systemName: symbolName)
                .font(.system(size: symbolSize, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle((appearance.color?.color ?? Color.primary).opacity(isHovered ? 1.0 : 0.84))
                .scaleEffect(isHovered ? 1.04 : 1)
                .animation(.spring(response: 0.16, dampingFraction: 0.68), value: isHovered)
        case .app(let bundleIdentifier):
            if let appURL = HaloIconCache.shared.appURL(for: bundleIdentifier) {
                styledFileIcon(for: appURL)
                    .saturation(appearance.color == nil ? 1 : 0)
                    .colorMultiply(appearance.color?.color ?? .white)
            } else {
                fallbackIcon
            }
        case .file(let path):
            styledFileIcon(for: URL(fileURLWithPath: path))
                .saturation(appearance.color == nil ? 1 : 0)
                .colorMultiply(appearance.color?.color ?? .white)
        case .image(let path, _):
            cachedImageIcon(path: path)
                .saturation(appearance.color == nil ? 1 : 0)
                .colorMultiply(appearance.color?.color ?? .white)
        }
    }

    private var fallbackIcon: some View {
        Image(systemName: icon.fallbackSymbolName)
            .font(.system(size: symbolSize, weight: .semibold))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle((appearance.color?.color ?? Color.primary).opacity(isHovered ? 1.0 : 0.84))
            .scaleEffect(isHovered ? 1.04 : 1)
            .animation(.spring(response: 0.16, dampingFraction: 0.68), value: isHovered)
    }

    private func baseFileIcon(for url: URL) -> some View {
        Image(nsImage: HaloIconCache.shared.fileIcon(for: url))
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }

    @ViewBuilder
    private func styledFileIcon(for url: URL) -> some View {
        switch appIconStyle {
        case .original:
            baseFileIcon(for: url)
                .scaleEffect(isHovered ? 1.04 : 1)
                .shadow(color: .black.opacity(isHovered ? 0.24 : 0.18), radius: isHovered ? 7 : 5, x: 0, y: isHovered ? 3 : 2)
                .animation(.spring(response: 0.16, dampingFraction: 0.68), value: isHovered)
        case .monochrome:
            baseFileIcon(for: url)
                .saturation(isHovered ? 1 : 0)
                .contrast(isHovered ? 1 : 1.22)
                .brightness(isHovered ? 0 : 0.08)
                .opacity(isHovered ? 1.0 : 0.92)
                .scaleEffect(isHovered ? 1.05 : 1)
                .shadow(color: .black.opacity(isHovered ? 0.24 : 0.16), radius: isHovered ? 7 : 4, x: 0, y: isHovered ? 3 : 2)
                .animation(.spring(response: 0.16, dampingFraction: 0.68), value: isHovered)
        }
    }

    @ViewBuilder
    private func cachedImageIcon(path: String) -> some View {
        if let image = HaloIconCache.shared.image(at: path) {
            switch appIconStyle {
            case .original:
                cachedOriginalImageIcon(image)
                    .scaleEffect(isHovered ? 1.04 : 1)
                    .shadow(color: .black.opacity(isHovered ? 0.24 : 0.16), radius: isHovered ? 7 : 4, x: 0, y: isHovered ? 3 : 2)
                    .animation(.spring(response: 0.16, dampingFraction: 0.68), value: isHovered)
            case .monochrome:
                cachedOriginalImageIcon(image)
                    .saturation(isHovered ? 1 : 0)
                    .contrast(isHovered ? 1 : 1.22)
                    .brightness(isHovered ? 0 : 0.08)
                    .opacity(isHovered ? 1.0 : 0.92)
                    .scaleEffect(isHovered ? 1.05 : 1)
                    .shadow(color: .black.opacity(isHovered ? 0.24 : 0.16), radius: isHovered ? 7 : 4, x: 0, y: isHovered ? 3 : 2)
                    .animation(.spring(response: 0.16, dampingFraction: 0.68), value: isHovered)
            }
        } else {
            fallbackIcon
        }
    }

    private func cachedOriginalImageIcon(_ image: NSImage) -> some View {
        let visualSize = size * image.haloRecommendedFaviconScale
        return Image(nsImage: image)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: visualSize, height: visualSize)
            .clipShape(RoundedRectangle(cornerRadius: max(9, visualSize * 0.28), style: .continuous))
            .frame(width: size, height: size)
    }

}

@MainActor
private final class HaloIconCache {
    static let shared = HaloIconCache()

    private var fileIcons: [String: NSImage] = [:]
    private var images: [String: NSImage] = [:]
    private var appURLs: [String: URL] = [:]

    private init() {}

    func fileIcon(for url: URL) -> NSImage {
        let path = url.path
        if let cached = fileIcons[path] {
            return cached
        }

        let image = NSWorkspace.shared.icon(forFile: path)
        image.size = NSSize(width: 128, height: 128)
        fileIcons[path] = image
        return image
    }

    func appURL(for bundleIdentifier: String) -> URL? {
        if let cached = appURLs[bundleIdentifier] {
            return cached
        }

        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return nil
        }

        appURLs[bundleIdentifier] = url
        return url
    }

    func image(at path: String) -> NSImage? {
        if let cached = images[path] {
            return cached
        }

        guard let image = NSImage(contentsOfFile: path) else {
            return nil
        }

        images[path] = image
        return image
    }
}

private extension NSImage {
    var haloRecommendedFaviconScale: CGFloat {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil),
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0.90
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = cgImage.bytesPerRow
        let bytesPerPixel = max(cgImage.bitsPerPixel / 8, 1)
        let alphaInfo = cgImage.alphaInfo
        let hasAlpha = alphaInfo != .none && alphaInfo != .noneSkipFirst && alphaInfo != .noneSkipLast
        guard hasAlpha, bytesPerPixel >= 4, width > 0, height > 0 else {
            return 0.84
        }

        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        var hasVisiblePixel = false

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let alphaOffset: Int
                switch alphaInfo {
                case .premultipliedFirst, .first:
                    alphaOffset = 0
                default:
                    alphaOffset = bytesPerPixel - 1
                }

                if bytes[offset + alphaOffset] > 18 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                    hasVisiblePixel = true
                }
            }
        }

        guard hasVisiblePixel else { return 0.90 }

        let contentWidth = CGFloat(maxX - minX + 1)
        let contentHeight = CGFloat(maxY - minY + 1)
        let coverage = max(contentWidth / CGFloat(width), contentHeight / CGFloat(height))

        if coverage > 0.94 {
            return 0.82
        } else if coverage > 0.84 {
            return 0.88
        } else if coverage > 0.72 {
            return 0.94
        } else {
            return 1.0
        }
    }
}

#if DEBUG
/// Diagnostic content behind the real panel surface, never used in release builds.
/// A window-only screenshot otherwise omits the desktop sampled by the compositor.
struct GlassVerificationBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(white: 0.92)
                HStack(spacing: 0) {
                    Color(white: 0.08)
                    Color(white: 0.92)
                }
                ForEach(0..<12) { index in
                    Rectangle()
                        .fill(index.isMultiple(of: 2) ? Color.blue : Color.orange)
                        .frame(width: 2)
                        .position(x: CGFloat(index + 1) * proxy.size.width / 13, y: proxy.size.height / 2)
                }
                ForEach(0..<12) { index in
                    Rectangle()
                        .fill(Color.red)
                        .frame(height: 2)
                        .position(x: proxy.size.width / 2, y: CGFloat(index + 1) * proxy.size.height / 13)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
#endif
