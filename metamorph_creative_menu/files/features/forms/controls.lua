local form_controls = {}

local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local valid = component_ops.valid
local get_value = component_ops.get

function form_controls.direction(controls_component)
    if not valid(controls_component) then return 0, 0, false end
    local left_down = get_value(controls_component, "mButtonDownLeft", false) == true
    local right_down = get_value(controls_component, "mButtonDownRight", false) == true
    local up_down = get_value(controls_component, "mButtonDownUp", false) == true
        or get_value(controls_component, "mButtonDownFly", false) == true
    local down_down = get_value(controls_component, "mButtonDownDown", false) == true
    local direction_x = (right_down and 1 or 0) - (left_down and 1 or 0)
    local direction_y = (down_down and 1 or 0) - (up_down and 1 or 0)
    local direction_length = math.sqrt(direction_x * direction_x + direction_y * direction_y)
    if direction_length > 1 then
        direction_x, direction_y = direction_x / direction_length, direction_y / direction_length
    end
    return direction_x, direction_y, direction_x ~= 0 or direction_y ~= 0
end

return form_controls
