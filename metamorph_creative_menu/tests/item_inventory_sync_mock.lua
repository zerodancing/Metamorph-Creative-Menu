local root = assert(arg[1], "root required")
local native_dofile = dofile
local sync_calls = 0

local inventory_slots = {
    pickup = function(player_entity, item_entity, play_sound)
        return true, "picked"
    end,
    enable_world = function() end,
    is_inside_player_inventory = function(player_entity, item_entity) return true end,
}
local ew_world_items = {
    notify_world_item = function() return true, "queued" end,
    world_sync_state = function() return true, "registered", "gid" end,
    outbox_state = function() return 1, 1, "ok" end,
    force_inventory_sync = function() sync_calls = sync_calls + 1; return true end,
}

dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/platform/noita/inventory_slots.lua" then return inventory_slots end
    if path == "mods/metamorph_creative_menu/files/integrations/ew/world_items.lua" then return ew_world_items end
    return native_dofile(path)
end

local alive = { [1]=true, [10]=true, [100]=true }
function EntityGetIsAlive(entity) return alive[entity] == true end
function EntityGetAllChildren(entity) if entity == 1 then return {100} elseif entity == 100 then return {10} end return {} end
function EntityGetName(entity) return entity == 100 and "inventory_quick" or "" end
function EntityGetParent(entity) return entity == 10 and 100 or (entity == 100 and 1 or 0) end
function EntityAddChild(parent, child) end
function EntityGetFirstComponentIncludingDisabled(entity, component_type)
    if entity == 10 and component_type == "ItemComponent" then return 200 end
    if entity == 1 and component_type == "Inventory2Component" then return 201 end
    return nil
end
function ComponentGetValue2(component, field)
    if component == 200 and field == "auto_pickup" then return false end
    return nil
end
function ComponentSetValue2() return true end
function ModDoesFileExist(path) return path == "data/test_item.xml" end
function EntityLoad(path) if path == "data/test_item.xml" then return 10 end return 0 end
function EntityGetTransform(entity) if entity == 1 then return 10,20 end return 0,0 end

METAMORPH_CREATIVE_MENU_ITEM_SERVICE = nil
local service = assert(native_dofile(root .. "/files/features/items/service.lua"))
local ok, reason = service.give(1, "data/test_item.xml", false)
assert(ok == true and reason == "picked", "inventory give did not commit")
assert(sync_calls == 1, "committed inventory change did not request EW inventory sync")
print("item_inventory_sync=PASS sync_calls=" .. tostring(sync_calls))
