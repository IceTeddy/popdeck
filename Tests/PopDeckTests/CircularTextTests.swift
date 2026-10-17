import XCTest
@testable import PopDeck

final class CircularTextTests: XCTestCase {
    func testGlyphsStayOnSameConcentricBaselineAndWithinSector() {
        for angle in stride(from: -Double.pi, through: Double.pi, by: .pi / 8) {
            let geometry = CircularTextGeometry(angle: angle, radius: 140, span: 0.6)
            for fraction in [-0.5, 0, 0.5] {
                let placement = geometry.placement(distance: geometry.availableLength * fraction)
                let x = placement.point.x + 140 * cos(angle)
                let y = placement.point.y + 140 * sin(angle)
                XCTAssertEqual(hypot(x, y), 140, accuracy: 1e-8)
                let delta = atan2(sin(atan2(y, x) - angle), cos(atan2(y, x) - angle))
                XCTAssertLessThanOrEqual(abs(delta), 0.6 / 2)
            }
        }
    }

    func testTopAndBottomReadLeftToRight() {
        for angle in [-Double.pi / 2, Double.pi / 2] {
            let geometry = CircularTextGeometry(angle: angle, radius: 140, span: 1)
            XCTAssertLessThan(geometry.placement(distance: -20).point.x, geometry.placement(distance: 20).point.x)
            XCTAssertEqual(geometry.placement(distance: 0).rotation, 0, accuracy: 1e-8)
        }
    }

    func testCircularStylePersistsForIconAppearance() throws {
        let icon = HaloIconAppearance(displayMode: .nameOnly, textStyle: .circular)
        XCTAssertEqual(try JSONDecoder().decode(HaloIconAppearance.self, from: JSONEncoder().encode(icon)), icon)
    }
}
