from pathlib import Path
import shutil
import subprocess
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()
texluac = shutil.which('texluac')
if not texluac:
    raise SystemExit('texluac not found')

lua_files = sorted(root.rglob('*.lua'))
failed = []
for path in lua_files:
    result = subprocess.run([texluac, '-p', str(path)], capture_output=True, text=True)
    if result.returncode != 0:
        failed.append((path.relative_to(root), result.stderr.strip() or result.stdout.strip()))

if failed:
    for path, error in failed:
        print(f'syntax.FAIL {path}: {error}')
    raise SystemExit(1)
print(f'syntax_contract=PASS lua_files={len(lua_files)}')
