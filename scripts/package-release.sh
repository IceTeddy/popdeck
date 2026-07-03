#!/usr/bin/env bash
set -euo pipefail

APP_NAME="PopDeck"
VERSION="${POPDECK_VERSION:-0.1.6}"
CONFIGURATION="${1:-release}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$ROOT_DIR/.build/$APP_NAME.app"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION.zip"
SHA_PATH="$ZIP_PATH.sha256"

"$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" > "$SHA_PATH"

echo "Created $ZIP_PATH"
echo "Created $SHA_PATH"
