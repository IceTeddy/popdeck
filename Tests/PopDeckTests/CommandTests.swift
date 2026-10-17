import AppKit
import Foundation
import XCTest
import SwiftUI
@testable import PopDeck

final class CommandTests: XCTestCase {
    func testShellSourceAndWorkingDirectory() throws {
        let output = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: output) }
        let result = CommandRunner.run("""
        cd ~
        printf '%s\\n' "$PWD" > '\(output.path)'
        printf '%s' 'quoted value' | /usr/bin/tr 'a-z' 'A-Z' >> '\(output.path)'
        """)
        XCTAssertEqual(result.status, 0, result.error)
        XCTAssertEqual(try String(contentsOf: output, encoding: .utf8), FileManager.default.homeDirectoryForCurrentUser.path + "\nQUOTED VALUE")
    }

    func testFailureWithLargeStderrDoesNotDeadlock() {
        let result = CommandRunner.run("/usr/bin/yes error | /usr/bin/head -c 100000 >&2; exit 7")
        XCTAssertEqual(result.status, 7)
        XCTAssertTrue(result.error.contains("error"))
        XCTAssertLessThanOrEqual(result.error.utf8.count, 8192)
    }

    func testCommandEditorPreservesShellPunctuation() async {
        await MainActor.run {
            let editor = CommandTextEditor(text: .constant(""))
            let host = NSHostingView(rootView: editor)
            host.frame = NSRect(x: 0, y: 0, width: 400, height: 150)
            host.layoutSubtreeIfNeeded()
            @MainActor func findTextView(_ view: NSView) -> NSTextView? {
                if let textView = view as? NSTextView { return textView }
                return view.subviews.lazy.compactMap { findTextView($0) }.first
            }
            guard let textView = findTextView(host) else {
                XCTFail("Missing command text view")
                return
            }
            XCTAssertFalse(textView.isRichText)
            XCTAssertFalse(textView.isAutomaticQuoteSubstitutionEnabled)
            XCTAssertFalse(textView.isAutomaticDashSubstitutionEnabled)
            XCTAssertFalse(textView.isAutomaticTextReplacementEnabled)
        }
    }

    func testCommandValidation() {
        XCTAssertFalse(CommandRunner.isValid(" \n\t"))
        XCTAssertFalse(CommandRunner.isValid("echo a\0echo b"))
        XCTAssertTrue(CommandRunner.isValid("printf 'hello'"))
    }

    func testPersistenceAndLegacyItems() throws {
        let command = "printf '%s' \"hello world\""
        let item = PersistedHaloMenuItem(id: UUID(), title: "Example", subtitleKey: nil, subtitle: "Command", symbolName: "terminal.fill", actionKind: .command, value: command)
        let decoded = try JSONDecoder().decode(PersistedHaloMenuItem.self, from: JSONEncoder().encode(item))
        XCTAssertEqual(item, decoded)
        XCTAssertEqual(decoded.menuItem().action, .command(command))
        for kind in [PersistedHaloMenuItem.ActionKind.app, .url, .folder, .file] {
            let legacy = """
            {"id":"\(UUID().uuidString)","title":"Old","subtitle":"Old","symbolName":"doc.fill","actionKind":"\(kind.rawValue)","value":"/tmp/example"}
            """
            XCTAssertEqual(try JSONDecoder().decode(PersistedHaloMenuItem.self, from: Data(legacy.utf8)).actionKind, kind)
        }
    }
    @MainActor
    func testFirstPanelAcceptsSeventhAndEighthItemsAndRejectsNinth() throws {
        let suite = "PanelCapacity-\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = HaloMenuStore(defaults: defaults)
        XCTAssertEqual(store.items.count, 6)
        XCTAssertTrue(store.addCommand(title: "Seven", command: "printf seven"))
        XCTAssertTrue(store.addCommand(title: "Eight", command: "printf eight"))
        XCTAssertEqual(store.items.count, LauncherLimits.panelItems)
        XCTAssertFalse(store.addCommand(title: "Nine", command: "printf nine"))
        XCTAssertEqual(store.items.count, 8)
        XCTAssertEqual(HaloMenuStore(defaults: defaults).items.count, 8)
    }

}
