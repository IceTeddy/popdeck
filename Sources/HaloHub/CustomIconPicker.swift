import SwiftUI
import UniformTypeIdentifiers

struct CustomIconPicker: View {
    @Binding var imageData: Data?
    @Binding var emoji: String
    @State private var choosingImage = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ProText.t("自定义图标", "Custom icon")).font(.headline)
            HStack {
                Button(ProText.t("选择图片…", "Choose image…"), systemImage: "photo") { choosingImage = true }
                Text(imageData == nil ? ProText.t("使用默认图标或 Emoji", "Default icon or Emoji") : ProText.t("已选择自定义图片", "Custom image selected"))
                    .font(.caption).foregroundStyle(.secondary)
            }
            EmojiSelectionMenu(selection: Binding(get: { emoji }, set: { emoji = $0; imageData = nil }),
                               emptyLabel: imageData == nil ? nil : ProText.t("改用 Emoji…", "Use Emoji…"))
            Text(ProText.t("图片会保存为图标副本，原文件移动或删除后仍可使用。", "An icon copy is saved, so moving or deleting the original image is safe."))
                .font(.caption).foregroundStyle(.secondary)
        }
        .fileImporter(isPresented: $choosingImage, allowedContentTypes: [.image], allowsMultipleSelection: false) { result in
            do {
                guard let url = try result.get().first else { return }
                let imported = try CustomIconImage.importFile(at: url)
                imageData = imported
                emoji = ""
            } catch {
                if (error as NSError).code == NSUserCancelledError { return }
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
        .alert(ProText.t("无法设置图标", "Unable to set icon"), isPresented: $showingError) {
            Button(L10n.t("settings.ok"), role: .cancel) {}
        } message: { Text(errorMessage) }
    }
}
