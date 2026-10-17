import AppKit
import Sparkle
import SwiftUI

@main
struct PopDeckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsWindowRedirect().frame(width: 1, height: 1)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(L10n.t("menu.settings")) { SettingsWindowController.shared.show() }
                    .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(after: .appSettings) {
                Button(L10n.t("menu.show")) {
                    HaloPanelController.shared.show(at: NSEvent.mouseLocation)
                }
                .keyboardShortcut("h", modifiers: [.command, .option])
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let hotKeyService = HotKeyService()
    private let singleInstanceGuard = SingleInstanceGuard()
    private var updaterController: SPUStandardUpdaterController?
    private var updaterLanguage: AppLanguage?
    private var shortcutRecordingHandler: ((HaloShortcut) -> Void)?

    private static var canStartSparkleUpdater: Bool {
        !AppIdentity.isDevelopment
            && Bundle.main.bundleURL.pathExtension == "app"
            && Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil
            && Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") != nil
    }

    private func localizedUpdaterController() -> SPUStandardUpdaterController? {
        guard Self.canStartSparkleUpdater else {
            NSLog("PopDeck Sparkle updater is disabled because the app is not running from a packaged .app bundle.")
            updaterController = nil
            updaterLanguage = nil
            return nil
        }

        let language = AppLanguage.current
        if let updaterController, updaterLanguage == language {
            return updaterController
        }

        UserDefaults.standard.set(language.sparkleAppleLanguages, forKey: "AppleLanguages")
        UserDefaults.standard.set(language.sparkleAppleLocale, forKey: "AppleLocale")
        UserDefaults.standard.synchronize()

        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        updaterController = controller
        updaterLanguage = language
        return controller
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard singleInstanceGuard.acquire() else {
            NSApp.terminate(nil)
            return
        }

        L10n.registerDefaults()
        NSApp.setActivationPolicy(.accessory)
        setupApplicationIcon()
        setupStatusItem()
        // Start Sparkle's scheduler at launch, honoring its stored consent and
        // automatic-check preferences instead of waiting for a menu click.
        if let updater = localizedUpdaterController()?.updater,
           updater.automaticallyChecksForUpdates {
            // Sparkle permits a launch-time background check immediately after
            // startup. Keep automatic-check consent and skipped versions intact.
            updater.checkForUpdatesInBackground()
        }
        hotKeyService.onInvoke = { [weak self] in
            Task { @MainActor in
                self?.toggleHalo()
            }
        }
        hotKeyService.onCaptureWhileRecording = { [weak self] shortcut in
            Task { @MainActor in
                self?.captureRecordedShortcut(shortcut)
            }
        }
        hotKeyService.start()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shortcutDidChange),
            name: HaloShortcut.didChangeNotification,
            object: nil
        )
        presentPermissionNoticeIfNeeded()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(where: { $0 == "--verify-glass" || $0 == "--verify-glass-inactive" || $0 == "--preview-panel" }), let screen = NSScreen.main {
            DispatchQueue.main.async {
                SettingsWindowController.shared.window?.orderOut(nil)
                HaloPanelController.shared.show(at: NSPoint(x: screen.visibleFrame.midX, y: screen.visibleFrame.midY))
            }
        }
        #endif
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
        hotKeyService.stop()
    }

    private func setupApplicationIcon() {
        let iconImage = Bundle.main.url(forResource: "AppIcon", withExtension: "icns")
            .flatMap(NSImage.init(contentsOf:))
            ?? Bundle.main.url(forResource: "AppIcon-1024", withExtension: "png")
                .flatMap(NSImage.init(contentsOf:))

        guard let iconImage else {
            return
        }

        NSApp.applicationIconImage = iconImage
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        button.image = menuBarIconImage()
        button.toolTip = AppIdentity.displayName
        if AppIdentity.isDevelopment { button.title = " Dev" }
        button.action = #selector(statusItemClicked)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func menuBarIconImage() -> NSImage? {
        let image = Bundle.main.url(forResource: "MenuBarIcon-template", withExtension: "png")
            .flatMap(NSImage.init(contentsOf:))
            ?? NSImage(systemSymbolName: "circle.hexagongrid.circle", accessibilityDescription: "PopDeck")

        image?.isTemplate = true
        image?.size = NSSize(width: 18, height: 18)
        image?.accessibilityDescription = "PopDeck"
        return image
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        showStatusMenu()
    }

    private func showStatusMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: L10n.t("menu.show"), action: #selector(showHalo), keyEquivalent: "h"))
        menu.addItem(NSMenuItem(title: L10n.t("menu.settings"), action: #selector(showSettings), keyEquivalent: ","))
        let checkForUpdatesItem: NSMenuItem
        if let updaterController = localizedUpdaterController() {
            checkForUpdatesItem = NSMenuItem(
                title: L10n.t("menu.checkForUpdates"),
                action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
                keyEquivalent: ""
            )
            checkForUpdatesItem.target = updaterController
            checkForUpdatesItem.isEnabled = updaterController.updater.canCheckForUpdates
        } else {
            checkForUpdatesItem = NSMenuItem(title: L10n.t("menu.checkForUpdatesUnavailable"), action: nil, keyEquivalent: "")
            checkForUpdatesItem.isEnabled = false
        }
        menu.addItem(checkForUpdatesItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L10n.t("menu.quit"), action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func showHalo() {
        guard !ShortcutRecordingState.shouldSuppressInvocation else { return }
        guard !ShortcutRecordingState.isRecording else {
            captureRecordedShortcut(HaloShortcut.current)
            return
        }
        HaloPanelController.shared.show(at: NSEvent.mouseLocation)
    }

    private func toggleHalo() {
        guard !ShortcutRecordingState.shouldSuppressInvocation else { return }
        guard !ShortcutRecordingState.isRecording else {
            captureRecordedShortcut(HaloShortcut.current)
            return
        }
        if HaloPanelController.shared.isVisible {
            HaloPanelController.shared.hide()
        } else {
            HaloPanelController.shared.show(at: NSEvent.mouseLocation)
        }
    }

    @objc private func shortcutDidChange() {
        guard !hotKeyServiceIsRecording else { return }
        hotKeyService.start()
    }

    private var hotKeyServiceIsRecording = false

    func setShortcutRecording(_ isRecording: Bool) {
        setShortcutRecording(isRecording, onCapture: shortcutRecordingHandler)
    }

    func setShortcutRecording(_ isRecording: Bool, onCapture: ((HaloShortcut) -> Void)?) {
        shortcutRecordingHandler = isRecording ? onCapture : nil
        hotKeyServiceIsRecording = isRecording
        if isRecording {
            ShortcutRecordingState.begin()
            hotKeyService.setSuspended(true)
        } else {
            ShortcutRecordingState.end()
            hotKeyService.setSuspended(false)
        }
    }

    private func captureRecordedShortcut(_ shortcut: HaloShortcut) {
        guard ShortcutRecordingState.isRecording else { return }
        shortcutRecordingHandler?(shortcut)
    }

    @objc private func showSettings() {
        SettingsWindowController.shared.show()
    }

    private func presentPermissionNoticeIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: SystemPermissionService.firstLaunchNoticeKey) else { return }

        let status = SystemPermissionStatus.current
        guard !status.allRequiredGranted else { return }
        defaults.set(true, forKey: SystemPermissionService.firstLaunchNoticeKey)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            NSApp.activate(ignoringOtherApps: true)

            let alert = NSAlert()
            alert.messageText = L10n.t("permissions.launch.title")
            alert.informativeText = L10n.t("permissions.launch.message")
            alert.alertStyle = .informational
            alert.addButton(withTitle: L10n.t("permissions.launch.openSettings"))
            alert.addButton(withTitle: L10n.t("permissions.launch.later"))

            if alert.runModal() == .alertFirstButtonReturn {
                SystemPermissionKind.allCases.forEach { SystemPermissionService.request($0) }
                let firstMissing = SystemPermissionKind.allCases.first { !status.isGranted($0) } ?? .accessibility
                SystemPermissionService.openSettings(for: firstMissing)
                SettingsWindowController.shared.show()
            }
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

@MainActor
final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.identifier = NSUserInterfaceItemIdentifier("PopDeckSettingsWindow")
        window.title = AppIdentity.settingsTitle(L10n.t("settings.window.title"))
        window.contentMinSize = NSSize(width: 1060, height: 520)
        window.center()
        window.isReleasedWhenClosed = false
        let hosting = NSHostingView(rootView: SettingsView())
        hosting.sizingOptions = [.minSize]
        window.contentView = hosting
        window.setFrameUsingName("PopDeckSettingsWindow")
        window.setFrameAutosaveName("PopDeckSettingsWindow")
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        refreshTitle()
        window?.makeKeyAndOrderFront(nil)
    }

    func growForPreview(_ diameter: CGFloat) {
        guard let window, let screen = window.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        let content = window.contentRect(forFrameRect: window.frame)
        let titleHeight = window.frame.height - content.height
        let target = SettingsWindowSizing.contentSize(current: content.size,
            screen: CGSize(width: visible.width, height: visible.height - titleHeight), previewDiameter: diameter)
        guard target.width > content.width + 1 || target.height > content.height + 1 else { return }
        var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: target))
        frame.origin.x = max(visible.minX, min(window.frame.minX, visible.maxX - frame.width))
        frame.origin.y = max(visible.minY, min(window.frame.maxY - frame.height, visible.maxY - frame.height))
        window.setFrame(frame, display: true, animate: false)
    }

    func refreshTitle() {
        window?.title = AppIdentity.settingsTitle(L10n.t("settings.window.title"))
    }
}
