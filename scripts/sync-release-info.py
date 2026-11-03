#!/usr/bin/env python3
"""Generate private website release links from the shared public version file."""
from pathlib import Path
import json
import re

root = Path(__file__).resolve().parents[1]
version = (root / 'VERSION').read_text().strip()
if not re.fullmatch(r'\d+\.\d+\.\d+', version):
    raise SystemExit('Invalid shared release version')
info = {
    'version': version,
    'mac': {'url': '/api/download', 'notes': f'https://github.com/IceTeddy/popdeck/releases/tag/v{version}'},
    'windows': {
        'x64': f'/windows/download/PopDeck-{version}-Windows-x64.zip',
        'arm64': f'/windows/download/PopDeck-{version}-Windows-arm64.zip',
        'notes': f'https://github.com/IceTeddy/popdeck/releases/tag/windows-v{version}'
    }
}
site = root / 'site'
if not site.is_dir():
    raise SystemExit('Private website source directory is not present in this checkout')
(site / 'release-info.js').write_text('window.POPDECK_RELEASE = ' + json.dumps(info, ensure_ascii=False, indent=2) + ';\n')
print('Website release metadata generated for ' + version)
