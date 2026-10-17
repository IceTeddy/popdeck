import SwiftUI

struct SettingsGlassBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.09, blue: 0.13),
                    Color(red: 0.12, green: 0.13, blue: 0.18),
                    Color(red: 0.06, green: 0.08, blue: 0.11)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if #available(macOS 26.0, *) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.001))
                    .glassEffect(.regular.tint(Color.white.opacity(0.06)).interactive(), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .padding(12)
            } else {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                    .opacity(0.88)
            }
        }
        .ignoresSafeArea()
    }
}
