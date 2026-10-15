import SwiftUI

struct AddCommandSheet: View {
    let onAdd: (String, String) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var command = ""
    @State private var didFailValidation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(L10n.t("settings.addCommand.button"), systemImage: "terminal.fill")
                .font(.title2.bold())
            Text(L10n.t("settings.addCommand.subtitle"))
                .font(.callout)
                .foregroundStyle(.secondary)
            TextField(L10n.t("settings.addURL.namePlaceholder"), text: $title)
                .textFieldStyle(.roundedBorder)
            Text(L10n.t("settings.addCommand.label"))
                .font(.headline)
            CommandTextEditor(text: $command)
                .frame(height: 150)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(.secondary.opacity(0.3)))
                .accessibilityLabel(L10n.t("settings.addCommand.label"))
            if didFailValidation {
                Text(L10n.t("settings.addCommand.invalid"))
                    .font(.callout)
                    .foregroundStyle(.red)
            }
            HStack {
                Spacer()
                Button(L10n.t("settings.cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.t("settings.addURL.confirm")) {
                    if onAdd(title, command) {
                        dismiss()
                    } else {
                        didFailValidation = true
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!CommandRunner.isValid(command))
            }
        }
        .padding(24)
        .frame(width: 480)
    }
}
