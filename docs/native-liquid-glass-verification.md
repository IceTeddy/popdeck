# Native Liquid Glass verification

Verified on macOS 27.0.1 with the macOS 27 SDK, 2026-10-15 and 2026-10-16.

## Findings

The public `NSGlassEffectView` API renders real edge refraction in PopDeck's actual circular panel. No custom edge highlight, shader, screenshot backdrop, private selector, or undocumented glass-style enum value is needed.

The important defect was the panel's window state. The previous borderless `NSPanel` could not become key and was shown using `orderFrontRegardless()`. In a controlled comparison, that state rendered the native clear material as a heavily frosted surface. A key-capable panel shown with `makeKeyAndOrderFront(_:)` rendered the same material with visible transparency and edge lensing.

The production fix uses a key-capable `HaloFloatingPanel`, retains the nonactivating-panel style, and puts the SwiftUI controls in `NSGlassEffectView.contentView`. Escape closes the panel. The system draws the optical boundary; the custom outer gradient stroke has been removed. Version 0.1.8 removes the former intensity slider: it changed tint, not frosting. The app now exposes the documented regular and clear variants, defaults to regular, and leaves `tintColor` nil in both. Existing `glassStrength` values are left untouched and ignored; they are not treated as blur values. Labels and symbols use the semantic primary foreground. Older systems retain the existing `NSVisualEffectView` fallback.

## Actual-panel comparison

Both observations used the real `HaloPanelController` / `HaloPanelView`, the same clear native glass, the same circular size, and the same diagnostic grid placed behind the glass inside that window:

| Window state | Observed result |
| --- | --- |
| Key-capable and key | Grid visible through glass; straight external lines visibly bend and shift at the circular boundary. |
| Non-key-capable, matching the previous implementation | Grid inside the circle largely obscured by frosting; visible edge refraction absent. |

The accessibility state identified the tested window as `PopDeck Panel` and identified it as focused in the active comparison. A window-only screenshot can omit the desktop backdrop sampled by the compositor, so the diagnostic backdrop was used to make refraction inspectable. This confirms native refraction in the actual panel; it is not a pixel-for-pixel comparison against Control Center over arbitrary other apps.

## Public API scope

Apple describes Liquid Glass as a refractive material. AppKit exposes `NSGlassEffectView` and `NSGlassEffectContainerView`; its documented glass styles are regular and clear. The installed SDK also exposes corner radius, tint, content, and (on macOS 27) interactivity. SwiftUI exposes `glassEffect`, the regular/clear variants, tint, interactivity, grouping and transitions.

There is no documented Control Center preset or independent blur-radius, lens-strength or bezel-width property in these interfaces. Apple’s HIG says regular blurs and adjusts background luminosity for legibility; clear emphasizes the background. System appearance and accessibility preferences can influence these variants. The macOS 27 system slider is a user preference, not a documented per-view scalar API. The presence of native refraction does not guarantee identical rendering to every system component: geometry, backdrop, window activity, system version, and accessibility settings affect the appearance. No private Control Center implementation is assumed here.

## Reproduce

Use an independently identified bundle so testing does not overwrite or launch the installed production app:

```sh
POPDECK_BUNDLE_ID=com.tangfanx.popdeck.glass-validation \
POPDECK_APP_DIR="$PWD/.build/glass-validation/PopDeck Glass Test.app" \
./scripts/build-app.sh debug
```

For an isolated visual test, remove `SUFeedURL` and `SUPublicEDKey` from the fixture's Info.plist and re-sign it before launch. Use the separate fixture preferences domain; do not modify `com.tangfanx.popdeck`. Open the fixture with `--verify-glass` for the grid, then choose the two styles in Settings. `--verify-glass-inactive` intentionally restores the old inability to become key. Diagnostic grid modes are compiled only in debug builds. Do not use `run-app.sh` when preserving an installed version for a real-user upgrade test.

On 2026-10-16, the real panel was inspected in both variants with the same split black/white grid. Regular visibly diffused the grid and retained readable foreground on its bright side. Clear preserved the lines and pronounced lensing at the circular edge, with poorer white-background contrast as expected. The fixture started with legacy `glassStrength = 0.5`; its initial style was regular. Selecting clear survived a later launch. These observations do not measure a continuous blur radius or change the system’s settings.

## Primary references

- [Apple: Build an AppKit app with the new design, 18:13–21:30](https://developer.apple.com/videos/play/wwdc2025/310/?time=1093): use the actual content as `contentView`; glass samples and refracts nearby content.
- [Apple: Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/): lensing, adaptive appearance, regular/clear variants and accessibility behavior.
- [NSGlassEffectView](https://developer.apple.com/documentation/appkit/nsglasseffectview)
- [NSGlassEffectView.Style](https://developer.apple.com/documentation/appkit/nsglasseffectview/style-swift.enum)
- [NSWindow.canBecomeKey](https://developer.apple.com/documentation/appkit/nswindow/canbecomekey)
- Installed macOS 27 SDK: `AppKit.framework/Headers/NSGlassEffectView.h` and `SwiftUICore.framework/Modules/SwiftUICore.swiftmodule/arm64e-apple-macos.swiftinterface`.

- [Apple HIG: Materials](https://developer.apple.com/design/human-interface-guidelines/materials): adaptive regular and translucent clear variants.
- [Apple: Platforms State of the Union 2026](https://developer.apple.com/videos/play/wwdc2026/102/): system transparency customization and accessibility adaptation.
