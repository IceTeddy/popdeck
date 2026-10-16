import SwiftUI

struct GlassStyleControl: View {
    @Binding var style: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(L10n.t("settings.glass.title"), selection: $style) {
                ForEach(HaloGlassStyle.allCases) { variant in
                    Text(variant.displayTitle).tag(variant.rawValue)
                }
            }
            .pickerStyle(.segmented)
            Text(L10n.t("settings.glass.hint"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white.opacity(0.92))
        .padding(15)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.14), lineWidth: 1)
        }
    }
}
