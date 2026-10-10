from pathlib import Path
import sys
root=Path(sys.argv[1]).resolve()
menu=(root/'files/ui/menu_controller.lua').read_text()
runtime=(root/'files/ui/runtime.lua').read_text()
bindings=(root/'files/platform/noita/action_bindings.lua').read_text()
guard=(root/'files/platform/noita/menu_inventory_guard.lua').read_text()
translations=(root/'translations.csv').read_text(encoding='utf-8-sig')
assert 'ui.text_input_active() == true' in menu, 'menu does not observe focused text input'
assert 'menu_inventory_guard.suppress_text_controls(player)' in menu, 'focused text still relies on disabling the whole ControlsComponent'
assert 'mButtonDownInventory' not in guard or '"Inventory"' in guard, 'text guard does not suppress inventory-toggle action'
assert 'pending_selection_restore = menu_inventory_guard.capture_scroll_selection(player)' in menu, 'numeric typing does not protect active held-item selection'
assert 'text_entry_guard.active()' in bindings, 'hotkey dispatcher ignores text-entry focus'
assert 'placeholder=ui_runtime.tr("$mcm_search_placeholder", "Search...")' in runtime, 'search has no real placeholder'
assert 'stable_text_input_id' in runtime, 'editable fields do not derive native identity from focus_key'
assert 'stable_text_capture_id' in runtime and 'capture_text_away_from_field' in runtime, 'click-once off-hover keyboard capture missing'
assert 'local text_capture_gui = nil' in runtime and 'ensure_text_capture_gui' in runtime, 'off-hover capture does not use an isolated Gui context'
assert 'pending_text_capture' not in runtime and 'flush_text_capture' not in runtime, 'legacy deferred root capture can still scroll/stall the main Gui'
assert 'GUI_OPTION.ForceFocusable' in runtime, 'editable widgets do not request stable native focus'
assert 'GuiButton(gui, ui_runtime.next_id(), 0, 0' not in runtime, 'editable fields still swap to GuiButton while inactive'
assert 'prominent=true' not in runtime, 'search still has the old accent outline'
assert 'mcm_search_placeholder' in translations, 'search placeholder localization missing'
print('text_entry_menu_guard_contract=PASS hotkeys=true text_actions=true held_item=true placeholder=true persistent_native=true isolated_off_hover_capture=true')
