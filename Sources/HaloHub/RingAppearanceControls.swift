import SwiftUI

struct RingAppearanceControls: View {
    @ObservedObject var configuration: FreePanelConfiguration
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ProText.t("面板外观", "Panel appearance")).font(.headline)
            Text(L10n.t("settings.hubSize.title"))
            Slider(value: Binding(get: { configuration.appearance.position }, set: { configuration.appearance.setPosition($0) }), in: 0...3)
            HStack {
                ForEach(HaloHubSizePreference.allCases) { size in
                    Text(size.displayTitle).font(.caption)
                    if size != HaloHubSizePreference.allCases.last { Spacer() }
                }
            }.foregroundStyle(.secondary)
            CenterDiameterControl(appearance: $configuration.appearance)
            Picker(L10n.t("settings.iconSize.title"), selection: $configuration.appearance.iconSize) {
                ForEach(HaloIconSizePreference.allCases) { Text($0.displayTitle).tag($0) }
            }
            Picker(L10n.t("settings.appIconStyle.title"), selection: $configuration.appearance.iconStyle) {
                ForEach(HaloAppIconStyle.allCases) { Text($0.displayTitle).tag($0) }
            }
        }.padding(15).background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
    }
}
