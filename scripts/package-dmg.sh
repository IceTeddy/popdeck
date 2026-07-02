#!/usr/bin/env bash
set -euo pipefail

APP_NAME="PopDeck"
VERSION="${POPDECK_VERSION:-0.1.4}"
CONFIGURATION="${1:-release}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$ROOT_DIR/.build/$APP_NAME.app"
STAGING_DIR="$ROOT_DIR/.build/dmg/$APP_NAME-$VERSION"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"
SHA_PATH="$DMG_PATH.sha256"

"$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION"

rm -rf "$STAGING_DIR" "$DMG_PATH" "$SHA_PATH"
mkdir -p "$STAGING_DIR" "$DIST_DIR"

cp -R "$APP_DIR" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "$APP_NAME $VERSION" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

shasum -a 256 "$DMG_PATH" > "$SHA_PATH"

echo "Created $DMG_PATH"
echo "Created $SHA_PATH"
