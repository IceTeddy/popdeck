import AppKit
import Sparkle
import SwiftUI

@main
struct PopDeckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
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
        Bundle.main.bundleURL.pathExtension == "app"
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

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

@MainActor
final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 660, height: 640),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.t("settings.window.title")
        window.minSize = NSSize(width: 620, height: 520)
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsView())
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        refreshTitle()
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    func refreshTitle() {
        window?.title = L10n.t("settings.window.title")
    }
}
