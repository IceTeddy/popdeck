import AppKit
import SwiftUI

@MainActor
final class HaloPanelController {
    static let shared = HaloPanelController()

    private var panel: NSPanel?
    private var hostingView: NSHostingView<HaloPanelView>?
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var isHiding = false
    private var isOrderingOut = false
    private var presentationID = 0
    private var hideRequestID = 0
    private var renderScale: CGFloat = 1
    private var clickGate = HaloPanelClickGate()
    private let focusRecovery = HaloPanelFocusRecovery()

    var isVisible: Bool {
        panel?.isVisible == true
    }

    private init() {}

    func show(at screenPoint: NSPoint) {
        guard !ShortcutRecordingState.shouldSuppressInvocation else { return }
        guard !ShortcutRecordingState.isRecording else { return }

        if isHiding, let panel {
            orderOutPanel(panel)
        }

        hideRequestID += 1
        if panel == nil {
            panel = makePanel()
        }

        guard let panel else { return }
        presentationID += 1
        let intrinsic = intrinsicPanelSize
        let screen = NSScreen.screens.first { $0.frame.contains(screenPoint) } ?? NSScreen.main
        let available = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 900)
        renderScale = min(1, min(available.width - 16, available.height - 16) / intrinsic)
        let size = currentPanelSize
        let origin = NSPoint(
            x: max(available.minX, min(available.maxX - size.width, screenPoint.x - size.width / 2)),
            y: max(available.minY, min(available.maxY - size.height, screenPoint.y - size.height / 2))
        )
        panel.setFrame(NSRect(origin: origin, size: size), display: false)
        updateContentView()
        startOutsideClickMonitoring()
        let request = presentationID
        focusRecovery.begin(isCurrent: { [weak self, weak panel] in
            guard let self, let panel else { return false }
            return self.panel === panel && panel.isVisible && !self.isHiding && !self.isOrderingOut
                && self.presentationID == request
        }, repair: { [weak self, weak panel] in
            guard let self, let panel else { return }
            if NSApp.isActive && panel.canBecomeKey && !panel.isKeyWindow {
                panel.makeKeyAndOrderFront(nil)
            }
            HaloPanelFocusRecovery.record("activation-recheck", panel: panel)
            // SwiftUI subscriptions and entrance state are now ready to receive hover.
            self.publishHoverLocation(onScreen: NSEvent.mouseLocation)
        })
        NSApp.activate(ignoringOtherApps: true)
        if panel.canBecomeKey {
            panel.makeKeyAndOrderFront(nil)
        } else {
            panel.orderFrontRegardless()
        }
        HaloPanelFocusRecovery.record("presented", panel: panel)
        publishHoverLocation(onScreen: NSEvent.mouseLocation)
    }

    func hide(immediately: Bool = false) {
        guard let panel, panel.isVisible, !isOrderingOut else { return }
        // Focus loss can interrupt an exit already waiting for its animation.
        guard immediately || !isHiding else { return }
        isHiding = true
        hideRequestID += 1
        let requestID = hideRequestID
        stopOutsideClickMonitoring()
        if immediately {
            orderOutPanel(panel)
            return
        }
        NotificationCenter.default.post(name: .haloPanelWillClose, object: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            guard let self else { return }
            guard self.hideRequestID == requestID else { return }
            self.orderOutPanel(panel)
        }
    }

    private func orderOutPanel(_ panel: NSPanel) {
        // orderOut itself can resign key; avoid re-entering the focus-loss handler.
        guard !isOrderingOut else { return }
        isOrderingOut = true
        panel.orderOut(nil)
        HaloPanelFocusRecovery.record("dismissed", panel: panel)
        isOrderingOut = false
        isHiding = false
    }

    private func makePanel() -> NSPanel {
        let panel = HaloFloatingPanel(
            contentRect: NSRect(origin: .zero, size: currentPanelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.onWillResignKey = { [weak self] in
            // Hide before native glass switches to its inactive, heavily tinted state.
            self?.hide(immediately: true)
        }
        panel.title = "PopDeck Panel"
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.acceptsMouseMovedEvents = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        updateContentView()
        panel.contentView = hostingView
        return panel
    }

    private func updateContentView() {
        let view = HaloPanelView(items: HaloMenuStore.shared.items,
            showItemNames: UserDefaults.standard.bool(forKey: AppPreferences.showItemNamesKey),
            appearance: FreePanelConfiguration.shared.appearance, presentationID: presentationID,
            onClose: { [weak self] in self?.hide() }, renderScale: renderScale)

        if let hostingView {
            hostingView.rootView = view
        } else {
            hostingView = NSHostingView(rootView: view)
        }
    }

    private func startOutsideClickMonitoring() {
        stopOutsideClickMonitoring()

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp, .rightMouseDown, .mouseMoved]) { [weak self] event in
            guard let self else { return event }
            if event.type == .mouseMoved {
                self.publishHoverLocation(onScreen: NSEvent.mouseLocation)
                return event
            }
            // Route base-ring clicks before native glass/hosting views can swallow them.
            if event.type == .leftMouseUp, self.clickGate.finish() {
                if let panel = self.panel, panel.isVisible, event.window === panel, let hosting = self.hostingView {
                    let point = hosting.convert(event.locationInWindow, from: nil)
                    NotificationCenter.default.post(name: .haloPanelSelection, object: NSValue(point: point))
                }
                return nil
            }
            if event.type == .leftMouseDown, event.window === self.panel,
               self.clickGate.begin(inside: self.isPointInsideHubCircle(NSEvent.mouseLocation), groupExpanded: false) {
                return nil
            }
            if !self.isPointInsideHubCircle(NSEvent.mouseLocation) {
                self.hide(immediately: true)
            }
            return event
        }

        let request = presentationID
        // Global monitors see other apps' events, local monitors see ours. Keep
        // hover working during activation instead of depending on key-window timing.
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .mouseMoved]) { [weak self] event in
            let isMovement = event.type == .mouseMoved
            Task { @MainActor in
                guard let self, self.panel?.isVisible == true, !self.isHiding,
                      self.presentationID == request else { return }
                if isMovement {
                    self.publishHoverLocation(onScreen: NSEvent.mouseLocation)
                } else if !self.isPointInsideHubCircle(NSEvent.mouseLocation) {
                    self.hide(immediately: true)
                }
            }
        }
    }

    private func publishHoverLocation(inWindow windowPoint: NSPoint) {
        guard let panel, panel.isVisible else { return }
        guard let hostingView else { return }
        let viewPoint = hostingView.convert(windowPoint, from: nil)
        NotificationCenter.default.post(
            name: .haloPanelMouseMoved,
            object: NSValue(point: viewPoint)
        )
    }

    private func publishHoverLocation(onScreen screenPoint: NSPoint) {
        guard let panel, panel.isVisible else { return }
        publishHoverLocation(inWindow: panel.convertPoint(fromScreen: screenPoint))
    }

    private func stopOutsideClickMonitoring() {
        focusRecovery.cancel()
        clickGate.reset()
        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
    }

    private func isPointInsideHubCircle(_ screenPoint: NSPoint) -> Bool {
        guard let panel, panel.isVisible else { return false }
        let frame = panel.frame
        let center = NSPoint(x: frame.midX, y: frame.midY)
        return hypot(screenPoint.x - center.x, screenPoint.y - center.y) <=
            (SinglePanelMetrics(appearance: FreePanelConfiguration.shared.appearance).outerRadius + 4) * renderScale
    }

    private var intrinsicPanelSize: CGFloat {
        SinglePanelMetrics(appearance: FreePanelConfiguration.shared.appearance).panelSize
    }

    private var currentPanelSize: NSSize {
        let size = intrinsicPanelSize * renderScale
        return NSSize(width: size, height: size)
    }

}

extension Notification.Name {
    static let haloPanelWillClose = Notification.Name("HaloPanelWillClose")
    static let haloPanelSelection = Notification.Name("HaloPanelSelection")
    static let haloPanelMouseMoved = Notification.Name("HaloPanelMouseMoved")
}

/// A borderless NSPanel is not key-capable by default. Native glass distinguishes
/// active and inactive windows, so a visible launcher must be able to become key.
private final class HaloFloatingPanel: NSPanel {
    var onWillResignKey: (() -> Void)?

    override func resignKey() {
        onWillResignKey?()
        super.resignKey()
    }

    override var canBecomeKey: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--verify-glass-inactive") { return false }
        #endif
        return true
    }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        HaloPanelController.shared.hide()
    }
}
