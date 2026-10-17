"""Exercise build safety guards without building or touching installed apps."""
from pathlib import Path
import os
import plistlib
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
base_env = {k: v for k, v in os.environ.items() if not k.startswith("POPDECK_")}
command = 'set -euo pipefail; ROOT_DIR="$1"; CONFIGURATION="$2"; source "$ROOT_DIR/scripts/app-build-settings.sh"; printf "%s\\n" "$CHANNEL" "$BUNDLE_ID" "$APP_DIR" "$EXECUTABLE_NAME"'
def profile(configuration="debug", **variables):
    return subprocess.run(["bash", "-c", command, "test", str(root), configuration], env={**base_env, **variables}, text=True, capture_output=True)
def rejected(**variables):
    result = profile(**variables)
    assert result.returncode != 0, result.stdout
    return result.stderr.strip()

assert profile().stdout.splitlines() == ["development", "com.tangfanx.popdeck.dev", str(root / ".build/PopDeck Dev.app"), "PopDeckDev"]
assert profile("release").stdout.splitlines()[1] == "com.tangfanx.popdeck"
assert profile("release", POPDECK_CHANNEL="development").stdout.splitlines()[1] == "com.tangfanx.popdeck.dev"
rejected(POPDECK_BUNDLE_ID="com.tangfanx.popdeck")
rejected(POPDECK_APP_DIR="/Applications/PopDeck.app")
rejected(POPDECK_APP_DIR=str(root / ".build/PopDeck.app"))
with tempfile.TemporaryDirectory(dir=root / ".build") as directory:
    folder = Path(directory)
    app = folder / "ExistingProduction.app"
    (app / "Contents").mkdir(parents=True)
    (app / "Contents/Info.plist").write_bytes(plistlib.dumps({"CFBundleIdentifier": "com.tangfanx.popdeck"}))
    rejected(POPDECK_APP_DIR=str(app))
    test_app = folder / "ExistingTest.app"
    (test_app / "Contents").mkdir(parents=True)
    (test_app / "Contents/Info.plist").write_bytes(plistlib.dumps({"CFBundleIdentifier": "com.tangfanx.popdeck.dev"}))
    rejected(configuration="release", POPDECK_APP_DIR=str(test_app))
    link = folder / "outside"
    link.symlink_to("/Applications", target_is_directory=True)
    rejected(POPDECK_APP_DIR=str(link / "PopDeck.app"))
print("Passed: channel defaults, optimized dev profile, production-ID guard, output and symlink guards, existing production artifact guard.")

for script in ["package-dmg.sh", "package-release.sh"]:
    result = subprocess.run([str(root / "scripts" / script), "debug"], env=base_env, capture_output=True, text=True)
    assert result.returncode != 0
    result = subprocess.run([str(root / "scripts" / script), "release"], env={**base_env, "POPDECK_CHANNEL": "development"}, capture_output=True, text=True)
    assert result.returncode != 0
print("Passed: distribution scripts refuse debug and development packages.")
