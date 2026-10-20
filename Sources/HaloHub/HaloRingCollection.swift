import Combine
import Foundation

/// Only the first panel configuration belongs to the public source edition.
/// All other preference keys remain untouched for the official full build.
@MainActor
final class FreePanelConfiguration: ObservableObject {
    static let shared = FreePanelConfiguration()
    @Published var appearance: HaloRingAppearance { didSet { save() } }
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = defaults.dictionary(forKey: "haloRingAppearance1") ?? [:]
        appearance = .init(
            size: HaloHubSizePreference(rawValue: saved["size"] as? String ?? defaults.string(forKey: AppPreferences.hubSizeKey) ?? "small") ?? .small,
            iconSize: HaloIconSizePreference(rawValue: saved["iconSize"] as? String ?? defaults.string(forKey: AppPreferences.iconSizeKey) ?? "medium") ?? .medium,
            iconStyle: HaloAppIconStyle(rawValue: saved["iconStyle"] as? String ?? defaults.string(forKey: AppPreferences.appIconStyleKey) ?? "original") ?? .original,
            sizePosition: (saved["sizePosition"] as? NSNumber)?.doubleValue,
            centerDiameter: (saved["centerDiameter"] as? NSNumber)?.doubleValue)
    }
    private func save() {
        var saved: [String: Any] = ["size": appearance.size.rawValue, "iconSize": appearance.iconSize.rawValue, "iconStyle": appearance.iconStyle.rawValue]
        if let position = appearance.sizePosition { saved["sizePosition"] = position }
        if let diameter = appearance.centerDiameter, diameter.isFinite { saved["centerDiameter"] = diameter }
        defaults.set(saved, forKey: "haloRingAppearance1")
        objectWillChange.send()
    }
}
struct SinglePanelMetrics {
    let appearance: HaloRingAppearance
    var outerRadius: CGFloat { 224 * appearance.scale }
    var innerRadius: CGFloat { appearance.centerInnerRadius }
    var itemRadius: CGFloat { 160 * appearance.scale }
    var centerSize: CGFloat { appearance.resolvedCenterDiameter }
    var panelSize: CGFloat { 550 * appearance.scale }
}
