import Foundation

struct HaloParentSector: Identifiable {
    let index: Int
    let item: HaloMenuItem
    let start: Double
    let end: Double
    var id: UUID { item.id }
    var angle: Double { (start + end) / 2 }
    var span: Double { end - start }

    static func make(items: [HaloMenuItem]) -> [Self] {
        guard !items.isEmpty else { return [] }
        let shares = SectorGeometry.shares(items.map(\.sectorWeight))
        var start = -Double.pi / 2 - .pi / Double(items.count) + (items.first?.layoutRotation ?? 0)
        return items.enumerated().map { index, item in
            let end = start + shares[index] * 2 * .pi
            defer { start = end }
            return Self(index: index, item: item, start: start, end: end)
        }
    }
}

enum SectorGeometry {
    static func shares(_ weights: [Double]) -> [Double] {
        let safe = weights.map { $0.isFinite && $0 > 0 ? min(1e9, max(1e-9, $0)) : 1 }
        let total = safe.reduce(0, +)
        return safe.map { $0 / max(1e-9, total) }
    }

    static func wrappedDelta(_ angle: Double) -> Double {
        atan2(sin(angle), cos(angle))
    }
}

struct SectorBoundary: Identifiable {
    let parentID: UUID?
    let leftID: UUID
    let rightID: UUID
    let angle: Double
    let availableSpan: Double
    let minimumSpan: Double
    var id: String { "\(parentID?.uuidString ?? "parents")/\(leftID)/\(rightID)" }

    static func make(items: [HaloMenuItem]) -> [Self] {
        let parents = HaloParentSector.make(items: items)
        let leaves = HaloPanelSector.make(items: items)
        var boundaries: [Self] = []
        if parents.count > 1 {
            for index in parents.indices {
                let previous = (index + parents.count - 1) % parents.count
                boundaries.append(Self(parentID: nil, leftID: parents[previous].id, rightID: parents[index].id,
                    angle: parents[index].start, availableSpan: 2 * .pi,
                    minimumSpan: min(leaves.last(where: { $0.parentID == parents[previous].id })?.span ?? parents[previous].span,
                                     leaves.first(where: { $0.parentID == parents[index].id })?.span ?? parents[index].span)))
            }
        }
        return boundaries
    }

    static func nearest(at point: CGPoint, center: CGFloat, inner: CGFloat, outer: CGFloat,
                        items: [HaloMenuItem], hitWidth: CGFloat = 10) -> Self? {
        let dx = point.x - center, dy = point.y - center
        guard hypot(dx, dy) >= inner, hypot(dx, dy) <= outer else { return nil }
        let angle = atan2(dy, dx)
        return make(items: items).filter {
            abs(SectorGeometry.wrappedDelta(angle - $0.angle)) <= max(0.0001, min(Double(hitWidth / max(1, hypot(dx, dy))), $0.minimumSpan * 0.22))
        }.min {
            abs(SectorGeometry.wrappedDelta(angle - $0.angle)) < abs(SectorGeometry.wrappedDelta(angle - $1.angle))
        }
    }

    /// Transfer angle only between the two neighbors. Never change actions or order.
    func resizing(_ items: [HaloMenuItem], by delta: Double) -> [HaloMenuItem] {
        guard delta.isFinite else { return items }
        var result = items
            guard let left = items.firstIndex(where: { $0.id == leftID }),
                  let right = items.firstIndex(where: { $0.id == rightID }), left != right else { return items }
            var weights = SectorGeometry.shares(items.map(\.sectorWeight))
            let applied = transfer(&weights, left: left, right: right, delta: delta / (2 * .pi), minimum: 8.0 / 360)
            guard applied != 0 else { return items }
            for index in result.indices {
                result[index].sectorWeight = weights[index] * Double(result.count)
                // The seam is movable too: rotate the origin so all other boundaries stay fixed.
                if right == 0 { result[index].layoutRotation += applied * 2 * .pi }
            }
        return result
    }

    private func transfer(_ weights: inout [Double], left: Int, right: Int, delta: Double, minimum: Double) -> Double {
        let sum = weights[left] + weights[right]
        let limit = min(minimum, sum / 4, weights[left], weights[right])
        let applied = min(weights[right] - limit, max(limit - weights[left], delta))
        weights[left] += applied
        weights[right] -= applied
        return applied
    }
}
