import Foundation

enum LauncherTextStyle: String, Codable, CaseIterable, Sendable {
    case horizontal, radial, fan, circular
}
enum LauncherTextLayout {
    static func isFlipped(angle: Double) -> Bool { cos(angle) < -1e-10 }
    static func rotation(angle: Double) -> Double { angle + (isFlipped(angle: angle) ? .pi : 0) }
    static func fontSize(progress: Double, angle: Double) -> Double {
        let p = min(1, max(0, progress))
        return 10 + 8 * (isFlipped(angle: angle) ? 1 - p : p)
    }
}
