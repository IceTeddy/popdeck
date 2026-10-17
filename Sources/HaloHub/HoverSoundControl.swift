import SwiftUI

struct HoverSoundControl: View {
    @AppStorage(AppPreferences.hoverSoundKey) private var enabled = true
    @AppStorage(HoverSoundStyle.preferenceKey) private var style = HoverSoundStyle.ratchet.rawValue
    var body: some View {
        Section {
            Toggle(L10n.t("settings.sound.title"), isOn: $enabled)
            HStack {
                Picker(L10n.t("settings.sound.style"), selection: $style) {
                    ForEach(HoverSoundStyle.availableStyles) { Text($0.title).tag($0.rawValue) }
                }.pickerStyle(.menu)
                Button(L10n.t("settings.sound.preview")) { HoverSoundPlayer.shared.preview() }
            }
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                if style == HoverSoundStyle.picker.rawValue { Text(L10n.t("settings.sound.pickerHint")) }
                Text(L10n.t("settings.sound.hint"))
            }.foregroundStyle(.secondary)
        }
        .onChange(of: style) { _, _ in HoverSoundPlayer.shared.preview() }
        .onChange(of: enabled) { _, value in if !value { HoverSoundPlayer.shared.stop() } }
    }
}
