import SwiftUI

struct LauncherItemSettingsList: View {
    let items: [HaloMenuItem]
    let onEditCommand: (UUID) -> Void
    let onEditAppearance: (UUID) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items) { item in
                HStack(spacing: 10) {
                    HaloMenuIconView(icon: item.icon, isHovered: false, appIconStyle: .original, size: 28, symbolSize: 22, appearance: item.iconAppearance)
                        .frame(width: 32, height: 32)
                    Text(item.title).lineLimit(1)
                    if item.kind == .unavailable { ProBadge() }
                    Spacer()
                    if item.kind == .command { Button(L10n.t("settings.editCommand")) { onEditCommand(item.id) } }
                    if item.kind != .unavailable { Button(L10n.t("settings.iconAppearance")) { onEditAppearance(item.id) } }
                }
            }
        }.padding(15).background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
    }
}
