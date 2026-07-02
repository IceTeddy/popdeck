#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${1:-release}"
APP_NAME="PopDeck"
BUNDLE_ID="com.tangfanx.popdeck"
MARKETING_VERSION="${POPDECK_VERSION:-0.1.0}"
BUILD_NUMBER="${POPDECK_BUILD_NUMBER:-1}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/arm64-apple-macosx/$CONFIGURATION"
APP_DIR="$ROOT_DIR/.build/$APP_NAME.app"
EXECUTABLE="$BUILD_DIR/$APP_NAME"
RESOURCE_DIR="$ROOT_DIR/Sources/HaloHub/Resources"
ICON_FILE="$RESOURCE_DIR/AppIcon.icns"

swift build -c "$CONFIGURATION"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$APP_DIR/Contents/Frameworks"

cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ICON_FILE" "$APP_DIR/Contents/Resources/AppIcon.icns"
cp "$RESOURCE_DIR/AppIcon-1024.png" "$APP_DIR/Contents/Resources/AppIcon-1024.png"
cp "$RESOURCE_DIR/MenuBarIcon-template.png" "$APP_DIR/Contents/Resources/MenuBarIcon-template.png"

SPARKLE_FRAMEWORK="$(find "$ROOT_DIR/.build/artifacts" -maxdepth 5 -path '*/Sparkle.framework' -type d 2>/dev/null | head -n 1 || true)"
if [[ -z "$SPARKLE_FRAMEWORK" ]]; then
    echo "Sparkle.framework was not found in .build/artifacts" >&2
    exit 1
fi
cp -R "$SPARKLE_FRAMEWORK" "$APP_DIR/Contents/Frameworks/"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_DIR/Contents/MacOS/$APP_NAME" 2>/dev/null || true

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$MARKETING_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>SUFeedURL</key>
    <string>https://raw.githubusercontent.com/IceTeddy/popdeck/main/appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string>n3WgaOnCNdk+273b1SSVHk/EFfWuojekFYpUxkkvhKY=</string>
</dict>
</plist>
PLIST

xattr -cr "$APP_DIR"
codesign --force --deep --sign - "$APP_DIR"

echo "Built $APP_DIR"
