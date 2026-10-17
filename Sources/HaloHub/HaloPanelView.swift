import SwiftUI

/// Public single-panel launcher. No nested actions or additional ring rendering.
struct HaloPanelView: View {
    let items: [HaloMenuItem]
    let showItemNames: Bool
    let appearance: HaloRingAppearance
    let presentationID: Int
    let onClose: () -> Void
    var renderScale: CGFloat = 1
    @State private var hoveredID: UUID?
    @State private var appeared = false
    private var metrics: SinglePanelMetrics { .init(appearance: appearance) }
    private var sectors: [HaloPanelSector] { HaloPanelSector.make(items: items) }
    private var center: CGFloat { metrics.panelSize / 2 }
    var body: some View {
        HaloGlassSurface(size: metrics.outerRadius * 2) {
            ZStack {
                ForEach(sectors) { sector in
                    let shape = RingSector(startAngle: sector.start, endAngle: sector.end, innerRadius: metrics.innerRadius, outerRadius: metrics.outerRadius, angularInset: 0)
                    shape.fill(sector.backgroundColor?.color.opacity(0.075) ?? .clear)
                    shape.fill(.white.opacity(hoveredID == sector.id ? 0.1 : 0))
                    SectorDivider(angle: sector.start, innerRadius: metrics.innerRadius, outerRadius: metrics.outerRadius)
                        .stroke(.primary.opacity(0.10), lineWidth: 0.7)
                    let fan = sector.item.iconAppearance.displayMode == .nameOnly && sector.item.iconAppearance.textStyle == .fan
                    LauncherItemLabel(item: sector.item, angle: sector.angle, radius: metrics.itemRadius,
                        isHovered: hoveredID == sector.id, showItemName: showItemNames,
                        iconSizePreference: appearance.iconSize, appIconStyle: appearance.iconStyle, span: sector.span)
                        .position(sector.position(center: center, radius: fan ? (metrics.innerRadius + metrics.outerRadius) / 2 : metrics.itemRadius))
                }
                HaloCenterGlassBackground(size: metrics.centerSize)
                    .overlay {
                        if let item = items.first(where: { $0.id == hoveredID }) {
                            Text(item.title).font(.system(size: 13, weight: .semibold))
                                .multilineTextAlignment(.center).lineLimit(3).frame(width: metrics.centerSize - 22)
                        }
                    }
            }.frame(width: metrics.panelSize, height: metrics.panelSize)
                .allowsHitTesting(false)
        }
        .frame(width: metrics.panelSize, height: metrics.panelSize)
        .scaleEffect(appeared ? renderScale : renderScale * 0.94)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.12), value: appeared)
        .frame(width: metrics.panelSize * renderScale, height: metrics.panelSize * renderScale)
        .onAppear { appeared = true }
        .onChange(of: presentationID) { _, _ in appeared = true; hoveredID = nil }
        .onReceive(NotificationCenter.default.publisher(for: .haloPanelWillClose)) { _ in appeared = false; hoveredID = nil; HoverSoundPlayer.shared.reset() }
        .onReceive(NotificationCenter.default.publisher(for: .haloPanelMouseMoved)) { note in
            guard let value = note.object as? NSValue else { return }
            hoveredID = hit(value.pointValue)?.id
            HoverSoundPlayer.shared.hover(hoveredID?.uuidString)
        }
        .onReceive(NotificationCenter.default.publisher(for: .haloPanelSelection)) { note in
            guard let value = note.object as? NSValue else { return }
            if let sector = hit(value.pointValue) { sector.item.action.perform() }
            onClose()
        }
    }
    private func hit(_ point: CGPoint) -> HaloPanelSector? {
        HaloPanelSector.hit(at: .init(x: point.x / renderScale, y: point.y / renderScale), center: center,
            inner: metrics.innerRadius, outer: metrics.outerRadius, sectors: sectors)
    }
}
