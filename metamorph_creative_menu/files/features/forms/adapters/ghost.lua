local ghost_adapter = {}

local entity_tree = dofile("mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua")
local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local controls = dofile("mods/metamorph_creative_menu/files/features/forms/controls.lua")

local valid = component_ops.valid
local component = component_ops.first
local get_value = component_ops.get
local ensure_controls = component_ops.ensure_controls

function ghost_adapter.stabilize_lifecycle(entity)
    entity_tree.walk(entity, function(current_entity)
        for _, ghost_component in ipairs(EntityGetComponentIncludingDisabled(current_entity, "GhostComponent") or {}) do
            pcall(ComponentSetValue2, ghost_component, "die_if_no_home", false)
            pcall(ComponentSetValue2, ghost_component, "mFramesWithoutHome", 0)
            pcall(EntitySetComponentIsEnabled, current_entity, ghost_component, true)
        end
        for _, lua_component in ipairs(EntityGetComponentIncludingDisabled(current_entity, "LuaComponent") or {}) do
            local source_file = string.lower(tostring(get_value(lua_component, "script_source_file", "") or ""))
            if string.find(source_file, "data/scripts/animals/wand_ghost.lua", 1, true) ~= nil then
                pcall(EntitySetComponentIsEnabled, current_entity, lua_component, false)
            end
        end
    end)
end

function ghost_adapter.configure(entity)
    ensure_controls(entity)
    ghost_adapter.stabilize_lifecycle(entity)
    local ghost_component = component(entity, "GhostComponent")
    if valid(ghost_component) then
        pcall(ComponentSetValue2, ghost_component, "target_tag", "__metamorph_creative_menu_player_controlled_ghost__")
        pcall(ComponentSetValue2, ghost_component, "max_distance_from_home", 1000000)
        pcall(ComponentSetValue2, ghost_component, "mEntityHome", 0)
        pcall(ComponentSetValue2, ghost_component, "mFramesWithoutHome", 0)
    end
end

function ghost_adapter.update(entity)
    local controls_component = ensure_controls(entity)
    local direction_x, direction_y, is_moving = controls.direction(controls_component)
    local ghost_component = component(entity, "GhostComponent")
    if not valid(ghost_component) then return end
    local entity_x, entity_y = EntityGetTransform(entity)
    if entity_x == nil then return end
    local movement_speed = math.max(1, tonumber(get_value(ghost_component, "speed", 5)) or 5)
    pcall(ComponentSetValue2, ghost_component, "die_if_no_home", false)
    pcall(ComponentSetValue2, ghost_component, "mFramesWithoutHome", 0)
    pcall(ComponentSetValue2, ghost_component, "mEntityHome", 0)
    pcall(ComponentSetValue2, ghost_component, "mTargetEntityId", 0)
    pcall(ComponentSetValue2, ghost_component, "mNextTargetCheckFrame", GameGetFrameNum() + 120)
    if is_moving then
        pcall(ComponentSetValue2, ghost_component, "mTargetPosition", entity_x + direction_x * 120, entity_y + direction_y * 120)
        pcall(ComponentSetValue2, ghost_component, "velocity", direction_x * movement_speed, direction_y * movement_speed)
    else
        pcall(ComponentSetValue2, ghost_component, "mTargetPosition", entity_x, entity_y)
        pcall(ComponentSetValue2, ghost_component, "velocity", 0, 0)
    end
end

return ghost_adapter
