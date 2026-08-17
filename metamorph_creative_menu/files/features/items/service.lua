if type(METAMORPH_CREATIVE_MENU_ITEM_SERVICE) == "table" then return METAMORPH_CREATIVE_MENU_ITEM_SERVICE end

local item_service = {}

local inventory_slots = dofile("mods/metamorph_creative_menu/files/platform/noita/inventory_slots.lua")
local ew_world_items = dofile("mods/metamorph_creative_menu/files/integrations/ew/world_items.lua")

local function valid_component(component)
    return component ~= nil and component ~= 0
end

function item_service.world_sync_state(entity)
    return ew_world_items.world_sync_state(entity)
end

function item_service.world_item_outbox_state()
    return ew_world_items.outbox_state()
end

-- Public only for items that must be constructed/customized before they become a world
-- entity (for example a liquid-filled flask). Normal catalogue spawns should use spawn_near.
function item_service.notify_world_item(entity)
    return ew_world_items.notify_world_item(entity)
end

local function drop_near(player, entity)
    if entity == nil or entity == 0 or not EntityGetIsAlive(entity) then return end
    EntityRemoveFromParent(entity)
    local player_x, player_y = EntityGetTransform(player)
    if player_x ~= nil then EntitySetTransform(entity, player_x + 12, player_y - 8) end
    inventory_slots.enable_world(entity)
    -- EW's distributed entity sync registers thrown world items through this stable
    -- CrossCall. Inventory resync alone cannot advertise an item that never entered
    -- the inventory, so overflow drops must take the same path as a normally thrown wand.
    ew_world_items.notify_world_item(entity)
end

local function load_near(player, path, offset_x, offset_y)
    if player == nil or player == 0 or not EntityGetIsAlive(player)
        or type(path) ~= "string" or path == "" or not ModDoesFileExist(path)
    then
        return 0, "invalid"
    end
    local player_x, player_y = EntityGetTransform(player)
    if player_x == nil then return 0, "position" end
    local entity = EntityLoad(path, player_x + (offset_x or 12), player_y + (offset_y or -8)) or 0
    if entity == 0 then return 0, "load" end
    return entity, "loaded"
end

function item_service.spawn_near(player, path, offset_x, offset_y)
    local entity, reason = load_near(player, path, offset_x, offset_y)
    if entity == 0 then return entity, reason end
    -- LMB world-spawns never pass through vanilla throw callbacks. Without explicitly
    -- registering them, EW has no gid/authority handoff and wands appear late or only on
    -- the spawning peer. ew_thrown itself defers serialization by one frame, so velocity
    -- and physics initialization are still allowed to settle normally.
    local synced, sync_reason = ew_world_items.notify_world_item(entity)
    return entity, synced and ("spawned_" .. tostring(sync_reason or "queued")) or "spawned_unsynced"
end

function item_service.give_existing_entity(player, entity, play_sound)
    if player == nil or player == 0 or not EntityGetIsAlive(player)
        or entity == nil or entity == 0 or not EntityGetIsAlive(entity)
    then
        return false, "invalid", entity or 0, false
    end
    local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
    if not valid_component(item) then return false, "not_item", entity, false end

    local ok_auto, auto_pickup = pcall(ComponentGetValue2, item, "auto_pickup")
    if ok_auto and auto_pickup == true then
        -- Hearts and similar pickups are effects, not inventory items. Put them on the
        -- player and let their vanilla pickup script own the health/stat transaction.
        local player_x, player_y = EntityGetTransform(player)
        if player_x == nil then return false, "position", entity, false end
        EntitySetTransform(entity, player_x, player_y)
        inventory_slots.enable_world(entity)
        return true, "auto_pickup", entity, false
    end

    local picked, pickup_reason = inventory_slots.pickup(player, entity, play_sound == true)
    if not picked then
        local spawned_nearby = EntityGetIsAlive(entity) == true
        if spawned_nearby then drop_near(player, entity) end
        return false, pickup_reason or "pickup_failed", entity, spawned_nearby
    end
    if not EntityGetIsAlive(entity) or not inventory_slots.is_inside_player_inventory(player, entity) then
        local spawned_nearby = EntityGetIsAlive(entity) == true
        if spawned_nearby then drop_near(player, entity) end
        return false, "pickup_not_committed", entity, spawned_nearby
    end

    pcall(ComponentSetValue2, item, "has_been_picked_by_player", true)
    local inventory = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
    if valid_component(inventory) then pcall(ComponentSetValue2, inventory, "mForceRefresh", true) end
    ew_world_items.force_inventory_sync()
    return true, "picked", entity, false
end

function item_service.spawn_filled_flask(player, material_id, pick_up)
    if player == nil or player == 0 or not EntityGetIsAlive(player) or type(material_id) ~= "string" or material_id == "" then
        return false, "invalid", 0, false
    end
    local player_x, player_y = EntityGetTransform(player)
    if player_x == nil then return false, "position", 0, false end
    local entity = EntityLoad("data/entities/items/pickup/potion_empty.xml", player_x + 12, player_y - 8) or 0
    if entity == 0 then return false, "load", 0, false end
    pcall(RemoveMaterialInventoryMaterial, entity)
    local material_added = pcall(AddMaterialInventoryMaterial, entity, material_id, 1000)
    if not material_added then EntityKill(entity); return false, "material", 0, false end
    if pick_up then return item_service.give_existing_entity(player, entity, true) end
    local synced = item_service.notify_world_item(entity)
    return true, synced and "spawned_synced" or "spawned", entity, true
end

function item_service.give(player, path, play_sound)
    -- Direct inventory give is intentionally *not* globalized as a world item first.
    -- Globalize->pickup in the same frame races EW's delayed ew_thrown serializer. The
    -- committed inventory snapshot below is the single authority path for this case.
    local entity, reason = load_near(player, path)
    if entity == 0 then return false, reason, 0, false end
    return item_service.give_existing_entity(player, entity, play_sound)
end

METAMORPH_CREATIVE_MENU_ITEM_SERVICE = item_service
return item_service
