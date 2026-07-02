import AppKit
import ApplicationServices
import CoreGraphics

enum SystemPermissionKind: CaseIterable, Identifiable {
    case accessibility
    case inputMonitoring

    var id: String {
        switch self {
        case .accessibility:
            return "accessibility"
        case .inputMonitoring:
            return "inputMonitoring"
        }
    }

    var title: String {
        switch self {
        case .accessibility:
            return L10n.t("settings.permissions.accessibility.title")
        case .inputMonitoring:
            return L10n.t("settings.permissions.inputMonitoring.title")
        }
    }

    var detail: String {
        switch self {
        case .accessibility:
            return L10n.t("settings.permissions.accessibility.detail")
        case .inputMonitoring:
            return L10n.t("settings.permissions.inputMonitoring.detail")
        }
    }

    var settingsURL: URL? {
        switch self {
        case .accessibility:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        case .inputMonitoring:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
        }
    }
}

struct SystemPermissionStatus: Equatable {
    let accessibilityGranted: Bool
    let inputMonitoringGranted: Bool

    var allRequiredGranted: Bool {
        accessibilityGranted && inputMonitoringGranted
    }

    func isGranted(_ kind: SystemPermissionKind) -> Bool {
        switch kind {
        case .accessibility:
            return accessibilityGranted
        case .inputMonitoring:
            return inputMonitoringGranted
        }
    }

    static var current: SystemPermissionStatus {
        SystemPermissionStatus(
            accessibilityGranted: AXIsProcessTrusted(),
            inputMonitoringGranted: CGPreflightListenEventAccess()
        )
    }
}

enum SystemPermissionService {
    static let firstLaunchNoticeKey = "systemPermissionFirstLaunchNoticeShown"

    static func request(_ kind: SystemPermissionKind) {
        switch kind {
        case .accessibility:
            let options: NSDictionary = [
                "AXTrustedCheckOptionPrompt": true
            ]
            _ = AXIsProcessTrustedWithOptions(options)
        case .inputMonitoring:
            _ = CGRequestListenEventAccess()
        }
    }

    static func openSettings(for kind: SystemPermissionKind) {
        if let url = kind.settingsURL, NSWorkspace.shared.open(url) {
            return
        }

        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
    }
}
