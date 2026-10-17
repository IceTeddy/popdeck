import SwiftUI

enum HaloIconColor: String, Codable, CaseIterable, Identifiable, Sendable {
    case red, orange, yellow, green, teal, blue, purple, pink
    var id: String { rawValue }
    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .teal: .teal
        case .blue: .blue
        case .purple: .purple
        case .pink: .pink
        }
    }
}

struct HaloIconAppearance: Codable, Hashable, Sendable {
    enum DisplayMode: String, Codable, CaseIterable, Sendable {
        case automatic, iconOnly, nameOnly, iconAndName
    }
    var displayMode: DisplayMode = .automatic
    var textStyle: LauncherTextStyle = .horizontal
    var emoji: String? = nil
    var color: HaloIconColor? = nil
    var backgroundColor: HaloIconColor? = nil

    enum CodingKeys: String, CodingKey { case emoji, color, displayMode, textStyle, backgroundColor }

    init(emoji: String? = nil, color: HaloIconColor? = nil, displayMode: DisplayMode = .automatic,
         textStyle: LauncherTextStyle = .horizontal, backgroundColor: HaloIconColor? = nil) {
        self.backgroundColor = backgroundColor
        self.emoji = emoji
        self.color = color
        self.displayMode = displayMode
        self.textStyle = textStyle
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        emoji = try c.decodeIfPresent(String.self, forKey: .emoji)
        color = try c.decodeIfPresent(HaloIconColor.self, forKey: .color)
        backgroundColor = try c.decodeIfPresent(HaloIconColor.self, forKey: .backgroundColor)
        displayMode = try c.decodeIfPresent(DisplayMode.self, forKey: .displayMode) ?? .automatic
        textStyle = try c.decodeIfPresent(LauncherTextStyle.self, forKey: .textStyle) ?? .horizontal
    }

    var normalized: Self {
        let text = emoji?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return Self(emoji: text.isEmpty ? nil : text, color: color, displayMode: displayMode, textStyle: textStyle, backgroundColor: backgroundColor)
    }

    var isValid: Bool {
        guard let text = normalized.emoji else { return true }
        if EmojiCatalog.symbols.contains(text) { return true }
        return text.count == 1 && text.unicodeScalars.contains {
            $0.properties.isEmojiPresentation || ($0.properties.isEmoji && $0.value > 127) || $0.value == 0x20E3
        }
    }
}
