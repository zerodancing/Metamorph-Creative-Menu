local worm_adapter = {}

local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local controls = dofile("mods/metamorph_creative_menu/files/features/forms/controls.lua")

local valid = component_ops.valid
local component = component_ops.first
local get_value = component_ops.get
local boolean_value = component_ops.boolean
local set_typed_scalar = component_ops.set_typed_scalar
local ensure_controls = component_ops.ensure_controls

local steering_x = 0
local steering_y = 0
local manual_direction_enabled = false
local STEERING_RESPONSE = 0.14

local function water_worm_component(entity)
    local worm_component = component(entity, "WormComponent")
    if valid(worm_component) and get_value(worm_component, "is_water_worm", false) == true then
        return worm_component
    end
    return nil
end

function worm_adapter.reset()
    steering_x = 0
    steering_y = 0
    manual_direction_enabled = false
end

function worm_adapter.configure(entity, root_lifecycle_was_temporary)
    steering_x, steering_y = 0, 0
    manual_direction_enabled = valid(water_worm_component(entity))

    local worm_component = component(entity, "WormComponent")
    if not valid(worm_component) or root_lifecycle_was_temporary ~= true then return end
    local gravity = tonumber(get_value(worm_component, "gravity", 0)) or 0
    local tail_gravity = tonumber(get_value(worm_component, "tail_gravity", 0)) or 0
    local is_water_worm = boolean_value(get_value(worm_component, "is_water_worm", false)) == true
    if gravity > 0 or tail_gravity > 0 or is_water_worm then return end

    -- The illusion worm is authored with a temporary root and a contact envelope that
    -- is unsuitable for player control. Reconstruct ordinary big-worm proportions while
    -- leaving direction to Noita's native WormPlayer controller.
    local part_distance = math.max(2, tonumber(get_value(worm_component, "part_distance", 10)) or 10)
    local ground_check_offset = math.max(1, math.floor(part_distance * 0.5 + 0.5))
    local hitbox_radius = math.max(1, part_distance * 0.5625)
    set_typed_scalar(worm_component, "ground_check_offset", ground_check_offset)
    set_typed_scalar(worm_component, "hitbox_radius", hitbox_radius)
end

function worm_adapter.update(entity)
    if not manual_direction_enabled then return end
    local controls_component = ensure_controls(entity)
    local direction_x, direction_y, is_moving = controls.direction(controls_component)
    local worm_player_component = component(entity, "WormPlayerComponent")
    if not valid(worm_player_component) then return end
    local target_x, target_y = is_moving and direction_x or 0, is_moving and direction_y or 0
    steering_x = steering_x + (target_x - steering_x) * STEERING_RESPONSE
    steering_y = steering_y + (target_y - steering_y) * STEERING_RESPONSE
    pcall(ComponentSetValue2, worm_player_component, "mDirection", steering_x, steering_y)
end

return worm_adapter
