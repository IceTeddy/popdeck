import SwiftUI
import Carbon.HIToolbox
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage(AppLanguage.storageKey) private var languageRawValue = AppLanguage.zhHans.rawValue
    @AppStorage(AppPreferences.showItemNamesKey) private var showItemNames = true
    @AppStorage(AppPreferences.iconSizeKey) private var iconSizeRawValue = HaloIconSizePreference.medium.rawValue
    @AppStorage(AppPreferences.hubSizeKey) private var hubSizeRawValue = HaloHubSizePreference.small.rawValue
    @AppStorage(AppPreferences.appIconStyleKey) private var appIconStyleRawValue = HaloAppIconStyle.original.rawValue
    @ObservedObject private var menuStore = HaloMenuStore.shared
    @State private var isAddingURL = false
    @State private var activeAlert: SettingsAlert?
    @State private var isRecordingShortcut = false
    @State private var shortcutRecordingPreview: String?
    @State private var shortcut = HaloShortcut.current
    @State private var launchAtLogin = LoginItemService.isEnabled
    @State private var permissionStatus = SystemPermissionStatus.current

    private let settingsControlColumnWidth: CGFloat = 184

    private var language: AppLanguage {
        get { AppLanguage(rawValue: languageRawValue) ?? .zhHans }
        nonmutating set { languageRawValue = newValue.rawValue }
    }

    private var defaultItems: [HaloMenuItem] {
        _ = languageRawValue
        return menuStore.items
    }

    private var iconSizePreference: HaloIconSizePreference {
        HaloIconSizePreference(rawValue: iconSizeRawValue) ?? .medium
    }

    private var hubSizePreference: HaloHubSizePreference {
        HaloHubSizePreference(rawValue: hubSizeRawValue) ?? .medium
    }

    private var appIconStyle: HaloAppIconStyle {
        if ["grayscale", "softMonochrome", "silhouette"].contains(appIconStyleRawValue) {
            DispatchQueue.main.async {
                appIconStyleRawValue = HaloAppIconStyle.original.rawValue
            }
            return .original
        }
        return HaloAppIconStyle(rawValue: appIconStyleRawValue) ?? .original
    }

    var body: some View {
        ZStack {
            SettingsGlassBackground()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 10) {
                    ZStack(alignment: .topTrailing) {
                        SettingsHubPreview(
                            items: defaultItems,
                            showItemNames: showItemNames,
                            iconSizePreference: iconSizePreference,
                            hubSizePreference: hubSizePreference,
                            appIconStyle: appIconStyle,
                            onAddDroppedItem: { menuStore.addDroppedItem(at: $0) },
                            onRemoveItem: { menuStore.removeItem(id: $0) },
                            onMoveItem: { menuStore.moveItem(id: $0, to: $1) }
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: hubSizePreference.previewFrameHeight)
                        .clipped()

                        Button {
                            NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications", isDirectory: true))
                        } label: {
                            Label(L10n.t("settings.openApplicationsFolder"), systemImage: "folder")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.12), in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                        )
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.top, 2)
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                        Button {
                            isAddingURL = true
                        } label: {
                            Label(L10n.t("settings.addURL.button"), systemImage: "link.badge.plus")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.12), in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                        )
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.top, 2)

                        Button {
                            activeAlert = .resetDefaults
                        } label: {
                            Label(L10n.t("settings.resetDefaults.button"), systemImage: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.red.opacity(0.16), in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(.red.opacity(0.24), lineWidth: 1)
                        )
                        .foregroundStyle(.white.opacity(0.94))
                        .padding(.bottom, 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }

                    Text(L10n.t("settings.hubHint"))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.56))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 12)

                        permissionStatusCard

                        HStack(spacing: 14) {
                            shortcutTile

                            settingTile(
                                icon: "circle.grid.3x3.circle.fill",
                                title: L10n.t("settings.launcher.title"),
                                value: String(format: L10n.t("settings.launcher.value"), defaultItems.count),
                                tint: .indigo
                            )
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "globe.asia.australia.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.mint.opacity(0.95))
                                .frame(width: 34)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(L10n.t("settings.language.title"))
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.54))
                                Text(language.displayName)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.92))
                            }

                            Spacer()

                            HStack(spacing: 0) {
                                Spacer()
                                Picker("", selection: $languageRawValue) {
                                    ForEach(AppLanguage.allCases) { language in
                                        Text(language.pickerLabel).tag(language.rawValue)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .frame(width: 184)
                            }
                            .frame(width: settingsControlColumnWidth)
                        }
                        .padding(15)
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                        )

                        HStack(spacing: 12) {
                            Text(L10n.t("settings.showNames.title"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))

                            Spacer()

                            HStack(spacing: 0) {
                                Spacer()
                                Toggle("", isOn: $showItemNames)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                            }
                            .frame(width: settingsControlColumnWidth)
                        }
                        .padding(15)
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                        )

                        HStack(spacing: 12) {
                            Text(L10n.t("settings.launchAtLogin.title"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))

                            Spacer()

                            HStack(spacing: 0) {
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { launchAtLogin },
                                    set: { setLaunchAtLogin($0) }
                                ))
                                .labelsHidden()
                                .toggleStyle(.switch)
                            }
                            .frame(width: settingsControlColumnWidth)
                        }
                        .padding(15)
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                        )

                        HStack(spacing: 12) {
                            Text(L10n.t("settings.iconSize.title"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))

                            Spacer()

                            HStack(spacing: 0) {
                                Spacer(minLength: 0)
                                Picker("", selection: $iconSizeRawValue) {
                                    ForEach(HaloIconSizePreference.allCases) { size in
                                        Text(size.displayTitle).tag(size.rawValue)
                                    }
                                }
                                .id("icon-size-\(languageRawValue)")
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .frame(width: settingsControlColumnWidth)
                            }
                            .frame(width: settingsControlColumnWidth)
                        }
                        .padding(15)
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                        )

                        HStack(spacing: 12) {
                            Text(L10n.t("settings.hubSize.title"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))

                            Spacer()

                            HStack(spacing: 0) {
                                Spacer(minLength: 0)
                                Picker("", selection: $hubSizeRawValue) {
                                    ForEach(HaloHubSizePreference.allCases) { size in
                                        Text(size.displayTitle).tag(size.rawValue)
                                    }
                                }
                                .id("hub-size-\(languageRawValue)")
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .frame(width: settingsControlColumnWidth)
                            }
                            .frame(width: settingsControlColumnWidth)
                        }
                        .padding(15)
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                        )

                        HStack(spacing: 12) {
                            Text(L10n.t("settings.appIconStyle.title"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))

                            Spacer()

                            HStack(spacing: 0) {
                                Spacer(minLength: 0)
                                Picker("", selection: $appIconStyleRawValue) {
                                    ForEach(HaloAppIconStyle.allCases) { style in
                                        Text(style.displayTitle).tag(style.rawValue)
                                    }
                                }
                                .id("app-icon-style-\(languageRawValue)")
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .frame(width: settingsControlColumnWidth)
                            }
                            .frame(width: settingsControlColumnWidth)
                        }
                        .padding(15)
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                        )

                        websiteFeedbackCard

                        Text(appVersionText)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.42))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 24)
            }
            .padding(10)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .frame(width: 660, height: 640)
        .alert(alertTitle, isPresented: Binding(
            get: { activeAlert != nil },
            set: { if !$0 { activeAlert = nil } }
        )) {
            switch activeAlert {
            case .resetDefaults:
                Button(L10n.t("settings.cancel"), role: .cancel) {}
                Button(L10n.t("settings.resetDefaults.confirm"), role: .destructive) {
                    menuStore.resetToDefaults()
                }
            case .itemLimitReached:
                Button(L10n.t("settings.ok"), role: .cancel) {}
            case nil:
                EmptyView()
            }
        } message: {
            Text(alertMessage)
        }
        .background(
            ShortcutRecorder(
                isRecording: $isRecordingShortcut,
                onPreview: { preview in
                    shortcutRecordingPreview = preview
                },
                onRecord: recordShortcut,
                onCancel: {
                    shortcutRecordingPreview = nil
                    isRecordingShortcut = false
                }
            )
        )
        .sheet(isPresented: $isAddingURL) {
            AddURLSheet { title, urlString in
                menuStore.addURL(title: title, urlString: urlString)
            }
        }
        .onChange(of: languageRawValue) { _, _ in
            SettingsWindowController.shared.refreshTitle()
        }
        .onAppear {
            launchAtLogin = LoginItemService.isEnabled
            refreshPermissionStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshPermissionStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: HaloMenuStore.itemLimitReachedNotification)) { _ in
            isAddingURL = false
            DispatchQueue.main.async {
                activeAlert = .itemLimitReached
            }
        }
    }

    private var permissionStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: permissionStatus.allRequiredGranted ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle((permissionStatus.allRequiredGranted ? Color.green : Color.orange).opacity(0.95))
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.t("settings.permissions.title"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                    Text(permissionStatus.allRequiredGranted ? L10n.t("settings.permissions.subtitle.ready") : L10n.t("settings.permissions.subtitle.needsAction"))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.58))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    refreshPermissionStatus()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.86))
                .background(.white.opacity(0.10), in: Circle())
                .help(L10n.t("settings.permissions.refresh"))
            }

            VStack(spacing: 8) {
                ForEach(SystemPermissionKind.allCases) { kind in
                    permissionRow(for: kind)
                }
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder((permissionStatus.allRequiredGranted ? Color.green.opacity(0.22) : Color.orange.opacity(0.24)), lineWidth: 1)
        )
    }

    private var websiteFeedbackCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.cyan.opacity(0.95))
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.t("settings.websiteFeedback.title"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                Text(L10n.t("settings.websiteFeedback.subtitle"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))
            }

            Spacer()

            HStack(spacing: 8) {
                websiteLinkButton(
                    title: L10n.t("settings.website.button"),
                    systemImage: "safari",
                    urlString: "https://popdeck.pages.dev/"
                )

                websiteLinkButton(
                    title: L10n.t("settings.feedback.button"),
                    systemImage: "text.bubble.fill",
                    urlString: "https://popdeck.pages.dev/#wall"
                )
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        )
    }

    private func websiteLinkButton(title: String, systemImage: String, urlString: String) -> some View {
        Button {
            openWebsite(urlString)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.12), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        )
        .foregroundStyle(.white.opacity(0.92))
    }

    private func openWebsite(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            NSSound.beep()
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func permissionRow(for kind: SystemPermissionKind) -> some View {
        let isGranted = permissionStatus.isGranted(kind)

        return HStack(alignment: .center, spacing: 10) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isGranted ? Color.green.opacity(0.92) : Color.orange.opacity(0.92))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(kind.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.90))
                Text(kind.detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.52))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 10)

            Text(isGranted ? L10n.t("settings.permissions.granted") : L10n.t("settings.permissions.missing"))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(isGranted ? Color.green.opacity(0.92) : Color.orange.opacity(0.92))
                .frame(width: 62, alignment: .trailing)

            if !isGranted {
                Button {
                    SystemPermissionService.request(kind)
                    SystemPermissionService.openSettings(for: kind)
                    schedulePermissionRefresh()
                } label: {
                    Text(L10n.t("settings.permissions.open"))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .frame(width: 72)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                )
                .foregroundStyle(.white.opacity(0.92))
            }
        }
        .padding(.vertical, 2)
    }

    private func refreshPermissionStatus() {
        permissionStatus = SystemPermissionStatus.current
    }

    private func schedulePermissionRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            refreshPermissionStatus()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            refreshPermissionStatus()
        }
    }

    private var appVersionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "PopDeck v\(version) (\(build))"
    }

    private enum SettingsAlert {
        case resetDefaults
        case itemLimitReached
    }

    private var alertTitle: String {
        switch activeAlert {
        case .resetDefaults:
            return L10n.t("settings.resetDefaults.title")
        case .itemLimitReached:
            return L10n.t("settings.itemLimit.title")
        case nil:
            return ""
        }
    }

    private var alertMessage: String {
        switch activeAlert {
        case .resetDefaults:
            return L10n.t("settings.resetDefaults.message")
        case .itemLimitReached:
            return L10n.t("settings.itemLimit.message")
        case nil:
            return ""
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled

        do {
            try LoginItemService.setEnabled(enabled)
            launchAtLogin = LoginItemService.isEnabled
        } catch {
            NSSound.beep()
            launchAtLogin = LoginItemService.isEnabled
            NSLog("PopDeck failed to update login item: \(error.localizedDescription)")
        }
    }

    private var shortcutTile: some View {
        Button {
            beginShortcutRecording()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isRecordingShortcut ? "record.circle.fill" : "command.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle((isRecordingShortcut ? Color.red : Color.cyan).opacity(0.95))
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.t("settings.shortcut.title"))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.54))
                    Text(shortcutDisplayText)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Spacer()
            }
            .padding(15)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(isRecordingShortcut ? 0.15 : 0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder((isRecordingShortcut ? Color.red.opacity(0.32) : .white.opacity(0.14)), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func beginShortcutRecording() {
        shortcutRecordingPreview = nil
        NSApp.delegate.flatMap { $0 as? AppDelegate }?.setShortcutRecording(true, onCapture: recordShortcut)
        isRecordingShortcut = true
    }

    private func recordShortcut(_ newShortcut: HaloShortcut) {
        ShortcutRecordingState.suppressInvocationsBriefly()
        shortcut = newShortcut
        shortcutRecordingPreview = nil
        isRecordingShortcut = false
        newShortcut.save()
        NSApp.delegate.flatMap { $0 as? AppDelegate }?.setShortcutRecording(false)
    }

    private var shortcutDisplayText: String {
        if isRecordingShortcut {
            return shortcutRecordingPreview ?? L10n.t("settings.shortcut.recording")
        }
        return shortcut.displayText
    }

    private func settingTile(icon: String, title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(tint.opacity(0.95))
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.54))
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
            }

            Spacer()
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct ShortcutRecorder: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onPreview: (String?) -> Void
    let onRecord: (HaloShortcut) -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = RecorderView(frame: .zero)
        view.onPreview = onPreview
        view.onRecord = onRecord
        view.onCancel = onCancel
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? RecorderView else { return }
        view.onPreview = onPreview
        view.onRecord = onRecord
        view.onCancel = onCancel
        view.update(isRecording: isRecording)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {}

    final class RecorderView: NSView {
        var onPreview: ((String?) -> Void)?
        var onRecord: ((HaloShortcut) -> Void)?
        var onCancel: (() -> Void)?

        private var isRecording = false
        private var previousFirstResponder: NSResponder?
        private var monitor: Any?
        private var pendingCurrentShortcutCapture: DispatchWorkItem?
        private var mouseButtonEventTap: MouseButtonEventTap?

        override var acceptsFirstResponder: Bool { true }

        func update(isRecording newValue: Bool) {
            guard newValue != isRecording else { return }
            isRecording = newValue

            if newValue {
                previousFirstResponder = window?.firstResponder
                startMonitor()
                onPreview?(nil)
                NSApp.delegate.flatMap { $0 as? AppDelegate }?.setShortcutRecording(true)
                window?.makeFirstResponder(self)
            } else {
                cancelPendingCurrentShortcutCapture()
                stopMonitor()
                stopMouseButtonEventTap()
                if window?.firstResponder === self {
                    window?.makeFirstResponder(previousFirstResponder)
                }
                previousFirstResponder = nil
                NSApp.delegate.flatMap { $0 as? AppDelegate }?.setShortcutRecording(false)
            }
        }

        override func keyDown(with event: NSEvent) {
            guard isRecording else {
                super.keyDown(with: event)
                return
            }

            handle(event)
        }

        override func otherMouseDown(with event: NSEvent) {
            guard isRecording else {
                super.otherMouseDown(with: event)
                return
            }

            handle(event)
        }

        override func flagsChanged(with event: NSEvent) {
            guard isRecording else {
                super.flagsChanged(with: event)
                return
            }

            handle(event)
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if isRecording {
                window?.makeFirstResponder(self)
            }
        }

        private func startMonitor() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged, .otherMouseDown]) { [weak self] event in
                guard let self, self.isRecording else { return event }
                self.handle(event)
                return nil
            }
            startMouseButtonEventTap()
        }

        private func stopMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }

        private func startMouseButtonEventTap() {
            guard mouseButtonEventTap == nil else { return }
            let tap = MouseButtonEventTap(consumeEvents: true) { [weak self] buttonNumber in
                Task { @MainActor in
                    guard let self, self.isRecording else { return }
                    self.cancelPendingCurrentShortcutCapture()
                    self.onRecord?(.mouseButton(buttonNumber))
                }
            }
            if tap.start() {
                mouseButtonEventTap = tap
            }
        }

        private func stopMouseButtonEventTap() {
            mouseButtonEventTap?.stop()
            mouseButtonEventTap = nil
        }

        private func handle(_ event: NSEvent) {
            if event.type == .keyDown, event.keyCode == UInt16(kVK_Escape) {
                cancelPendingCurrentShortcutCapture()
                onCancel?()
                return
            }

            if event.type == .flagsChanged {
                onPreview?(HaloShortcut.recordingPreviewText(from: event))
                scheduleCurrentShortcutCaptureIfNeeded(for: event)
                return
            }

            if let preview = HaloShortcut.recordingPreviewText(from: event), event.type == .keyDown {
                onPreview?(preview)
            }

            if let shortcut = HaloShortcut.keyboard(from: event) ?? HaloShortcut.mouseButton(from: event) {
                cancelPendingCurrentShortcutCapture()
                onRecord?(shortcut)
            } else {
                NSSound.beep()
            }
        }

        private func scheduleCurrentShortcutCaptureIfNeeded(for event: NSEvent) {
            guard let currentModifiers = HaloShortcut.current.keyboardModifiers else {
                cancelPendingCurrentShortcutCapture()
                return
            }

            let pressedModifiers = HaloShortcut.carbonModifiers(from: event.modifierFlags)
            guard pressedModifiers == currentModifiers else {
                cancelPendingCurrentShortcutCapture()
                return
            }

            pendingCurrentShortcutCapture?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                guard let self, self.isRecording else { return }
                self.onRecord?(HaloShortcut.current)
            }
            pendingCurrentShortcutCapture = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
        }

        private func cancelPendingCurrentShortcutCapture() {
            pendingCurrentShortcutCapture?.cancel()
            pendingCurrentShortcutCapture = nil
        }
    }
}

private struct AddURLSheet: View {
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
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.56))
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

private struct SettingsHubPreview: View {
    let items: [HaloMenuItem]
    let showItemNames: Bool
    let iconSizePreference: HaloIconSizePreference
    let hubSizePreference: HaloHubSizePreference
    let appIconStyle: HaloAppIconStyle
    let onAddDroppedItem: (URL) -> Void
    let onRemoveItem: (HaloMenuItem.ID) -> Void
    let onMoveItem: (HaloMenuItem.ID, Int) -> Void

    @State private var isAppDropTarget = false
    @State private var isDeleteTarget = false
    @State private var draggingItemID: HaloMenuItem.ID?
    @State private var reorderTargetIndex: Int?
    @State private var dragTranslation: CGSize = .zero

    private var panelSize: CGFloat { hubSizePreference.panelSize }
    private var outerSize: CGFloat { hubSizePreference.outerSize }
    private var innerSectorRadius: CGFloat { hubSizePreference.innerSectorRadius }
    private var outerSectorRadius: CGFloat { hubSizePreference.outerSectorRadius }
    private var radius: CGFloat { hubSizePreference.itemRadius }
    private var center: CGFloat { panelSize / 2 }

    var body: some View {
        ZStack {
            HaloGlassBackground(size: outerSize)
                .overlay {
                    Circle()
                        .strokeBorder(Color.mint.opacity(isAppDropTarget ? 0.72 : 0), lineWidth: 2)
                        .frame(width: outerSize, height: outerSize)
                }

            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let sector = RingSector(
                    startAngle: sectorAngles(for: index, count: items.count).start,
                    endAngle: sectorAngles(for: index, count: items.count).end,
                    innerRadius: innerSectorRadius,
                    outerRadius: outerSectorRadius,
                    angularInset: 0
                )

                sector
                    .fill(Color.white.opacity(reorderTargetIndex == index ? 0.10 : 0))
                    .overlay {
                        sector
                            .stroke(Color.mint.opacity(reorderTargetIndex == index ? 0.22 : 0), lineWidth: 1)
                    }
                    .frame(width: panelSize, height: panelSize)
                    .contentShape(sector)
                    .gesture(reorderGesture(for: item, at: index))
            }

            ForEach(items.indices, id: \.self) { index in
                SectorDivider(
                    angle: sectorAngles(for: index, count: items.count).start,
                    innerRadius: innerSectorRadius,
                    outerRadius: outerSectorRadius
                )
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0), .white.opacity(0.12), .white.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.7
                )
                .frame(width: panelSize, height: panelSize)
            }

            HaloCenterGlassBackground(size: hubSizePreference.centerSize)
                .overlay(
                    Circle()
                        .fill(isDeleteTarget ? .red.opacity(0.24) : .clear)
                )
                .overlay {
                    if draggingItemID != nil {
                        VStack(spacing: 7) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 29, weight: .semibold))
                            Text("Remove")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                            Text("Drop here")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.78))
                        }
                    }
                }

            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                VStack(spacing: showItemNames ? 2 : 0) {
                    HaloMenuIconView(
                        icon: item.icon,
                        isHovered: false,
                        appIconStyle: appIconStyle,
                        size: iconSizePreference.normalIconSize,
                        symbolSize: iconSizePreference.normalSymbolSize
                    )
                    .frame(width: iconSizePreference.hoveredIconSize, height: iconSizePreference.hoveredIconSize)
                    if showItemNames {
                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.90))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .minimumScaleFactor(0.78)
                            .frame(width: 68)
                            .clipped()
                            .help(item.title)
                    }
                }
                .frame(width: 102, height: 102)
                .position(position(for: index, count: items.count))
                .offset(draggingItemID == item.id ? dragTranslation : .zero)
                .scaleEffect(draggingItemID == item.id ? 1.08 : 1)
                .opacity(draggingItemID == nil || draggingItemID == item.id ? 1 : 0.58)
                .zIndex(draggingItemID == item.id ? 10 : 1)
                .gesture(reorderGesture(for: item, at: index))
                .animation(.spring(response: 0.18, dampingFraction: 0.78), value: draggingItemID)
            }
        }
        .frame(width: panelSize, height: panelSize)
        .coordinateSpace(name: "hubPreview")
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isAppDropTarget) { providers in
            loadApplicationDrop(from: providers)
        }
    }

    private func loadApplicationDrop(from providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let url = DropItemDecoder.fileURL(from: item) else { return }
            Task { @MainActor in
                onAddDroppedItem(url)
            }
        }
        return true
    }

    private func reorderGesture(for item: HaloMenuItem, at index: Int) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("hubPreview"))
            .onChanged { value in
                draggingItemID = item.id
                let originalPosition = position(for: index, count: items.count)
                let currentPoint = value.location
                dragTranslation = CGSize(
                    width: currentPoint.x - originalPosition.x,
                    height: currentPoint.y - originalPosition.y
                )

                isDeleteTarget = isInsideDeleteTarget(currentPoint)
                reorderTargetIndex = isDeleteTarget ? nil : sectorIndex(at: currentPoint)
            }
            .onEnded { value in
                let finalPoint = value.location
                if isInsideDeleteTarget(finalPoint) {
                    onRemoveItem(item.id)
                } else if let finalTargetIndex = sectorIndex(at: finalPoint) {
                    onMoveItem(item.id, finalTargetIndex)
                }

                draggingItemID = nil
                reorderTargetIndex = nil
                isDeleteTarget = false
                dragTranslation = .zero
            }
    }
}

private enum DropItemDecoder {
    static func fileURL(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL {
            return url
        }
        if let data = item as? Data,
           let string = String(data: data, encoding: .utf8) {
            return URL(string: string)
        }
        if let string = item as? String {
            return URL(string: string)
        }
        return nil
    }
}

struct SectorDivider: Shape {
    let angle: Double
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.move(to: CGPoint(
            x: center.x + cos(angle) * innerRadius,
            y: center.y + sin(angle) * innerRadius
        ))
        path.addLine(to: CGPoint(
            x: center.x + cos(angle) * outerRadius,
            y: center.y + sin(angle) * outerRadius
        ))
        return path
    }
}

private extension SettingsHubPreview {
    func position(for index: Int, count: Int) -> CGPoint {
        let angle = centerAngle(for: index, count: count)
        return CGPoint(
            x: center + cos(angle) * radius,
            y: center + sin(angle) * radius
        )
    }

    func centerAngle(for index: Int, count: Int) -> Double {
        let startAngle = -Double.pi / 2
        let step = (Double.pi * 2) / Double(max(count, 1))
        return startAngle + step * Double(index)
    }

    func sectorAngles(for index: Int, count: Int) -> (start: Double, end: Double) {
        let step = (Double.pi * 2) / Double(max(count, 1))
        let centerAngle = centerAngle(for: index, count: count)
        return (centerAngle - step / 2, centerAngle + step / 2)
    }

    func isInsideDeleteTarget(_ point: CGPoint) -> Bool {
        hypot(point.x - center, point.y - center) <= 75
    }

    func sectorIndex(at point: CGPoint) -> Int? {
        let dx = point.x - center
        let dy = point.y - center
        let distance = hypot(dx, dy)
        guard distance >= innerSectorRadius, distance <= outerSectorRadius else {
            return nil
        }

        let pointerAngle = normalizedAngle(atan2(dy, dx))
        let step = (Double.pi * 2) / Double(max(items.count, 1))
        for index in items.indices {
            let angle = normalizedAngle(centerAngle(for: index, count: items.count))
            if angularDistance(pointerAngle, angle) <= step / 2 {
                return index
            }
        }
        return nil
    }

    func normalizedAngle(_ angle: Double) -> Double {
        let full = Double.pi * 2
        var result = angle.truncatingRemainder(dividingBy: full)
        if result < 0 {
            result += full
        }
        return result
    }

    func angularDistance(_ lhs: Double, _ rhs: Double) -> Double {
        let full = Double.pi * 2
        let diff = abs(lhs - rhs).truncatingRemainder(dividingBy: full)
        return min(diff, full - diff)
    }
}

private struct SettingsGlassBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.09, blue: 0.13),
                    Color(red: 0.12, green: 0.13, blue: 0.18),
                    Color(red: 0.06, green: 0.08, blue: 0.11)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if #available(macOS 26.0, *) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.001))
                    .glassEffect(.regular.tint(Color.white.opacity(0.06)).interactive(), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .padding(12)
            } else {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                    .opacity(0.88)
            }
        }
        .ignoresSafeArea()
    }
}
