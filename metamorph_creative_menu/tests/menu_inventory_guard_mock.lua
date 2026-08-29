local root = assert(arg[1], "root required")
local native_dofile = dofile
local bridge_calls = 0
local component_writes = {}
local controls_enabled = true

local patcher_bridge = {
    get = function(request)
        assert(request.capability == "SetActiveHeldEntity", "wrong patcher capability")
        return {
            SetActiveHeldEntity = function(player_entity_id, item_entity_id)
                assert(player_entity_id == 1 and item_entity_id == 10, "wrong active item restore")
                bridge_calls = bridge_calls + 1
            end,
        }
    end,
}
dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua" then return patcher_bridge end
    return native_dofile(path)
end

function GameIsInventoryOpen() return false end
function EntityGetIsAlive(entity_id) return entity_id == 1 or entity_id == 10 or entity_id == 11 end
function EntityGetFirstComponentIncludingDisabled(entity_id, component_type)
    if entity_id == 1 and component_type == "ControlsComponent" then return 20 end
    if entity_id == 1 and component_type == "InventoryGuiComponent" then return 21 end
    if entity_id == 1 and component_type == "Inventory2Component" then return 22 end
    return nil
end
function EntityGetComponentIsEnabled(player_entity_id, component_id) return true end
function ComponentGetValue2(component_id, field_name)
    if component_id == 20 and field_name == "enabled" then return controls_enabled end
    if component_id == 21 and field_name == "mActive" then return true end
    if component_id == 22 and field_name == "mActiveItem" then return 10 end
    if component_id == 22 and field_name == "mActualActiveItem" then return 11 end
    return nil
end
function ComponentSetValue2(component_id, field_name, value)
    component_writes[field_name] = value
    if component_id == 20 and field_name == "enabled" then controls_enabled = value end
end
function EntityGetAllChildren() return {} end
function EntityGetName() return "" end
function EntitySetComponentsWithTagEnabled() end

METAMORPH_CREATIVE_MENU_MENU_INVENTORY_GUARD = nil
local guard = assert(native_dofile(root .. "/files/platform/noita/menu_inventory_guard.lua"))
assert(guard.controls_disabled(1) == false, "enabled controls reported disabled")
assert(guard.inventory_open(1) == true, "InventoryGuiComponent open state was ignored")
local snapshot = assert(guard.capture_scroll_selection(1))
assert(snapshot.active_item_entity_id == 10 and snapshot.actual_active_item_entity_id == 11, "selection snapshot incorrect")
assert(component_writes.mButtonFrameChangeItemR == -1 and component_writes.mButtonCountChangeItemL == 0, "wheel input was not suppressed")
assert(guard.restore_scroll_selection(snapshot) == true, "selection restore failed")
assert(bridge_calls == 1, "NoitaPatcher held-item restore was not used")
assert(component_writes.mActiveItem == 10 and component_writes.mActualActiveItem == 11 and component_writes.mForceRefresh == true, "inventory ids/refresh not restored")
assert(guard.acquire_manual_controls(1)==true and controls_enabled==false and guard.manual_controls_owned(),
    'manual menu did not suppress gameplay controls')
assert(guard.release_manual_controls()==true and controls_enabled==true and not guard.manual_controls_owned(),
    'manual menu did not restore its controls baseline')
controls_enabled=false
assert(guard.acquire_manual_controls(1)==true)
controls_enabled=true -- a later external owner re-enabled controls
assert(guard.release_manual_controls()==true and controls_enabled==true,
    'manual menu overwrote a later external controls decision')
print("menu_inventory_guard=PASS capture_restore=true manual_controls=true compare_and_swap=true")
