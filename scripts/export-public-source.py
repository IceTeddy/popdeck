#!/usr/bin/env python3
"""Export a reviewable Free source tree using a positive path allowlist."""
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import sys

root = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('public_audit', root / 'scripts/audit-public-source.py')
audit = importlib.util.module_from_spec(spec); spec.loader.exec_module(audit)
errors = audit.audit(root)
if errors: sys.exit('\n'.join(errors))
output = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else root / '.build/public-source'
if output.exists(): sys.exit('Export path already exists; use a new review directory.')
output.mkdir(parents=True)
manifest = {}
for source in audit.public_files(root):
    relative = source.relative_to(root)
    destination = output / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    manifest[str(relative)] = hashlib.sha256(source.read_bytes()).hexdigest()
(output / 'PUBLIC_SOURCE_MANIFEST.json').write_text(json.dumps({'edition': 'free', 'sha256': manifest}, indent=2) + '\n')
print(f'Exported {len(manifest)} audited public files to {output}. No .git, private overlay, local configuration, build cache or issuer data included.')
