<p align="center"><img src="docs/assets/popdeck-logo.png" width="128" alt="PopDeck"></p>
<h1 align="center">PopDeck</h1>

[Website](https://popdeck.pages.dev/) · [中文](README.zh-CN.md)

A native macOS radial launcher built with SwiftUI and AppKit. This repository provides the independently buildable **single-ring Free source edition**. Multiple rings, groups, command sets, license activation, and their tests/resources are maintained in an external private source overlay, outside the public source distribution.

Free features include apps, files, folders, URLs, editable shell commands (silent or Terminal execution), Emoji/icon colors, text display and curved typography, sector widths, panel sizing, hover sounds, shortcuts and launch at login. macOS 26+ uses native Liquid Glass; earlier systems use the existing blur material.

PRO is planned as a ¥6 one-time personal lifetime purchase, including future updates on the buyer's own Macs. It is currently being validated only in an independent development app and has not been released. Public PRO badges and information do not include paid feature implementations or license verification.

## Build and test

Requires macOS 14+, Xcode 26+ or a matching Swift toolchain.

```sh
swift build
./scripts/test-edition.sh free
POPDECK_EDITION=free ./scripts/run-app.sh debug
```

`swift build` and `swift test` default to public Free sources only. The run script builds/signs/opens `.build/PopDeck Dev.app`; it never installs or replaces `/Applications/PopDeck.app`. Public clones without private local configuration also run Free with `./scripts/run-app.sh debug`.

Commands run with `/bin/zsh -lc` in the user's home directory. Multiline commands, pipes and redirection are supported. Use Terminal mode when interactive input is required.

Unsupported configuration entries remain inert placeholders with unknown JSON fields preserved; other ring preference keys are untouched. Explicit resets/deletions still follow the user's action. The public source build does not activate PRO. Licenses are stored separately from panel preferences and are not deleted when switching builds.

## Public source boundary

```sh
python3 scripts/audit-public-source.py --history
python3 scripts/export-public-source.py
```

The default export is `.build/public-source`: an allowlisted Free source tree, tests, documentation and build tools with a SHA-256 inventory. It excludes Git metadata, private overlays, local configuration, caches, issuer tools, private keys, ledgers and activation credentials. Existing export directories are never overwritten.

[Source boundaries and private local builds](docs/source-boundaries.md) · [Independent development builds](docs/development-builds.md)

## License

Public Free source remains under the [MIT License](LICENSE). Previously published grants remain unchanged. The unpublished external PRO implementation is outside this public source distribution.
