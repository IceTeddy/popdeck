"""Select an existing development certificate and retain that choice locally."""
from pathlib import Path
import re
import subprocess
import sys

saved = Path(sys.argv[1])
identities = subprocess.check_output(
    ['security', 'find-identity', '-v', '-p', 'codesigning'], text=True
)
valid = re.findall(r'\b([A-F0-9]{40}) "Apple Development:[^"]+"', identities)
if saved.exists():
    chosen = saved.read_text().strip()
    if chosen not in valid:
        sys.exit('Saved development certificate is unavailable. Set POPDECK_CODESIGN_IDENTITY explicitly instead of silently changing identity.')
else:
    chosen = valid[0] if valid else '-'
    if chosen != '-':
        saved.write_text(chosen + '\n')
if chosen == '-':
    print('No Apple Development certificate found; using ad-hoc signing. Test permissions may need renewed approval.', file=sys.stderr)
print(chosen)
