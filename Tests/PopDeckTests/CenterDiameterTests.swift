import XCTest
@testable import PopDeck

final class CenterDiameterTests: XCTestCase {
    func testLegacyDefaultAndIndependentDiameterAcrossPanelSizes() {
        for size in HaloHubSizePreference.allCases {
            var appearance = HaloRingAppearance(size: size, iconSize: .medium, iconStyle: .original)
            XCTAssertEqual(appearance.resolvedCenterDiameter, 150 * appearance.scale, accuracy: 1e-8)
            XCTAssertEqual(appearance.centerInnerRadius, 78 * appearance.scale, accuracy: 1e-8)
            let scale = appearance.scale
            appearance.centerDiameter = 90
            XCTAssertEqual(appearance.resolvedCenterDiameter, 90)
            XCTAssertEqual(appearance.scale, scale)
            appearance.setPosition(3)
            XCTAssertEqual(appearance.resolvedCenterDiameter, 90)
            appearance.centerDiameter = nil
            XCTAssertEqual(appearance.resolvedCenterDiameter, 135)
        }
    }

    func testDiameterBoundsHandleCorruptValuesAndKeepIconsClear() {
        for size in HaloHubSizePreference.allCases {
            var appearance = HaloRingAppearance(size: size, iconSize: .medium, iconStyle: .original)
            appearance.centerDiameter = -.infinity
            XCTAssertEqual(appearance.resolvedCenterDiameter, 150 * appearance.scale)
            appearance.centerDiameter = .nan
            XCTAssertEqual(appearance.resolvedCenterDiameter, 150 * appearance.scale)
            appearance.centerDiameter = -100
            XCTAssertEqual(appearance.resolvedCenterDiameter, 48)
            appearance.centerDiameter = 1e6
            XCTAssertEqual(appearance.resolvedCenterDiameter, appearance.centerDiameterRange.upperBound)
            XCTAssertLessThan(appearance.centerInnerRadius, 160 * appearance.scale)
            XCTAssertLessThan(appearance.centerInnerRadius, 224 * appearance.scale)
        }
    }
}
