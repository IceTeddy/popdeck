# Release Notes

This document describes the current manual release process for PopDeck. Sparkle update signing is configured; Developer ID signing and notarization are not yet enabled. Publish the DMG before making its appcast item live.

## Current Release Identity

- App name: `PopDeck`
- Bundle identifier: `com.tangfanx.popdeck`
- Version: `0.1.8`
- Build: `9`
- Minimum macOS version: `14.0`

## Create Local Artifacts

From the repository root:

```bash
./scripts/package-dmg.sh
```

This creates:

```text
dist/PopDeck-0.1.8.dmg
dist/PopDeck-0.1.8.dmg.sha256
```

## Publish On GitHub

1. Create a GitHub Release tag such as `v0.1.8`.
2. Upload `dist/PopDeck-0.1.8.dmg`.
3. Keep the release notes short and user-facing.
4. Clearly state that the build is currently unsigned.

Sparkle uses the same DMG through `appcast.xml`, so the release page should not upload a separate automatic-update zip.

## Before Public Promotion

- Add Developer ID signing.
- Add Apple notarization.
- Verify the Sparkle update flow from the previous release.
- Decide whether appcast and release assets should stay on GitHub Releases or move to Cloudflare R2.
