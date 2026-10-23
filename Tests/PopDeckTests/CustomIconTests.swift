import AppKit
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import PopDeck

final class CustomIconTests: XCTestCase {
    static func png(width: Int = 64, height: Int = 64) throws -> Data {
        let context = try XCTUnwrap(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 0.7))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try XCTUnwrap(context.makeImage())
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return data as Data
    }

    func testImportPreservesAspectAndSurvivesOriginalFileRemoval() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CustomIcon-\(UUID()).png")
        try Self.png(width: 512, height: 256).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let icon = try CustomIconImage.importFile(at: url)
        try FileManager.default.removeItem(at: url)
        let bitmap = try XCTUnwrap(CustomIconImage.decodedImage(icon))
        XCTAssertEqual(bitmap.width, 128)
        XCTAssertEqual(bitmap.height, 64)
        XCTAssertLessThanOrEqual(icon.count, CustomIconImage.dataLimit)
        let original = HaloIconAppearance(customImageData: icon)
        let restored = try JSONDecoder().decode(HaloIconAppearance.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(restored, original)
        XCTAssertTrue(restored.isValid)
    }

    func testInvalidImportsDoNotProduceAnIcon() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("InvalidIcon-\(UUID()).png")
        try Data("not an image".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertThrowsError(try CustomIconImage.importFile(at: url))
        XCTAssertFalse(HaloIconAppearance(customImageData: Data("invalid".utf8)).isValid)
        XCTAssertFalse(HaloIconAppearance(customImageData: Data(repeating: 0, count: CustomIconImage.dataLimit + 1)).isValid)
        XCTAssertFalse(HaloIconAppearance(customImageData: try Self.png(width: 512, height: 512)).isValid)
        XCTAssertNil(try JSONDecoder().decode(HaloIconAppearance.self, from: Data("{}".utf8)).customImageData)
        let malformed = Data(#"{"customImageData":"not-base64","color":"blue"}"#.utf8)
        XCTAssertEqual(try JSONDecoder().decode(HaloIconAppearance.self, from: malformed).color, .blue)
    }

    func testRestoreClearsOnlyIconOverridesAndEmojiWinsConflictingData() throws {
        let data = try Self.png()
        let appearance = HaloIconAppearance(emoji: "🚀", color: .blue, displayMode: .iconAndName,
            textStyle: .circular, backgroundColor: .orange, customImageData: data)
        XCTAssertNil(appearance.normalized.customImageData)
        XCTAssertEqual(appearance.normalized.emoji, "🚀")
        let restored = appearance.restoringDefaultIcon()
        XCTAssertNil(restored.customImageData)
        XCTAssertNil(restored.emoji)
        XCTAssertNil(restored.color)
        XCTAssertEqual(restored.displayMode, .iconAndName)
        XCTAssertEqual(restored.textStyle, .circular)
        XCTAssertEqual(restored.backgroundColor, .orange)
    }

    @MainActor
    func testEveryOrdinaryItemPersistsAndRestoresItsOriginalIconAndAction() throws {
        let suite = "CustomIcon-\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let entries: [PersistedHaloMenuItem] = [
            .init(id: UUID(), title: "App", subtitleKey: nil, subtitle: "", symbolName: "app.fill", actionKind: .app, value: "com.apple.finder"),
            .init(id: UUID(), title: "File", subtitleKey: nil, subtitle: "", symbolName: "doc.fill", actionKind: .file, value: "/tmp/icon-test.txt"),
            .init(id: UUID(), title: "Folder", subtitleKey: nil, subtitle: "", symbolName: "folder", actionKind: .folder, value: "/tmp"),
            .init(id: UUID(), title: "URL", subtitleKey: nil, subtitle: "", symbolName: "link", actionKind: .url, value: "https://example.com", iconPath: "/tmp/unavailable-favicon.png"),
            .init(id: UUID(), title: "Command", subtitleKey: nil, subtitle: "", symbolName: "terminal", actionKind: .command, value: "true")
        ]
        defaults.set(try JSONEncoder().encode(entries), forKey: "haloMenuItems")
        let store = HaloMenuStore(defaults: defaults)
        let data = try Self.png()
        for original in entries {
            XCTAssertTrue(store.updateAppearance(id: original.id, appearance: .init(customImageData: data)))
        }
        let reload = HaloMenuStore(defaults: defaults)
        for (index, original) in entries.enumerated() {
            XCTAssertEqual(reload.items[index].iconAppearance.customImageData, data)
            XCTAssertEqual(reload.items[index].action, original.menuItem().action)
            XCTAssertNotNil(CustomIconImageCache.shared.image(for: data))
            XCTAssertTrue(reload.updateAppearance(id: original.id, appearance: reload.items[index].iconAppearance.restoringDefaultIcon()))
        }
        let restored = HaloMenuStore(defaults: defaults)
        XCTAssertEqual(restored.persistedItems, entries)
        for (index, original) in entries.enumerated() {
            XCTAssertEqual(restored.items[index].icon, original.menuItem().icon)
            XCTAssertEqual(restored.items[index].action, original.menuItem().action)
        }
    }
}
