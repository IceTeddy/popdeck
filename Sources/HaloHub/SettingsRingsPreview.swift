import SwiftUI
import UniformTypeIdentifiers

/// Free editor: a single circle, parent-sector resizing and ordinary item editing.
struct SettingsRingsPreview: View {
    @ObservedObject var store: HaloMenuStore
    let appearance: HaloRingAppearance
    let isResizing: Bool
    let showNames: Bool
    let onURL: () -> Void
    let onCommand: () -> Void
    let onEdit: (UUID) -> Void
    let onAppearance: (HaloMenuItem) -> Void
    @State private var draft: [HaloMenuItem]?
    @State private var boundary: SectorBoundary?
    @State private var baseline: [HaloMenuItem] = []
    @State private var lastAngle: Double = 0
    @State private var delta: Double = 0
    @State private var cursorPushed = false
    @State private var hovered: UUID?
    private var metrics: SinglePanelMetrics { .init(appearance: appearance) }
    private var center: CGFloat { metrics.panelSize / 2 }
    private var items: [HaloMenuItem] { draft ?? store.items }
    @Environment(\.settingsPreviewDiameter) private var availableDiameter
    private var scale: CGFloat { min(1, availableDiameter / metrics.panelSize) }

    var body: some View {
        ZStack {
            HaloGlassSurface(size: metrics.outerRadius * 2) {
                ZStack {
                    ForEach(HaloPanelSector.make(items: items)) { sector in
                        RingSector(startAngle: sector.start, endAngle: sector.end, innerRadius: metrics.innerRadius, outerRadius: metrics.outerRadius, angularInset: 0)
                            .fill(sector.backgroundColor?.color.opacity(0.075) ?? .clear)
                        SectorDivider(angle: sector.start, innerRadius: metrics.innerRadius, outerRadius: metrics.outerRadius)
                            .stroke(.primary.opacity(0.10), lineWidth: 0.7)
                    }
                    HaloCenterGlassBackground(size: metrics.centerSize)
                }.frame(width: metrics.panelSize, height: metrics.panelSize)
            }.allowsHitTesting(false)
            ForEach(HaloPanelSector.make(items: items)) { sector in
                let shape = RingSector(startAngle: sector.start, endAngle: sector.end, innerRadius: metrics.innerRadius, outerRadius: metrics.outerRadius, angularInset: 0)
                shape.fill(.white.opacity(hovered == sector.id ? 0.08 : 0.001)).contentShape(shape)
                    .gesture(DragGesture(minimumDistance: 4, coordinateSpace: .named("freeEditor")).onEnded { value in
                        if hypot(value.location.x - center, value.location.y - center) < metrics.centerSize / 2 { store.removeItem(id: sector.id) }
                        else if let target = hit(value.location), let index = items.firstIndex(where: { $0.id == target.id }) { store.moveItem(id: sector.id, to: index) }
                    }, including: isResizing ? .none : .all)
                    .contextMenu {
                        if sector.item.kind == .command { Button(L10n.t("settings.editCommand")) { onEdit(sector.id) } }
                        if sector.item.kind == .unavailable { Button { FreeEditionInfo.show() } label: { ProMenuLabel(title: sector.item.title) } }
                        else { Button(L10n.t("settings.iconAppearance")) { onAppearance(sector.item) } }
                        Button(L10n.t("settings.rings.remove"), role: .destructive) { store.removeItem(id: sector.id) }
                    }
                LauncherItemLabel(item: sector.item, angle: sector.angle, radius: metrics.itemRadius,
                    isHovered: false, showItemName: showNames, iconSizePreference: appearance.iconSize, appIconStyle: appearance.iconStyle, span: sector.span)
                    .position(sector.position(center: center, radius: sector.item.iconAppearance.displayMode == .nameOnly && sector.item.iconAppearance.textStyle == .fan ? (metrics.innerRadius + metrics.outerRadius) / 2 : metrics.itemRadius))
                    .allowsHitTesting(false)
            }
            if let item = items.first(where: { $0.id == hovered }) {
                Text(item.title).font(.system(size: 12, weight: .semibold)).lineLimit(3)
                    .frame(width: metrics.centerSize - 20).multilineTextAlignment(.center).allowsHitTesting(false)
            }
            if isResizing {
                ForEach(SectorBoundary.make(items: items)) { edge in
                    SectorDivider(angle: edge.angle, innerRadius: metrics.innerRadius + 5, outerRadius: metrics.outerRadius - 5)
                        .stroke(Color.accentColor.opacity(0.8), lineWidth: 3 / scale).allowsHitTesting(false)
                    Circle().fill(Color.accentColor).frame(width: 8 / scale, height: 8 / scale)
                        .position(x: center + cos(edge.angle) * (metrics.innerRadius + metrics.outerRadius) / 2,
                                  y: center + sin(edge.angle) * (metrics.innerRadius + metrics.outerRadius) / 2).allowsHitTesting(false)
                }
                Color.clear.contentShape(Circle()).gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("freeEditor"))
                    .onChanged { value in
                        let angle = atan2(value.location.y - center, value.location.x - center)
                        if boundary == nil {
                            boundary = SectorBoundary.nearest(at: value.startLocation, center: center, inner: metrics.innerRadius + 5, outer: metrics.outerRadius, items: items, hitWidth: 10 / scale)
                            baseline = store.items; delta = 0
                            lastAngle = atan2(value.startLocation.y - center, value.startLocation.x - center)
                        }
                        guard let boundary else { return }
                        delta += SectorGeometry.wrappedDelta(angle - lastAngle); lastAngle = angle
                        draft = boundary.resizing(baseline, by: delta)
                    }.onEnded { _ in if let draft { _ = store.updateSectorLayout(draft) }; boundary = nil; draft = nil; setResizeCursor(false) })
            }
            Menu {
                Button(L10n.t("settings.group.addFile")) { pickFiles() }
                Button(L10n.t("settings.addURL.button"), action: onURL)
                Button(L10n.t("settings.addCommand.button"), action: onCommand)
                Divider()
                Button { FreeEditionInfo.show() } label: { ProMenuLabel(title: L10n.t("settings.commandSet.add")) }
                Button { FreeEditionInfo.show() } label: { ProMenuLabel(title: L10n.t("settings.group.add")) }
            } label: { Image(systemName: "plus").font(.system(size: 15, weight: .semibold)).frame(width: 28, height: 28) }
                .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                .background(.regularMaterial, in: Circle()).scaleEffect(1 / scale)
                .position(x: center + metrics.outerRadius * 0.7071, y: center - metrics.outerRadius * 0.7071)
        }
        .frame(width: metrics.panelSize, height: metrics.panelSize)
        .coordinateSpace(name: "freeEditor")
        .onContinuousHover { phase in
            if case .active(let point) = phase {
                hovered = hit(point)?.id
                setResizeCursor(isResizing && SectorBoundary.nearest(at: point, center: center, inner: metrics.innerRadius + 5, outer: metrics.outerRadius, items: items, hitWidth: 10 / scale) != nil)
            } else { hovered = nil; setResizeCursor(false) }
        }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: nil) { providers in
            for provider in providers {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    let url: URL?
                    if let value = item as? URL { url = value }
                    else if let data = item as? Data { url = URL(dataRepresentation: data, relativeTo: nil) }
                    else { url = nil }
                    guard let url, url.isFileURL else { return }
                    Task { @MainActor in store.addDroppedItem(at: url) }
                }
            }
            return !providers.isEmpty
        }
        .scaleEffect(scale).frame(width: metrics.panelSize * scale, height: metrics.panelSize * scale)
        .onDisappear { setResizeCursor(false) }
        .onChange(of: isResizing) { _, _ in boundary = nil; draft = nil; setResizeCursor(false) }
    }
    private func setResizeCursor(_ active: Bool) {
        if active && !cursorPushed { NSCursor.resizeLeftRight.push(); cursorPushed = true }
        if !active && cursorPushed { NSCursor.pop(); cursorPushed = false }
    }
    private func hit(_ point: CGPoint) -> HaloPanelSector? {
        HaloPanelSector.hit(at: point, center: center, inner: metrics.innerRadius, outer: metrics.outerRadius, sectors: HaloPanelSector.make(items: items))
    }
    private func pickFiles() {
        let panel = NSOpenPanel(); panel.canChooseFiles = true; panel.canChooseDirectories = true; panel.allowsMultipleSelection = true
        panel.begin { response in if response == .OK { for url in panel.urls { store.addDroppedItem(at: url) } } }
    }
}
