if type(METAMORPH_CREATIVE_MENU_COMPANION_HEALTH) == "table" then return METAMORPH_CREATIVE_MENU_COMPANION_HEALTH end

local companion_health = {}

local function valid(entity)
    return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity)
end

local function state_component(entity)
    local component = EntityGetFirstComponentIncludingDisabled(entity, "VariableStorageComponent", "mcm_companion_health_target")
    return component ~= nil and component ~= 0 and component or nil
end

-- Repair only the base-humanoid initialization clamp recorded by player_avatar.lua.
-- This function never heals ordinary combat damage: HP is raised only on the first
-- observed 1/1-style clamp while max_hp is below the intended spawn max.
function companion_health.repair(entity)
    if not valid(entity) then return false, true, "entity_gone" end
    local state = state_component(entity)
    local damage = EntityGetFirstComponentIncludingDisabled(entity, "DamageModelComponent")
    if state == nil or damage == nil or damage == 0 then return false, true, "components_missing" end

    local desired = tonumber(ComponentGetValue2(state, "value_float")) or 0
    local born = tonumber(ComponentGetValue2(state, "value_int")) or GameGetFrameNum()
    local repaired = ComponentGetValue2(state, "value_bool") == true
    local frame = tonumber(GameGetFrameNum()) or 0
    local changed = false

    if desired > 0 then
        local current_max = tonumber(ComponentGetValue2(damage, "max_hp")) or 0
        if current_max + 0.0001 < desired then
            local current_hp = tonumber(ComponentGetValue2(damage, "hp")) or 0
            local cap = tonumber(ComponentGetValue2(damage, "max_hp_cap")) or 0
            if cap <= 0 or cap < desired then ComponentSetValue2(damage, "max_hp_cap", desired) end
            ComponentSetValue2(damage, "max_hp", desired)
            -- Only the first initialization clamp may restore HP. Once repaired=true,
            -- a later max_hp correction cannot undo combat damage.
            if not repaired and current_hp > 0 and current_hp <= math.max(1.0001, current_max + 0.0001) then
                ComponentSetValue2(damage, "hp", desired)
            end
            ComponentSetValue2(state, "value_bool", true)
            repaired = true
            changed = true
        end
    end

    local finished = frame - born >= 30
    return changed, finished, finished and "window_complete" or (repaired and "repaired" or "watching")
end

METAMORPH_CREATIVE_MENU_COMPANION_HEALTH = companion_health
return companion_health
