if type(METAMORPH_CREATIVE_MENU_MENU_INVENTORY_GUARD) == "table" then return METAMORPH_CREATIVE_MENU_MENU_INVENTORY_GUARD end

local menu_inventory_guard = {}
local patcher_bridge = dofile("mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua")

local function valid_component(component_id)
    return component_id ~= nil and component_id ~= 0
end

function menu_inventory_guard.controls_disabled(player_entity_id)
    if player_entity_id == nil or player_entity_id == 0 then return false end
    local controls_component = EntityGetFirstComponentIncludingDisabled(player_entity_id, "ControlsComponent")
    if not valid_component(controls_component) then return false end

    local controls_enabled = ComponentGetValue2(controls_component, "enabled")
    local component_enabled = true
    local read_succeeded, enabled = pcall(EntityGetComponentIsEnabled, player_entity_id, controls_component)
    if read_succeeded then component_enabled = enabled == true end
    return controls_enabled == false or component_enabled == false
end

function menu_inventory_guard.inventory_open(player_entity_id)
    local inventory_open = false
    local query_succeeded, native_open = pcall(GameIsInventoryOpen)
    if query_succeeded then inventory_open = native_open == true end

    if player_entity_id ~= nil and player_entity_id ~= 0 then
        local inventory_gui_component = EntityGetFirstComponentIncludingDisabled(player_entity_id, "InventoryGuiComponent")
        if valid_component(inventory_gui_component)
            and ComponentGetValue2(inventory_gui_component, "mActive") == true
        then
            inventory_open = true
        end
    end
    return inventory_open
end

function menu_inventory_guard.capture_scroll_selection(player_entity_id)
    if player_entity_id == nil or player_entity_id == 0 then return nil end
    local inventory_component = EntityGetFirstComponentIncludingDisabled(player_entity_id, "Inventory2Component")
    if not valid_component(inventory_component) then return nil end

    local selection_snapshot = {
        player_entity_id = player_entity_id,
        active_item_entity_id = ComponentGetValue2(inventory_component, "mActiveItem") or 0,
        actual_active_item_entity_id = ComponentGetValue2(inventory_component, "mActualActiveItem") or 0,
    }

    local controls_component = EntityGetFirstComponentIncludingDisabled(player_entity_id, "ControlsComponent")
    if valid_component(controls_component) then
        pcall(ComponentSetValue2, controls_component, "mButtonDownChangeItemR", false)
        pcall(ComponentSetValue2, controls_component, "mButtonDownChangeItemL", false)
        pcall(ComponentSetValue2, controls_component, "mButtonFrameChangeItemR", -1)
        pcall(ComponentSetValue2, controls_component, "mButtonFrameChangeItemL", -1)
        pcall(ComponentSetValue2, controls_component, "mButtonCountChangeItemR", 0)
        pcall(ComponentSetValue2, controls_component, "mButtonCountChangeItemL", 0)
    end
    return selection_snapshot
end

local function restore_held_item_component_tags(player_entity_id, active_item_entity_id)
    for _, inventory_container_entity_id in ipairs(EntityGetAllChildren(player_entity_id) or {}) do
        if EntityGetName(inventory_container_entity_id) == "inventory_quick" then
            for _, item_entity_id in ipairs(EntityGetAllChildren(inventory_container_entity_id) or {}) do
                local is_held_item = item_entity_id == active_item_entity_id
                EntitySetComponentsWithTagEnabled(item_entity_id, "enabled_in_world", false)
                EntitySetComponentsWithTagEnabled(item_entity_id, "enabled_in_hand", is_held_item)
                EntitySetComponentsWithTagEnabled(item_entity_id, "enabled_in_inventory", not is_held_item)
            end
            return
        end
    end
end

function menu_inventory_guard.restore_scroll_selection(selection_snapshot)
    if type(selection_snapshot) ~= "table" then return false end
    local player_entity_id = tonumber(selection_snapshot.player_entity_id) or 0
    if player_entity_id == 0 or not EntityGetIsAlive(player_entity_id) then return false end

    local inventory_component = EntityGetFirstComponentIncludingDisabled(player_entity_id, "Inventory2Component")
    if not valid_component(inventory_component) then return false end

    local active_item_entity_id = tonumber(selection_snapshot.active_item_entity_id) or 0
    local actual_active_item_entity_id = tonumber(selection_snapshot.actual_active_item_entity_id) or 0

    if active_item_entity_id == 0 or EntityGetIsAlive(active_item_entity_id) then
        pcall(ComponentSetValue2, inventory_component, "mActiveItem", active_item_entity_id)
    end
    if actual_active_item_entity_id == 0 or EntityGetIsAlive(actual_active_item_entity_id) then
        pcall(ComponentSetValue2, inventory_component, "mActualActiveItem", actual_active_item_entity_id)
    end

    if active_item_entity_id ~= 0 and EntityGetIsAlive(active_item_entity_id) then
        local bridge = patcher_bridge.get({ capability="SetActiveHeldEntity" })
        if bridge ~= nil then
            pcall(bridge.SetActiveHeldEntity, player_entity_id, active_item_entity_id, false, false)
        else
            restore_held_item_component_tags(player_entity_id, active_item_entity_id)
        end
    end

    pcall(ComponentSetValue2, inventory_component, "mForceRefresh", true)
    return true
end

METAMORPH_CREATIVE_MENU_MENU_INVENTORY_GUARD = menu_inventory_guard
return menu_inventory_guard
