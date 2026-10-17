#!/usr/bin/env python3
import importlib.util
from pathlib import Path
import tempfile

root = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('audit', root / 'scripts/audit-public-source.py')
audit = importlib.util.module_from_spec(spec); spec.loader.exec_module(audit)
with tempfile.TemporaryDirectory() as directory:
    base = Path(directory)
    sources = base / 'Sources'; sources.mkdir()
    assert audit.audit(base) == []
    file = sources / 'Feature.swift'
    file.write_text('struct GroupFanView {}')
    assert any('PRO implementation' in error for error in audit.audit(base))
    file.unlink()
    file = sources / 'signing-key.json'; file.write_text('{}')
    assert any('private path' in error for error in audit.audit(base)); file.unlink()
    file = sources / 'public.json'; file.write_text('{"keys":{"test":{"kty":"EC","d":"TEST-ONLY"}}}')
    assert any('private JWK' in error for error in audit.audit(base)); file.unlink()
    file.write_text('{"format":"popdeck-license","version":1,"code":"TEST-ONLY"}')
    assert any('activation credential' in error for error in audit.audit(base)); file.unlink()
    file = sources / 'escape.swift'; file.symlink_to(root / 'Package.swift')
    assert any('symlink' in error for error in audit.audit(base)); file.unlink()
    (base / '.popdeck-pro-root').write_text('/outside/private')
    (base / '.private').mkdir(); (base / '.private/ledger.json').write_text('{}')
    (base / 'site').mkdir(); (base / 'site/secret.json').write_text('{}')
    assert not audit.public_files(base)
print('PASS: PRO implementation, private path/JWK/credential and symlink rejection; local private/deployment data excluded from export allowlist.')
