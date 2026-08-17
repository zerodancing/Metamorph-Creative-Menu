local fish_adapter = {}

local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local controls = dofile("mods/metamorph_creative_menu/files/features/forms/controls.lua")

local valid = component_ops.valid
local component = component_ops.first
local ensure_controls = component_ops.ensure_controls
local set_component_type_enabled = component_ops.set_type_enabled

function fish_adapter.configure(entity)
    set_component_type_enabled(entity, "AdvancedFishAIComponent", true)
    local fish_ai_component = component(entity, "AdvancedFishAIComponent")
    if valid(fish_ai_component) then
        pcall(ComponentSetValue2, fish_ai_component, "flock", false)
        pcall(ComponentSetValue2, fish_ai_component, "avoid_predators", false)
    end
end

function fish_adapter.update(entity)
    local controls_component = ensure_controls(entity)
    local direction_x, direction_y, is_moving = controls.direction(controls_component)
    local fish_ai_component = component(entity, "AdvancedFishAIComponent")
    if not valid(fish_ai_component) then return end
    local entity_x, entity_y = EntityGetTransform(entity)
    if entity_x == nil then return end
    pcall(ComponentSetValue2, fish_ai_component, "mHasTargetDirection", is_moving == true)
    if is_moving then
        pcall(ComponentSetValue2, fish_ai_component, "mTargetVec", direction_x, direction_y)
        pcall(ComponentSetValue2, fish_ai_component, "mTargetPos", entity_x + direction_x * 96, entity_y + direction_y * 96)
    else
        pcall(ComponentSetValue2, fish_ai_component, "mTargetVec", 0, 0)
    end
end

return fish_adapter
