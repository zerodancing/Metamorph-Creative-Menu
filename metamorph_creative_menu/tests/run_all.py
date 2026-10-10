from pathlib import Path
import shutil
import subprocess
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()
texlua = shutil.which('texlua')
if not texlua:
    raise SystemExit('texlua not found')

# Contracts are discovered automatically so a newly added contract cannot be forgotten
# in the runner. Keep a small deterministic order for foundational checks; remaining
# contracts are appended alphabetically.
preferred_contracts = [
    'syntax_contract.py',
    'architecture_contract.py',
    'behavior_coverage_contract.py',
    'localization_contract.py',
    'qa_phase_contract.py',
]
contract_paths = {path.name: path for path in (root / 'tests').glob('*_contract.py')}
ordered_contracts = []
for name in preferred_contracts:
    path = contract_paths.pop(name, None)
    if path is not None:
        ordered_contracts.append(path)
ordered_contracts.extend(contract_paths[name] for name in sorted(contract_paths))

# Every Lua mock is executable regression coverage. Auto-discovery prevents the common
# failure mode where a useful new test exists in tests/ but run_all.py never invokes it.
mock_paths = sorted((root / 'tests').glob('*_mock.lua'), key=lambda path: path.name)

commands = [[sys.executable, str(path), str(root)] for path in ordered_contracts]
commands.extend([[texlua, str(path), str(root)] for path in mock_paths])

for command in commands:
    print('+', ' '.join(command), flush=True)
    subprocess.run(command, check=True)

print(
    'ALL_REGRESSION_TESTS=PASS '
    f'count={len(commands)} contracts={len(ordered_contracts)} behavioral_mocks={len(mock_paths)}'
)
