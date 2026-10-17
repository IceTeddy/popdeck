import XCTest
@testable import PopDeck

final class FreeEditionTests: XCTestCase {
    @MainActor
    func testUnknownActionsAndFieldsSurviveEditingOrdinaryItems() throws {
        let suite = "FreePreserve-\(UUID())", defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let unknownID = UUID(), ordinaryID = UUID()
        let raw: [[String: Any]] = [
            ["id": unknownID.uuidString, "title": "Retained", "subtitle": "", "symbolName": "folder", "actionKind": "future-extension", "value": "", "commands": [["source": "opaque", "metadata": ["flag": true]]], "children": [["unknown": [1, 2, 3]]], "futureColor": "blue"],
            ["id": ordinaryID.uuidString, "title": "Command", "subtitle": "", "symbolName": "terminal", "actionKind": "command", "value": "true", "futureSetting": ["keep": "yes"]]
        ]
        defaults.set(try JSONSerialization.data(withJSONObject: raw), forKey: "haloMenuItems")
        defaults.set(4, forKey: "haloRingCount")
        let outer = Data("retained outer payload".utf8)
        defaults.set(outer, forKey: "haloSecondRingItems")
        let store = HaloMenuStore(defaults: defaults)
        XCTAssertEqual(store.items.first?.kind, .unavailable)
        XCTAssertTrue(store.updateCommand(id: ordinaryID, title: "Edited", command: "printf ok", opensTerminal: true))
        let saved = try XCTUnwrap(defaults.data(forKey: "haloMenuItems"))
        let rows = try JSONSerialization.jsonObject(with: saved) as! [[String: Any]]
        XCTAssertEqual(rows[0]["actionKind"] as? String, "future-extension")
        XCTAssertEqual(rows[0]["futureColor"] as? String, "blue")
        XCTAssertEqual(try JSONSerialization.data(withJSONObject: rows[0]["commands"]!, options: .sortedKeys), try JSONSerialization.data(withJSONObject: raw[0]["commands"]!, options: .sortedKeys))
        XCTAssertEqual(try JSONSerialization.data(withJSONObject: rows[0]["children"]!, options: .sortedKeys), try JSONSerialization.data(withJSONObject: raw[0]["children"]!, options: .sortedKeys))
        XCTAssertEqual((rows[1]["futureSetting"] as? [String: String])?["keep"], "yes")
        XCTAssertEqual(defaults.integer(forKey: "haloRingCount"), 4)
        XCTAssertEqual(defaults.data(forKey: "haloSecondRingItems"), outer)
        XCTAssertEqual(HaloMenuStore(defaults: defaults).persistedItems[1].value, "printf ok")
    }
    @MainActor
    func testSinglePanelSettingsNeverRewriteOtherConfiguration() throws {
        let suite = "SinglePanel-\(UUID())", defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(3, forKey: "haloRingCount")
        defaults.set(["sizePosition": 0.3], forKey: "haloRingAppearance2")
        let config = FreePanelConfiguration(defaults: defaults)
        config.appearance.setPosition(1.5)
        XCTAssertEqual(FreePanelConfiguration(defaults: defaults).appearance.position, 1.5)
        XCTAssertEqual(defaults.integer(forKey: "haloRingCount"), 3)
        XCTAssertEqual((defaults.dictionary(forKey: "haloRingAppearance2")?["sizePosition"] as? Double), 0.3)
        let metrics = SinglePanelMetrics(appearance: config.appearance)
        XCTAssertLessThan(metrics.innerRadius, metrics.itemRadius)
        XCTAssertLessThan(metrics.itemRadius, metrics.outerRadius)
    }
}
