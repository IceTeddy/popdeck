#!/usr/bin/env python3
"""Audit the public source boundary without printing secrets or personal records."""
from pathlib import Path
import json
import re
import subprocess
import sys

TOP = {'.gitignore', 'Package.swift', 'LICENSE', 'README.md', 'README.zh-CN.md', 'appcast.xml'}
DOCS = {'development-builds.md', 'source-boundaries.md', 'native-liquid-glass-verification.md', 'item-editing-validation.md', 'auto-update.md', 'release.md'}
PRIVATE_NAMES = {'signing-key.json', 'ledger.json', 'owner-test-license.json', 'popdeck-public-keys.json', 'pro-alipay.png', 'pro-wechat.png', '.popdeck-pro-root'}
IMPLEMENTATION = re.compile(rb'\b(?:struct|class|enum)\s+(?:ExpandedHaloGroup|GroupFanView|GroupEditorSheet|CommandSetSheet|NamedCommand|ProLicenseStore|ProLicenseVerifier|ProLicensePayload|ProSettingsView|ProFreePreviewControl|HaloRingCollection|HaloRingMetrics|HaloPanelInput|HaloPanelPresentation|SettingsRingGeometry|CommandSetAppearance|CommandSetAppearanceControls|CommandSetSectorLabel)\b')
PEM = re.compile(rb'-----BEGIN (?:EC |RSA |OPENSSH |ENCRYPTED )?PRIVATE KEY-----[\r\n]+[A-Za-z0-9+/=\r\n]{32,}')

def public_files(root):
    result = []
    for name in TOP:
        path = root / name
        if path.is_file(): result.append(path)
    for name in ('Sources', 'Tests', 'scripts'):
        folder = root / name
        if folder.exists(): result += [p for p in folder.rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    docs = root / 'docs'
    if docs.exists():
        result += [p for p in docs.iterdir() if p.is_file() and p.name in DOCS]
        for folder in ('assets', 'releases'):
            if (docs / folder).exists(): result += [p for p in (docs / folder).rglob('*') if p.is_file()]
    return sorted(result)

def inspect_blob(relative, data):
    reasons = []
    path = Path(relative)
    if path.name in PRIVATE_NAMES or (path.name.startswith('ledger') and path.suffix == '.json') or any(x in ('.private', 'author-tools', 'Private', 'ProPrivate') for x in path.parts): reasons.append('private path')
    if 'owner-test' in path.name or path.suffix in ('.pem', '.p12', '.pfx', '.key', '.popdecklicense'): reasons.append('private artifact')
    if path.suffix == '.swift' and IMPLEMENTATION.search(data): reasons.append('PRO implementation')
    if PEM.search(data): reasons.append('private PEM key')
    if path.suffix == '.json':
        try:
            value = json.loads(data)
            def private_jwk(v):
                if isinstance(v, dict): return (v.get('kty') in ('EC', 'RSA', 'OKP') and 'd' in v) or any(private_jwk(x) for x in v.values())
                return isinstance(v, list) and any(private_jwk(x) for x in v)
            if private_jwk(value): reasons.append('private JWK')
            if isinstance(value, dict) and (value.get('format') == 'popdeck-license' or str(value.get('code', '')).startswith(('PDPRO1.', 'TWPRO1.'))): reasons.append('activation credential')
        except (ValueError, UnicodeDecodeError): pass
    return reasons

def audit(root):
    root = root.resolve()
    errors = []
    for path in public_files(root):
        relative = path.relative_to(root)
        if any(root.joinpath(*relative.parts[:i]).is_symlink() for i in range(1, len(relative.parts) + 1)): errors.append(str(relative) + ': symlink'); continue
        reasons = inspect_blob(str(relative), path.read_bytes())
        if reasons: errors.append(str(relative) + ': ' + ', '.join(reasons))
    checked = {str(p.relative_to(root)) for p in public_files(root)}
    tracked = subprocess.run(['git', '-C', str(root), 'ls-files', '-z'], capture_output=True)
    if tracked.returncode == 0:
        for name in tracked.stdout.decode().split('\0'):
            if name and (Path(name).name in PRIVATE_NAMES or any(p in ('.private', 'author-tools', 'Private', 'ProPrivate') for p in Path(name).parts)):
                errors.append(name + ': private path tracked by Git')
            if name and Path(name).parts[0] in ('.build', '.swiftpm', 'dist', 'node_modules'):
                errors.append(name + ': generated/private artifact tracked by Git')
            path = root / name
            if name and name not in checked and path.is_file():
                reasons = inspect_blob(name, path.read_bytes())
                if reasons: errors.append(name + ': tracked outside export boundary: ' + ', '.join(reasons))
    return errors

def audit_history(root, include_internal=False):
    # Only read Git objects; never rewrite history or print matched contents.
    refs = ['--all'] if include_internal else ['--branches', '--tags', '--remotes']
    listing = subprocess.check_output(['git', '-C', str(root), 'rev-list', *refs, '--objects']).decode().splitlines()
    errors, count = [], 0
    for entry in listing:
        parts = entry.split(' ', 1)
        if len(parts) != 2: continue
        oid, name = parts
        if subprocess.check_output(['git', '-C', str(root), 'cat-file', '-t', oid]).strip() != b'blob': continue
        data = subprocess.check_output(['git', '-C', str(root), 'cat-file', '-p', oid]); count += 1
        reasons = inspect_blob(name, data)
        if reasons: errors.append(name + ' @ ' + oid[:10] + ': ' + ', '.join(reasons))
    return count, errors

if __name__ == '__main__':
    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 and not sys.argv[1].startswith('--') else Path(__file__).resolve().parent.parent
    errors = audit(root)
    if '--history' in sys.argv:
        count, history_errors = audit_history(root, '--all-local-refs' in sys.argv); errors += history_errors
        print(f'Inspected {count} historical Git blobs in ' + ('all local refs' if '--all-local-refs' in sys.argv else 'branches/tags/remotes') + ' (read-only).')
        internal = subprocess.check_output(['git', '-C', str(root), 'for-each-ref', '--format=%(refname)', 'refs/codex/']).decode().splitlines()
        if internal: print('NOTE: app-managed local Codex snapshots are excluded from public history scope. Never mirror-push this working directory; source export excludes all .git metadata.')
    if errors:
        print('\n'.join(errors)); sys.exit(1)
    print(f'PASS: {len(public_files(root))} public files; no known PRO implementations, private keys, licensing credentials or ledgers detected.')
