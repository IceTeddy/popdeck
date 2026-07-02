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
    private var presentationID = 0
    private var hideRequestID = 0

    var isVisible: Bool {
        panel?.isVisible == true
    }

    private init() {}

    func show(at screenPoint: NSPoint) {
        guard !ShortcutRecordingState.shouldSuppressInvocation else { return }
        guard !ShortcutRecordingState.isRecording else { return }

        if isHiding {
            panel?.orderOut(nil)
            isHiding = false
        }

        hideRequestID += 1
        if panel == nil {
            panel = makePanel()
        }

        guard let panel else { return }
        presentationID += 1
        let size = currentPanelSize
        let origin = NSPoint(
            x: screenPoint.x - size.width / 2,
            y: screenPoint.y - size.height / 2
        )
        panel.setFrame(NSRect(origin: origin, size: size), display: false)
        updateContentView()
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: false)
        startOutsideClickMonitoring()
        publishHoverLocation(onScreen: NSEvent.mouseLocation)
    }

    func hide() {
        guard let panel, panel.isVisible, !isHiding else { return }
        isHiding = true
        hideRequestID += 1
        let requestID = hideRequestID
        stopOutsideClickMonitoring()
        NotificationCenter.default.post(name: .haloPanelWillClose, object: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            guard let self else { return }
            guard self.hideRequestID == requestID else { return }
            panel.orderOut(nil)
            self.isHiding = false
        }
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: currentPanelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.acceptsMouseMovedEvents = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        updateContentView()
        panel.contentView = hostingView
        return panel
    }

    private func updateContentView() {
        let view = HaloPanelView(
            items: HaloMenuStore.shared.items,
            showItemNames: UserDefaults.standard.bool(forKey: AppPreferences.showItemNamesKey),
            iconSizePreference: HaloIconSizePreference.current,
            hubSizePreference: HaloHubSizePreference.current,
            appIconStyle: HaloAppIconStyle.current,
            presentationID: presentationID,
            onClose: { [weak self] in self?.hide() }
        )

        if let hostingView {
            hostingView.rootView = view
        } else {
            hostingView = NSHostingView(rootView: view)
        }
    }

    private func startOutsideClickMonitoring() {
        stopOutsideClickMonitoring()

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .mouseMoved]) { [weak self] event in
            guard let self else { return event }
            if event.type == .mouseMoved {
                self.publishHoverLocation(onScreen: NSEvent.mouseLocation)
                return event
            }
            if !self.isPointInsideHubCircle(NSEvent.mouseLocation) {
                self.hide()
            }
            return event
        }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if !self.isPointInsideHubCircle(NSEvent.mouseLocation) {
                    self.hide()
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
        return hypot(screenPoint.x - center.x, screenPoint.y - center.y) <= HaloHubSizePreference.current.hitRadius
    }

    private var currentPanelSize: NSSize {
        let size = HaloHubSizePreference.current.panelSize
        return NSSize(width: size, height: size)
    }
}

extension Notification.Name {
    static let haloPanelWillClose = Notification.Name("HaloPanelWillClose")
    static let haloPanelMouseMoved = Notification.Name("HaloPanelMouseMoved")
}
