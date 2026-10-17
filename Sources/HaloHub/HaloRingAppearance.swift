import Foundation

struct HaloRingAppearance: Equatable {
    var size: HaloHubSizePreference
    var iconSize: HaloIconSizePreference
    var iconStyle: HaloAppIconStyle
    /// Continuous position between the four named stops. Nil reads the legacy preset.
    var sizePosition: Double? = nil

    var position: Double {
        let fallback = Double(HaloHubSizePreference.allCases.firstIndex(of: size) ?? 1)
        guard let value = sizePosition, value.isFinite else { return fallback }
        return min(3, max(0, value))
    }
    mutating func setPosition(_ value: Double) {
        sizePosition = value.isFinite ? min(3, max(0, value)) : position
        size = HaloHubSizePreference.allCases[Int(position.rounded())]
    }
    private func interpolate(_ stops: [Double]) -> Double {
        let lower = min(2, Int(position))
        return stops[lower] + (stops[lower + 1] - stops[lower]) * (position - Double(lower))
    }
    var scale: Double { interpolate([0.68, 0.80, 0.90, 1.0]) }
}
