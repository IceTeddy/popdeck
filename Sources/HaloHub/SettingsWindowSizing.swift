import Foundation

/// Grow only, retaining the user's chosen size until more preview space is needed.
enum SettingsWindowSizing {
    static func contentSize(current: CGSize, screen: CGSize, previewDiameter: CGFloat) -> CGSize {
        let width = 211 + (previewDiameter + 36) / 0.46
        let height = previewDiameter + 240
        return CGSize(width: max(current.width, min(screen.width, width)),
                      height: max(current.height, min(screen.height, height)))
    }
}
