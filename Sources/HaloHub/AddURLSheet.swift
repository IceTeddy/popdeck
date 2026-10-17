import SwiftUI

struct AddURLSheet: View {
    let onAdd: (String, String) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var urlString = ""
    @State private var didFailValidation = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case url
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.cyan.opacity(0.95))

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.t("settings.addURL.title"))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(L10n.t("settings.addURL.subtitle"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                TextField(L10n.t("settings.addURL.namePlaceholder"), text: $title)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .title)
                    .padding(12)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    )

                TextField(L10n.t("settings.addURL.urlPlaceholder"), text: $urlString)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .url)
                    .padding(12)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(didFailValidation ? .red.opacity(0.58) : .white.opacity(0.12), lineWidth: 1)
                    )
                    .onSubmit(add)

                if didFailValidation {
                    Text(L10n.t("settings.addURL.invalid"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.red.opacity(0.86))
                }
            }

            HStack(spacing: 10) {
                Spacer()
                Button(L10n.t("settings.cancel")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(L10n.t("settings.addURL.confirm")) {
                    add()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 430)
        .background(SettingsGlassBackground())
        .onAppear {
            focusedField = .url
        }
    }

    private func add() {
        if onAdd(title, urlString) {
            dismiss()
        } else {
            didFailValidation = true
            focusedField = .url
        }
    }
}
