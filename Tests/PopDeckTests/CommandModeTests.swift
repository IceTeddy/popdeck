import Foundation
import XCTest
@testable import PopDeck

final class CommandModeTests: XCTestCase {
    @MainActor
    func testModesDefaultSilentAndPersistThroughEditing() throws {
        let suite = "PopDeckTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("[]".utf8), forKey: "haloMenuItems")
        let store = HaloMenuStore(defaults: defaults)
        XCTAssertTrue(store.addCommand(title: "Silent", command: "printf silent"))
        XCTAssertFalse(store.persistedItems[0].opensTerminal)
        XCTAssertTrue(store.addCommand(title: "Terminal", command: "printf terminal", opensTerminal: true))
        let id = store.persistedItems[1].id
        XCTAssertEqual(store.items[1].action, .command("printf terminal", opensTerminal: true))
        XCTAssertTrue(store.updateCommand(id: id, title: "Edited", command: "printf edited", opensTerminal: true))
        XCTAssertTrue(HaloMenuStore(defaults: defaults).persistedItems[1].opensTerminal)
        XCTAssertTrue(store.updateCommand(id: id, title: "Edited", command: "printf edited", opensTerminal: false))
        XCTAssertFalse(HaloMenuStore(defaults: defaults).persistedItems[1].opensTerminal)
        let legacy = """
        {"id":"\(UUID().uuidString)","title":"Old","subtitle":"Command","symbolName":"terminal.fill","actionKind":"command","value":"echo old"}
        """
        XCTAssertFalse(try JSONDecoder().decode(PersistedHaloMenuItem.self, from: Data(legacy.utf8)).opensTerminal)
    }

    func testShellArgumentRoundTripsWithoutExpansion() throws {
        let source = "printf '%s\\n' \"$HOME\" | cat\n# ' \" \\ $(printf unexpected) `printf unexpected` 👩🏽‍💻"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "printf '%s' " + TerminalCommandLauncher.shellArgument(source)]
        let output = Pipe()
        process.standardOutput = output
        try process.run()
        let result = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertEqual(String(decoding: result, as: UTF8.self), source)
    }

    func testFullEmojiCatalogIsUniqueAndSelectable() {
        XCTAssertGreaterThan(EmojiCatalog.catalog.entries.count, 3900)
        XCTAssertEqual(EmojiCatalog.symbols.count, EmojiCatalog.catalog.entries.count)
        XCTAssertEqual(EmojiCatalog.groups.count, 9)
        for entry in EmojiCatalog.catalog.entries {
            XCTAssertTrue(HaloIconAppearance(emoji: entry.symbol).isValid, entry.name)
        }
    }
}
