import SwiftUI

struct EmojiChoice: Decodable, Identifiable {
    let symbol: String
    let group: String
    let name: String
    var id: String { symbol }
}

enum EmojiCatalog {
    struct Catalog: Decodable { let version: String; let entries: [EmojiChoice] }
    static let catalog: Catalog = {
        let url = Bundle.main.url(forResource: "emoji-catalog", withExtension: "json")
            ?? Bundle.module.url(forResource: "emoji-catalog", withExtension: "json")
        guard let url, let data = try? Data(contentsOf: url),
              let result = try? JSONDecoder().decode(Catalog.self, from: data) else {
            return Catalog(version: "", entries: [])
        }
        return result
    }()
    static let symbols = Set(catalog.entries.map(\.symbol))
    static var groups: [String] {
        var seen = Set<String>()
        return catalog.entries.map(\.group).filter { seen.insert($0).inserted }
    }
}

struct EmojiSelectionMenu: View {
    @Binding var selection: String
    var emptyLabel: String? = nil
    @State private var isExpanded = false

    var body: some View {
        Button { isExpanded.toggle() } label: {
            HStack {
                Text(selection.isEmpty ? (emptyLabel ?? L10n.t("settings.iconOriginal")) : selection)
                Spacer()
                Image(systemName: "chevron.down")
            }
            .padding(.vertical, 5)
        }
        .accessibilityLabel(L10n.t("settings.iconEmoji"))
        .accessibilityValue(selection.isEmpty ? (emptyLabel ?? L10n.t("settings.iconOriginal")) : selection)
        .popover(isPresented: $isExpanded, arrowEdge: .bottom) {
            EmojiSelectionPanel(selection: selection) { symbol in
                selection = symbol
                isExpanded = false
            }
        }
    }
}

private struct EmojiSelectionPanel: View {
    let selection: String
    let onSelect: (String) -> Void
    @State private var group = ""
    @State private var search = ""
    private let columns = Array(repeating: GridItem(.fixed(38), spacing: 6), count: 8)
    private var choices: [EmojiChoice] {
        EmojiCatalog.catalog.entries.filter {
            (group.isEmpty || $0.group == group) &&
            (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.symbol.contains(search))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.t("settings.iconEmoji")).font(.headline)
                Spacer()
                Button(L10n.t("settings.iconOriginal")) { onSelect("") }
            }
            Picker(L10n.t("settings.emojiCategory"), selection: $group) {
                Text(L10n.t("settings.emojiAll")).tag("")
                ForEach(EmojiCatalog.groups, id: \.self) { category in
                    Text(L10n.t("emoji.group.\(category)")).tag(category)
                }
            }
            .pickerStyle(.menu)
            TextField(L10n.t("settings.emojiSearch"), text: $search)
                .textFieldStyle(.roundedBorder)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(choices) { emoji in
                        Button { onSelect(emoji.symbol) } label: {
                            Text(emoji.symbol).font(.system(size: 25))
                                .frame(width: 38, height: 38)
                                .background(selection == emoji.symbol ? Color.accentColor.opacity(0.25) : .clear,
                                            in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .help(emoji.name)
                        .accessibilityLabel("\(emoji.symbol) \(emoji.name)")
                    }
                }
                .padding(2)
            }
            .frame(height: 280)
            Text(String(format: L10n.t("settings.emojiCount"), choices.count))
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 390)
    }
}
