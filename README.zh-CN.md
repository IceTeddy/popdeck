<p align="center">
  <img src="docs/assets/popdeck-logo.png" width="128" alt="PopDeck logo">
</p>

<h1 align="center">PopDeck</h1>

<p align="center">
  <a href="README.md">English</a> | <a href="README.zh-CN.md">中文</a>
</p>

PopDeck 是一款使用 SwiftUI 和 AppKit 构建的原生 macOS 弹出式启动器。它常驻菜单栏，可以在鼠标指针附近呼出启动面板，用来快速打开常用应用、文件夹、文件和网页链接。

项目目前处于早期开发阶段。当前目标是先做成一个轻量、开源、配置清晰的 macOS 工具，并为后续自动更新能力打好发布基础。

## 预览

<img src="docs/assets/popdeck-hub-demo.webp" width="420" alt="PopDeck 启动器演示">

## 功能

- 无 Dock 图标的菜单栏应用。
- 全局启动快捷键，可在设置中配置。
- 跟随鼠标位置呼出的启动面板。
- 支持拖动、排序和移除启动项。
- 内置常用应用和文件夹默认项。
- 支持添加自定义应用、文件夹、文件和 URL。
- 支持一键还原默认启动器布局。
- 可选开机自动启动。
- 支持中文和英文界面文本。

## 环境要求

- macOS 14 或更高版本。
- Xcode 16 或更高版本，或对应的 Swift 工具链。

## 从源码运行

```bash
swift run
```

也可以在 Xcode 中将本文件夹作为 Swift package 打开，选择 `PopDeck` executable 后运行。

Sparkle 自动更新检查需要通过打包后的 `.app` bundle 运行。开发时如果要测试检查更新，请使用：

```bash
./scripts/run-app.sh
```

## 构建 App Bundle

```bash
./scripts/build-app.sh release
```

构建完成后的 app bundle 位于：

```text
.build/PopDeck.app
```

## 创建 DMG

```bash
./scripts/package-dmg.sh
```

DMG 是 GitHub Release 里的公开下载文件，也同时作为 Sparkle 自动更新包：

```text
dist/PopDeck-0.1.4.dmg
dist/PopDeck-0.1.4.dmg.sha256
```

## 安装与首次打开

1. 从 GitHub Releases 下载 `PopDeck-0.1.4.dmg`。
2. 打开 DMG 后，将 `PopDeck.app` 拖到“应用程序”文件夹。
3. 打开 PopDeck。

当前发布构建尚未签名。如果 macOS 阻止打开应用，可以使用下面任意一种方式：

- 按住 Control 键点击 `PopDeck.app`，选择“打开”，然后在确认弹窗中再次选择“打开”。
- 或打开“系统设置”，进入“隐私与安全性”，找到 PopDeck 被阻止的提示，然后选择“仍要打开”。

Developer ID 签名和 Apple notarization 会在后续版本中加入。

## 项目标识

- App 名称：`PopDeck`
- Bundle identifier：`com.tangfanx.popdeck`
- 当前版本：`0.1.4`
- 当前构建号：`5`

## Roadmap

- 使用 GitHub Releases 提供第一批公开下载。
- 接入基于 Sparkle 的自动更新。
- 添加 Developer ID 签名和 Apple notarization。
- 根据实际情况选择 GitHub Releases、Cloudflare R2 或二者共同托管更新 feed 和发布产物。

## License

PopDeck 使用 MIT License 开源。详见 [LICENSE](LICENSE)。
