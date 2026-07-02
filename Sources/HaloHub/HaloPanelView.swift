import SwiftUI

struct HaloPanelView: View {
    let items: [HaloMenuItem]
    let showItemNames: Bool
    let iconSizePreference: HaloIconSizePreference
    let hubSizePreference: HaloHubSizePreference
    let appIconStyle: HaloAppIconStyle
    let presentationID: Int
    let onClose: () -> Void

    @State private var hoveredID: HaloMenuItem.ID?
    @State private var appeared = false
    @State private var chromeAppeared = false

    private var panelSize: CGFloat { hubSizePreference.panelSize }
    private var outerSize: CGFloat { hubSizePreference.outerSize }
    private var innerSectorRadius: CGFloat { hubSizePreference.innerSectorRadius }
    private var outerSectorRadius: CGFloat { hubSizePreference.outerSectorRadius }
    private var radius: CGFloat { hubSizePreference.itemRadius }
    private var center: CGFloat { panelSize / 2 }

    var body: some View {
        ZStack {
            Group {
                HaloGlassBackground(size: outerSize)

                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let sector = RingSector(
                        startAngle: sectorAngles(for: index, count: items.count).start,
                        endAngle: sectorAngles(for: index, count: items.count).end,
                        innerRadius: innerSectorRadius,
                        outerRadius: outerSectorRadius,
                        angularInset: 0
                    )

                    sector
                        .fill(Color.white.opacity(hoveredID == item.id ? 0.10 : 0))
                        .overlay {
                            sector
                                .stroke(Color.white.opacity(hoveredID == item.id ? 0.16 : 0), lineWidth: 1)
                        }
                        .frame(width: panelSize, height: panelSize)
                        .contentShape(sector)
                        .gesture(selectionGesture())
                        .animation(.easeOut(duration: 0.12), value: hoveredID)
                }

                ForEach(items.indices, id: \.self) { index in
                    SectorDivider(
                        angle: sectorAngles(for: index, count: items.count).start,
                        innerRadius: innerSectorRadius,
                        outerRadius: outerSectorRadius
                    )
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0), .white.opacity(0.12), .white.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.7
                    )
                    .frame(width: panelSize, height: panelSize)
                }

                HaloCenterGlassBackground(size: hubSizePreference.centerSize)
                    .onTapGesture(perform: onClose)
            }
            .scaleEffect(chromeAppeared ? 1 : 0.94)
            .opacity(chromeAppeared ? 1 : 0)
            .animation(chromeAppeared ? .easeOut(duration: 0.16) : .easeIn(duration: 0.12), value: chromeAppeared)

            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HaloMenuButton(
                    item: item,
                    isHovered: hoveredID == item.id,
                    showItemName: showItemNames,
                    iconSizePreference: iconSizePreference,
                    appIconStyle: appIconStyle,
                    action: {
                        item.action.perform()
                        onClose()
                    }
                )
                .position(position(for: index, count: items.count))
                .scaleEffect(appeared ? 1 : 0.88)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.16), value: appeared)
                .allowsHitTesting(false)
            }
        }
        .frame(width: panelSize, height: panelSize)
        .background(Color.clear)
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                hoveredID = hoveredItemID(at: location)
            case .ended:
                hoveredID = nil
            }
        }
        .onAppear {
            startEntranceAnimation()
        }
        .onChange(of: presentationID) { _, _ in
            startEntranceAnimation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .haloPanelWillClose)) { _ in
            startExitAnimation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .haloPanelMouseMoved)) { notification in
            guard let value = notification.object as? NSValue else { return }
            hoveredID = hoveredItemID(at: value.pointValue)
        }
    }

    private func startEntranceAnimation() {
        hoveredID = nil
        chromeAppeared = false
        appeared = false
        DispatchQueue.main.async {
            chromeAppeared = true
            appeared = true
        }
    }

    private func startExitAnimation() {
        hoveredID = nil
        chromeAppeared = false
        appeared = false
    }

    private func position(for index: Int, count: Int) -> CGPoint {
        let angle = centerAngle(for: index, count: count)
        return CGPoint(
            x: center + cos(angle) * radius,
            y: center + sin(angle) * radius
        )
    }

    private func hoveredItemID(at point: CGPoint) -> HaloMenuItem.ID? {
        let dx = point.x - center
        let dy = point.y - center
        let distance = hypot(dx, dy)
        guard distance >= innerSectorRadius, distance <= outerSectorRadius else {
            return nil
        }

        let pointerAngle = normalizedAngle(atan2(dy, dx))
        for (index, item) in items.enumerated() {
            let angle = normalizedAngle(centerAngle(for: index, count: items.count))
            let step = (Double.pi * 2) / Double(max(items.count, 1))
            if angularDistance(pointerAngle, angle) <= step / 2 {
                return item.id
            }
        }

        return nil
    }

    private func selectionGesture() -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                hoveredID = hoveredItemID(at: value.location)
            }
            .onEnded { value in
                guard let targetID = hoveredItemID(at: value.location),
                      let targetItem = items.first(where: { $0.id == targetID }) else {
                    hoveredID = nil
                    return
                }

                targetItem.action.perform()
                onClose()
            }
    }

    private func centerAngle(for index: Int, count: Int) -> Double {
        let startAngle = -Double.pi / 2
        let step = (Double.pi * 2) / Double(max(count, 1))
        return startAngle + step * Double(index)
    }

    private func sectorAngles(for index: Int, count: Int) -> (start: Double, end: Double) {
        let step = (Double.pi * 2) / Double(max(count, 1))
        let centerAngle = centerAngle(for: index, count: count)
        return (centerAngle - step / 2, centerAngle + step / 2)
    }

    private func normalizedAngle(_ angle: Double) -> Double {
        let full = Double.pi * 2
        var result = angle.truncatingRemainder(dividingBy: full)
        if result < 0 {
            result += full
        }
        return result
    }

    private func angularDistance(_ lhs: Double, _ rhs: Double) -> Double {
        let full = Double.pi * 2
        let diff = abs(lhs - rhs).truncatingRemainder(dividingBy: full)
        return min(diff, full - diff)
    }
}

struct HaloGlassBackground: View {
    let size: CGFloat

    var body: some View {
        if #available(macOS 26.0, *) {
            Circle()
                .fill(Color.white.opacity(0.001))
                .glassEffect(.regular.tint(Color.white.opacity(0.055)).interactive(), in: Circle())
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.025),
                                    Color.white.opacity(0.00)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.screen)
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 9)
                        .blur(radius: 10)
                        .padding(7)
                        .blendMode(.screen)
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.58),
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.34)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.20), radius: 22, x: 0, y: 14)
                .shadow(color: .white.opacity(0.12), radius: 10, x: -5, y: -6)
        } else {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(Circle())
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.20), lineWidth: 1)
                )
        }
    }
}

struct HaloCenterGlassBackground: View {
    let size: CGFloat

    var body: some View {
        if #available(macOS 26.0, *) {
            Circle()
                .fill(Color.white.opacity(0.001))
                .glassEffect(.regular.tint(Color.white.opacity(0.075)).interactive(), in: Circle())
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.02),
                                    Color.white.opacity(0.00)
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: size * 0.85
                            )
                        )
                        .blendMode(.screen)
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.48),
                                    Color.white.opacity(0.10),
                                    Color.white.opacity(0.24)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.16), radius: 15, x: 0, y: 8)
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

private struct HaloMenuButton: View {
    let item: HaloMenuItem
    let isHovered: Bool
    let showItemName: Bool
    let iconSizePreference: HaloIconSizePreference
    let appIconStyle: HaloAppIconStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: showItemName ? 2 : 0) {
                HaloMenuIconView(
                    icon: item.icon,
                    isHovered: isHovered,
                    appIconStyle: appIconStyle,
                    size: isHovered ? iconSizePreference.hoveredIconSize : iconSizePreference.normalIconSize,
                    symbolSize: isHovered ? iconSizePreference.hoveredSymbolSize : iconSizePreference.normalSymbolSize
                )
                .frame(width: iconSizePreference.hoveredIconSize, height: iconSizePreference.hoveredIconSize)
                    .offset(y: isHovered && showItemName ? -2 : 0)
                if showItemName {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(isHovered ? 0.98 : 0.90))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.78)
                        .frame(width: 68)
                        .clipped()
                        .help(item.title)
                }
            }
            .frame(width: 102, height: 102)
            .contentShape(Circle())
            .scaleEffect(isHovered ? 1.06 : 1)
            .shadow(color: .black.opacity(isHovered ? 0.18 : 0), radius: 12, x: 0, y: 7)
            .animation(.spring(response: 0.16, dampingFraction: 0.72), value: isHovered)
        }
        .buttonStyle(.plain)
    }
}

struct HaloMenuIconView: View {
    let icon: HaloMenuIcon
    let isHovered: Bool
    let appIconStyle: HaloAppIconStyle
    let size: CGFloat
    let symbolSize: CGFloat

    var body: some View {
        switch icon {
        case .symbol(let symbolName):
            Image(systemName: symbolName)
                .font(.system(size: symbolSize, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(Color.white.opacity(isHovered ? 1.0 : 0.84))
                .scaleEffect(isHovered ? 1.04 : 1)
                .animation(.spring(response: 0.16, dampingFraction: 0.68), value: isHovered)
        case .app(let bundleIdentifier):
            if let appURL = HaloIconCache.shared.appURL(for: bundleIdentifier) {
                styledFileIcon(for: appURL)
            } else {
                fallbackIcon
            }
        case .file(let path):
            styledFileIcon(for: URL(fileURLWithPath: path))
        case .image(let path, _):
            cachedImageIcon(path: path)
        }
    }

    private var fallbackIcon: some View {
        Image(systemName: icon.fallbackSymbolName)
            .font(.system(size: symbolSize, weight: .semibold))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(Color.white.opacity(isHovered ? 1.0 : 0.84))
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
