if type(METAMORPH_CREATIVE_MENU_PERMANENT_SPELL_SERVICE) == "table" then
    return METAMORPH_CREATIVE_MENU_PERMANENT_SPELL_SERVICE
end

local permanent_service = {}
local wand_api = dofile("mods/metamorph_creative_menu/files/platform/noita/wand.lua")
local inventory_slots = dofile("mods/metamorph_creative_menu/files/platform/noita/inventory_slots.lua")
local inventory_policy = dofile("mods/metamorph_creative_menu/files/core/inventory_policy.lua")
local spell_factory = dofile("mods/metamorph_creative_menu/files/features/spells/factory.lua")
local spell_service = dofile("mods/metamorph_creative_menu/files/features/spells/service.lua")
local ew_world_items = dofile("mods/metamorph_creative_menu/files/integrations/ew/world_items.lua")

local function valid(component) return component ~= nil and component ~= 0 end
local function alive(entity) return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity) == true end

local function set_slot(item, x, y)
    if not valid(item) then return false end
    local wrote = pcall(ComponentSetValue2, item, "inventory_slot", x, y)
    local read, actual_x, actual_y = pcall(ComponentGetValue2, item, "inventory_slot")
    return wrote and read and tonumber(actual_x) == tonumber(x) and (tonumber(actual_y) or 0) == (tonumber(y) or 0)
end

local function set_bool(item, field, value)
    if not valid(item) then return false end
    local wrote = pcall(ComponentSetValue2, item, field, value == true)
    local read, actual = pcall(ComponentGetValue2, item, field)
    return wrote and read and actual == (value == true)
end

local function raw_capacity(wand)
    local ability = wand_api.ability(wand)
    if ability == 0 then return nil, nil, "not_wand" end
    local value, ok = wand_api.get_object(ability, "gun_config", "deck_capacity")
    value = ok and tonumber(value) or nil
    if value == nil or value ~= value or value == math.huge or value == -math.huge then
        return nil, nil, "capacity_read_failed"
    end
    return ability, value, "ok"
end

local function write_capacity(ability, value)
    value = tonumber(value)
    if value == nil or value < 1 then return false end
    return wand_api.set_object(ability, "gun_config", "deck_capacity", value)
end

local function attach_wand(wand, entity)
    local parent = EntityGetParent(entity) or 0
    if parent ~= 0 and parent ~= wand then pcall(EntityRemoveFromParent, entity) end
    if EntityGetParent(entity) ~= wand then
        local ok = pcall(EntityAddChild, wand, entity)
        if not ok or EntityGetParent(entity) ~= wand then return false end
    end
    EntitySetComponentsWithTagEnabled(entity, "enabled_in_hand", false)
    EntitySetComponentsWithTagEnabled(entity, "enabled_in_inventory", false)
    EntitySetComponentsWithTagEnabled(entity, "enabled_in_world", false)
    return true
end

local function detach(entity)
    if not alive(entity) then return false end
    local ok = pcall(EntityRemoveFromParent, entity)
    if not ok then return false end
    return type(EntityGetParent) ~= "function" or tonumber(EntityGetParent(entity) or 0) == 0
end

local function item_action(entity)
    if not alive(entity) then return nil, nil, "missing_action" end
    local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
    local action = EntityGetFirstComponentIncludingDisabled(entity, "ItemActionComponent")
    if not valid(item) or not valid(action) then return nil, nil, "components_missing" end
    return item, action, "ok"
end

local function restore_permanent(wand, entry)
    if type(entry) ~= "table" or not alive(entry.entity) then return end
    local parent = EntityGetParent(entry.entity) or 0
    if parent ~= 0 and parent ~= wand then pcall(EntityRemoveFromParent, entry.entity) end
    attach_wand(wand, entry.entity)
    set_slot(entry.item_component, entry.actual_slot or -1, entry.actual_slot_y or -1)
    set_bool(entry.item_component, "permanently_attached", true)
    pcall(ComponentSetValue2, entry.item_component, "has_been_picked_by_player", true)
end

local function restore_regular(wand, entry)
    if type(entry) ~= "table" or not alive(entry.entity) then return end
    local parent = EntityGetParent(entry.entity) or 0
    if parent ~= 0 and parent ~= wand then pcall(EntityRemoveFromParent, entry.entity) end
    attach_wand(wand, entry.entity)
    set_bool(entry.item_component, "permanently_attached", false)
    set_slot(entry.item_component, entry.actual_slot or entry.slot or 0, entry.actual_slot_y or 0)
end

local function restore_inventory(player, entry, x, y)
    if type(entry) ~= "table" or not alive(entry.entity) then return end
    local parent = EntityGetParent(entry.entity) or 0
    if parent ~= 0 then pcall(EntityRemoveFromParent, entry.entity) end
    set_bool(entry.item_component, "permanently_attached", false)
    inventory_slots.place_exact(player, entry.entity, "inventory_full", x, y)
end

local function finish(player, wand)
    spell_service.refresh(player, wand)
end

function permanent_service.add(player, wand, action_id)
    if type(action_id) ~= "string" or action_id == "" then return false, "invalid_action" end
    local ability, raw, reason = raw_capacity(wand)
    if ability == nil then return false, reason end
    local entity, create_reason = spell_factory.create(action_id)
    if entity == nil or entity == 0 then return false, create_reason or "create_failed" end
    local item, action, component_reason = item_action(entity)
    if item == nil then pcall(EntityKill, entity); return false, component_reason end
    local read_action, actual_action = pcall(ComponentGetValue2, action, "action_id")
    if not read_action or tostring(actual_action or "") ~= action_id then
        pcall(EntityKill, entity); return false, "action_mismatch"
    end
    if not set_slot(item, -1, -1) or not set_bool(item, "permanently_attached", true) then
        pcall(EntityKill, entity); return false, "configure_failed"
    end
    pcall(ComponentSetValue2, item, "has_been_picked_by_player", true)
    if not attach_wand(wand, entity) then pcall(EntityKill, entity); return false, "attach_failed" end
    if not write_capacity(ability, raw + 1) then
        pcall(EntityRemoveFromParent, entity); pcall(EntityKill, entity)
        return false, "capacity_write_failed"
    end
    finish(player, wand)
    return true, "permanent_added", entity
end

function permanent_service.replace(player, wand, entry, action_id)
    if type(entry) ~= "table" or not alive(entry.entity) then return false, "missing_action" end
    if type(action_id) ~= "string" or action_id == "" then return false, "invalid_action" end
    if tostring(entry.action_id or "") == action_id then return true, "unchanged" end

    local entity, create_reason = spell_factory.create(action_id)
    if entity == nil or entity == 0 then return false, create_reason or "create_failed" end
    local item, action, component_reason = item_action(entity)
    if item == nil then pcall(EntityKill, entity); return false, component_reason end
    local read_action, actual_action = pcall(ComponentGetValue2, action, "action_id")
    if not read_action or tostring(actual_action or "") ~= action_id then
        pcall(EntityKill, entity); return false, "action_mismatch"
    end
    if not set_slot(item, -1, -1) or not set_bool(item, "permanently_attached", true) then
        pcall(EntityKill, entity); return false, "configure_failed"
    end
    pcall(ComponentSetValue2, item, "has_been_picked_by_player", true)
    if not attach_wand(wand, entity) then pcall(EntityKill, entity); return false, "attach_failed" end

    if not detach(entry.entity) then
        pcall(EntityRemoveFromParent, entity); pcall(EntityKill, entity)
        return false, "old_detach_failed"
    end
    local killed = pcall(EntityKill, entry.entity)
    if not killed then
        restore_permanent(wand, entry)
        pcall(EntityRemoveFromParent, entity); pcall(EntityKill, entity)
        return false, "old_kill_failed"
    end
    finish(player, wand)
    return true, "permanent_replaced", entity
end

function permanent_service.promote(player, wand, entry)
    if type(entry) ~= "table" or not alive(entry.entity) then return false, "missing_action" end
    local ability, raw, reason = raw_capacity(wand)
    if ability == nil then return false, reason end
    local old_x, old_y = entry.actual_slot or entry.slot or 0, entry.actual_slot_y or 0
    if not set_slot(entry.item_component, -1, -1) then return false, "slot_write_failed" end
    if not set_bool(entry.item_component, "permanently_attached", true) then
        set_slot(entry.item_component, old_x, old_y)
        return false, "permanent_write_failed"
    end
    if not write_capacity(ability, raw + 1) then
        set_bool(entry.item_component, "permanently_attached", false)
        set_slot(entry.item_component, old_x, old_y)
        return false, "capacity_write_failed"
    end
    finish(player, wand)
    return true, "promoted"
end

function permanent_service.demote(player, wand, entry, target_slot)
    if type(entry) ~= "table" or not alive(entry.entity) then return false, "missing_action" end
    target_slot = math.max(0, math.floor(tonumber(target_slot) or 0))
    local slots, highest, permanent_count = spell_service.contents(wand)
    local cap = spell_service.capacity(wand, highest, permanent_count)
    if target_slot >= cap then return false, "slot_out_of_range" end
    if slots[target_slot] ~= nil then return false, "occupied" end
    local ability, raw, reason = raw_capacity(wand)
    if ability == nil then return false, reason end
    if raw - 1 < 1 then return false, "capacity_underflow" end
    local old_x, old_y = entry.actual_slot or -1, entry.actual_slot_y or -1
    if not set_bool(entry.item_component, "permanently_attached", false) then return false, "permanent_write_failed" end
    if not set_slot(entry.item_component, target_slot, 0) then
        set_bool(entry.item_component, "permanently_attached", true)
        return false, "slot_write_failed"
    end
    if not write_capacity(ability, raw - 1) then
        set_slot(entry.item_component, old_x, old_y)
        set_bool(entry.item_component, "permanently_attached", true)
        return false, "capacity_write_failed"
    end
    finish(player, wand)
    return true, "demoted", target_slot
end

-- Exchanging a normal and an Always Cast card keeps the permanent count unchanged,
-- so raw deck capacity must remain unchanged as well.
function permanent_service.swap_with_slot(player, wand, permanent_entry, regular_entry)
    if type(permanent_entry) ~= "table" or not alive(permanent_entry.entity) then return false, "permanent_missing" end
    if type(regular_entry) ~= "table" or not alive(regular_entry.entity) then return false, "regular_missing" end
    local target_slot = math.max(0, math.floor(tonumber(regular_entry.slot) or 0))
    local p_x, p_y = permanent_entry.actual_slot or -1, permanent_entry.actual_slot_y or -1
    local r_x, r_y = regular_entry.actual_slot or target_slot, regular_entry.actual_slot_y or 0

    if not set_slot(regular_entry.item_component, -1, -1) then return false, "regular_slot_failed" end
    if not set_bool(regular_entry.item_component, "permanently_attached", true) then
        set_slot(regular_entry.item_component, r_x, r_y); return false, "regular_promote_failed"
    end
    if not set_bool(permanent_entry.item_component, "permanently_attached", false) then
        set_bool(regular_entry.item_component, "permanently_attached", false); set_slot(regular_entry.item_component, r_x, r_y)
        return false, "permanent_demote_failed"
    end
    if not set_slot(permanent_entry.item_component, target_slot, 0) then
        set_bool(permanent_entry.item_component, "permanently_attached", true); set_slot(permanent_entry.item_component, p_x, p_y)
        set_bool(regular_entry.item_component, "permanently_attached", false); set_slot(regular_entry.item_component, r_x, r_y)
        return false, "permanent_slot_failed"
    end
    finish(player, wand)
    return true, "swapped_permanent"
end

function permanent_service.adopt_inventory(player, wand, source_entry)
    if type(source_entry) ~= "table" or not alive(source_entry.entity) then return false, "source_missing" end
    if not inventory_slots.is_inside_player_inventory(player, source_entry.entity) then return false, "source_not_inventory" end
    local source_x, source_y = math.floor(tonumber(source_entry.x) or -1), math.floor(tonumber(source_entry.y) or -1)
    if source_x < 0 or source_y < 0 then return false, "source_slot_missing" end
    local ability, raw, reason = raw_capacity(wand)
    if ability == nil then return false, reason end

    if not detach(source_entry.entity) then return false, "source_detach_failed" end
    if not set_slot(source_entry.item_component, -1, -1) or not set_bool(source_entry.item_component, "permanently_attached", true)
        or not attach_wand(wand, source_entry.entity)
    then
        restore_inventory(player, source_entry, source_x, source_y)
        return false, "source_attach_failed"
    end
    if not write_capacity(ability, raw + 1) then
        restore_inventory(player, source_entry, source_x, source_y)
        return false, "capacity_write_failed"
    end
    finish(player, wand)
    return true, "inventory_promoted"
end

function permanent_service.export_to_inventory_slot(player, wand, entry, x, y)
    if type(entry) ~= "table" or not alive(entry.entity) then return false, "missing_action" end
    x, y = math.floor(tonumber(x) or -1), math.floor(tonumber(y) or -1)
    if x < 0 or y < 0 then return false, "slot_out_of_range" end
    local layout, layout_reason = inventory_slots.snapshot(player, "inventory_full")
    if layout == nil then return false, layout_reason end
    local occupied = layout.by_slot[inventory_policy.slot_key(x, y)]
    if occupied ~= nil and occupied.entity ~= entry.entity then return false, "occupied", occupied end
    local ability, raw, reason = raw_capacity(wand)
    if ability == nil then return false, reason end
    if raw - 1 < 1 then return false, "capacity_underflow" end

    if not detach(entry.entity) then return false, "detach_failed" end
    set_bool(entry.item_component, "permanently_attached", false)
    local placed, place_reason = inventory_slots.place_exact(player, entry.entity, "inventory_full", x, y)
    if not placed then restore_permanent(wand, entry); return false, place_reason end
    if not write_capacity(ability, raw - 1) then
        restore_permanent(wand, entry)
        return false, "capacity_write_failed"
    end
    finish(player, wand)
    return true, "inventory_slot"
end

function permanent_service.swap_with_inventory(player, wand, permanent_entry, inventory_entry)
    if type(permanent_entry) ~= "table" or not alive(permanent_entry.entity) then return false, "permanent_missing" end
    if type(inventory_entry) ~= "table" or not alive(inventory_entry.entity) then return false, "inventory_missing" end
    local x, y = math.floor(tonumber(inventory_entry.x) or -1), math.floor(tonumber(inventory_entry.y) or -1)
    if x < 0 or y < 0 then return false, "inventory_slot_missing" end

    if not detach(inventory_entry.entity) then return false, "inventory_detach_failed" end
    if not set_slot(inventory_entry.item_component, -1, -1) or not set_bool(inventory_entry.item_component, "permanently_attached", true)
        or not attach_wand(wand, inventory_entry.entity)
    then
        restore_inventory(player, inventory_entry, x, y)
        return false, "inventory_promote_failed"
    end
    if not detach(permanent_entry.entity) then
        restore_inventory(player, inventory_entry, x, y)
        return false, "permanent_detach_failed"
    end
    set_bool(permanent_entry.item_component, "permanently_attached", false)
    local placed, place_reason = inventory_slots.place_exact(player, permanent_entry.entity, "inventory_full", x, y)
    if not placed then
        restore_permanent(wand, permanent_entry)
        restore_inventory(player, inventory_entry, x, y)
        return false, place_reason or "inventory_place_failed"
    end
    finish(player, wand)
    return true, "swapped_inventory_permanent"
end

function permanent_service.move_to_inventory(player, wand, entry)
    if type(entry) ~= "table" or not alive(entry.entity) then return false, "missing_action" end
    local plan, plan_reason = inventory_slots.preflight(player, entry.entity)
    if plan == nil then return false, plan_reason or "inventory_full" end
    return permanent_service.export_to_inventory_slot(player, wand, entry, plan.x, plan.y)
end

function permanent_service.drop_to_world(player, wand, entry, target_x, target_y)
    if type(entry) ~= "table" or not alive(entry.entity) then return false, "missing_action" end
    local ability, raw, reason = raw_capacity(wand)
    if ability == nil then return false, reason end
    if raw - 1 < 1 then return false, "capacity_underflow" end
    local plan, plan_reason = spell_service.prepare_world_launch(player, target_x, target_y)
    if plan == nil then return false, plan_reason end
    if not detach(entry.entity) then return false, "detach_failed" end
    if not write_capacity(ability, raw - 1) then restore_permanent(wand, entry); return false, "capacity_write_failed" end
    local launched, launch_reason = spell_service.apply_world_launch(entry.entity, plan, false)
    if not launched then
        write_capacity(ability, raw)
        restore_permanent(wand, entry)
        finish(player, wand)
        return false, launch_reason
    end
    pcall(ew_world_items.notify_world_item, entry.entity)
    finish(player, wand)
    return true, "thrown"
end

function permanent_service.remove(player, wand, entry, drop_into_world, defer_world_notify)
    if type(entry) ~= "table" or not alive(entry.entity) then return false, "missing_action" end
    local ability, raw, reason = raw_capacity(wand)
    if ability == nil then return false, reason end
    if raw - 1 < 1 then return false, "capacity_underflow" end
    local px, py
    if drop_into_world then
        px, py = EntityGetTransform(player)
        if px == nil then return false, "position_failed" end
    end
    if not detach(entry.entity) then return false, "detach_failed" end
    if not write_capacity(ability, raw - 1) then restore_permanent(wand, entry); return false, "capacity_write_failed" end

    if drop_into_world then
        set_bool(entry.item_component, "permanently_attached", false)
        set_slot(entry.item_component, -1, -1)
        EntitySetComponentsWithTagEnabled(entry.entity, "enabled_in_hand", false)
        EntitySetComponentsWithTagEnabled(entry.entity, "enabled_in_inventory", false)
        EntitySetComponentsWithTagEnabled(entry.entity, "enabled_in_world", true)
        EntitySetTransform(entry.entity, px + 12, py - 8)
        if defer_world_notify ~= true then ew_world_items.notify_world_item(entry.entity) end
    else
        local killed = pcall(EntityKill, entry.entity)
        if not killed then
            write_capacity(ability, raw)
            restore_permanent(wand, entry)
            return false, "kill_failed"
        end
    end
    finish(player, wand)
    return true, drop_into_world and "dropped" or "deleted"
end

METAMORPH_CREATIVE_MENU_PERMANENT_SPELL_SERVICE = permanent_service
return permanent_service
