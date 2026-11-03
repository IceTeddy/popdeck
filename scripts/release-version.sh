#!/usr/bin/env bash
# Shared marketing version. ROOT_DIR must point at the checkout before sourcing.
RELEASE_VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
MACOS_BUILD_NUMBER="$(tr -d '[:space:]' < "$ROOT_DIR/MACOS_BUILD_NUMBER")"
if [[ ! "$RELEASE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ || ! "$MACOS_BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
    echo 'Invalid shared release version metadata.' >&2
    exit 2
fi
