#!/usr/bin/env python3
"""Compose local private overlays into ignored build staging. Never copy secrets."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys

root = Path(__file__).resolve().parent.parent
edition = sys.argv[1] if len(sys.argv) > 1 else 'free'
if edition not in ('free', 'pro'):
    sys.exit('Edition must be free or pro')
if edition == 'free':
    print('Free: public sources only; no private overlay loaded.')
    sys.exit(0)
config = root / '.popdeck-pro-root'
value = os.environ.get('POPDECK_PRO_ROOT') or (config.read_text().strip() if config.exists() else '')
if not value:
    sys.exit('PRO requires an external POPDECK_PRO_ROOT or ignored .popdeck-pro-root file.')
private = Path(value).expanduser().resolve()
if private == root or root in private.parents:
    sys.exit('The private source overlay must be outside the public repository.')
if not (private / 'overlay.json').is_file():
    sys.exit('Missing private overlay.json; refusing to guess a source tree.')
manifest = json.loads((private / 'overlay.json').read_text())
if manifest.get('product') != 'popdeck-pro' or manifest.get('version') != 1:
    sys.exit('Invalid private overlay manifest.')
target = root / '.build/editions/pro'
if target.exists():
    shutil.rmtree(target)
target.mkdir(parents=True)
for folder in ('Sources', 'Tests'):
    shutil.copytree(root / folder, target / folder)
for name in manifest.get('excludeTests', []):
    if Path(name).name != name:
        sys.exit('Unsafe test exclusion.')
    path = target / 'Tests/PopDeckTests' / name
    if path.exists(): path.unlink()
hashes = {}
for relative in manifest['files']:
    path = Path(relative)
    if path.is_absolute() or '..' in path.parts or path.parts[0] not in ('Sources', 'Tests'):
        sys.exit('Unsafe overlay path.')
    source = private / path
    if source.is_symlink() or not source.is_file() or private not in source.resolve().parents:
        sys.exit('Unsafe or missing private source: ' + relative)
    if source.name in ('signing-key.json', 'ledger.json', 'owner-test-license.json') or '.private' in source.parts:
        sys.exit('Licensing secrets may not be staged into app sources.')
    if source.suffix == '.json':
        value = json.loads(source.read_text())
        if 'keys' in value and any('d' in key for key in value['keys'].values()):
            sys.exit('Private JWK may not be staged.')
    destination = target / path
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    hashes[relative] = hashlib.sha256(source.read_bytes()).hexdigest()
(target / 'prepared.json').write_text(json.dumps({'edition': 'pro', 'sha256': hashes}, indent=2) + '\n')
print('PRO: composed public foundation + external private overlay into .build/editions/pro.')
