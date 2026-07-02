import Foundation
import CoreGraphics

enum AppLanguage: String, CaseIterable, Identifiable {
    case zhHans = "zh-Hans"
    case en = "en"

    static let storageKey = "appLanguage"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zhHans:
            return "中文"
        case .en:
            return "English"
        }
    }

    var pickerLabel: String {
        switch self {
        case .zhHans:
            return "🇨🇳 中文"
        case .en:
            return "🇺🇸 English"
        }
    }

    static var current: AppLanguage {
        let rawValue = UserDefaults.standard.string(forKey: storageKey) ?? AppLanguage.zhHans.rawValue
        return AppLanguage(rawValue: rawValue) ?? .zhHans
    }

    var sparkleAppleLanguages: [String] {
        switch self {
        case .zhHans:
            return ["zh_CN", "zh-Hans", "zh", "en"]
        case .en:
            return ["en"]
        }
    }

    var sparkleAppleLocale: String {
        switch self {
        case .zhHans:
            return "zh_CN"
        case .en:
            return "en_US"
        }
    }
}

enum AppPreferences {
    static let showItemNamesKey = "showItemNames"
    static let iconSizeKey = "iconSize"
    static let appIconStyleKey = "appIconStyle"
    static let hubSizeKey = "hubSize"
}

enum HaloIconSizePreference: String, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .small:
            return L10n.t("settings.iconSize.small")
        case .medium:
            return L10n.t("settings.iconSize.medium")
        case .large:
            return L10n.t("settings.iconSize.large")
        }
    }

    var normalIconSize: CGFloat {
        switch self {
        case .small:
            return 32
        case .medium:
            return 44
        case .large:
            return 58
        }
    }

    var hoveredIconSize: CGFloat {
        switch self {
        case .small:
            return 36
        case .medium:
            return 48
        case .large:
            return 64
        }
    }

    var normalSymbolSize: CGFloat {
        switch self {
        case .small:
            return 19
        case .medium:
            return 27
        case .large:
            return 36
        }
    }

    var hoveredSymbolSize: CGFloat {
        switch self {
        case .small:
            return 22
        case .medium:
            return 31
        case .large:
            return 40
        }
    }

    static var current: HaloIconSizePreference {
        let rawValue = UserDefaults.standard.string(forKey: AppPreferences.iconSizeKey) ?? HaloIconSizePreference.medium.rawValue
        return HaloIconSizePreference(rawValue: rawValue) ?? .medium
    }
}

enum HaloHubSizePreference: String, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .small:
            return L10n.t("settings.hubSize.small")
        case .medium:
            return L10n.t("settings.hubSize.medium")
        case .large:
            return L10n.t("settings.hubSize.large")
        }
    }

    var panelSize: CGFloat { scaled(550) }
    var outerSize: CGFloat { scaled(448) }
    var innerSectorRadius: CGFloat { scaled(78) }
    var outerSectorRadius: CGFloat { scaled(224) }
    var itemRadius: CGFloat { scaled(160) }
    var centerSize: CGFloat { scaled(150) }
    var hitRadius: CGFloat { scaled(228) }
    var previewFrameHeight: CGFloat { panelSize - scaled(74) }

    private var scale: CGFloat {
        switch self {
        case .small:
            return 0.80
        case .medium:
            return 0.90
        case .large:
            return 1.00
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    static var current: HaloHubSizePreference {
        let rawValue = UserDefaults.standard.string(forKey: AppPreferences.hubSizeKey) ?? HaloHubSizePreference.small.rawValue
        return HaloHubSizePreference(rawValue: rawValue) ?? .small
    }
}

enum HaloAppIconStyle: String, CaseIterable, Identifiable {
    case original
    case monochrome

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .original:
            return L10n.t("settings.appIconStyle.original")
        case .monochrome:
            return L10n.t("settings.appIconStyle.monochrome")
        }
    }

    static var current: HaloAppIconStyle {
        let storedRawValue = UserDefaults.standard.string(forKey: AppPreferences.appIconStyleKey)
        if ["grayscale", "softMonochrome", "silhouette"].contains(storedRawValue) {
            UserDefaults.standard.set(HaloAppIconStyle.original.rawValue, forKey: AppPreferences.appIconStyleKey)
            return .original
        }

        let rawValue = storedRawValue ?? HaloAppIconStyle.original.rawValue
        return HaloAppIconStyle(rawValue: rawValue) ?? .original
    }
}

enum L10n {
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            AppLanguage.storageKey: AppLanguage.zhHans.rawValue,
            AppPreferences.showItemNamesKey: true,
            AppPreferences.iconSizeKey: HaloIconSizePreference.medium.rawValue,
            AppPreferences.appIconStyleKey: HaloAppIconStyle.original.rawValue,
            AppPreferences.hubSizeKey: HaloHubSizePreference.small.rawValue,
            HaloShortcut.storageKey: (try? JSONEncoder().encode(HaloShortcut.defaultShortcut)) ?? Data()
        ])
    }

    static func t(_ key: String) -> String {
        strings[AppLanguage.current]?[key] ?? strings[.zhHans]?[key] ?? key
    }

    private static let strings: [AppLanguage: [String: String]] = [
        .zhHans: [
            "menu.show": "显示 PopDeck",
            "menu.settings": "设置",
            "menu.checkForUpdates": "检查更新...",
            "menu.checkForUpdatesUnavailable": "检查更新不可用",
            "menu.quit": "退出 PopDeck",
            "settings.window.title": "PopDeck 设置",
            "settings.subtitle": "弹出式启动器偏好设置",
            "settings.hubHint": "拖入应用或文件来添加，拖动扇形区域调整顺序，拖到中心可移除。",
            "settings.shortcut.title": "快捷键",
            "settings.shortcut.value": "鼠标滚轮按下",
            "settings.shortcut.recording": "按下快捷键或鼠标功能键...",
            "settings.shortcut.middleMouseButton": "鼠标滚轮按下",
            "settings.shortcut.mouseButton": "鼠标按键 %d",
            "settings.launcher.title": "启动器",
            "settings.launcher.value": "%d 个默认操作",
            "settings.language.title": "语言",
            "settings.language.value": "中文",
            "settings.showNames.title": "显示名称",
            "settings.launchAtLogin.title": "开机自动启动",
            "settings.iconSize.title": "图标尺寸",
            "settings.iconSize.small": "小",
            "settings.iconSize.medium": "中",
            "settings.iconSize.large": "大",
            "settings.hubSize.title": "面板尺寸",
            "settings.hubSize.small": "小",
            "settings.hubSize.medium": "中",
            "settings.hubSize.large": "大",
            "settings.appIconStyle.title": "App 图标风格",
            "settings.appIconStyle.original": "原始",
            "settings.appIconStyle.monochrome": "单色",
            "settings.openApplicationsFolder": "打开应用文件夹",
            "settings.resetDefaults.button": "一键还原",
            "settings.resetDefaults.title": "还原默认启动器？",
            "settings.resetDefaults.message": "这会清除当前拖动、移除、排序和新增的项目配置，并恢复为默认图标。",
            "settings.resetDefaults.confirm": "确认还原",
            "settings.itemLimit.title": "已达到上限",
            "settings.itemLimit.message": "PopDeck 最多支持 8 个选项，请先移除一个现有选项后再添加。",
            "settings.addURL.button": "添加网址",
            "settings.addURL.title": "添加网址",
            "settings.addURL.subtitle": "保存到 PopDeck，点击后直接打开。",
            "settings.addURL.namePlaceholder": "名称，可选",
            "settings.addURL.urlPlaceholder": "网址，例如 chatgpt.com",
            "settings.addURL.invalid": "请输入有效的网址。",
            "settings.addURL.confirm": "添加",
            "settings.ok": "好",
            "settings.cancel": "取消",
            "settings.starterRing": "默认圆环",
            "settings.note": "自定义操作、工作区、二级菜单和主题会作为下一阶段设置加入。",
            "item.finder.subtitle": "文件",
            "item.safari.subtitle": "网页",
            "item.terminal.subtitle": "终端",
            "item.settings.title": "系统设置",
            "item.settings.subtitle": "系统",
            "item.downloads.title": "下载",
            "item.downloads.subtitle": "文件夹",
            "item.chatgpt.subtitle": "链接",
            "item.addedApp.subtitle": "应用",
            "item.addedFolder.subtitle": "文件夹",
            "item.addedFile.subtitle": "文件",
            "item.addedURL.subtitle": "网址"
        ],
        .en: [
            "menu.show": "Show PopDeck",
            "menu.settings": "Settings",
            "menu.checkForUpdates": "Check for Updates...",
            "menu.checkForUpdatesUnavailable": "Check for Updates Unavailable",
            "menu.quit": "Quit PopDeck",
            "settings.window.title": "PopDeck Settings",
            "settings.subtitle": "Pop-up launcher preferences",
            "settings.hubHint": "Drop apps or files to add them, drag sectors to reorder, and drop items in the center to remove.",
            "settings.shortcut.title": "Shortcut",
            "settings.shortcut.value": "Middle Click",
            "settings.shortcut.recording": "Press a shortcut or mouse button...",
            "settings.shortcut.middleMouseButton": "Middle Click",
            "settings.shortcut.mouseButton": "Mouse Button %d",
            "settings.launcher.title": "Launcher",
            "settings.launcher.value": "%d starter actions",
            "settings.language.title": "Language",
            "settings.language.value": "English",
            "settings.showNames.title": "Show Names",
            "settings.launchAtLogin.title": "Launch at Login",
            "settings.iconSize.title": "Icon Size",
            "settings.iconSize.small": "S",
            "settings.iconSize.medium": "M",
            "settings.iconSize.large": "L",
            "settings.hubSize.title": "Panel Size",
            "settings.hubSize.small": "S",
            "settings.hubSize.medium": "M",
            "settings.hubSize.large": "L",
            "settings.appIconStyle.title": "App Icon Style",
            "settings.appIconStyle.original": "Original",
            "settings.appIconStyle.monochrome": "Mono",
            "settings.openApplicationsFolder": "Open Applications Folder",
            "settings.resetDefaults.button": "Reset",
            "settings.resetDefaults.title": "Reset launcher defaults?",
            "settings.resetDefaults.message": "This will clear dragged, removed, reordered, and added items, then restore the default icons.",
            "settings.resetDefaults.confirm": "Reset",
            "settings.itemLimit.title": "Limit Reached",
            "settings.itemLimit.message": "PopDeck supports up to 8 items. Remove an existing item before adding another.",
            "settings.addURL.button": "Add URL",
            "settings.addURL.title": "Add URL",
            "settings.addURL.subtitle": "Save it to PopDeck and open it directly.",
            "settings.addURL.namePlaceholder": "Name, optional",
            "settings.addURL.urlPlaceholder": "URL, for example chatgpt.com",
            "settings.addURL.invalid": "Enter a valid URL.",
            "settings.addURL.confirm": "Add",
            "settings.ok": "OK",
            "settings.cancel": "Cancel",
            "settings.starterRing": "Starter Ring",
            "settings.note": "Custom actions, workspaces, nested menus, and themes will be added as the next settings sections.",
            "item.finder.subtitle": "Files",
            "item.safari.subtitle": "Web",
            "item.terminal.subtitle": "Shell",
            "item.settings.title": "Settings",
            "item.settings.subtitle": "System",
            "item.downloads.title": "Downloads",
            "item.downloads.subtitle": "Folder",
            "item.chatgpt.subtitle": "URL",
            "item.addedApp.subtitle": "App",
            "item.addedFolder.subtitle": "Folder",
            "item.addedFile.subtitle": "File",
            "item.addedURL.subtitle": "URL"
        ]
    ]
}
