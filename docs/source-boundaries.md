# Public Free / private PRO source boundary

The repository is the independently buildable Free edition. Shared native glass, launch actions, ordinary command editing, icon/Emoji/text appearance, single-panel geometry, permissions, signing isolation and updater infrastructure stay public. PRO implementations, their model/editor/rendering variants, licensing, verification keys, purchase resources, tests and validation notes live in an external private overlay.

This is an explicit **source overlay**, not a separate linked framework: private versions replace a small set of edition-specific files, then compile together with the shared foundation in the same Swift executable target. Keeping internal Swift interfaces avoids widening access modifiers solely for modularization. Shared typography and native panel primitives have been extracted to common files. Some edition-specific model/settings orchestration is intentionally separate because the public edition must contain no advanced feature algorithms.

## Default build

`swift build`, `swift test` and `./scripts/test-edition.sh free` always select public sources by default, even if a private directory exists elsewhere on disk. `POPDECK_EDITION=free ./scripts/run-app.sh debug` runs only the independent Dev app.

The public source Free build provides a single panel. Unknown saved action kinds remain inert, and unknown JSON fields are round-tripped without interpretation. Extra-ring preferences and saved licenses remain untouched. The official full app can therefore recover its advanced configuration when reopened. Explicit removal/reset is still destructive by user choice; do not use it merely to test entitlement.

## Private development composition

Only an author checkout supplies `POPDECK_PRO_ROOT=/absolute/private/path` or an ignored `.popdeck-pro-root` text file. That folder must be outside this repository and have a versioned `overlay.json` allowlist. No private remote dependency or automatic download is configured.

```sh
./scripts/test-edition.sh pro
POPDECK_EDITION=pro ./scripts/run-app.sh debug
```

Preparation copies shared sources/tests into ignored `.build/editions/pro`, applies explicitly listed private files, and records hashes. It refuses unsafe paths, symlinks, signing-key/ledger/owner-license files and private JWKs. The public manifest refuses PRO builds if preparation is absent. Missing private sources fail explicitly; no fake successful unlock or fallback implementation is supplied.

The run script may choose PRO automatically only in a local author checkout with ignored private configuration; explicit `POPDECK_EDITION` always wins. Build-app defaults to Free. Both editions keep the existing Dev signing identity and preference isolation; production installation is never used for validation.

The issuer remains a separate local author tool, with its signing private keys and sales ledger outside both public and private app source trees. App composition receives only verification public keys. Free source exports contain neither verification/activation implementation nor purchase resources.

## Auditing and export

`python3 scripts/audit-public-source.py --history` examines the public allowlist, tracked private paths and branch/tag/remote history. It prints paths and reason categories, never matched secrets. `--all-local-refs` additionally examines application-managed local snapshots, which may contain prior unpublished working files. Such snapshots are not public branches and must not be mirror-pushed. They are not modified or deleted by these tools.

`python3 scripts/export-public-source.py` creates a new `.build/public-source` directory with the same positive allowlist and SHA-256 manifest. No `.git`, private local path, build cache, ignored website deployment configuration or issuer directory is copied. Use this clean tree for publication review; never publish an arbitrary whole-folder ZIP or mirror-push the author checkout. Existing exports are not replaced.

Audits are safeguards for known implementation markers and key/credential formats, not a guarantee against arbitrary future secrets. Review the generated inventory before publication and extend the checks when introducing new private features or data formats. No commit, push, Git history rewrite or release is performed by export.
