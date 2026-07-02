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

The build script embeds `Sparkle.framework` into:

```text
.build/PopDeck.app/Contents/Frameworks/
```

It also adds the app rpath required for the executable to load the embedded framework:

```text
@executable_path/../Frameworks
```

## Signing An Update Archive

After creating a release zip:

```bash
./scripts/package-release.sh
.build/artifacts/halohub/Sparkle/bin/sign_update --account com.tangfanx.popdeck dist/PopDeck-0.1.0.zip
```

The command prints `sparkle:edSignature` and `length` attributes for the appcast item.

## Next Release Workflow

For the first real update test, publish a new version such as `0.1.1`:

1. Bump `MARKETING_VERSION` and `BUILD_NUMBER` in `scripts/build-app.sh`.
2. Build the release zip with `./scripts/package-release.sh`.
3. Publish the zip on GitHub Releases.
4. Generate or update `appcast.xml` with Sparkle's `generate_appcast`.
5. Commit and push the updated `appcast.xml`.
6. Use PopDeck's `Check for Updates...` menu item from an older installed build.

The current `appcast.xml` is intentionally minimal. It keeps the feed URL live while the first Sparkle-enabled build is being prepared.
