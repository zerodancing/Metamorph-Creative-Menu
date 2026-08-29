from pathlib import Path
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()
failures = []
def fail(message): failures.append(message)

def read(rel): return (root / rel).read_text(encoding='utf-8')

runtime = read('files/ui/runtime.lua')
scroll = read('files/ui/widgets/scroll_model.lua')
horizontal = read('files/ui/widgets/horizontal_strip.lua')
spells = read('files/ui/tabs/spells.lua')

for dead in ('function ui_runtime.reset_scroll', 'ui_runtime.SCROLL_STEP', 'ui_runtime.HORIZONTAL_SCROLL_STEP',
             'ui_runtime.SCROLLBAR_WIDTH'):
    if dead in runtime: fail(f'dead runtime scroll API retained: {dead}')
if 'function scroll_model.wheel_owner' in scroll:
    fail('test-only scroll_model.wheel_owner accessor retained')
if 'wheel_enabled' in horizontal or 'wheel_enabled' in spells:
    fail('dead wheel_enabled branch/plumbing retained')
if 'scroll_model.consume_wheel' not in horizontal:
    fail('horizontal strip bypasses shared wheel ownership')
if 'pointer.left_just_down' in horizontal or 'state.drag' in horizontal:
    fail('horizontal strip still has an ambiguous LMB pan recognizer')
if 'ui.begin_scroll_viewport("spells.workspace."' not in spells:
    fail('Spells workspace bypasses shared runtime viewport')
if 'ui.columns(workspace_content_width' not in spells:
    fail('spell catalogue grid ignores actual viewport content width')

for name in ('controls','creatures','effects','items','materials','perks','players','spells','weather','world_rules'):
    if 'ui.begin_scroll_viewport' not in read(f'files/ui/tabs/{name}.lua'):
        fail(f'{name} tab bypasses shared viewport')

if failures:
    print('scroll_usage_contract=FAIL')
    for message in failures: print(' -', message)
    raise SystemExit(1)
print('scroll_usage_contract=PASS shared_tabs=true no_dead_exports=true wheel_branch=false')
