import SwiftUI

struct IconAppearanceSheet: View {
    let item: HaloMenuItem
    let onSave: (HaloIconAppearance) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var displayMode: HaloIconAppearance.DisplayMode
    @State private var textStyle: LauncherTextStyle
    @State private var emoji: String
    @State private var customImageData: Data?
    @State private var backgroundColor: HaloIconColor?
    @State private var color: HaloIconColor?

    init(item: HaloMenuItem, onSave: @escaping (HaloIconAppearance) -> Bool) {
        self.item = item
        self.onSave = onSave
        _displayMode = State(initialValue: item.iconAppearance.displayMode)
        _textStyle = State(initialValue: item.iconAppearance.textStyle)
        _emoji = State(initialValue: item.iconAppearance.emoji ?? "")
        _customImageData = State(initialValue: item.iconAppearance.customImageData)
        _color = State(initialValue: item.iconAppearance.color)
        _backgroundColor = State(initialValue: item.sectorBackgroundColor)
    }

    private var draft: HaloIconAppearance { .init(emoji: emoji, color: color, displayMode: displayMode, textStyle: textStyle, backgroundColor: backgroundColor, customImageData: customImageData) }

    private var previewItem: HaloMenuItem {
        HaloMenuItem(id: item.id, title: item.title, subtitle: item.subtitle, icon: item.icon,
                     kind: item.kind, action: item.action, iconAppearance: draft.normalized)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView {
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
                    CustomIconPicker(imageData: $customImageData, emoji: $emoji)
                    if displayMode == .nameOnly {
                        Text(ProText.t("当前为仅文字显示，切换显示方式后可看到图标。", "Switch from Text Only to see the icon on the ring."))
                            .font(.caption).foregroundStyle(.secondary)
                    }

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
                    .disabled((draft.normalized.emoji != nil || draft.normalized.customImageData != nil) && displayMode != .nameOnly)
                    Text(L10n.t("settings.iconAppearance.hint")).font(.caption).foregroundStyle(.secondary)
                    SectorBackgroundPicker(selection: $backgroundColor)
                    Text(L10n.t("settings.commandSet.backgroundHint")).font(.caption).foregroundStyle(.secondary)
                    if !draft.isValid {
                        Text(L10n.t("settings.iconEmoji.invalid")).font(.callout).foregroundStyle(.red)
                    }
                }
                .padding(.trailing, 4)
            }
            Divider()
            HStack {
                Button(ProText.t("恢复默认图标", "Restore default icon")) {
                    let restored = draft.restoringDefaultIcon()
                    emoji = restored.emoji ?? ""
                    customImageData = restored.customImageData
                    color = restored.color
                }
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
        .frame(width: 450, height: min(740, (NSScreen.main?.visibleFrame.height ?? 840) - 100))
    }
}
