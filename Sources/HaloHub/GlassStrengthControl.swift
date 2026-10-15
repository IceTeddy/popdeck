import SwiftUI

struct GlassStrengthControl: View {
    @Binding var strength: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.t("settings.glass.title"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer()
                Text("\(Int(strength * 100))")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Button(L10n.t("settings.glass.reset")) { strength = 0 }
                    .buttonStyle(.borderless)
            }
            Slider(value: $strength, in: 0...1) {
                Text(L10n.t("settings.glass.title"))
            }
            .accessibilityValue("\(Int(strength * 100))")
            HStack {
                Text(L10n.t("settings.glass.clear"))
                Spacer()
                Text(L10n.t("settings.glass.strong"))
            }
            .font(.caption)
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
