# Development and production coexistence

Daily development uses `./scripts/run-app.sh` (debug) or `./scripts/run-app.sh release` (optimized test). Both always build and launch **PopDeck Dev**, never the production identity. Plain `build-app.sh` also defaults to debug/development. Use explicit `build-app.sh release` only to stage a production artifact, or the existing release packaging scripts to distribute it.

| Property | Production | Development |
| --- | --- | --- |
| App | PopDeck.app | PopDeck Dev.app |
| Bundle ID / preferences domain | com.tangfanx.popdeck | com.tangfanx.popdeck.dev |
| Executable | PopDeck | PopDeckDev |
| Default output | .build/PopDeck.app | .build/PopDeck Dev.app |
| Default shortcut | Mouse middle button | Control-Option-Command-H |
| Updates | Production Sparkle feed | Disabled; no production feed/key in bundle |
| Favicon cache | Application Support/PopDeck/Favicons | Application Support/com.tangfanx.popdeck.dev/Favicons |
| Signing | Existing release configuration, ad-hoc by default | Existing Apple Development certificate if available |

Preferences, login-item registration and privacy permissions belong to each app's identity. Single-instance locks are separate. The development menu-bar button includes “Dev”; Settings title and version label identify the test app. Development starts from its own defaults and does not import production items. Users can change the test shortcut independently; choosing the same shortcut in both apps may conflict.

The run script only stops the exact development bundle executable and waits for its exit. It never uses `pkill -x PopDeck`. Build output must resolve inside this project's `.build` directory, including through symlinks. A development build cannot use the production ID or replace an existing production artifact. Packaging refuses development/debug profiles. No build/run script installs into /Applications.

## Stable development signing

The first development build selects an existing Apple Development certificate and remembers its fingerprint in ignored `.build/dev-signing-identity`. Later builds reuse that certificate and fail rather than silently switch when it disappears. To select a certificate explicitly, pass `POPDECK_CODESIGN_IDENTITY` (certificate SHA-1 or identity name). Use the same identity on subsequent builds. Removing the local `.build` signing record allows automatic selection again; pin the environment variable if several certificates are present.

If no Apple Development certificate is available, development falls back to ad-hoc signing with a warning. An independent bundle ID still protects production, but macOS may ask to re-authorize rebuilt test binaries. Stable certificate signing gives the test app a stable designated requirement; privacy approval remains controlled by macOS and is not guaranteed to survive certificate, entitlement, identity, or system-policy changes. No permissions are reset or granted by these scripts.

## Validation (2026-10-17)

- Five existing Swift regression tests passed.
- `python3 scripts/test-build-isolation.py` checks default channel identities, optimized development, production-ID refusal, external output refusal, symlink escape refusal, and existing production bundle protection without compiling or touching installed apps.
- Development bundle passed deep/strict code-signature verification and contains the distinct identifier in its certificate-backed designated requirement.
- Runtime inspection identifies PopDeck Dev Settings, a separate default launcher and Control-Option-Command-H shortcut; the installed production 0.1.8 retains its custom launcher, middle-mouse shortcut and granted permissions.
- Changing the test's show-names preference left the production settings fingerprint unchanged. Executable and Info.plist hashes of /Applications/PopDeck.app remained unchanged.

Apple references: [Bundle identifiers](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleidentifier), [Code-signing requirements and privacy choices](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements).

The final coexistence check observed both installed production and development processes at once. Restarting the development app changed only the development PID; the production PID remained running. The production staging profile was also built in an independent project directory and retained its original identifier and update feed.
