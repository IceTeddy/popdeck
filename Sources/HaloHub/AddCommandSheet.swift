import SwiftUI

struct AddCommandSheet: View {
    let isEditing: Bool
    let onAdd: (String, String, Bool) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var command = ""
    @State private var opensTerminal = false
    @State private var didFailValidation = false

    init(item: PersistedHaloMenuItem? = nil, onAdd: @escaping (String, String, Bool) -> Bool) {
        self.onAdd = onAdd
        isEditing = item != nil
        _title = State(initialValue: item?.title ?? "")
        _command = State(initialValue: item?.value ?? "")
        _opensTerminal = State(initialValue: item?.opensTerminal ?? false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(L10n.t(isEditing ? "settings.editCommand" : "settings.addCommand.button"), systemImage: "terminal.fill")
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
            Toggle(L10n.t("settings.command.openTerminal"), isOn: $opensTerminal)
                .toggleStyle(.checkbox)
            Text(L10n.t(opensTerminal ? "settings.command.terminalHint" : "settings.command.silentHint"))
                .font(.caption)
                .foregroundStyle(.secondary)
            if didFailValidation {
                Text(L10n.t("settings.addCommand.invalid"))
                    .font(.callout)
                    .foregroundStyle(.red)
            }
            HStack {
                Spacer()
                Button(L10n.t("settings.cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.t(isEditing ? "settings.save" : "settings.addURL.confirm")) {
                    if onAdd(title, command, opensTerminal) {
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
