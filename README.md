# PopDeck

[English](README.md) | [中文](README.zh-CN.md)

PopDeck is a native macOS pop-up launcher built with SwiftUI and AppKit. It lives in the menu bar and opens a cursor-centered launcher for frequently used apps, folders, and web links.

The project is currently in early development. The first goal is a lightweight, open-source macOS utility with a clean local configuration model and a release path that can later support automatic updates.

## Preview

<img src="docs/assets/popdeck-hub-demo.gif" width="720" alt="PopDeck launcher demo">

## Features

- Menu bar app with no Dock icon.
- Global launcher shortcut, configurable from Settings.
- Cursor-centered launcher panel with draggable items.
- Default actions for common apps and folders.
- Add custom apps, folders, files, and URLs.
- Restore the default launcher layout with one click.
- Optional launch at login.
- Chinese and English interface strings.

## Requirements

- macOS 14 or later.
- Xcode 16 or later, or the matching Swift toolchain.

## Run From Source

```bash
swift run
```

In Xcode, open this folder as a Swift package, select the `PopDeck` executable, and run it.

## Build The App Bundle

```bash
./scripts/build-app.sh release
```

The app bundle is created at:

```text
.build/PopDeck.app
```

## Create A Release Zip

```bash
./scripts/package-release.sh
```

The release artifacts are written to `dist/`:

```text
dist/PopDeck-0.1.0.zip
dist/PopDeck-0.1.0.zip.sha256
```

Current release builds are unsigned. Users may need to allow the app manually in macOS Privacy & Security until Developer ID signing and notarization are added.

## Project Identity

- App name: `PopDeck`
- Bundle identifier: `com.tangfanx.popdeck`
- Current version: `0.1.0`
- Current build: `1`

## Roadmap

- GitHub Releases for the first public downloads.
- Sparkle-based automatic updates.
- Developer ID signing and notarization.
- Optional Cloudflare-hosted update feed and release artifacts.

## License

PopDeck is released under the MIT License. See [LICENSE](LICENSE).
