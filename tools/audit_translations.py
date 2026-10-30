#!/usr/bin/env python3
"""Read-only language coverage audit. Nonzero exit when strict mode is enabled."""
from pathlib import Path
import json,sys
root=Path(__file__).resolve().parent/'i18n'
source=json.loads((root/'source.json').read_text())['app']
failed=False
for file in sorted(root.glob('*.json')):
 if file.stem in ('source','keys'):continue
 entries=json.loads(file.read_text()).get('app',{})
 missing=[k for k in source if not entries.get(k)]
 same=[k for k in source if entries.get(k)==k and len(k)>9]
 print(f'{file.stem:8} {len(source)-len(missing):>3}/{len(source)} translated entries; {len(missing)} missing; {len(same)} English-identical (review)')
 failed |= bool(missing)
if '--strict' in sys.argv and failed:sys.exit(1)
