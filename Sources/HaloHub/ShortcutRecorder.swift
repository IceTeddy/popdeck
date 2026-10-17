import SwiftUI
import Carbon.HIToolbox

struct ShortcutRecorder: NSViewRepresentable {
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
