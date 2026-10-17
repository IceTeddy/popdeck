#!/usr/bin/env bash
# Source after ROOT_DIR and CONFIGURATION; shared by build/run/package scripts.
case "$CONFIGURATION" in debug|release) ;; *) echo 'Configuration must be debug or release.' >&2; exit 2 ;; esac
CHANNEL="${POPDECK_CHANNEL:-}"
if [[ -z "$CHANNEL" ]]; then
    if [[ "$CONFIGURATION" == debug ]]; then CHANNEL=development; else CHANNEL=production; fi
fi
case "$CHANNEL" in
    development)
        APP_NAME='PopDeck Dev'
        EXECUTABLE_NAME=PopDeckDev
        BUNDLE_ID="${POPDECK_BUNDLE_ID:-com.tangfanx.popdeck.dev}"
        if [[ "$BUNDLE_ID" == com.tangfanx.popdeck ]]; then
            echo 'Development builds cannot use the production identifier.' >&2; exit 2
        fi
        ;;
    production)
        if [[ "$CONFIGURATION" != release ]]; then echo 'Production requires release configuration.' >&2; exit 2; fi
        APP_NAME=PopDeck
        EXECUTABLE_NAME=PopDeck
        BUNDLE_ID="${POPDECK_BUNDLE_ID:-com.tangfanx.popdeck}"
        if [[ "$BUNDLE_ID" != com.tangfanx.popdeck ]]; then echo 'Production identifier must remain com.tangfanx.popdeck.' >&2; exit 2; fi
        ;;
    *) echo 'POPDECK_CHANNEL must be development or production.' >&2; exit 2 ;;
esac
APP_DIR="${POPDECK_APP_DIR:-$ROOT_DIR/.build/$APP_NAME.app}"
# Resolve symlinks before any removal. Building must never install an app.
APP_DIR="$(python3 - "$ROOT_DIR" "$APP_DIR" "$CHANNEL" <<'PY_PATH'
from pathlib import Path
import sys, plistlib
root = Path(sys.argv[1]).resolve() / '.build'
app = Path(sys.argv[2]).resolve()
if app.suffix != '.app' or root not in app.parents:
    sys.exit('Build output must be an .app inside the project .build directory.')
info = app / 'Contents/Info.plist'
if info.exists():
    identifier = plistlib.loads(info.read_bytes()).get('CFBundleIdentifier')
    if sys.argv[3] == 'development' and identifier == 'com.tangfanx.popdeck':
        sys.exit('Development builds cannot replace an existing production bundle.')
    if sys.argv[3] == 'production' and identifier != 'com.tangfanx.popdeck':
        sys.exit('Production builds cannot replace an existing test bundle.')
print(app)
PY_PATH
)"
if [[ "$CHANNEL" == development && "$APP_DIR" == "$ROOT_DIR/.build/PopDeck.app" ]]; then
    echo 'Development builds cannot replace the production artifact.' >&2; exit 2
fi
export POPDECK_CHANNEL="$CHANNEL" POPDECK_APP_DIR="$APP_DIR"
