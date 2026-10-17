import SwiftUI

struct SectorBackgroundPicker: View {
    @Binding var selection: HaloIconColor?
    var body: some View {
        Picker(L10n.t("settings.sector.background"), selection: Binding(
            get: { selection?.rawValue ?? "" }, set: { selection = HaloIconColor(rawValue: $0) }
        )) {
            Text(L10n.t("settings.iconDefault")).tag("")
            ForEach(HaloIconColor.allCases) { color in
                Text(L10n.t("icon.color." + color.rawValue)).tag(color.rawValue)
            }
        }
    }
}
