# Automatic Updates

PopDeck uses Sparkle 2 for automatic updates.

## Current Setup

- Sparkle version: `2.9.3`
- Sparkle package source: official `Sparkle-for-Swift-Package-Manager.zip`
- Appcast URL: `https://raw.githubusercontent.com/IceTeddy/popdeck/main/appcast.xml`
- Sparkle signing key account: `com.tangfanx.popdeck`
- Public EdDSA key in `Info.plist`: `n3WgaOnCNdk+273b1SSVHk/EFfWuojekFYpUxkkvhKY=`

The private EdDSA key is stored in the macOS Keychain and must not be committed to the repository.

## App Integration

The menu bar menu includes a `Check for Updates...` item wired to Sparkle's `SPUStandardUpdaterController`.

Sparkle is only enabled when PopDeck is running from a packaged `.app` bundle with `SUFeedURL` and `SUPublicEDKey` in its `Info.plist`.

Sparkle's standard UI uses bundle localization. PopDeck bridges its in-app language setting to Sparkle by setting the app's `AppleLanguages` preference before creating `SPUStandardUpdaterController`.

- Chinese setting: `zh-Hans`, `zh_CN`, `zh`, then `en`
- English setting: `en`

Do not use `swift run` to test Sparkle. `swift run` starts a bare executable instead of the packaged app bundle, so Sparkle cannot reliably launch its updater services. Use:

```bash
./scripts/run-app.sh
```

or:

```bash
./scripts/build-app.sh debug
open .build/PopDeck.app
```

The build script embeds `Sparkle.framework` into:

```text
.build/PopDeck.app/Contents/Frameworks/
```

It also adds the app rpath required for the executable to load the embedded framework:

```text
@executable_path/../Frameworks
```

The packaged app is also ad-hoc signed after clearing extended attributes:

```bash
xattr -cr .build/PopDeck.app
codesign --force --deep --sign - .build/PopDeck.app
```

This does not replace Developer ID signing, but it gives Sparkle's embedded XPC services and updater app a valid local signing boundary for development builds.

## Generating The Appcast

PopDeck uses the public DMG as the Sparkle update archive. Create the DMG first:

```bash
./scripts/package-dmg.sh
```

Then generate the signed appcast:

```bash
./scripts/generate-appcast.sh
```

`generate_appcast` writes the `sparkle:edSignature` and `length` attributes into `appcast.xml`.

## Next Release Workflow

1. Bump `MARKETING_VERSION` and `BUILD_NUMBER` in `scripts/build-app.sh`.
2. Build the release DMG with `./scripts/package-dmg.sh`.
3. Generate or update `appcast.xml` with `./scripts/generate-appcast.sh`.
4. Publish the DMG on GitHub Releases.
5. Commit and push the updated `appcast.xml`.
6. Use PopDeck's `Check for Updates...` menu item from an older installed build.
