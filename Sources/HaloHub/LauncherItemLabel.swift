import SwiftUI

/// Used by both the live ring and its Settings preview.
struct LauncherItemLabel: View {
    let item: HaloMenuItem
    let angle: Double
    let radius: CGFloat
    let isHovered: Bool
    let showItemName: Bool
    let iconSizePreference: HaloIconSizePreference
    let appIconStyle: HaloAppIconStyle
    var span: Double = .pi / 3

    var compact = false
    var radialLength: CGFloat? = nil
    var availableThickness: CGFloat? = nil
    private var iconLimit: CGFloat { availableThickness.map { max(10, $0 - (showsName ? 22 : 4)) } ?? .greatestFiniteMagnitude }

    private var showsName: Bool {
        switch item.iconAppearance.displayMode {
        case .automatic: showItemName
        case .iconOnly: false
        case .nameOnly, .iconAndName: true
        }
    }

    var body: some View {
        VStack(spacing: 3) {
            if item.iconAppearance.displayMode != .nameOnly {
                HaloMenuIconView(icon: item.icon, isHovered: false, appIconStyle: appIconStyle,
                    size: min(iconLimit, compact ? iconSizePreference.normalIconSize * 0.72 : iconSizePreference.normalIconSize),
                    symbolSize: min(iconLimit, compact ? iconSizePreference.normalSymbolSize * 0.72 : iconSizePreference.normalSymbolSize),
                    appearance: item.iconAppearance)
                    .frame(width: min(iconLimit, compact ? 44 : iconSizePreference.hoveredIconSize), height: min(iconLimit, compact ? 44 : iconSizePreference.hoveredIconSize))
                    .scaleEffect(isHovered ? 1.06 : 1)
                    .animation(.easeOut(duration: 0.12), value: isHovered)
            }
            if showsName {
                if item.iconAppearance.displayMode == .nameOnly && item.iconAppearance.textStyle == .circular {
                    CircularCommandText(text: item.title, angle: angle, radius: radius, span: span,
                        color: item.iconAppearance.color?.color ?? .primary)
                } else if item.iconAppearance.displayMode == .nameOnly && item.iconAppearance.textStyle != .horizontal {
                    Group {
                        if item.iconAppearance.textStyle == .fan {
                            FanCommandText(text: item.title, angle: angle, length: (radialLength ?? radius * 0.65), thickness: 26,
                                color: item.iconAppearance.color?.color ?? .primary)
                        } else {
                            Text(item.title).font(.system(size: 14, weight: .semibold))
                                .lineLimit(1).minimumScaleFactor(0.5).frame(width: (radialLength ?? radius * 0.65))
                        }
                    }
                    .rotationEffect(.radians(LauncherTextLayout.rotation(angle: angle)))
                } else {
                    Text(item.title).font(.system(size: compact ? 11 : 13, weight: .semibold))
                        .lineLimit(item.iconAppearance.displayMode == .nameOnly ? 2 : 1)
                        .multilineTextAlignment(.center).minimumScaleFactor(0.75)
                        .frame(width: compact ? 56 : (item.iconAppearance.displayMode == .nameOnly ? 90 : 68))
                }
            }
        }
        .foregroundStyle(item.iconAppearance.color?.color ?? .primary)
        .frame(width: compact ? 68 : 102, height: compact ? 68 : 102)
        .overlay(alignment: .bottomTrailing) {
            if item.kind == .unavailable {
                Image(systemName: "lock.fill").font(.system(size: 10)).foregroundStyle(.orange)
                    .padding(5).background(.regularMaterial, in: Circle()).allowsHitTesting(false)
            }
        }
        .help(item.title)
        .accessibilityLabel(item.title)
    }
}
