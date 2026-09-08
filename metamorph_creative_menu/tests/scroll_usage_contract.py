from pathlib import Path
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()
failures = []
def fail(message): failures.append(message)

def read(rel): return (root / rel).read_text(encoding='utf-8')

def png_size(rel):
    data = (root / rel).read_bytes()
    if len(data) < 24 or data[:8] != b'\x89PNG\r\n\x1a\n':
        fail(f'invalid PNG asset: {rel}')
        return 0, 0
    return int.from_bytes(data[16:20], 'big'), int.from_bytes(data[20:24], 'big')

runtime = read('files/ui/runtime.lua')
scroll = read('files/ui/widgets/scroll_model.lua')
horizontal = read('files/ui/widgets/horizontal_strip.lua')
spells = read('files/ui/tabs/spells.lua')
wand_presets = read('files/ui/components/wand_presets.lua')

for dead in ('function ui_runtime.reset_scroll', 'ui_runtime.SCROLL_STEP', 'ui_runtime.HORIZONTAL_SCROLL_STEP',
             'ui_runtime.SCROLLBAR_WIDTH'):
    if dead in runtime: fail(f'dead runtime scroll API retained: {dead}')
if 'function scroll_model.wheel_owner' in scroll:
    fail('test-only scroll_model.wheel_owner accessor retained')
if 'wheel_enabled' in horizontal or 'wheel_enabled' in spells:
    fail('dead wheel_enabled branch/plumbing retained')
if 'scroll_model' in horizontal or 'consume_wheel' in horizontal:
    fail('horizontal strip still consumes wheel input')
if 'GuiImageButton' not in horizontal or 'page_left.png' not in horizontal or 'page_right.png' not in horizontal:
    fail('horizontal strip is missing its tall high-contrast image navigation arrows')
if '"<<<"' in horizontal or '">>>"' in horizontal:
    fail('horizontal strip still wastes slot width on repeated text chevrons')
for arrow in ('files/ui/assets/page_left.png', 'files/ui/assets/page_right.png'):
    width, height = png_size(arrow)
    if width > 10:
        fail(f'navigation arrow is too wide and steals spell-slot space: {arrow}={width}x{height}')
    if height < 20:
        fail(f'navigation arrow is too short to be visually prominent: {arrow}={width}x{height}')
if 'pointer.left_just_down' in horizontal or 'state.drag' in horizontal:
    fail('horizontal strip still has an ambiguous LMB pan recognizer')
if 'ui.begin_scroll_viewport("spells.workspace."' not in spells:
    fail('Spells workspace bypasses shared runtime viewport')
if 'ui.columns(workspace_content_width' not in spells:
    fail('spell catalogue grid ignores actual viewport content width')
if 'begin_scroll_viewport' in wand_presets or 'end_scroll_viewport' in wand_presets:
    fail('wand presets create a nested scroll viewport inside the already-scrollable WAND workspace')

for name in ('controls','creatures','effects','items','materials','perks','players','spells','weather','world_rules'):
    if 'ui.begin_scroll_viewport' not in read(f'files/ui/tabs/{name}.lua'):
        fail(f'{name} tab bypasses shared viewport')

if failures:
    print('scroll_usage_contract=FAIL')
    for message in failures: print(' -', message)
    raise SystemExit(1)
print('scroll_usage_contract=PASS shared_tabs=true horizontal_wheel=false inline_arrows=true')
