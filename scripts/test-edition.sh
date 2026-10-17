#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
export POPDECK_EDITION="${1:-free}"
python3 scripts/prepare-edition.py "$POPDECK_EDITION"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build-clang-cache"
swift test --disable-sandbox --cache-path .build/local-cache --manifest-cache local
