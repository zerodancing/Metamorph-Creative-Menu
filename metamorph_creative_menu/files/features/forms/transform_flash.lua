local transform_flash = {}

local active_override = nil

local function valid(component)
    return component ~= nil and component ~= 0
end

local function world_state_component()
    local world_entity = GameGetWorldStateEntity()
    if world_entity == nil or world_entity == 0 then return nil end
    local world_state_component_id = EntityGetFirstComponentIncludingDisabled(world_entity, "WorldStateComponent")
    return valid(world_state_component_id) and world_state_component_id or nil
end

function transform_flash.restore(force)
    local override = active_override
    if type(override) ~= "table" then return end
    local current_frame = tonumber(GameGetFrameNum()) or 0
    local world_state_component_id = override.component
    if force ~= true and current_frame < (tonumber(override.until_frame) or current_frame) then
        if valid(world_state_component_id) then
            pcall(ComponentSetValue2, world_state_component_id, "damage_flash_multiplier", 0)
            pcall(ComponentSetValue2, world_state_component_id, "mFlashAlpha", 0)
        end
        return
    end
    if valid(world_state_component_id) then
        local read_succeeded, current_multiplier = pcall(ComponentGetValue2, world_state_component_id, "damage_flash_multiplier")
        if read_succeeded and math.abs((tonumber(current_multiplier) or 0)) < 0.000001 then
            pcall(ComponentSetValue2, world_state_component_id, "damage_flash_multiplier", override.original)
        end
        pcall(ComponentSetValue2, world_state_component_id, "mFlashAlpha", 0)
    end
    active_override = nil
end

function transform_flash.suppress(frames)
    transform_flash.restore(true)
    local world_state_component_id = world_state_component()
    if not valid(world_state_component_id) then return end
    local read_succeeded, original_multiplier = pcall(ComponentGetValue2, world_state_component_id, "damage_flash_multiplier")
    if not read_succeeded or tonumber(original_multiplier) == nil then return end
    active_override = {
        component = world_state_component_id,
        original = tonumber(original_multiplier),
        until_frame = (tonumber(GameGetFrameNum()) or 0) + math.max(3, tonumber(frames) or 16),
    }
    pcall(ComponentSetValue2, world_state_component_id, "damage_flash_multiplier", 0)
    pcall(ComponentSetValue2, world_state_component_id, "mFlashAlpha", 0)
end

return transform_flash
