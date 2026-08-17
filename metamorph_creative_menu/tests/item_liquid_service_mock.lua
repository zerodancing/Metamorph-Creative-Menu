local root = assert(arg[1], "root required")
local native_dofile = dofile

local inventory_slots = {
    pickup = function() return true, "picked" end,
    enable_world = function() end,
    is_inside_player_inventory = function() return true end,
}
local ew_world_items = {
    notify_world_item = function() return true, "queued" end,
    world_sync_state = function() return true, "registered", "gid" end,
    outbox_state = function() return 0, 0, "" end,
    force_inventory_sync = function() return true end,
}

dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/platform/noita/inventory_slots.lua" then return inventory_slots end
    if path == "mods/metamorph_creative_menu/files/integrations/ew/world_items.lua" then return ew_world_items end
    return native_dofile(path)
end

local alive = { [1]=true }
local next_entity = 10
local material_by_entity = {}
function EntityGetIsAlive(entity_id) return alive[entity_id] == true end
function EntityGetTransform(entity_id) return 100, 200 end
function EntityLoad(path, x, y)
    assert(path == "data/entities/items/pickup/potion_empty.xml", "wrong flask template")
    local entity_id = next_entity
    next_entity = next_entity + 1
    alive[entity_id] = true
    return entity_id
end
function RemoveMaterialInventoryMaterial(entity_id) material_by_entity[entity_id] = nil end
function AddMaterialInventoryMaterial(entity_id, material_id, amount)
    assert(amount == 1000, "wrong flask fill amount")
    material_by_entity[entity_id] = material_id
    return true
end
function EntityKill(entity_id) alive[entity_id] = false end
function EntityGetFirstComponentIncludingDisabled(entity_id, component_type)
    if component_type == "ItemComponent" then return 50 end
    return nil
end
function ComponentGetValue2(component_id, field)
    if field == "auto_pickup" then return false end
    return nil
end
function ComponentSetValue2() return true end
function ModDoesFileExist() return true end

METAMORPH_CREATIVE_MENU_ITEM_SERVICE = nil
local service = assert(native_dofile(root .. "/files/features/items/service.lua"))
local ok_spawn, reason_spawn, spawned_entity, spawned_nearby = service.spawn_filled_flask(1, "water", false)
assert(ok_spawn == true, "liquid LMB spawn failed")
assert(reason_spawn == "spawned_synced", "liquid LMB was not EW-registered")
assert(material_by_entity[spawned_entity] == "water", "liquid material was not filled")
assert(spawned_nearby == true, "LMB liquid must be reported as world-spawned")

local ok_take, reason_take, taken_entity, take_spawned_nearby = service.spawn_filled_flask(1, "oil", true)
assert(ok_take == true and reason_take == "picked", "liquid RMB inventory path failed")
assert(material_by_entity[taken_entity] == "oil", "RMB flask material was not filled")
assert(take_spawned_nearby == false, "successful RMB take must not report fallback world spawn")
print("item_liquid_service=PASS lmb_and_rmb=true")
