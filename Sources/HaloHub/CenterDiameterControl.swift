import SwiftUI

struct CenterDiameterControl: View {
    @Binding var appearance: HaloRingAppearance

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(ProText.t("中心圆直径", "Center diameter"))
                Spacer()
                Text("\(Int(appearance.resolvedCenterDiameter.rounded())) pt")
                    .monospacedDigit().foregroundStyle(.secondary)
            }
            Slider(value: Binding(get: { appearance.resolvedCenterDiameter },
                                  set: { appearance.centerDiameter = $0 }),
                   in: appearance.centerDiameterRange)
                .accessibilityLabel(ProText.t("中心圆直径", "Center diameter"))
                .accessibilityValue("\(Int(appearance.resolvedCenterDiameter.rounded())) pt")
            HStack(alignment: .top) {
                Text(ProText.t("单独调整中心圆，保留第一圈外径与图标位置。", "Adjust the center while keeping the first ring’s outer diameter and icon positions."))
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(ProText.t("恢复默认", "Reset")) { appearance.centerDiameter = nil }
                    .font(.caption).disabled(appearance.centerDiameter == nil)
            }
        }
    }
}
