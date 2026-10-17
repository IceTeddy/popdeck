import SwiftUI

struct GlassStyleControl: View {
    @Binding var style: String
    var body: some View {
        Section {
            Picker(L10n.t("settings.glass.title"), selection: $style) {
                ForEach(HaloGlassStyle.allCases) { Text($0.displayTitle).tag($0.rawValue) }
            }.pickerStyle(.menu)
        } footer: {
            Text(L10n.t("settings.glass.hint")).foregroundStyle(.secondary)
        }
    }
}
