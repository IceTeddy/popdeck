# Native Liquid Glass verification

Verified on macOS 27.0.1 with the macOS 27 SDK, 2026-10-15.

## Findings

The public `NSGlassEffectView` API renders real edge refraction in PopDeck's actual circular panel. No custom edge highlight, shader, screenshot backdrop, private selector, or undocumented glass-style enum value is needed.

The important defect was the panel's window state. The previous borderless `NSPanel` could not become key and was shown using `orderFrontRegardless()`. In a controlled comparison, that state rendered the native clear material as a heavily frosted surface. A key-capable panel shown with `makeKeyAndOrderFront(_:)` rendered the same material with visible transparency and edge lensing.

The production fix uses a key-capable `HaloFloatingPanel`, retains the nonactivating-panel style, and puts the SwiftUI controls in `NSGlassEffectView.contentView`. Escape closes the panel. The system draws the optical boundary; the custom outer gradient stroke has been removed. The optional Glass intensity slider only sets the native `tintColor` alpha (0 to 0.75, using a black tint to retain contrast with the launcher’s white symbols); it does not add an overlay, modify the content opacity, or interpolate blur radii. Older systems retain the existing `NSVisualEffectView` fallback.

## Actual-panel comparison

Both observations used the real `HaloPanelController` / `HaloPanelView`, the same clear native glass, the same circular size, and the same diagnostic grid placed behind the glass inside that window:

| Window state | Observed result |
| --- | --- |
| Key-capable and key | Grid visible through glass; straight external lines visibly bend and shift at the circular boundary. |
| Non-key-capable, matching the previous implementation | Grid inside the circle largely obscured by frosting; visible edge refraction absent. |

The accessibility state identified the tested window as `PopDeck Panel` and identified it as focused in the active comparison. A window-only screenshot can omit the desktop backdrop sampled by the compositor, so the diagnostic backdrop was used to make refraction inspectable. This confirms native refraction in the actual panel; it is not a pixel-for-pixel comparison against Control Center over arbitrary other apps.

## Public API scope

Apple describes Liquid Glass as a refractive material. AppKit exposes `NSGlassEffectView` and `NSGlassEffectContainerView`; its documented glass styles are regular and clear. The installed SDK also exposes corner radius, tint, content, and (on macOS 27) interactivity. SwiftUI exposes `glassEffect`, the regular/clear variants, tint, interactivity, grouping and transitions.

There is no documented Control Center preset or independent lens-strength/bezel-width property in these interfaces. The presence of native refraction does not guarantee identical rendering to every system component: geometry, backdrop, window activity, system version, and accessibility settings affect the appearance. No private Control Center implementation is assumed here.

## Reproduce

Build a debug app with `./scripts/build-app.sh debug`. Quit an existing PopDeck instance before launching each mode:

```sh
open -n .build/PopDeck.app --args --verify-glass
```

```sh
open -n .build/PopDeck.app --args --verify-glass-inactive
```

The second mode intentionally restores the old inability to become key. If Settings is selected by the inspection tool, close Settings to inspect `PopDeck Panel`. Both grid modes are compiled only in debug builds. Run `./scripts/run-app.sh debug` to return to normal mode. Normal mode contains no diagnostic grid and retains the user's saved launcher items.

## Primary references

- [Apple: Build an AppKit app with the new design, 18:13–21:30](https://developer.apple.com/videos/play/wwdc2025/310/?time=1093): use the actual content as `contentView`; glass samples and refracts nearby content.
- [Apple: Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/): lensing, adaptive appearance, regular/clear variants and accessibility behavior.
- [NSGlassEffectView](https://developer.apple.com/documentation/appkit/nsglasseffectview)
- [NSGlassEffectView.Style](https://developer.apple.com/documentation/appkit/nsglasseffectview/style-swift.enum)
- [NSWindow.canBecomeKey](https://developer.apple.com/documentation/appkit/nswindow/canbecomekey)
- Installed macOS 27 SDK: `AppKit.framework/Headers/NSGlassEffectView.h` and `SwiftUICore.framework/Modules/SwiftUICore.swiftmodule/arm64e-apple-macos.swiftinterface`.
