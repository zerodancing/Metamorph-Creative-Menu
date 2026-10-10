from pathlib import Path
import sys
root=Path(sys.argv[1]).resolve()
menu=(root/'files/ui/menu_controller.lua').read_text()
runtime=(root/'files/ui/runtime.lua').read_text()
assert 'inventory_cursor_guard' not in menu, 'failed native tooltip shield is still wired into menu runtime'
assert not (root/'files/platform/noita/inventory_cursor_guard.lua').exists(), 'dead tooltip-shield module still ships in release'
assert 'fully opaque dark backing' not in runtime, 'opaque tooltip-occlusion backing still changes menu appearance'
assert '{0.018, 0.018, 0.012, 1.0}' not in runtime, 'opaque panel backing still present'
print('menu_overlay_revert_contract=PASS stock_transparency=true tooltip_shield_removed=true')
