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
    static let hoverSoundKey = "hoverSoundEnabled"
    static let showItemNamesKey = "showItemNames"
    static let iconSizeKey = "iconSize"
    static let appIconStyleKey = "appIconStyle"
    static let hubSizeKey = "hubSize"
    // The former glassStrength value only controlled black tint. Do not map it
    // to a material or rewrite it during upgrade.
    static let glassStyleKey = "glassStyle"
}

enum HaloGlassStyle: String, CaseIterable, Identifiable {
    case regular
    case clear

    var id: String { rawValue }
    var displayTitle: String { L10n.t("settings.glass.\(rawValue)") }
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
    case extraSmall
    case small
    case medium
    case large

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .extraSmall:
            return L10n.t("settings.hubSize.extraSmall")
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
        case .extraSmall:
            return 0.68
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
            AppPreferences.hoverSoundKey: true,
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
            "settings.sound.style": "音效风格",
            "settings.sound.picker": "Apple 时间拨轮原声（试听）",
            "settings.sound.pickerHint": "来自本机 iOS 运行时的时间拨轮音频，供测试版试听确认。",
            "settings.sound.ratchet": "原始棘轮",
            "settings.sound.soft": "柔和轻点",
            "settings.sound.wood": "木质短击",
            "settings.sound.bright": "清脆拨轮",
            "settings.sound.title": "悬停棘轮音效",
            "settings.sound.preview": "试听",
            "settings.sound.hint": "指针移入新选项时播放轻微拨轮声。可随时关闭，快速移动时会限制播放频率。",
            "settings.guide.context": "右键扇形可编辑命令、组或图标外观；每圈右上角 + 可添加项目。",
            "settings.guide.more": "更多操作提示",
            "settings.guide.drag": "拖动项目可调整顺序或跨圈移动；拖到最中央的移除区删除。外部文件直接拖入目标圈即可添加。",
            "settings.guide.resize": "先开启“调整扇形宽度”，再沿圆周拖动分界线。此时普通项目拖动暂停，关闭后恢复。",
            "settings.guide.group": "点击分组展开子项，再次点击分组或点击扇形外部收起；空组点击无操作。圆心显示当前名称，全部子项同时显示。命令集则直接在原扇形中细分命令。",
            "settings.guide.retained": "“收起最外圈”会保留配置，再次添加圆环时恢复。菜单中的“一键还原”只重置该圈。",
            "settings.guide.run": "实际面板中，单击项目执行、悬停在圆心查看名称。命令默认静默执行，需要交互时在编辑窗口勾选“打开终端窗口执行”。",
            "settings.group.close": "收起组",
            "settings.group.previousPage": "上一页",
            "settings.group.nextPage": "下一页",
            "settings.rings.dragRemove": "拖到这里移除",
            "settings.rings.resetMessage": "将重置第 %d 圈的启动项，其它圆环不受影响。",
            "settings.rings.addTo": "添加到第 %d 圈",
            "settings.rings.dropRemove": "松开以移除",
            "settings.rings.directHint": "各圈均可直接编辑；启动项可跨圈拖动，拖到最中央的移除区删除。",
            "settings.rings.configure": "配置圆环",
            "settings.rings.configureHint": "选择右侧要配置的圆环；左侧预览会实时显示修改。",
            "settings.rings.appearance": "第 %d 圈 · 外观设置",
            "settings.rings.appearanceHint": "仅影响这一圈及其展开分组。外圈尺寸调整圆环的厚度，内外圈保持相接。",
            "settings.rings.directTitle": "圆环与启动项",
            "settings.rings.number": "第 %d 圈",
            "settings.rings.add": "添加圆环",
            "settings.rings.hideOuter": "收起最外圈",
            "settings.rings.keep": "保留这一圈的配置，再次添加时恢复。",
            "settings.rings.multiHint": "直接拖入目标圆环，或点击各圈右上角的 + 添加。收起最外圈会保留配置。",
            "settings.group.add": "添加组",
            "settings.group.edit": "编辑组",
            "settings.group.kind": "组",
            "settings.group.name": "组名称，例如：娱乐",
            "settings.group.hint": "点击组后展开局部扇形。可以保存空组；空组点击无操作。每组最多 24 项，全部同时显示。",
            "settings.group.empty": "组内暂无项目",
            "settings.group.emptyHint": "使用右上角“添加项目”，也可以直接保存为空组。",
            "settings.group.addFile": "添加应用、文件或文件夹…",
            "settings.group.addItem": "添加项目",
            "settings.group.editItem": "编辑",
            "settings.group.moveUp": "上移",
            "settings.group.moveDown": "下移",
            "settings.group.invalid": "请输入组名称，并检查组内项目。",
            "settings.group.save": "保存组",
            "settings.rings.enabled": "启用第二圈",
            "settings.rings.remove": "移除此启动项",
            "settings.rings.edit": "编辑圆环",
            "settings.rings.first": "第一圈",
            "settings.rings.second": "第二圈",
            "settings.rings.hint": "选择要编辑的圆环，再用右上角 + 添加快捷项。关闭第二圈会保留配置。",
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
            "settings.permissions.title": "系统权限",
            "settings.permissions.subtitle.ready": "权限已就绪，快捷键和鼠标按键可以正常呼出 PopDeck。",
            "settings.permissions.subtitle.needsAction": "如果 Hub 呼不出，请先允许下面的系统权限。",
            "settings.permissions.granted": "已允许",
            "settings.permissions.missing": "未允许",
            "settings.permissions.request": "请求权限",
            "settings.permissions.open": "打开设置",
            "settings.permissions.refresh": "刷新",
            "settings.permissions.accessibility.title": "辅助功能",
            "settings.permissions.accessibility.detail": "用于让全局快捷键和鼠标按键稳定触发 PopDeck。",
            "settings.permissions.inputMonitoring.title": "输入监听",
            "settings.permissions.inputMonitoring.detail": "用于监听键盘快捷键和鼠标功能键。",
            "permissions.launch.title": "允许 PopDeck 使用快捷键？",
            "permissions.launch.message": "PopDeck 需要辅助功能和输入监听权限，才能在后台响应快捷键或鼠标按键。",
            "permissions.launch.openSettings": "打开设置",
            "permissions.launch.later": "稍后",
            "settings.iconSize.title": "图标尺寸",
            "settings.iconSize.small": "小",
            "settings.iconSize.medium": "中",
            "settings.iconSize.large": "大",
            "settings.hubSize.title": "面板尺寸",
            "settings.hubSize.extraSmall": "超小",
            "settings.hubSize.small": "小",
            "settings.hubSize.medium": "中",
            "settings.hubSize.large": "大",
            "settings.appIconStyle.title": "App 图标风格",
            "settings.appIconStyle.original": "原始",
            "settings.appIconStyle.monochrome": "单色",
            "settings.openApplicationsFolder": "打开应用文件夹",
            "settings.websiteFeedback.title": "官网与反馈",
            "settings.websiteFeedback.subtitle": "查看官网，或到留言墙告诉我你的想法。",
            "settings.website.button": "访问官网",
            "settings.feedback.button": "给我留言",
            "settings.resetDefaults.button": "一键还原",
            "settings.resetDefaults.title": "还原默认启动器？",
            "settings.resetDefaults.message": "这会清除当前拖动、移除、排序和新增的项目配置，并恢复为默认图标。",
            "settings.resetDefaults.confirm": "确认还原",
            "settings.itemLimit.title": "已达到上限",
            "settings.itemLimit.message": "PopDeck 最多支持 8 个选项，请先移除一个现有选项后再添加。",
            "settings.addURL.button": "添加网址",
            "item.command.subtitle": "命令",
            "settings.addCommand.button": "添加命令",
            "settings.commandSet.add": "添加扇形命令集",
            "settings.commandSet.showGroupIcon": "显示总扇形图标",
            "settings.addMenu": "添加启动项与更多操作",
            "settings.sections": "设置分类",
            "settings.section.items": "启动项",
            "settings.sectors.resize": "调整扇形宽度",
            "settings.sectors.equal": "恢复均分",
            "settings.sectors.resizeHint": "将鼠标移到分界线上，沿圆周拖动调整相邻扇形宽度；松开即保存。支持总扇形和命令集内部，关闭此模式后可继续拖动排序。",
            "settings.sectors.parentBoundary": "调整总扇形分界",
            "settings.sectors.childBoundary": "调整子命令分界",

            "settings.section.preferences": "偏好设置",
            "settings.itemDisplay": "显示方式",
            "settings.itemDisplay.automatic": "默认",
            "settings.itemDisplay.iconOnly": "图标",
            "settings.itemDisplay.nameOnly": "文字",
            "settings.itemDisplay.iconAndName": "图标+文字",
            "settings.commandSet.background": "分组背景",
            "settings.commandSet.backgroundHint": "浅色分组提示保留原生玻璃的透亮和折射；默认不叠加颜色。",
            "settings.commandSet.commandsTab": "命令列表",
            "settings.commandSet.appearanceTab": "外观",
            "settings.commandSet.commandsHint": "点击一条命令展开编辑。每次点击小扇形只执行对应命令。",
            "settings.commandSet.untitled": "未命名命令",
            "settings.commandSet.silent": "静默执行",
            "settings.commandSet.visibility": "显示内容",
            "settings.commandSet.typography": "文字与分组背景",

            "settings.commandSet.showGroupName": "显示总扇形名称",
            "settings.commandSet.showNumbers": "显示编号",
            "settings.commandSet.showCommandNames": "显示命令名称",
            "settings.commandSet.textStyle": "文字排列",
            "settings.commandSet.style.circular": "沿圆环排列",
            "settings.commandSet.style.horizontal": "水平",
            "settings.commandSet.style.radial": "沿半径排列",
            "settings.commandSet.style.fan": "扇形渐变（内小外大）",
            "settings.commandSet.appearanceHint": "这些选项只作用于当前命令集。悬停时圆心始终显示完整名称；左半圆文字自动翻转，保持正向阅读。",

            "settings.commandSet.edit": "编辑命令集",
            "settings.commandSet.kind": "扇形命令集",
            "settings.commandSet.hint": "一个命令集占一个总扇形，按下面的顺序均分成小扇形。点击只执行对应命令；默认静默执行。窄扇形显示序号；过密时仅显示悬停项，圆心显示完整名称。",
            "settings.commandSet.name": "命令集名称",
            "settings.commandSet.memberName": "命令名称",
            "settings.commandSet.addMember": "添加一条命令",
            "settings.commandSet.count": "条命令",
            "settings.commandSet.invalid": "请填写命令集名称、每条命令的名称和有效命令。",
            "settings.commandSet.up": "上移命令",
            "settings.commandSet.down": "下移命令",
            "settings.commandSet.remove": "删除命令",

            "settings.command.openTerminal": "打开终端窗口执行",
            "settings.command.silentHint": "未勾选：静默执行，不打开终端，不支持交互输入。",
            "settings.command.terminalHint": "已勾选：使用系统 Terminal，显示输出并支持交互输入，执行后保持打开。",
            "settings.iconOriginal": "使用原图标",
            "settings.emojiCategory": "分类",
            "settings.emojiAll": "全部表情",
            "settings.emojiSearch": "搜索英文名称或表情（可选）",
            "settings.emojiCount": "%d 个表情 · 可滚动浏览",
            "emoji.group.Smileys & Emotion": "表情与情感",
            "emoji.group.People & Body": "人物与身体",
            "emoji.group.Animals & Nature": "动物与自然",
            "emoji.group.Food & Drink": "食物与饮品",
            "emoji.group.Travel & Places": "旅行与地点",
            "emoji.group.Activities": "活动",
            "emoji.group.Objects": "物品",
            "emoji.group.Symbols": "符号",
            "emoji.group.Flags": "旗帜",
            "settings.editCommand": "编辑命令",
            "settings.save": "保存",
            "settings.iconAppearance": "显示与图标",
            "settings.items.title": "启动项",
            "settings.iconEmoji": "Emoji 图标",
            "settings.iconEmoji.placeholder": "输入一个 emoji，留空使用原图标",
            "settings.sector.background": "扇形背景色",
            "settings.iconColor": "原图标颜色",
            "settings.iconDefault": "默认",
            "settings.selected": "已选择",
            "settings.iconRestore": "恢复默认图标",
            "settings.iconAppearance.hint": "展开列表选择 Emoji，支持分类浏览；Emoji 保留自身颜色。部分新表情的显示取决于 macOS 字体支持。",
            "settings.iconEmoji.invalid": "请输入一个 emoji（支持组合表情），或留空。",
            "icon.color.red": "红色",
            "icon.color.orange": "橙色",
            "icon.color.yellow": "黄色",
            "icon.color.green": "绿色",
            "icon.color.teal": "青色",
            "icon.color.blue": "蓝色",
            "icon.color.purple": "紫色",
            "icon.color.pink": "粉色",
            "settings.glass.title": "液态玻璃",
            "settings.glass.clear": "清透",
            "settings.glass.regular": "常规（推荐）",
            "settings.glass.hint": "常规：系统自适应模糊，提高可读性。清透：突出背景与边缘折射。透明度也会受 macOS 外观及辅助功能设置影响。",
            "settings.addCommand.subtitle": "支持多行命令、管道和重定向，工作目录为用户主目录。可选择静默执行或打开终端执行。",
            "settings.addCommand.label": "Shell 命令",
            "settings.addCommand.invalid": "命令不能为空、包含空字符或与已有命令重复。",
            "command.failed.title": "命令执行失败",
            "command.failed.message": "退出状态：%d",
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
            "settings.sound.style": "Sound style",
            "settings.sound.picker": "Apple time-wheel original (preview)",
            "settings.sound.pickerHint": "Original time-wheel audio from the locally installed iOS runtime, for development auditioning.",
            "settings.sound.ratchet": "Original ratchet",
            "settings.sound.soft": "Soft click",
            "settings.sound.wood": "Wooden tick",
            "settings.sound.bright": "Bright detent",
            "settings.sound.title": "Hover tick sound",
            "settings.sound.preview": "Preview",
            "settings.sound.hint": "Play a soft wheel-like tick when entering a new item. Disable it anytime; rapid movement is rate-limited.",
            "settings.guide.context": "Right-click a sector to edit its command, group or appearance. Each ring’s upper-right + adds items.",
            "settings.guide.more": "More interaction tips",
            "settings.guide.drag": "Drag items to reorder or move between rings. Drop in the shared center to remove. Drop external files onto a ring to add them.",
            "settings.guide.resize": "Enable Adjust Sector Widths, then drag a divider around the circle. Normal item dragging pauses in this mode and resumes when disabled.",
            "settings.guide.group": "Click a group to expand it; empty groups do nothing. Click the parent again or outside the fan to collapse. The center shows the current name; all children are shown together. Command sets subdivide their original sector.",
            "settings.guide.retained": "Hide Outer Ring keeps its configuration for the next time you add it. Restore Defaults in a ring’s menu affects only that ring.",
            "settings.guide.run": "On the actual panel, click to run and hover to see names in the center. Commands run silently unless Run in a Terminal Window is selected in the editor.",
            "settings.group.close": "Collapse group",
            "settings.group.previousPage": "Previous page",
            "settings.group.nextPage": "Next page",
            "settings.rings.dragRemove": "Drop here to remove",
            "settings.rings.resetMessage": "Reset the items in ring %d. Other rings keep their contents.",
            "settings.rings.addTo": "Add to ring %d",
            "settings.rings.dropRemove": "Drop to remove",
            "settings.rings.directHint": "Edit every ring directly. Drag between rings, or drop in the shared center to remove.",
            "settings.rings.configure": "Configure ring",
            "settings.rings.configureHint": "Choose the ring to configure. The preview on the left updates immediately.",
            "settings.rings.appearance": "Ring %d · Appearance",
            "settings.rings.appearanceHint": "Applies to this ring and its expanded groups. Outer ring size controls its thickness; neighboring rings stay connected.",
            "settings.rings.directTitle": "Rings and items",
            "settings.rings.number": "Ring %d",
            "settings.rings.add": "Add ring",
            "settings.rings.hideOuter": "Hide outer ring",
            "settings.rings.keep": "Keep this ring’s contents and restore them when added again.",
            "settings.rings.multiHint": "Drop onto a ring or use its upper-right +. Hidden outer rings keep their contents.",
            "settings.group.add": "Add group",
            "settings.group.edit": "Edit group",
            "settings.group.kind": "Group",
            "settings.group.name": "Group name, e.g. Entertainment",
            "settings.group.hint": "Click a group to open a partial fan. Empty groups can be saved and do nothing when clicked. Up to 24 items, all shown together.",
            "settings.group.empty": "No items in this group",
            "settings.group.emptyHint": "Use Add Item, or save this as an empty group.",
            "settings.group.addFile": "Add apps, files or folders…",
            "settings.group.addItem": "Add item",
            "settings.group.editItem": "Edit",
            "settings.group.moveUp": "Move up",
            "settings.group.moveDown": "Move down",
            "settings.group.invalid": "Enter a group name and check its items.",
            "settings.group.save": "Save group",
            "settings.rings.enabled": "Enable second ring",
            "settings.rings.remove": "Remove shortcut",
            "settings.rings.edit": "Edit ring",
            "settings.rings.first": "First ring",
            "settings.rings.second": "Second ring",
            "settings.rings.hint": "Select a ring, then use + to add shortcuts. Disabling the second ring keeps its items.",
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
            "settings.permissions.title": "System Permissions",
            "settings.permissions.subtitle.ready": "Permissions are ready, so shortcuts and mouse buttons can open PopDeck.",
            "settings.permissions.subtitle.needsAction": "If the hub does not open, allow the system permissions below first.",
            "settings.permissions.granted": "Allowed",
            "settings.permissions.missing": "Not Allowed",
            "settings.permissions.request": "Request",
            "settings.permissions.open": "Open Settings",
            "settings.permissions.refresh": "Refresh",
            "settings.permissions.accessibility.title": "Accessibility",
            "settings.permissions.accessibility.detail": "Lets global shortcuts and mouse buttons trigger PopDeck reliably.",
            "settings.permissions.inputMonitoring.title": "Input Monitoring",
            "settings.permissions.inputMonitoring.detail": "Lets PopDeck listen for keyboard shortcuts and extra mouse buttons.",
            "permissions.launch.title": "Allow PopDeck to use shortcuts?",
            "permissions.launch.message": "PopDeck needs Accessibility and Input Monitoring permissions to respond to shortcuts or mouse buttons in the background.",
            "permissions.launch.openSettings": "Open Settings",
            "permissions.launch.later": "Later",
            "settings.iconSize.title": "Icon Size",
            "settings.iconSize.small": "S",
            "settings.iconSize.medium": "M",
            "settings.iconSize.large": "L",
            "settings.hubSize.title": "Panel Size",
            "settings.hubSize.extraSmall": "XS",
            "settings.hubSize.small": "S",
            "settings.hubSize.medium": "M",
            "settings.hubSize.large": "L",
            "settings.appIconStyle.title": "App Icon Style",
            "settings.appIconStyle.original": "Original",
            "settings.appIconStyle.monochrome": "Mono",
            "settings.openApplicationsFolder": "Open Applications Folder",
            "settings.websiteFeedback.title": "Website & Feedback",
            "settings.websiteFeedback.subtitle": "Visit the website or leave a message on the wall.",
            "settings.website.button": "Website",
            "settings.feedback.button": "Message",
            "settings.resetDefaults.button": "Reset",
            "settings.resetDefaults.title": "Reset launcher defaults?",
            "settings.resetDefaults.message": "This will clear dragged, removed, reordered, and added items, then restore the default icons.",
            "settings.resetDefaults.confirm": "Reset",
            "settings.itemLimit.title": "Limit Reached",
            "settings.itemLimit.message": "PopDeck supports up to 8 items. Remove an existing item before adding another.",
            "settings.addURL.button": "Add URL",
            "item.command.subtitle": "Command",
            "settings.addCommand.button": "Add Command",
            "settings.commandSet.add": "Add Command Set",
            "settings.commandSet.showGroupIcon": "Show set icon",
            "settings.addMenu": "Add items and more actions",
            "settings.sections": "Settings sections",
            "settings.section.items": "Launcher Items",
            "settings.sectors.resize": "Adjust Sector Widths",
            "settings.sectors.equal": "Reset Equal Widths",
            "settings.sectors.resizeHint": "Hover a divider and drag around the circle to resize its two neighbors. Release to save. Supports parent and child sectors. Exit this mode to reorder items.",
            "settings.sectors.parentBoundary": "Resize parent boundary",
            "settings.sectors.childBoundary": "Resize command boundary",

            "settings.section.preferences": "Preferences",
            "settings.itemDisplay": "Display",
            "settings.itemDisplay.automatic": "Default",
            "settings.itemDisplay.iconOnly": "Icon",
            "settings.itemDisplay.nameOnly": "Text",
            "settings.itemDisplay.iconAndName": "Icon + Text",
            "settings.commandSet.background": "Group background",
            "settings.commandSet.backgroundHint": "A subtle color wash preserves the native glass material and refraction. Default adds no color.",
            "settings.commandSet.commandsTab": "Commands",
            "settings.commandSet.appearanceTab": "Appearance",
            "settings.commandSet.commandsHint": "Expand a command to edit. Each sector runs only its own command.",
            "settings.commandSet.untitled": "Untitled command",
            "settings.commandSet.silent": "Silent execution",
            "settings.commandSet.visibility": "Visibility",
            "settings.commandSet.typography": "Text and group background",

            "settings.commandSet.showGroupName": "Show set name",
            "settings.commandSet.showNumbers": "Show numbers",
            "settings.commandSet.showCommandNames": "Show command names",
            "settings.commandSet.textStyle": "Text layout",
            "settings.commandSet.style.circular": "Around the ring",
            "settings.commandSet.style.horizontal": "Horizontal",
            "settings.commandSet.style.radial": "Radial",
            "settings.commandSet.style.fan": "Fan (small inside, large outside)",
            "settings.commandSet.appearanceHint": "Applies only to this set. Hover always shows the full name in the center. Text on the left flips to stay upright.",

            "settings.commandSet.edit": "Edit Command Set",
            "settings.commandSet.kind": "Command Set",
            "settings.commandSet.hint": "One main sector, divided equally in the order below. Each click runs only that command, silently by default. Narrow sectors show numbers; very dense sectors show only the hovered label. Full names appear in the center.",
            "settings.commandSet.name": "Command set name",
            "settings.commandSet.memberName": "Command name",
            "settings.commandSet.addMember": "Add a command",
            "settings.commandSet.count": "commands",
            "settings.commandSet.invalid": "Name the set and every command, and enter valid commands.",
            "settings.commandSet.up": "Move command up",
            "settings.commandSet.down": "Move command down",
            "settings.commandSet.remove": "Remove command",

            "settings.command.openTerminal": "Run in a Terminal window",
            "settings.command.silentHint": "Unchecked: run silently without a terminal or interactive input.",
            "settings.command.terminalHint": "Checked: show output and allow interactive input in Terminal; keep it open afterward.",
            "settings.iconOriginal": "Use Original Icon",
            "settings.emojiCategory": "Category",
            "settings.emojiAll": "All Emoji",
            "settings.emojiSearch": "Search English names or emoji (optional)",
            "settings.emojiCount": "%d emoji · Scroll to browse",
            "emoji.group.Smileys & Emotion": "Smileys & Emotion",
            "emoji.group.People & Body": "People & Body",
            "emoji.group.Animals & Nature": "Animals & Nature",
            "emoji.group.Food & Drink": "Food & Drink",
            "emoji.group.Travel & Places": "Travel & Places",
            "emoji.group.Activities": "Activities",
            "emoji.group.Objects": "Objects",
            "emoji.group.Symbols": "Symbols",
            "emoji.group.Flags": "Flags",
            "settings.editCommand": "Edit Command",
            "settings.save": "Save",
            "settings.iconAppearance": "Display & Icon",
            "settings.items.title": "Launcher Items",
            "settings.iconEmoji": "Emoji Icon",
            "settings.iconEmoji.placeholder": "One emoji, or leave blank for the original icon",
            "settings.sector.background": "Sector background",
            "settings.iconColor": "Original Icon Color",
            "settings.iconDefault": "Default",
            "settings.selected": "Selected",
            "settings.iconRestore": "Restore Default Icon",
            "settings.iconAppearance.hint": "Choose an emoji from the categorized list. Emoji keep their own colors; newer emoji depend on macOS font support.",
            "settings.iconEmoji.invalid": "Enter one emoji (combined emoji supported), or leave blank.",
            "icon.color.red": "Red",
            "icon.color.orange": "Orange",
            "icon.color.yellow": "Yellow",
            "icon.color.green": "Green",
            "icon.color.teal": "Teal",
            "icon.color.blue": "Blue",
            "icon.color.purple": "Purple",
            "icon.color.pink": "Pink",
            "settings.glass.title": "Liquid Glass",
            "settings.glass.clear": "Clear",
            "settings.glass.regular": "Regular (Recommended)",
            "settings.glass.hint": "Regular adapts background blur for readability. Clear emphasizes the backdrop and edge refraction. macOS appearance and accessibility settings also affect transparency.",
            "settings.addCommand.subtitle": "Run multiline shell commands, pipes and redirection from your home directory. Choose silent execution or a Terminal window.",
            "settings.addCommand.label": "Shell command",
            "settings.addCommand.invalid": "Enter a nonempty command without NUL characters or duplicates.",
            "command.failed.title": "Command failed",
            "command.failed.message": "Exit status: %d",
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
