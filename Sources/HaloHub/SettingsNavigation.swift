import SwiftUI

/// A native source list keeps one editing task visible at a time.
struct SettingsNavigation<Content: View>: View {
    @Binding var selection: Int
    var showsSupport: Bool
    @ViewBuilder var content: () -> Content
    private var destinations: [(Int, String, String)] {
        var rows = [
            (0, ProText.t("面板与启动项", "Panel & Items"), "circle.hexagongrid"),
            (1, ProText.t("通用", "General"), "gearshape"),
            (3, ProText.t("液态玻璃", "Liquid Glass"), "circle.lefthalf.filled"),
            (4, ProText.t("音效", "Sound"), "speaker.wave.2"),
            (5, ProText.t("快捷键与权限", "Shortcuts & Permissions"), "keyboard"),
            (2, "PopDeck PRO", "sparkles")
        ]
        if showsSupport { rows.append((6, ProText.t("请我喝一杯", "Buy Me a Coffee"), "cup.and.saucer")) }
        return rows
    }
    @State private var sidebarVisible = true
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Button { sidebarVisible.toggle() } label: {
                        Image(systemName: "sidebar.left").frame(width: 22, height: 22)
                    }.buttonStyle(.plain)
                        .help(ProText.t("显示或隐藏边栏", "Show or hide sidebar"))
                        .accessibilityLabel(ProText.t("显示或隐藏边栏", "Show or hide sidebar"))
                    if sidebarVisible { Text("PopDeck").font(.headline) }
                    Spacer(minLength: 0)
                }.padding(.horizontal, 16).frame(height: 62)
                if sidebarVisible {
                    List(selection: Binding<Int?>(get: { selection }, set: { if let value = $0 { selection = value } })) {
                        ForEach(destinations, id: \.0) { row in
                            Label(row.1, systemImage: row.2).tag(row.0).padding(.vertical, 3)
                        }
                    }.listStyle(.sidebar)
                } else { Spacer() }
            }.frame(width: sidebarVisible ? 210 : 54)
                .background(.regularMaterial)
            Divider()
            VStack(alignment: .leading, spacing: 0) {
                Text(destinations.first(where: { $0.0 == selection })?.1 ?? "PopDeck")
                    .font(.title2.bold()).padding(.horizontal, 24).frame(height: 62)
                Divider()
                content()
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: showsSupport) { _, visible in
            if !visible && selection == 6 { selection = 2 }
        }
    }
}

struct SettingsPage<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20, content: content)
                    .frame(maxWidth: 760, alignment: .leading)
                    .padding(24).frame(maxWidth: .infinity)
                    .environment(\.settingsPreviewDiameter, max(180, min(490, proxy.size.width - 48)))
            }
        }
    }
}

/// Preview stays in place while the selected ring's configuration scrolls.
struct SettingsPanelEditor<Preview: View, Tools: View, Configuration: View>: View {
    var naturalDiameter: CGFloat
    @State private var previewScale: CGFloat?
    @ViewBuilder var preview: () -> Preview
    @ViewBuilder var tools: () -> Tools
    @ViewBuilder var configuration: () -> Configuration
    var body: some View {
        GeometryReader { proxy in
            let available = max(200, proxy.size.width * 0.46 - 36)
            let factor = previewScale ?? min(1, available / naturalDiameter)
            let diameter = min(available, naturalDiameter * factor)
            HStack(alignment: .top, spacing: 0) {
                VStack(spacing: 16) {
                    tools()
                    preview().frame(height: diameter)
                        .environment(\.settingsPreviewDiameter, diameter)
                    Text(ProText.t("拖入文件 · 拖动排序 · 拖至中心移除\n右键编辑 · 各圈 + 添加项目", "Drop files · Drag to reorder · Drag to center to remove\nRight-click to edit · Use each ring’s + to add"))
                        .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Spacer(minLength: 0)
                }.padding(18).frame(width: proxy.size.width * 0.46)
                Divider()
                SettingsPage(content: configuration)
            }
            .onAppear { if previewScale == nil { previewScale = factor } }
            .onChange(of: naturalDiameter) { old, new in
                if new > old {
                    SettingsWindowController.shared.growForPreview(new * factor)
                }
            }
        }
    }
}
