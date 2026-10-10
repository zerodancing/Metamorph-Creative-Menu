if type(METAMORPH_CREATIVE_MENU_ITEM_SERVICE) == "table" then return METAMORPH_CREATIVE_MENU_ITEM_SERVICE end

local item_service = {}

local inventory_slots = dofile("mods/metamorph_creative_menu/files/platform/noita/inventory_slots.lua")
local ew_world_items = dofile("mods/metamorph_creative_menu/files/integrations/ew/world_items.lua")

local function valid_component(component)
    return component ~= nil and component ~= 0
end

local function valid_coordinate(value)
    value = tonumber(value)
    return value ~= nil and value == value and value > -1000000000 and value < 1000000000
end

local function kill_tree(entity)
    if entity == nil or entity == 0 or not EntityGetIsAlive(entity) then return end
    if type(EntityGetAllChildren) == "function" then
        local ok, children = pcall(EntityGetAllChildren, entity)
        if ok and type(children) == "table" then
            for _, child in ipairs(children) do kill_tree(child) end
        end
    end
    if EntityGetIsAlive(entity) then pcall(EntityKill, entity) end
end

local function commit_world_entity(entity)
    if entity == nil or entity == 0 or not EntityGetIsAlive(entity) then return false, "invalid" end
    local enabled = pcall(inventory_slots.enable_world, entity)
    if not enabled or not EntityGetIsAlive(entity) then
        kill_tree(entity)
        return false, "world_enable"
    end
    local call_ok, synced, sync_reason = pcall(ew_world_items.notify_world_item, entity)
    if not call_ok or synced ~= true then
        kill_tree(entity)
        return false, call_ok and (sync_reason or "world_sync") or "world_sync"
    end
    return true, sync_reason or "singleplayer"
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
    -- World state is enabled before the single optional EW handoff; failure rolls back the
    -- newly created entity tree instead of leaving a local-only partial item.
    local committed, sync_reason = commit_world_entity(entity)
    if not committed then return 0, sync_reason end
    return entity, "spawned_" .. tostring(sync_reason or "queued")
end

local function give_existing_entity(player, entity, play_sound, options)
    options = type(options) == "table" and options or {}
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
        if options.rollback_on_failure == true then
            kill_tree(entity)
            return false, pickup_reason or "pickup_failed", 0, false
        end
        local spawned_nearby = EntityGetIsAlive(entity) == true
        if spawned_nearby then drop_near(player, entity) end
        return false, pickup_reason or "pickup_failed", entity, spawned_nearby
    end
    if not EntityGetIsAlive(entity) or not inventory_slots.is_inside_player_inventory(player, entity) then
        if options.rollback_on_failure == true then
            kill_tree(entity)
            return false, "pickup_not_committed", 0, false
        end
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

local function create_filled_flask(material_id, x, y)
    if type(material_id) ~= "string" or material_id == "" or not valid_coordinate(x) or not valid_coordinate(y) then
        return 0, "invalid"
    end
    local entity = EntityLoad("data/entities/items/pickup/potion_empty.xml", tonumber(x), tonumber(y)) or 0
    if entity == 0 then return 0, "load" end
    pcall(RemoveMaterialInventoryMaterial, entity)
    local material_added = pcall(AddMaterialInventoryMaterial, entity, material_id, 1000)
    if not material_added then kill_tree(entity); return 0, "material" end
    return entity, "filled"
end

-- Exact world placement used only after a catalog drag has completed. The entity is not
-- created before release; world enablement and the single EW handoff are part of the same
-- transaction, so a failed handoff cannot leave a half-committed item behind.
function item_service.spawn_at(path, x, y)
    if type(path) ~= "string" or path == "" or not valid_coordinate(x) or not valid_coordinate(y)
        or not ModDoesFileExist(path)
    then
        return 0, "invalid"
    end
    local entity = EntityLoad(path, tonumber(x), tonumber(y)) or 0
    if entity == 0 then return 0, "load" end
    local committed, reason = commit_world_entity(entity)
    if not committed then return 0, reason end
    return entity, "spawned_" .. tostring(reason)
end

function item_service.spawn_filled_flask_at(material_id, x, y)
    local entity, reason = create_filled_flask(material_id, x, y)
    if entity == 0 then return false, reason, 0, false end
    local committed, sync_reason = commit_world_entity(entity)
    if not committed then return false, sync_reason, 0, false end
    return true, "spawned_" .. tostring(sync_reason), entity, true
end

function item_service.give_strict(player, path, play_sound)
    local entity, reason = load_near(player, path)
    if entity == 0 then return false, reason, 0, false end
    return give_existing_entity(player, entity, play_sound, {rollback_on_failure=true})
end

function item_service.give_filled_flask_strict(player, material_id)
    if player == nil or player == 0 or not EntityGetIsAlive(player) then return false, "invalid", 0, false end
    local player_x, player_y = EntityGetTransform(player)
    if player_x == nil then return false, "position", 0, false end
    local entity, reason = create_filled_flask(material_id, player_x + 12, player_y - 8)
    if entity == 0 then return false, reason, 0, false end
    return give_existing_entity(player, entity, true, {rollback_on_failure=true})
end

function item_service.spawn_filled_flask(player, material_id, pick_up)
    if player == nil or player == 0 or not EntityGetIsAlive(player) or type(material_id) ~= "string" or material_id == "" then
        return false, "invalid", 0, false
    end
    local player_x, player_y = EntityGetTransform(player)
    if player_x == nil then return false, "position", 0, false end
    local entity, reason = create_filled_flask(material_id, player_x + 12, player_y - 8)
    if entity == 0 then return false, reason, 0, false end
    if pick_up then return give_existing_entity(player, entity, true) end
    local committed, sync_reason = commit_world_entity(entity)
    if not committed then return false, sync_reason, 0, false end
    return true, "spawned_synced", entity, true
end

function item_service.give(player, path, play_sound)
    -- Direct inventory give is intentionally *not* globalized as a world item first.
    -- Globalize->pickup in the same frame races EW's delayed ew_thrown serializer. The
    -- committed inventory snapshot below is the single authority path for this case.
    local entity, reason = load_near(player, path)
    if entity == 0 then return false, reason, 0, false end
    return give_existing_entity(player, entity, play_sound)
end

METAMORPH_CREATIVE_MENU_ITEM_SERVICE = item_service
return item_service
