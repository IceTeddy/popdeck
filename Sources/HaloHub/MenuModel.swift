import AppKit
import Foundation

struct HaloMenuItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let icon: HaloMenuIcon
    let kind: HaloMenuItemKind
    let action: HaloAction

    init(id: UUID = UUID(), title: String, subtitle: String, symbolName: String, action: HaloAction) {
        self.init(id: id, title: title, subtitle: subtitle, icon: .symbol(symbolName), kind: HaloMenuItemKind(action: action), action: action)
    }

    init(id: UUID = UUID(), title: String, subtitle: String, icon: HaloMenuIcon, kind: HaloMenuItemKind, action: HaloAction) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.kind = kind
        self.action = action
    }

    static let defaultItems: [HaloMenuItem] = [
        HaloMenuItem(title: "Finder", subtitle: L10n.t("item.finder.subtitle"), symbolName: "folder.fill", action: .app(bundleIdentifier: "com.apple.finder")),
        HaloMenuItem(title: "Safari", subtitle: L10n.t("item.safari.subtitle"), symbolName: "safari.fill", action: .app(bundleIdentifier: "com.apple.Safari")),
        HaloMenuItem(title: "Terminal", subtitle: L10n.t("item.terminal.subtitle"), symbolName: "terminal.fill", action: .app(bundleIdentifier: "com.apple.Terminal")),
        HaloMenuItem(title: L10n.t("item.settings.title"), subtitle: L10n.t("item.settings.subtitle"), symbolName: "gearshape.fill", action: .app(bundleIdentifier: "com.apple.systempreferences")),
        HaloMenuItem(title: L10n.t("item.downloads.title"), subtitle: L10n.t("item.downloads.subtitle"), symbolName: "tray.and.arrow.down.fill", action: .folder(FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first)),
        HaloMenuItem(title: "ChatGPT", subtitle: L10n.t("item.chatgpt.subtitle"), symbolName: "link.circle.fill", action: .url(URL(string: "https://chatgpt.com")))
    ]
}

enum HaloMenuItemKind: Hashable {
    case app
    case file
    case folder
    case url

    init(action: HaloAction) {
        switch action {
        case .app:
            self = .app
        case .file:
            self = .file
        case .folder:
            self = .folder
        case .url:
            self = .url
        }
    }

    var badgeSymbolName: String {
        switch self {
        case .app:
            return "square.grid.2x2.fill"
        case .file:
            return "doc.fill"
        case .folder:
            return "folder.fill"
        case .url:
            return "link"
        }
    }
}

enum HaloMenuIcon: Hashable {
    case symbol(String)
    case app(bundleIdentifier: String)
    case file(path: String)
    case image(path: String, fallbackSymbolName: String)

    var fallbackSymbolName: String {
        switch self {
        case .symbol(let symbolName):
            return symbolName
        case .app:
            return "app.fill"
        case .file:
            return "doc.fill"
        case .image(_, let fallbackSymbolName):
            return fallbackSymbolName
        }
    }
}

enum HaloAction: Hashable {
    case app(bundleIdentifier: String)
    case url(URL?)
    case folder(URL?)
    case file(URL?)

    @MainActor
    func perform() {
        switch self {
        case .app(let bundleIdentifier):
            openApp(bundleIdentifier: bundleIdentifier)
        case .url(let url), .folder(let url), .file(let url):
            guard let url else { return }
            NSWorkspace.shared.open(url)
        }
    }

    @MainActor
    private func openApp(bundleIdentifier: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            NSSound.beep()
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: configuration)
    }
}

struct PersistedHaloMenuItem: Codable, Identifiable, Equatable {
    enum ActionKind: String, Codable {
        case app
        case url
        case folder
        case file
    }

    let id: UUID
    let title: String
    let subtitleKey: String?
    let subtitle: String
    let symbolName: String
    let actionKind: ActionKind
    let value: String
    var iconPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitleKey
        case subtitle
        case symbolName
        case actionKind
        case value
        case iconPath
    }

    init(id: UUID, title: String, subtitleKey: String?, subtitle: String, symbolName: String, actionKind: ActionKind, value: String, iconPath: String? = nil) {
        self.id = id
        self.title = title
        self.subtitleKey = subtitleKey
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.actionKind = actionKind
        self.value = value
        self.iconPath = iconPath
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        subtitleKey = try container.decodeIfPresent(String.self, forKey: .subtitleKey)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        symbolName = try container.decode(String.self, forKey: .symbolName)
        actionKind = try container.decode(ActionKind.self, forKey: .actionKind)
        value = try container.decode(String.self, forKey: .value)
        iconPath = try container.decodeIfPresent(String.self, forKey: .iconPath)
    }

    var localizedSubtitle: String {
        if let subtitleKey {
            return L10n.t(subtitleKey)
        }
        return subtitle
    }

    func menuItem() -> HaloMenuItem {
        let action: HaloAction
        let icon: HaloMenuIcon
        switch actionKind {
        case .app:
            action = .app(bundleIdentifier: value)
            icon = symbolName == "app.fill" ? .app(bundleIdentifier: value) : .symbol(symbolName)
        case .url:
            action = .url(URL(string: value))
            if let iconPath, FileManager.default.fileExists(atPath: iconPath) {
                icon = .image(path: iconPath, fallbackSymbolName: symbolName)
            } else {
                icon = .symbol(symbolName)
            }
        case .folder:
            action = .folder(URL(fileURLWithPath: value))
            icon = subtitleKey == nil ? .file(path: value) : .symbol(symbolName)
        case .file:
            action = .file(URL(fileURLWithPath: value))
            icon = .file(path: value)
        }

        return HaloMenuItem(
            id: id,
            title: title,
            subtitle: localizedSubtitle,
            icon: icon,
            kind: HaloMenuItemKind(action: action),
            action: action
        )
    }
}

@MainActor
final class HaloMenuStore: ObservableObject {
    static let shared = HaloMenuStore()
    static let itemLimitReachedNotification = Notification.Name("HaloMenuStoreItemLimitReached")

    @Published private(set) var persistedItems: [PersistedHaloMenuItem] = []

    private let storageKey = "haloMenuItems"
    private let maxItemCount = 8

    var items: [HaloMenuItem] {
        persistedItems.map { $0.menuItem() }
    }

    private init() {
        load()
    }

    func addDroppedItem(at url: URL) {
        if url.pathExtension.lowercased() == "app" {
            addApplication(at: url)
        } else {
            addFile(at: url)
        }
    }

    @discardableResult
    func addURL(title: String, urlString: String) -> Bool {
        guard canAddItem else { return false }

        guard let url = normalizedWebURL(from: urlString) else {
            NSSound.beep()
            return false
        }

        let absoluteString = url.absoluteString
        if persistedItems.contains(where: { $0.actionKind == .url && $0.value == absoluteString }) {
            NSSound.beep()
            return false
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let hostTitle = url.host?.replacingOccurrences(of: "www.", with: "") ?? absoluteString
        let itemID = UUID()
        persistedItems.append(PersistedHaloMenuItem(
            id: itemID,
            title: trimmedTitle.isEmpty ? hostTitle : trimmedTitle,
            subtitleKey: nil,
            subtitle: L10n.t("item.addedURL.subtitle"),
            symbolName: "link.circle.fill",
            actionKind: .url,
            value: absoluteString,
            iconPath: nil
        ))
        save()
        fetchFavicon(for: itemID, url: url)
        return true
    }

    private func addApplication(at url: URL) {
        guard canAddItem else { return }

        guard url.pathExtension.lowercased() == "app" else {
            NSSound.beep()
            return
        }

        let bundle = Bundle(url: url)
        guard let bundleIdentifier = bundle?.bundleIdentifier else {
            NSSound.beep()
            return
        }

        if persistedItems.contains(where: { $0.actionKind == .app && $0.value == bundleIdentifier }) {
            NSSound.beep()
            return
        }

        let displayName = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent

        persistedItems.append(PersistedHaloMenuItem(
            id: UUID(),
            title: displayName,
            subtitleKey: nil,
            subtitle: L10n.t("item.addedApp.subtitle"),
            symbolName: "app.fill",
            actionKind: .app,
            value: bundleIdentifier,
            iconPath: nil
        ))
        save()
    }

    private func addFile(at url: URL) {
        guard canAddItem else { return }

        let standardizedURL = url.standardizedFileURL
        let path = standardizedURL.path
        if persistedItems.contains(where: { ($0.actionKind == .file || $0.actionKind == .folder) && $0.value == path }) {
            NSSound.beep()
            return
        }

        let isDirectory = (try? standardizedURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        persistedItems.append(PersistedHaloMenuItem(
            id: UUID(),
            title: standardizedURL.deletingPathExtension().lastPathComponent,
            subtitleKey: nil,
            subtitle: isDirectory ? L10n.t("item.addedFolder.subtitle") : standardizedURL.pathExtension.uppercased().isEmpty ? L10n.t("item.addedFile.subtitle") : standardizedURL.pathExtension.uppercased(),
            symbolName: isDirectory ? "folder.fill" : "doc.fill",
            actionKind: isDirectory ? .folder : .file,
            value: path,
            iconPath: nil
        ))
        save()
    }

    private func fetchFavicon(for itemID: UUID, url: URL) {
        Task {
            guard let iconURL = await FaviconFetcher.shared.cachedIcon(for: url) else { return }
            await MainActor.run {
                guard let index = persistedItems.firstIndex(where: { $0.id == itemID }) else { return }
                persistedItems[index].iconPath = iconURL.path
                save()
            }
        }
    }

    private func normalizedWebURL(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let components = URLComponents(string: candidate),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              components.host?.isEmpty == false,
              let url = components.url else {
            return nil
        }

        return url
    }

    private var canAddItem: Bool {
        if persistedItems.count < maxItemCount {
            return true
        }

        NSSound.beep()
        NotificationCenter.default.post(name: Self.itemLimitReachedNotification, object: nil)
        return false
    }

    func removeItem(id: HaloMenuItem.ID) {
        persistedItems.removeAll { $0.id == id }
        save()
    }

    func moveItem(id: HaloMenuItem.ID, to targetIndex: Int) {
        guard let sourceIndex = persistedItems.firstIndex(where: { $0.id == id }),
              persistedItems.indices.contains(targetIndex),
              sourceIndex != targetIndex else {
            return
        }

        let item = persistedItems.remove(at: sourceIndex)
        let adjustedTargetIndex = min(targetIndex, persistedItems.count)
        persistedItems.insert(item, at: adjustedTargetIndex)
        save()
    }

    func resetToDefaults() {
        persistedItems = Self.makeDefaultItems()
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([PersistedHaloMenuItem].self, from: data) else {
            persistedItems = Self.makeDefaultItems()
            save()
            scheduleMissingFaviconRefresh()
            return
        }
        persistedItems = Array(decoded.prefix(maxItemCount))
        if decoded.count > maxItemCount {
            save()
        }
        scheduleMissingFaviconRefresh()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(persistedItems) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func refreshMissingFavicons() {
        for item in persistedItems where item.actionKind == .url && item.iconPath == nil {
            guard let url = URL(string: item.value) else { continue }
            fetchFavicon(for: item.id, url: url)
        }
    }

    private func scheduleMissingFaviconRefresh() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            refreshMissingFavicons()
        }
    }

    private static func makeDefaultItems() -> [PersistedHaloMenuItem] {
        [
            PersistedHaloMenuItem(id: UUID(), title: "Finder", subtitleKey: "item.finder.subtitle", subtitle: "Files", symbolName: "folder.fill", actionKind: .app, value: "com.apple.finder", iconPath: nil),
            PersistedHaloMenuItem(id: UUID(), title: "Safari", subtitleKey: "item.safari.subtitle", subtitle: "Web", symbolName: "safari.fill", actionKind: .app, value: "com.apple.Safari", iconPath: nil),
            PersistedHaloMenuItem(id: UUID(), title: "Terminal", subtitleKey: "item.terminal.subtitle", subtitle: "Shell", symbolName: "terminal.fill", actionKind: .app, value: "com.apple.Terminal", iconPath: nil),
            PersistedHaloMenuItem(id: UUID(), title: L10n.t("item.settings.title"), subtitleKey: "item.settings.subtitle", subtitle: "System", symbolName: "gearshape.fill", actionKind: .app, value: "com.apple.systempreferences", iconPath: nil),
            PersistedHaloMenuItem(id: UUID(), title: L10n.t("item.downloads.title"), subtitleKey: "item.downloads.subtitle", subtitle: "Folder", symbolName: "tray.and.arrow.down.fill", actionKind: .folder, value: FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? "", iconPath: nil),
            PersistedHaloMenuItem(id: UUID(), title: "ChatGPT", subtitleKey: "item.chatgpt.subtitle", subtitle: "URL", symbolName: "link.circle.fill", actionKind: .url, value: "https://chatgpt.com", iconPath: nil)
        ]
    }
}
