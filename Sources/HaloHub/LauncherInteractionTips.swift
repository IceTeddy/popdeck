import SwiftUI

struct LauncherInteractionTips: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(L10n.t("settings.guide.context"), systemImage: "cursorarrow.click.2")
                .font(.system(size: 15)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            DisclosureGroup(L10n.t("settings.guide.more")) {
                VStack(alignment: .leading, spacing: 9) {
                    Text(L10n.t("settings.guide.drag"))
                    Text(L10n.t("settings.guide.resize"))
                    Text(L10n.t("settings.guide.run"))
                }
                .font(.system(size: 14)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 5)
            }.font(.system(size: 14))
        }
    }
}
