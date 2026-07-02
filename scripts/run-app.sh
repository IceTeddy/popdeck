#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${1:-debug}"
APP_DIR="$ROOT_DIR/.build/PopDeck.app"

"$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION"
open "$APP_DIR"
