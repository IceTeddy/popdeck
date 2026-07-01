import AppKit
import Carbon.HIToolbox

final class HotKeyService {
    var onInvoke: (() -> Void)?
    var onCaptureWhileRecording: ((HaloShortcut) -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var mouseButtonEventTap: MouseButtonEventTap?
    private var keyboardEventTap: KeyboardShortcutEventTap?
    private var isSuspended = false

    func start() {
        stop()
        guard !isSuspended else { return }

        switch HaloShortcut.current {
        case .keyboard(let keyCode, let modifiers):
            NSLog("PopDeck starting keyboard shortcut keyCode=\(keyCode), modifiers=\(modifiers)")
            startKeyboardHotKey(keyCode: keyCode, modifiers: modifiers)
        case .mouseButton(let buttonNumber):
            NSLog("PopDeck starting mouse shortcut button=\(buttonNumber)")
            startMouseButtonHotKey(buttonNumber: buttonNumber)
        }
    }

    private func startKeyboardHotKey(keyCode: UInt32, modifiers: UInt32) {
        let keyboardTap = KeyboardShortcutEventTap(keyCode: keyCode, modifiers: modifiers, consumeEvents: true) { [weak self] in
            guard let self else { return }
            if ShortcutRecordingState.isRecording {
                self.onCaptureWhileRecording?(HaloShortcut.current)
            } else if !self.isSuspended {
                self.onInvoke?()
            }
        }
        if keyboardTap.start() {
            keyboardEventTap = keyboardTap
        }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData else { return noErr }
                let service = Unmanaged<HotKeyService>.fromOpaque(userData).takeUnretainedValue()
                if ShortcutRecordingState.isRecording {
                    service.onCaptureWhileRecording?(HaloShortcut.current)
                    return noErr
                }
                if !service.isSuspended {
                    service.onInvoke?()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        let hotKeyID = EventHotKeyID(signature: fourCharCode("POPD"), id: 1)
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if status != noErr {
            NSLog("PopDeck failed to register hotkey. Carbon status: \(status)")
        } else {
            NSLog("PopDeck registered Carbon hotkey keyCode=\(keyCode), modifiers=\(modifiers)")
        }
    }

    private func startMouseButtonHotKey(buttonNumber: Int) {
        let tap = MouseButtonEventTap(buttonNumber: buttonNumber, consumeEvents: true) { [weak self] _ in
            guard let self else { return }
            if ShortcutRecordingState.isRecording {
                self.onCaptureWhileRecording?(HaloShortcut.current)
            } else if !self.isSuspended {
                self.onInvoke?()
            }
        }
        if tap.start() {
            mouseButtonEventTap = tap
        }

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.otherMouseDown]) { [weak self] event in
            guard let self else { return event }
            if event.buttonNumber == buttonNumber, ShortcutRecordingState.isRecording {
                self.onCaptureWhileRecording?(HaloShortcut.current)
                return nil
            }
            if event.buttonNumber == buttonNumber, !self.isSuspended {
                self.onInvoke?()
                return nil
            }
            return event
        }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.otherMouseDown]) { [weak self] event in
            if event.buttonNumber == buttonNumber, ShortcutRecordingState.isRecording {
                self?.onCaptureWhileRecording?(HaloShortcut.current)
                return
            }
            guard let self, event.buttonNumber == buttonNumber, !self.isSuspended else { return }
            self.onInvoke?()
        }
    }

    func setSuspended(_ suspended: Bool) {
        isSuspended = suspended
        if !suspended {
            start()
        }
    }

    func stop() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
        mouseButtonEventTap?.stop()
        mouseButtonEventTap = nil
        keyboardEventTap?.stop()
        keyboardEventTap = nil
    }

    private func fourCharCode(_ value: String) -> OSType {
        value.utf8.reduce(0) { ($0 << 8) + OSType($1) }
    }
}
