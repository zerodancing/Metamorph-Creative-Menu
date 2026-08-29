if type(METAMORPH_CREATIVE_MENU_SPELL_INVENTORY_SERVICE) == "table" then return METAMORPH_CREATIVE_MENU_SPELL_INVENTORY_SERVICE end

local inventory_service = {}
local inventory_slots = dofile("mods/metamorph_creative_menu/files/platform/noita/inventory_slots.lua")
local spell_factory = dofile("mods/metamorph_creative_menu/files/features/spells/factory.lua")
local spell_service = dofile("mods/metamorph_creative_menu/files/features/spells/service.lua")
local ew_runtime = dofile("mods/metamorph_creative_menu/files/integrations/ew/runtime.lua")
local ew_world_items = dofile("mods/metamorph_creative_menu/files/integrations/ew/world_items.lua")

local function valid(component) return component ~= nil and component ~= 0 end
local function alive(entity) return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity) == true end

local function coordinates(layout, index)
    index = math.floor(tonumber(index) or -1)
    if type(layout) ~= "table" or index < 0 or index >= layout.width * layout.height then return nil end
    return index % layout.width, math.floor(index / layout.width)
end

local function action_record(record, width)
    if type(record) ~= "table" or record.is_action ~= true then return nil end
    local action = EntityGetFirstComponentIncludingDisabled(record.entity, "ItemActionComponent")
    if not valid(action) then return nil end
    local ok, action_id = pcall(ComponentGetValue2, action, "action_id")
    if not ok or type(action_id) ~= "string" or action_id == "" then return nil end
    return {
        entity=record.entity,
        item_component=record.item_component,
        action_component=action,
        action_id=action_id,
        x=record.x, y=record.y,
        index=record.y * width + record.x,
    }
end

function inventory_service.contents(player)
    local layout, reason = inventory_slots.snapshot(player, "inventory_full")
    if layout == nil then return nil, reason end
    local by_index, entries = {}, {}
    for _, record in ipairs(layout.entries) do
        local entry = action_record(record, layout.width)
        if entry ~= nil then
            by_index[entry.index] = entry
            entries[#entries + 1] = entry
        end
    end
    return {
        inventory=layout.inventory,
        width=layout.width,
        height=layout.height,
        capacity=layout.width * layout.height,
        by_index=by_index,
        entries=entries,
    }, "ok"
end

local function configure_card(entity, action_id, x, y)
    local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
    local action = EntityGetFirstComponentIncludingDisabled(entity, "ItemActionComponent")
    if not valid(item) or not valid(action) then return nil, "components_missing" end
    local action_ok, actual_action = pcall(ComponentGetValue2, action, "action_id")
    if not action_ok or tostring(actual_action or "") ~= tostring(action_id or "") then return nil, "action_mismatch" end
    local writes = {
        {"inventory_slot",x,y},
        {"permanently_attached",false},
        {"has_been_picked_by_player",true},
    }
    for _, write in ipairs(writes) do
        local ok
        if write[3] ~= nil then ok = pcall(ComponentSetValue2, item, write[1], write[2], write[3])
        else ok = pcall(ComponentSetValue2, item, write[1], write[2]) end
        if not ok then return nil, "configure_failed" end
    end
    return {entity=entity,item_component=item,action_component=action,action_id=action_id,x=x,y=y}, "ok"
end

function inventory_service.create_at(player, action_id, index)
    local layout, reason = inventory_service.contents(player)
    if layout == nil then return false, reason end
    local x, y = coordinates(layout, index)
    if x == nil then return false, "slot_out_of_range" end
    if layout.by_index[index] ~= nil then return false, "occupied" end

    local entity, create_reason = spell_factory.create(action_id)
    if entity == nil or entity == 0 then return false, create_reason or "create_failed" end
    local record, configure_reason = configure_card(entity, action_id, x, y)
    if record == nil then pcall(EntityKill, entity); return false, configure_reason end
    local placed, place_reason = inventory_slots.place_exact(player, entity, "inventory_full", x, y)
    if not placed then pcall(EntityKill, entity); return false, place_reason end
    ew_runtime.force_inventory_sync()
    return true, "created", entity
end

function inventory_service.move(player, source_entry, target_index)
    if type(source_entry) ~= "table" or not alive(source_entry.entity) then return false, "missing_action" end
    local layout, reason = inventory_service.contents(player)
    if layout == nil then return false, reason end
    local x, y = coordinates(layout, target_index)
    if x == nil then return false, "slot_out_of_range" end
    if source_entry.index == target_index then return true, "unchanged" end
    local target = layout.by_index[target_index]
    local ok, move_reason
    if target ~= nil then
        ok, move_reason = inventory_slots.swap_exact(player, source_entry.entity, target.entity)
    else
        ok, move_reason = inventory_slots.place_exact(player, source_entry.entity, "inventory_full", x, y)
    end
    if not ok then return false, move_reason end
    ew_runtime.force_inventory_sync()
    return true, target ~= nil and "swapped" or "moved"
end

function inventory_service.drop_to_world(player, entry, target_x, target_y)
    if type(entry) ~= "table" or not alive(entry.entity) then return false, "missing_action" end
    local parent = EntityGetParent(entry.entity) or 0
    if parent == 0 then return false, "not_inventory" end
    local plan, plan_reason = spell_service.prepare_world_launch(player, target_x, target_y)
    if plan == nil then return false, plan_reason end
    local detached = pcall(EntityRemoveFromParent, entry.entity)
    if not detached or (type(EntityGetParent) == "function" and EntityGetParent(entry.entity) ~= 0) then
        return false, "detach_failed"
    end
    local launched, launch_reason = spell_service.apply_world_launch(entry.entity, plan, false)
    if not launched then
        local restored = inventory_slots.place_exact(player, entry.entity, "inventory_full", entry.x, entry.y)
        if not restored then
            pcall(EntityAddChild, parent, entry.entity)
            pcall(ComponentSetValue2, entry.item_component, "inventory_slot", entry.x, entry.y)
            pcall(EntitySetComponentsWithTagEnabled, entry.entity, "enabled_in_world", false)
            pcall(EntitySetComponentsWithTagEnabled, entry.entity, "enabled_in_inventory", true)
        end
        ew_runtime.force_inventory_sync()
        return false, launch_reason
    end
    pcall(ew_world_items.notify_world_item, entry.entity)
    ew_runtime.force_inventory_sync()
    return true, "thrown"
end

function inventory_service.remove(player, entry, drop_into_world, defer_world_notify)
    if type(entry) ~= "table" or not alive(entry.entity) then return false, "missing_action" end
    local parent = EntityGetParent(entry.entity) or 0
    if parent == 0 then return false, "not_inventory" end
    local detached = pcall(EntityRemoveFromParent, entry.entity)
    if not detached or (type(EntityGetParent) == "function" and EntityGetParent(entry.entity) ~= 0) then
        return false, "detach_failed"
    end
    if drop_into_world then
        local x, y = EntityGetTransform(player)
        if x == nil then
            pcall(EntityAddChild, parent, entry.entity)
            pcall(ComponentSetValue2, entry.item_component, "inventory_slot", entry.x, entry.y)
            return false, "position_failed"
        end
        pcall(ComponentSetValue2, entry.item_component, "inventory_slot", -1, -1)
        EntitySetComponentsWithTagEnabled(entry.entity, "enabled_in_hand", false)
        EntitySetComponentsWithTagEnabled(entry.entity, "enabled_in_inventory", false)
        EntitySetComponentsWithTagEnabled(entry.entity, "enabled_in_world", true)
        EntitySetTransform(entry.entity, x + 12, y - 8)
        if defer_world_notify ~= true then ew_world_items.notify_world_item(entry.entity) end
    else
        local killed = pcall(EntityKill, entry.entity)
        if not killed then
            pcall(EntityAddChild, parent, entry.entity)
            pcall(ComponentSetValue2, entry.item_component, "inventory_slot", entry.x, entry.y)
            return false, "kill_failed"
        end
    end
    ew_runtime.force_inventory_sync()
    return true, drop_into_world and "dropped" or "deleted"
end

METAMORPH_CREATIVE_MENU_SPELL_INVENTORY_SERVICE = inventory_service
return inventory_service
