import SwiftUI

private struct SettingsPreviewDiameterKey: EnvironmentKey { static let defaultValue: CGFloat = 490 }
extension EnvironmentValues {
    var settingsPreviewDiameter: CGFloat {
        get { self[SettingsPreviewDiameterKey.self] }
        set { self[SettingsPreviewDiameterKey.self] = newValue }
    }
}

/// Groups purchase information and activation into a single focused detail page.
struct SettingsColumns<Left: View, Right: View>: View {
    @ViewBuilder var left: () -> Left
    @ViewBuilder var right: () -> Right
    var body: some View {
        SettingsPage {
            left()
            Divider()
            right()
        }
    }
}

enum SupportPayment: String, CaseIterable, Identifiable {
    case wechat, alipay, paypal, usdt
    var id: String { rawValue }
    var title: String {
        switch self {
        case .wechat: ProText.t("微信", "WeChat Pay")
        case .alipay: ProText.t("支付宝", "Alipay")
        case .paypal: "PayPal"
        case .usdt: "USDT"
        }
    }
    var purchasePrice: String {
        switch self {
        case .wechat, .alipay: ProText.t("人民币 ¥6", "CNY ¥6")
        case .paypal: "US$1"
        case .usdt: "1 USDT"
        }
    }
}

struct SupportPaymentPicker: View {
    @Binding var payment: SupportPayment
    var body: some View {
        VStack(spacing: 12) {
            Picker(ProText.t("支付方式", "Payment method"), selection: $payment) {
                ForEach(SupportPayment.allCases) { Text($0.title).tag($0) }
            }.labelsHidden().pickerStyle(.segmented)
            if let url = Bundle.main.url(forResource: "support-" + payment.rawValue, withExtension: "png") ?? Bundle.module.url(forResource: "support-" + payment.rawValue, withExtension: "png"),
               let image = NSImage(contentsOf: url) {
                Image(nsImage: image).resizable().interpolation(.high).scaledToFit()
                    .frame(maxWidth: 210, maxHeight: 230).padding(10)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityLabel(payment.title)
            }
        }.frame(maxWidth: .infinity)
    }
}

struct SupportCoffeeView: View {
    @State private var payment: SupportPayment = .wechat
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(ProText.t("请我喝一杯", "Buy me a coffee"), systemImage: "cup.and.saucer.fill").font(.headline)
            Text(ProText.t("如果 PopDeck 帮你节省了时间，欢迎自愿支持开发，金额随心。打赏不会自动激活 PRO；购买 PRO 请前往 PRO 标签页。", "If PopDeck saves you time, you can support development with any amount. Donations do not activate PRO. To buy PRO, visit the PRO tab."))
                .font(.callout).foregroundStyle(.secondary)
            SupportPaymentPicker(payment: $payment)
            Link(ProText.t("更多支持方式与说明", "Support details"), destination: URL(string: "https://popdeck.pages.dev/")!)
        }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }
}
