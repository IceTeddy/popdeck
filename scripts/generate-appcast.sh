#!/usr/bin/env bash
set -euo pipefail

APP_NAME="PopDeck"
VERSION="${POPDECK_VERSION:-0.1.5}"
ACCOUNT="${SPARKLE_ACCOUNT:-com.tangfanx.popdeck}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"
APPCAST_STAGE_DIR="$ROOT_DIR/.build/appcast"
SPARKLE_BIN="$ROOT_DIR/.build/artifacts/halohub/Sparkle/bin/generate_appcast"
DOWNLOAD_URL_PREFIX="https://github.com/IceTeddy/popdeck/releases/download/v$VERSION/"
RELEASE_NOTES_URL="https://github.com/IceTeddy/popdeck/releases/tag/v$VERSION"

if [[ ! -x "$SPARKLE_BIN" ]]; then
    echo "Sparkle generate_appcast was not found at $SPARKLE_BIN" >&2
    exit 1
fi

if [[ ! -f "$DMG_PATH" ]]; then
    echo "Release DMG was not found at $DMG_PATH" >&2
    exit 1
fi

rm -rf "$APPCAST_STAGE_DIR"
mkdir -p "$APPCAST_STAGE_DIR"
cp "$DMG_PATH" "$APPCAST_STAGE_DIR/"

"$SPARKLE_BIN" \
    --account "$ACCOUNT" \
    --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
    --link "https://github.com/IceTeddy/popdeck" \
    --full-release-notes-url "$RELEASE_NOTES_URL" \
    --maximum-versions 1 \
    -o "$ROOT_DIR/appcast.xml" \
    "$APPCAST_STAGE_DIR"

echo "Updated $ROOT_DIR/appcast.xml"
