import SwiftUI

/// Single-panel sectors: one persisted launch item per sector.
struct HaloPanelSector: Identifiable {
    let id: UUID
    let parentID: UUID
    let item: HaloMenuItem
    let start: Double
    let end: Double
    var angle: Double { (start + end) / 2 }
    var span: Double { end - start }
    var backgroundColor: HaloIconColor? { item.iconAppearance.backgroundColor }
    static func make(items: [HaloMenuItem]) -> [Self] {
        HaloParentSector.make(items: items).map { .init(id: $0.id, parentID: $0.id, item: $0.item, start: $0.start, end: $0.end) }
    }
    func position(center: CGFloat, radius: CGFloat) -> CGPoint {
        .init(x: center + cos(angle) * radius, y: center + sin(angle) * radius)
    }
    static func hit(at point: CGPoint, center: CGFloat, inner: CGFloat, outer: CGFloat, sectors: [Self]) -> Self? {
        let dx = point.x - center, dy = point.y - center
        guard hypot(dx, dy) >= inner, hypot(dx, dy) <= outer else { return nil }
        let angle = atan2(dy, dx), full = 2 * Double.pi
        return sectors.first {
            var delta = (angle - $0.start).truncatingRemainder(dividingBy: full)
            if delta < 0 { delta += full }
            return delta < $0.span
        }
    }
}
