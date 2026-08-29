local root = assert(arg[1], "root required")
local native_dofile = dofile
local alive = {[1]=true}
local killed = {}
local next_entity = 100

local entity_tree = { walk=function(entity, callback) callback(entity) end }
local component_ops = {
    valid=function(value) return value ~= nil and value ~= 0 end,
    first=function() return nil end,
    get=function(component, field, default)
        if component == 10 and field == "image_file" then return "data/entities/gun.xml" end
        return default
    end,
    boolean=function(value) return value == true end,
    ensure_controls=function() return nil end,
    set_type_enabled=function() end,
    set_type_enabled_tree=function() end,
}
local tree_cache = { components=function() return {} end }

dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua" then return entity_tree end
    if path == "mods/metamorph_creative_menu/files/features/forms/component_ops.lua" then return component_ops end
    if path == "mods/metamorph_creative_menu/files/features/forms/entity_tree_cache.lua" then return tree_cache end
    return native_dofile(path)
end

EntityGetComponentIncludingDisabled = function(entity, component_type)
    if entity == 1 and component_type == "SpriteComponent" then return {10} end
    return {}
end
EntityCreateNew = function()
    local entity = next_entity
    next_entity = next_entity + 1
    alive[entity] = true
    return entity
end
EntityAddTag = function() end
EntityAddComponent2 = function() return 20 end
EntityGetTransform = function() return 5, 6 end
EntitySetTransform = function() end
EntitySetComponentIsEnabled = function() end
EntityGetIsAlive = function(entity) return alive[entity] == true end
EntityKill = function(entity) alive[entity] = false; killed[entity] = true end

METAMORPH_CREATIVE_MENU_FORM_COMBAT = nil
local first = assert(native_dofile(root .. "/files/features/forms/combat.lua"))
local second = assert(native_dofile(root .. "/files/features/forms/combat.lua"))
assert(first == second, "combat service was duplicated inside one Lua context")
first.setup_manual_barrels(1)
assert(alive[100] == true, "test pivot was not created")
second.reset()
assert(killed[100] == true and alive[100] == false,
    "reset through the other combat consumer did not clean the created runtime pivot")

dofile = native_dofile
print("form_combat_singleton_cleanup=PASS shared_lifecycle=true runtime_pivot_cleaned=true")
