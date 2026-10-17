import SwiftUI

struct IconAppearanceSheet: View {
    let item: HaloMenuItem
    let onSave: (HaloIconAppearance) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var displayMode: HaloIconAppearance.DisplayMode
    @State private var textStyle: LauncherTextStyle
    @State private var emoji: String
    @State private var backgroundColor: HaloIconColor?
    @State private var color: HaloIconColor?

    init(item: HaloMenuItem, onSave: @escaping (HaloIconAppearance) -> Bool) {
        self.item = item
        self.onSave = onSave
        _displayMode = State(initialValue: item.iconAppearance.displayMode)
        _textStyle = State(initialValue: item.iconAppearance.textStyle)
        _emoji = State(initialValue: item.iconAppearance.emoji ?? "")
        _color = State(initialValue: item.iconAppearance.color)
        _backgroundColor = State(initialValue: item.sectorBackgroundColor)
    }

    private var draft: HaloIconAppearance { .init(emoji: emoji, color: color, displayMode: displayMode, textStyle: textStyle, backgroundColor: backgroundColor) }

    private var previewItem: HaloMenuItem {
        HaloMenuItem(id: item.id, title: item.title, subtitle: item.subtitle, icon: item.icon,
                     kind: item.kind, action: item.action, iconAppearance: draft.normalized)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.t("settings.iconAppearance")).font(.title2.bold())
            HStack(spacing: 16) {
                LauncherItemLabel(item: previewItem, angle: -0.3, radius: 130, isHovered: false,
                                  showItemName: false, iconSizePreference: .medium, appIconStyle: .original)
                    .frame(width: 110, height: 80)
                Text(item.title).font(.headline).lineLimit(2)
            }
            if item.kind != .unavailable {
                Picker(L10n.t("settings.itemDisplay"), selection: $displayMode) {
                    ForEach(HaloIconAppearance.DisplayMode.allCases, id: \.self) { mode in
                        Text(L10n.t("settings.itemDisplay." + mode.rawValue)).tag(mode)
                    }
                }
                if displayMode == .nameOnly {
                    Picker(L10n.t("settings.commandSet.textStyle"), selection: $textStyle) {
                        ForEach(LauncherTextStyle.allCases, id: \.self) { style in
                            Text(L10n.t("settings.commandSet.style." + style.rawValue)).tag(style)
                        }
                    }
                }
                Divider()
            }
            Text(L10n.t("settings.iconEmoji")).font(.headline)
            EmojiSelectionMenu(selection: $emoji)
            Text(L10n.t("settings.iconColor")).font(.headline)
            HStack {
                Button(L10n.t("settings.iconDefault")) { color = nil }
                ForEach(HaloIconColor.allCases) { choice in
                    Button { color = choice } label: {
                        Circle().fill(choice.color).frame(width: 24, height: 24)
                            .overlay { if color == choice { Image(systemName: "checkmark").foregroundStyle(.white).font(.caption.bold()) } }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.t("icon.color.\(choice.rawValue)"))
                    .accessibilityValue(color == choice ? L10n.t("settings.selected") : "")
                }
            }
            .disabled(draft.normalized.emoji != nil && displayMode != .nameOnly)
            Text(L10n.t("settings.iconAppearance.hint")).font(.caption).foregroundStyle(.secondary)
            SectorBackgroundPicker(selection: $backgroundColor)
            Text(L10n.t("settings.commandSet.backgroundHint")).font(.caption).foregroundStyle(.secondary)
            if !draft.isValid {
                Text(L10n.t("settings.iconEmoji.invalid")).font(.callout).foregroundStyle(.red)
            }
            HStack {
                Button(L10n.t("settings.iconRestore")) { emoji = ""; color = nil }
                Spacer()
                Button(L10n.t("settings.cancel")) { dismiss() }.keyboardShortcut(.cancelAction)
                Button(L10n.t("settings.save")) {
                    if onSave(draft) { dismiss() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!draft.isValid)
            }
        }
        .padding(24)
        .frame(width: 450)
    }
}
