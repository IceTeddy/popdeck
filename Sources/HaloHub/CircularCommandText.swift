import SwiftUI

/// Positions each grapheme on a concentric baseline, rotating along the tangent.
/// The lower semicircle reverses the traversal so the label remains readable.
struct CircularTextGeometry {
    let angle: Double
    let radius: CGFloat
    let span: Double
    var reversed: Bool { sin(angle) > 0 }
    var availableLength: CGFloat { max(1, radius * min(.pi * 0.85, max(0.01, span * 0.80))) }
    func placement(distance: CGFloat) -> (point: CGPoint, rotation: Double) {
        let theta = angle + (reversed ? -1 : 1) * distance / max(1, radius)
        return (.init(x: radius * (cos(theta) - cos(angle)),
                      y: radius * (sin(theta) - sin(angle))),
                theta + (reversed ? -.pi / 2 : .pi / 2))
    }
}

struct CircularCommandText: View {
    let text: String
    let angle: Double
    let radius: CGFloat
    let span: Double
    let color: Color

    var body: some View {
        let geometry = CircularTextGeometry(angle: angle, radius: radius, span: span)
        Canvas { context, size in
            let runs = text.map { context.resolve(Text(String($0)).font(.system(size: 14, weight: .semibold)).foregroundColor(color)) }
            let widths = runs.map { $0.measure(in: CGSize(width: 1000, height: 40)).width }
            let total = widths.reduce(0, +)
            let scale = min(1, geometry.availableLength / max(1, total))
            var distance = -total * scale / 2
            for (index, run) in runs.enumerated() {
                let width = widths[index] * scale
                let placement = geometry.placement(distance: distance + width / 2)
                var glyph = context
                glyph.translateBy(x: size.width / 2 + placement.point.x, y: size.height / 2 + placement.point.y)
                glyph.rotate(by: .radians(placement.rotation))
                glyph.scaleBy(x: scale, y: scale)
                glyph.draw(run, at: .zero, anchor: .center)
                distance += width
            }
        }
        .frame(width: min(radius * 2 + 40, geometry.availableLength + 40),
               height: min(radius * 2 + 40, geometry.availableLength + 40))
        .allowsHitTesting(false)
        .accessibilityLabel(text)
    }
}
