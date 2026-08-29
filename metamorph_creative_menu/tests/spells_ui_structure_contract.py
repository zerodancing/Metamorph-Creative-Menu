from pathlib import Path
import csv
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()
spells = (root / 'files/ui/tabs/spells.lua').read_text(encoding='utf-8')

failures = []
def require(condition: bool, message: str) -> None:
    if not condition:
        failures.append(message)

def section(first_marker: str, next_marker: str) -> str:
    first = spells.find(first_marker)
    last = spells.find(next_marker, first + len(first_marker)) if first >= 0 else -1
    require(first >= 0, f'missing marker: {first_marker}')
    require(last >= 0, f'missing next marker: {next_marker}')
    return spells[first:last] if first >= 0 and last >= 0 else ''

require('placement_mode' not in spells, 'hidden placement_mode state still exists')
require('workspace == "loadout"' not in spells and 'draw_loadout' not in spells,
        'removed LOADOUT workspace still exists')
for key in ('mcm_spell_workspace_loadout', 'mcm_spell_mode_replace', 'mcm_spell_mode_insert',
            'mcm_spell_mode_append', 'mcm_spell_mode_always'):
    require(key not in spells, f'removed workspace/mode key still referenced: {key}')

catalog = section('    local function draw_catalog()', '    local function draw_wand_tools()')
for call, label in (('draw_slot_strip()', 'wand slots'), ('draw_always_cast()', 'Always Cast'),
                    ('draw_inventory()', 'spell inventory')):
    require(catalog.count(call) == 1, f'CATALOG must render {label} exactly once')
positions = [catalog.find('$mcm_spell_controls_hint'), catalog.find('draw_slot_strip()'),
             catalog.find('draw_always_cast()'), catalog.find('draw_inventory()')]
require(all(p >= 0 for p in positions) and positions == sorted(positions),
        'CATALOG controls/surfaces are not in the documented order')

wand = section('    local function draw_wand_tools()', '    GuiLayoutBeginVertical(ui.gui(), 0, 2, true)')
require('draw_slot_strip()' not in wand and 'draw_always_cast()' not in wand and 'draw_inventory()' not in wand,
        'WAND duplicates a CATALOG placement strip')
require('wand_editor.draw' in wand and 'wand_presets.draw' in wand,
        'WAND must contain editor + presets')

workspace = section('    local workspace_items = {', '    -- The entire active workspace')
require(workspace.count('$mcm_spell_workspace_catalog') == 1, 'CATALOG workspace button missing/duplicated')
require(workspace.count('$mcm_spell_workspace_wand') == 1, 'WAND workspace button missing/duplicated')
require('LOADOUT' not in workspace, 'LOADOUT button still rendered')

with (root / 'translations.csv').open('r', encoding='utf-8-sig', newline='') as handle:
    rows = list(csv.reader(handle))
by_key = {row[0]: row for row in rows[1:] if row}
for key in ('mcm_spell_workspace_loadout', 'mcm_spell_mode_replace', 'mcm_spell_mode_insert',
            'mcm_spell_mode_append', 'mcm_spell_mode_always', 'mcm_wand_strip_drag_hint'):
    require(key not in by_key, f'dead translation retained: {key}')
hint = by_key.get('mcm_spell_controls_hint')
require(hint is not None, 'localized spell controls hint missing')
if hint is not None:
    require(len(hint) == 15, f'spell controls hint has {len(hint)} columns, expected 15')
    require(all(hint[i].strip() for i in range(1, 12)), 'spell controls hint has blank game-language column')
scroll_hint = by_key.get('mcm_wand_strip_hint')
require(scroll_hint is not None, 'horizontal strip wheel hint missing')
if scroll_hint is not None:
    require(all(scroll_hint[i].strip() for i in range(1, 12)), 'horizontal strip hint has blank game-language column')
    require('drag' not in scroll_hint[1].lower(), 'English strip hint still promises drag-to-scroll')

if failures:
    print('spells_ui_structure_contract=FAIL')
    for failure in failures:
        print(' -', failure)
    raise SystemExit(1)
print('spells_ui_structure_contract=PASS workspaces=2 catalog_surfaces=3 wand_strips=0 placement_modes=false hints_localized=true')
