from pathlib import Path
import re
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()
source = (root / 'files/qa/runner.lua').read_text(errors='replace')

# This test intentionally does not prescribe the names or count of QA scenarios. It only
# verifies the state machine is internally complete: every literal transition target has
# a handler. Scenario behavior itself belongs in Lua mocks and in the in-game QA run.
handled = set(re.findall(r'state\.phase\s*==\s*"([^"]+)"', source))
targets = set(re.findall(r'set_wait\([^,]+,\s*"([^"]+)"\)', source))
for line in source.splitlines():
    if 'state.phase=' in line or 'state.phase =' in line:
        rhs = line.split('state.phase', 1)[1]
        targets.update(re.findall(r'"([a-z][a-z0-9_]+)"', rhs))
targets.update(re.findall(r'state\s*=\s*\{[^\n]*phase="([^"]+)"', source))

missing_handlers = sorted(targets - handled)
if missing_handlers:
    raise SystemExit('qa_phase_contract=FAIL missing_handlers=' + ','.join(missing_handlers))

# A phase handler that is never a transition target is suspicious, but the initial phase
# is expected to be entered directly when a run is created. Require at least one coherent
# graph rather than an exact historical phase list.
if not handled or not targets:
    raise SystemExit('qa_phase_contract=FAIL empty_state_machine')

print(f'qa_phase_contract=PASS handled={len(handled)} transition_targets={len(targets)}')
