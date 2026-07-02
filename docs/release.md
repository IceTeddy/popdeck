# Release Notes

This document describes the current manual release process for PopDeck. It is intentionally simple so the project can publish early builds before Sparkle, signing, and notarization are fully wired in.

## Current Release Identity

- App name: `PopDeck`
- Bundle identifier: `com.tangfanx.popdeck`
- Version: `0.1.4`
- Build: `4`
- Minimum macOS version: `14.0`

## Create Local Artifacts

From the repository root:

```bash
./scripts/package-release.sh
```

This creates:

```text
dist/PopDeck-0.1.4.zip
dist/PopDeck-0.1.4.zip.sha256
```

## Publish On GitHub

1. Create a GitHub Release tag such as `v0.1.4`.
2. Upload `dist/PopDeck-0.1.4.zip`.
3. Include the SHA256 value from `dist/PopDeck-0.1.4.zip.sha256` in the release notes.
4. Clearly state that the build is currently unsigned.

## Before Public Promotion

- Add Developer ID signing.
- Add Apple notarization.
- Verify the Sparkle update flow from the previous release.
- Decide whether appcast and release assets should stay on GitHub Releases or move to Cloudflare R2.
