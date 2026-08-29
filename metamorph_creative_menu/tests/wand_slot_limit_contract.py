from pathlib import Path
import sys
root=Path(sys.argv[1]).resolve()
service=(root/'files/features/wands/service.lua').read_text()
editor=(root/'files/ui/components/wand_editor.lua').read_text()
numeric=(root/'files/ui/components/fixed_numeric_editor.lua').read_text()
blueprints=(root/'files/features/wands/blueprints.lua').read_text()
assert 'local MAX_EDITABLE_SLOTS = 64' in service, 'wand slot safety cap is not 64'
assert 'max=MAX_EDITABLE_SLOTS' in service, 'slot definition does not use the safety cap'
assert 'function wand_service.max_slots()' in service, 'slot limit is not exposed to other write paths'
assert 'max=definition.max' in editor and 'min=definition.min' in editor, 'wand numeric UI does not receive service bounds'
assert 'normalize_candidate' in numeric and 'options.max' in numeric, 'numeric editor does not normalize bounded values'
assert 'requested_capacity > max_slots' in blueprints and 'highest_requested >= max_slots' in blueprints, 'blueprint path can bypass slot cap'
print('wand_slot_limit_contract=PASS max_slots=64 ui_clamp=true blueprint_guard=true')
