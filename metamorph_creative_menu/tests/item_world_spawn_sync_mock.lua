local root = assert(arg[1], "root required")
local native_dofile = dofile
local notified_entity = nil
local loaded = nil

local inventory_slots = { enable_world=function() end }
local world_items = {
    notify_world_item=function(entity) notified_entity=entity; return true,"queued" end,
    world_sync_state=function() return false,"pending","" end,
    outbox_state=function() return 0,0,"" end,
    force_inventory_sync=function() return true end,
}

dofile=function(path)
    if path=="mods/metamorph_creative_menu/files/platform/noita/inventory_slots.lua" then return inventory_slots end
    if path=="mods/metamorph_creative_menu/files/integrations/ew/world_items.lua" then return world_items end
    return native_dofile(path)
end
function EntityGetIsAlive(entity) return entity==1 or entity==20 end
function ModDoesFileExist(path) return path=="data/entities/items/test.xml" end
function EntityGetTransform(entity) assert(entity==1); return 50,60 end
function EntityLoad(path,x,y) loaded={path=path,x=x,y=y}; return 20 end

METAMORPH_CREATIVE_MENU_ITEM_SERVICE=nil
local service=assert(native_dofile(root.."/files/features/items/service.lua"))
local entity,reason=service.spawn_near(1,"data/entities/items/test.xml")
assert(entity==20 and reason=="spawned_queued","LMB item spawn did not report synced world spawn")
assert(loaded.path=="data/entities/items/test.xml" and loaded.x==62 and loaded.y==52,"LMB item spawn position changed")
assert(notified_entity==20,"LMB world item was not registered with EW world-item transport")
io.write("item_world_spawn_sync=PASS lmb=true ew_notify=true\n")
