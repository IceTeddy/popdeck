import SwiftUI

struct SettingsView: View {
    @ObservedObject private var store = HaloMenuStore.shared
    @ObservedObject private var configuration = FreePanelConfiguration.shared
    @AppStorage(AppLanguage.storageKey) private var language = AppLanguage.zhHans.rawValue
    @AppStorage(AppPreferences.showItemNamesKey) private var showNames = true
    @AppStorage(AppPreferences.glassStyleKey) private var glassStyle = HaloGlassStyle.regular.rawValue
    @State private var section = 0
    @State private var resizing = false
    @State private var addingURL = false
    @State private var addingCommand = false
    @State private var editingCommand: PersistedHaloMenuItem?
    @State private var editingAppearance: HaloMenuItem?
    @State private var recording = false
    @State private var shortcut = HaloShortcut.current
    @State private var shortcutPreview: String?
    @State private var login = LoginItemService.isEnabled
    @State private var permissions = SystemPermissionStatus.current
    @State private var reset = false

    var body: some View {
        SettingsNavigation(selection: $section, showsSupport: true) {
            VStack(spacing: 0) {
                if section == 0 {
                    SettingsPanelEditor(naturalDiameter: SinglePanelMetrics(appearance: configuration.appearance).panelSize) {
                            SettingsRingsPreview(store: store, appearance: configuration.appearance, isResizing: resizing,
                                showNames: showNames, onURL: { addingURL = true }, onCommand: { addingCommand = true },
                                onEdit: edit, onAppearance: { editingAppearance = $0 })
                                .frame(maxWidth: .infinity)
                    } tools: {
                        Picker(ProText.t("编辑模式", "Editing mode"), selection: $resizing) {
                            Text(ProText.t("常规编辑", "Arrange")).tag(false)
                            Text(ProText.t("调整扇形宽度", "Sector Width")).tag(true)
                        }.pickerStyle(.segmented).labelsHidden()
                    } configuration: {
                            HStack {
                                Text(L10n.t("settings.section.items")).font(.headline)
                                Text("\(store.items.count) / \(LauncherLimits.panelItems)").font(.callout.monospacedDigit()).foregroundStyle(.secondary)
                                Spacer()
                                Button { FreeEditionInfo.show() } label: { ProFeatureLabel(title: L10n.t("settings.rings.add"), systemImage: "plus.circle") }
                            }
                            RingAppearanceControls(configuration: configuration)
                            LauncherItemSettingsList(items: store.items, onEditCommand: edit, onEditAppearance: { id in editingAppearance = store.items.first { $0.id == id } })
                            Button(L10n.t("settings.resetDefaults.button")) { reset = true }
                    }
                } else if section == 1 {
                    Form {
                            Picker(L10n.t("settings.language.title"), selection: $language) {
                                ForEach(AppLanguage.allCases) { Text($0.pickerLabel).tag($0.rawValue) }
                            }
                            Toggle(L10n.t("settings.launchAtLogin.title"), isOn: Binding(get: { login }, set: { value in
                                do { try LoginItemService.setEnabled(value); login = LoginItemService.isEnabled }
                                catch { login = LoginItemService.isEnabled }
                            }))
                    }.formStyle(.grouped)
                } else if section == 5 {
                    Form {
                            HStack {
                                Text(L10n.t("settings.shortcut.title"))
                                Spacer()
                                Button(recording ? (shortcutPreview ?? L10n.t("settings.shortcut.recording")) : shortcut.displayText) {
                                    recording = true
                                    NSApp.delegate.flatMap { $0 as? AppDelegate }?.setShortcutRecording(true, onCapture: capture)
                                }
                            }

                            ForEach(SystemPermissionKind.allCases) { kind in
                                HStack {
                                    Text(kind.title)
                                    Spacer()
                                    Button(permissions.isGranted(kind) ? ProText.t("已授权", "Granted") : ProText.t("打开系统设置", "Open system settings")) { SystemPermissionService.openSettings(for: kind) }
                                }
                            }
                            Button(L10n.t("settings.permissions.refresh")) { permissions = .current }
                            Link(L10n.t("settings.website.button"), destination: URL(string: "https://popdeck.pages.dev/")!)
                    }.formStyle(.grouped)
                } else if section == 3 {
                    Form {
                        if #available(macOS 26.0, *) { GlassStyleControl(style: $glassStyle) }
                        else { Text(ProText.t("当前系统使用毛玻璃效果。", "This macOS version uses the frosted glass appearance.")) }
                    }.formStyle(.grouped)
                } else if section == 4 {
                    Form { HoverSoundControl() }.formStyle(.grouped)
                } else if section == 6 {
                    SettingsPage { SupportCoffeeView() }
                } else {
                    SettingsPage { FreeEditionInfoView() }
                }
                Text("PopDeck Free · " + (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development"))
                    .font(.caption).foregroundStyle(.secondary).padding(.bottom, 10)
            }
        }
        .frame(minWidth: 1060, minHeight: 520)
        .background(ShortcutRecorder(isRecording: $recording, onPreview: { shortcutPreview = $0 }, onRecord: capture, onCancel: { recording = false }))
        .sheet(isPresented: $addingURL) { AddURLSheet { store.addURL(title: $0, urlString: $1) } }
        .sheet(isPresented: $addingCommand) { AddCommandSheet { store.addCommand(title: $0, command: $1, opensTerminal: $2) } }
        .sheet(item: $editingCommand) { item in AddCommandSheet(item: item) { store.updateCommand(id: item.id, title: $0, command: $1, opensTerminal: $2) } }
        .sheet(item: $editingAppearance) { item in IconAppearanceSheet(item: item) { store.updateAppearance(id: item.id, appearance: $0) } }
        .alert(L10n.t("settings.resetDefaults.button"), isPresented: $reset) {
            Button(L10n.t("settings.cancel"), role: .cancel) {}
            Button(L10n.t("settings.resetDefaults.confirm"), role: .destructive) { store.resetToDefaults() }
        }
    }
    private func edit(_ id: UUID) {
        guard let item = store.persistedItems.first(where: { $0.id == id }) else { return }
        if item.actionKind == .command { editingCommand = item }
        else if item.actionKind == .unavailable { FreeEditionInfo.show() }
    }
    private func capture(_ value: HaloShortcut) {
        ShortcutRecordingState.suppressInvocationsBriefly(); shortcut = value; recording = false; value.save()
        NSApp.delegate.flatMap { $0 as? AppDelegate }?.setShortcutRecording(false)
    }
}
