import XCTest
@testable import PopDeck

final class SettingsWindowSizingTests: XCTestCase {
    func testLargerPanelGrowsBothDimensions() {
        let size = SettingsWindowSizing.contentSize(current: .init(width: 1060, height: 520), screen: .init(width: 1920, height: 1080), previewDiameter: 500)
        XCTAssertGreaterThan(size.width, 1060)
        XCTAssertGreaterThan(size.height, 520)
        XCTAssertGreaterThanOrEqual((size.width - 211) * 0.46 - 36, 500 - 0.001)
    }
    func testGrowthFitsScreenAndDoesNotShrinkExistingWindow() {
        let screen = CGSize(width: 1440, height: 850)
        XCTAssertEqual(SettingsWindowSizing.contentSize(current: .init(width: 1060, height: 520), screen: screen, previewDiameter: 2000), screen)
        let existing = CGSize(width: 1400, height: 800)
        XCTAssertEqual(SettingsWindowSizing.contentSize(current: existing, screen: screen, previewDiameter: 200), existing)
    }
}
