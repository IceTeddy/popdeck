#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${1:-debug}"
# This entrypoint always runs the test identity, including optimized builds.
export POPDECK_CHANNEL=development
source "$ROOT_DIR/scripts/app-build-settings.sh"
# Local private checkouts may opt into the full Dev build. Public clones have
# no local config and run Free. An explicit edition always wins.
if [[ -z "${POPDECK_EDITION:-}" ]]; then
    if [[ -n "${POPDECK_PRO_ROOT:-}" || -f "$ROOT_DIR/.popdeck-pro-root" ]]; then
        export POPDECK_EDITION=pro
    else
        export POPDECK_EDITION=free
    fi
fi
python3 "$ROOT_DIR/scripts/prepare-edition.py" "$POPDECK_EDITION"
# Stop only the exact test bundle executable, never all PopDeck processes.
python3 - "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME" <<'PY_STOP'
import subprocess,sys,os,signal,time
result=subprocess.run(['ps','-axww','-o','pid=,comm='],capture_output=True,text=True,check=True)
for line in result.stdout.splitlines():
    parts=line.strip().split(None,1)
    if len(parts)==2 and parts[1]==sys.argv[1]:
        pid=int(parts[0])
        try: os.kill(pid,signal.SIGTERM)
        except ProcessLookupError: continue
        for _ in range(50):
            try: os.kill(pid,0)
            except ProcessLookupError: break
            time.sleep(0.1)
        else: sys.exit('Test process did not exit; refusing to replace its bundle.')
PY_STOP
"$ROOT_DIR/scripts/build-app.sh" "$CONFIGURATION"
open -n "$APP_DIR"
