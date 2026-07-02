#!/usr/bin/env bash
set -euo pipefail

APP_NAME="PopDeck"
VERSION="${POPDECK_VERSION:-0.1.1}"
ACCOUNT="${SPARKLE_ACCOUNT:-com.tangfanx.popdeck}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION.zip"
SPARKLE_BIN="$ROOT_DIR/.build/artifacts/halohub/Sparkle/bin/generate_appcast"
DOWNLOAD_URL_PREFIX="https://github.com/IceTeddy/popdeck/releases/download/v$VERSION/"
RELEASE_NOTES_URL="https://github.com/IceTeddy/popdeck/releases/tag/v$VERSION"

if [[ ! -x "$SPARKLE_BIN" ]]; then
    echo "Sparkle generate_appcast was not found at $SPARKLE_BIN" >&2
    exit 1
fi

if [[ ! -f "$ZIP_PATH" ]]; then
    echo "Release archive was not found at $ZIP_PATH" >&2
    exit 1
fi

"$SPARKLE_BIN" \
    --account "$ACCOUNT" \
    --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
    --link "https://github.com/IceTeddy/popdeck" \
    --full-release-notes-url "$RELEASE_NOTES_URL" \
    --maximum-versions 3 \
    -o "$ROOT_DIR/appcast.xml" \
    "$DIST_DIR"

echo "Updated $ROOT_DIR/appcast.xml"
