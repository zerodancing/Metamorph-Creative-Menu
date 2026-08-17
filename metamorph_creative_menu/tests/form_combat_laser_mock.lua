local root = assert(arg[1], "root required")
local native_dofile = dofile
local laser_component = 20
local controls_component = 10
local writes = {}
local ranged_components = {}

METAMORPH_CREATIVE_MENU_FORM_COMPONENT_OPS = nil
METAMORPH_CREATIVE_MENU_FORM_ENTITY_TREE_CACHE = nil

local component_values = {
    [controls_component] = {mButtonDownFire=true, mButtonDownFire2=false},
    [laser_component] = {},
}

local component_ops_stub = {
    valid=function(value) return value ~= nil and value ~= 0 end,
    first=function(entity, kind) if kind == "ControlsComponent" then return controls_component end return nil end,
    get=function(component, field, fallback)
        local values = component_values[component]
        local value = values and values[field]
        return value ~= nil and value or fallback
    end,
    boolean=function(value) return value == true or value == 1 end,
    ensure_controls=function() return controls_component end,
    set_type_enabled=function() end,
    set_type_enabled_tree=function() end,
}
local tree_cache_stub = {
    components=function(_, kind)
        if kind == "LaserEmitterComponent" then return {laser_component} end
        if kind == "AIAttackComponent" then return ranged_components end
        return {}
    end,
}
local entity_tree_stub = {walk=function(entity, fn) fn(entity) end}

dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/features/forms/component_ops.lua" then return component_ops_stub end
    if path == "mods/metamorph_creative_menu/files/features/forms/entity_tree_cache.lua" then return tree_cache_stub end
    if path == "mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua" then return entity_tree_stub end
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path, 1, #prefix) == prefix then return native_dofile(root .. "/" .. string.sub(path, #prefix + 1)) end
    return native_dofile(path)
end

function ComponentGetEntity(component) return component == laser_component and 1 or 0 end
function EntityGetIsAlive(entity) return entity == 1 end
function EntityGetTransform(entity) return 0, 0, math.pi * 0.75, 1, 1 end
function DEBUG_GetMouseWorld() return 100, 0 end
function GameGetFrameNum() return 50 end
function ComponentSetValue2(component, field, value)
    writes[field] = value
    component_values[component] = component_values[component] or {}
    component_values[component][field] = value
end

local combat = native_dofile(root .. "/files/features/forms/combat.lua")
combat.update_manual_lasers(1)
assert(type(writes.laser_angle_add_rad) == "number", "laser aim angle was not calculated")
assert(writes.laser_angle_add_rad >= -math.pi and writes.laser_angle_add_rad <= math.pi, "laser angle was not normalized")
assert(writes.emit_until_frame == 52, "primary fire did not extend laser emission")

-- Ranged creatures reserve primary fire for their native ranged attack; their manual
-- laser must only respond to secondary fire. This catches Lua's false-and/or trap.
ranged_components={30}
writes.emit_until_frame=nil
component_values[controls_component].mButtonDownFire=true
component_values[controls_component].mButtonDownFire2=false
combat.update_manual_lasers(1)
assert(writes.emit_until_frame==nil,"ranged creature primary fire incorrectly activated manual laser")
component_values[controls_component].mButtonDownFire2=true
combat.update_manual_lasers(1)
assert(writes.emit_until_frame==52,"ranged creature secondary fire did not activate manual laser")
print("form_combat_laser=PASS normalized_angle=true ranged_secondary_only=true fire_frame=52")
