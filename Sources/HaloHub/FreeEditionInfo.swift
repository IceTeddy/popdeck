import AppKit
import SwiftUI

/// Public marketing/compatibility information only. Paid implementations and
/// license verification are absent from this source edition.
enum FreeEditionInfo {
    @MainActor static func show() {
        let alert = NSAlert()
        alert.messageText = ProText.t("此功能属于 PopDeck PRO", "This feature requires PopDeck PRO")
        alert.informativeText = ProText.t("公开源码构建提供单圈免费版。多圈、分组和扇形命令集可在官方完整版中解锁；已有配置会保留。", "The public source build provides the single-ring Free edition. The official full build supports PRO rings, groups and command sets. Existing configuration is preserved.")
        alert.addButton(withTitle: ProText.t("好", "OK")); alert.runModal()
    }
}
struct FreeEditionInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProFeatureLabel(title: "PopDeck")
            Text(ProText.t("人民币 ¥6 / US$1 / 1 USDT，一次性永久解锁多圈、分组和扇形命令集，包含后续更新，可在本人多台 Mac 使用。", "US$1 / CNY ¥6 / 1 USDT permanently unlocks multiple rings, groups and command sets, including future updates, on your own Macs."))
            Text(ProText.t("当前是公开源码免费版，未包含高级功能实现或激活模块。如需使用 PRO，请下载官方完整版。", "This public source build does not include premium implementations or activation. Download the official full build to use PRO."))
                .foregroundStyle(.secondary)
            Link(ProText.t("访问官网", "Visit website"), destination: URL(string: "https://popdeck.pages.dev/")!)
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }
}
