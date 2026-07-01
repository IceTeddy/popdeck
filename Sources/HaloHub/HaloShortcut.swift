import AppKit
import Carbon.HIToolbox

enum HaloShortcut: Codable, Equatable {
    case keyboard(keyCode: UInt32, modifiers: UInt32)
    case mouseButton(Int)

    static let storageKey = "haloShortcut"
    static let didChangeNotification = Notification.Name("HaloShortcutDidChange")
    static let defaultShortcut = HaloShortcut.mouseButton(2)

    static var current: HaloShortcut {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let shortcut = try? JSONDecoder().decode(HaloShortcut.self, from: data) else {
            return defaultShortcut
        }
        return shortcut
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }

    var displayText: String {
        switch self {
        case .keyboard(let keyCode, let modifiers):
            return "\(modifierDisplayText(modifiers))\(keyDisplayText(keyCode))"
        case .mouseButton(let buttonNumber):
            if buttonNumber == 2 {
                return L10n.t("settings.shortcut.middleMouseButton")
            }
            return String(format: L10n.t("settings.shortcut.mouseButton"), buttonNumber)
        }
    }

    var keyboardModifiers: UInt32? {
        guard case .keyboard(_, let modifiers) = self else { return nil }
        return modifiers
    }

    static func keyboard(from event: NSEvent) -> HaloShortcut? {
        guard event.type == .keyDown, event.keyCode != UInt16(kVK_Escape) else { return nil }

        let modifiers = carbonModifiers(from: event.modifierFlags)
        return .keyboard(keyCode: UInt32(event.keyCode), modifiers: modifiers)
    }

    static func mouseButton(from event: NSEvent) -> HaloShortcut? {
        guard event.type == .otherMouseDown else { return nil }
        return .mouseButton(event.buttonNumber)
    }

    static func recordingPreviewText(from event: NSEvent) -> String? {
        let modifiers = carbonModifiers(from: event.modifierFlags)
        guard modifiers != 0 else { return nil }

        let parts = modifierSymbols(modifiers)
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " + ") + " +"
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        return result
    }

    private static func modifierSymbols(_ modifiers: UInt32) -> [String] {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        return parts
    }

    private func modifierDisplayText(_ modifiers: UInt32) -> String {
        Self.modifierSymbols(modifiers).joined()
    }

    private func keyDisplayText(_ keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_Grave:
            return "`"
        case kVK_Space:
            return "Space"
        case kVK_Return:
            return "Return"
        case kVK_Tab:
            return "Tab"
        case kVK_Delete:
            return "Delete"
        case kVK_Escape:
            return "Esc"
        case kVK_UpArrow:
            return "↑"
        case kVK_DownArrow:
            return "↓"
        case kVK_LeftArrow:
            return "←"
        case kVK_RightArrow:
            return "→"
        default:
            return keyCharacters(for: keyCode)
        }
    }

    private func keyCharacters(for keyCode: UInt32) -> String {
        let source = TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
        guard let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return "Key \(keyCode)"
        }

        let data = Unmanaged<CFData>.fromOpaque(layoutData).takeUnretainedValue() as Data
        return data.withUnsafeBytes { buffer in
            guard let keyboardLayout = buffer.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else {
                return "Key \(keyCode)"
            }

            var deadKeyState: UInt32 = 0
            var length = 0
            var chars = [UniChar](repeating: 0, count: 4)
            let status = UCKeyTranslate(
                keyboardLayout,
                UInt16(keyCode),
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                chars.count,
                &length,
                &chars
            )

            guard status == noErr, length > 0 else { return "Key \(keyCode)" }
            return String(utf16CodeUnits: chars, count: length).uppercased()
        }
    }
}

enum ShortcutRecordingState {
    nonisolated(unsafe) private(set) static var isRecording = false
    nonisolated(unsafe) private static var suppressInvocationUntil = Date.distantPast

    static func begin() {
        isRecording = true
    }

    static func end() {
        isRecording = false
    }

    static func suppressInvocationsBriefly() {
        suppressInvocationUntil = Date().addingTimeInterval(0.8)
    }

    static var shouldSuppressInvocation: Bool {
        Date() < suppressInvocationUntil
    }
}
