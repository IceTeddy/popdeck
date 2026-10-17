import Foundation
import XCTest
@testable import PopDeck

final class ItemCustomizationTests: XCTestCase {
    @MainActor
    func testEditAtCapacityPreservesIdentityOrderAndAppearance() throws {
        let suite = "PopDeckTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let entries = (0..<8).map { index in
            PersistedHaloMenuItem(id: UUID(), title: "Command \(index)", subtitleKey: "item.command.subtitle",
                subtitle: "Command", symbolName: "terminal.fill", actionKind: .command, value: "printf '\(index)'",
                iconAppearance: .init(emoji: "🚀", color: .blue))
        }
        defaults.set(try JSONEncoder().encode(entries), forKey: "haloMenuItems")
        let store = HaloMenuStore(defaults: defaults)
        let edited = entries[3]
        let source = "printf '%s\\n' \"new value\" | cat\n# keep punctuation"
        XCTAssertTrue(store.updateCommand(id: edited.id, title: "Renamed", command: source))
        XCTAssertEqual(store.persistedItems.map(\.id), entries.map(\.id))
        XCTAssertEqual(store.persistedItems[3].title, "Renamed")
        XCTAssertEqual(store.persistedItems[3].iconAppearance, edited.iconAppearance)
        XCTAssertEqual(store.items[3].action, .command(source))
        let reloaded = HaloMenuStore(defaults: defaults)
        XCTAssertEqual(reloaded.persistedItems, store.persistedItems)
        let before = store.persistedItems
        XCTAssertFalse(store.updateCommand(id: edited.id, title: "bad", command: entries[0].value))
        XCTAssertFalse(store.updateCommand(id: edited.id, title: "bad", command: " \n"))
        XCTAssertEqual(store.persistedItems, before)
        XCTAssertTrue(store.updateCommand(id: edited.id, title: "Rename only", command: source))
    }

    @MainActor
    func testFileAppearancePersistsAndRestoresWithoutChangingAction() throws {
        let suite = "PopDeckTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let file = PersistedHaloMenuItem(id: UUID(), title: "File", subtitleKey: nil, subtitle: "TXT",
            symbolName: "doc.fill", actionKind: .file, value: "/tmp/test.txt")
        defaults.set(try JSONEncoder().encode([file]), forKey: "haloMenuItems")
        let store = HaloMenuStore(defaults: defaults)
        XCTAssertTrue(store.updateAppearance(id: file.id, appearance: .init(color: .green)))
        XCTAssertEqual(store.items[0].iconAppearance.color, .green)
        XCTAssertEqual(store.items[0].action, file.menuItem().action)
        XCTAssertTrue(store.updateAppearance(id: file.id, appearance: .init(emoji: " 👩🏽‍💻 ")))
        XCTAssertEqual(HaloMenuStore(defaults: defaults).items[0].iconAppearance.emoji, "👩🏽‍💻")
        let before = store.persistedItems
        XCTAssertFalse(store.updateAppearance(id: file.id, appearance: .init(emoji: "abc")))
        XCTAssertFalse(store.updateAppearance(id: UUID(), appearance: .init()))
        XCTAssertEqual(store.persistedItems, before)
        XCTAssertTrue(store.updateAppearance(id: file.id, appearance: .init()))
        XCTAssertEqual(HaloMenuStore(defaults: defaults).persistedItems, [file])
        XCTAssertFalse(store.updateCommand(id: file.id, title: "Oops", command: "true"))
    }

    func testEmojiValidationSupportsCombinedCharacters() {
        for emoji in ["🚀", "👩🏽‍💻", "🇨🇳", "1️⃣", "☀️", ""] {
            XCTAssertTrue(HaloIconAppearance(emoji: emoji).isValid, emoji)
        }
        for text in ["hello", "🚀🚀", "1", "A"] {
            XCTAssertFalse(HaloIconAppearance(emoji: text).isValid, text)
        }
    }
}
