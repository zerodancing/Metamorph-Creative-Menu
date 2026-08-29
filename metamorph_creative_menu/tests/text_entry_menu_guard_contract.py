from pathlib import Path
import sys
root=Path(sys.argv[1]).resolve()
menu=(root/'files/ui/menu_controller.lua').read_text()
runtime=(root/'files/ui/runtime.lua').read_text()
bindings=(root/'files/platform/noita/action_bindings.lua').read_text()
translations=(root/'translations.csv').read_text(encoding='utf-8-sig')
assert 'ui.text_input_active() == true' in menu, 'menu does not observe focused text input'
assert 'menu_inventory_guard.acquire_manual_controls(player)' in menu, 'focused text does not suppress player controls'
assert 'pending_selection_restore = menu_inventory_guard.capture_scroll_selection(player)' in menu, 'numeric typing does not protect active held-item selection'
assert 'text_entry_guard.active()' in bindings, 'hotkey dispatcher ignores text-entry focus'
assert 'placeholder=ui_runtime.tr("$mcm_search_placeholder", "Search...")' in runtime, 'search has no real placeholder'
assert 'stable_text_input_id' in runtime, 'editable fields do not derive native identity from focus_key'
assert 'GuiButton(gui, ui_runtime.next_id(), 0, 0' not in runtime, 'editable fields still swap to GuiButton while inactive'
assert 'prominent=true' not in runtime, 'search still has the old accent outline'
assert 'mcm_search_placeholder' in translations, 'search placeholder localization missing'
print('text_entry_menu_guard_contract=PASS hotkeys=true held_item=true placeholder=true persistent_native=true')
