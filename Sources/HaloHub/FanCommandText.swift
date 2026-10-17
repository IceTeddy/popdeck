import SwiftUI

/// Sizes each grapheme independently; joins/emoji/diacritics remain a single glyph run.
struct FanCommandText: View {
    let text: String
    let angle: Double
    let length: CGFloat
    let thickness: CGFloat
    let color: Color

    var body: some View {
        Canvas { context, size in
            let characters = Array(text)
            let runs = characters.enumerated().map { index, character in
                let progress = Double(index) / Double(max(1, characters.count - 1))
                return context.resolve(Text(String(character))
                    .font(.system(size: LauncherTextLayout.fontSize(progress: progress, angle: angle), weight: .semibold))
                    .foregroundColor(color))
            }
            let widths = runs.map { $0.measure(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 40)).width }
            let total = widths.reduce(0, +)
            let scale = min(1, size.width / max(1, total), size.height / 22)
            context.translateBy(x: (size.width - total * scale) / 2, y: size.height / 2)
            context.scaleBy(x: scale, y: scale)
            var x: CGFloat = 0
            for (index, run) in runs.enumerated() {
                context.draw(run, at: CGPoint(x: x, y: 0), anchor: .leading)
                x += widths[index]
            }
        }
        .frame(width: length, height: thickness)
        .accessibilityLabel(text)
    }
}
