local human_restore = {}
local ew_serialization = dofile("mods/metamorph_creative_menu/files/integrations/ew/serialization.lua")

local POLYMORPH_EFFECTS = {
    "POLYMORPH", "POLYMORPH_RANDOM", "POLYMORPH_UNSTABLE", "POLYMORPH_CESSATION",
}

local function valid_component(component)
    return component ~= nil and component ~= 0
end

function human_restore.protect_player(player_entity, invincibility_frames)
    if player_entity == nil or player_entity == 0 then return end
    local damage_component = EntityGetFirstComponentIncludingDisabled(player_entity, "DamageModelComponent")
    if valid_component(damage_component) then
        local current_frames = tonumber(ComponentGetValue2(damage_component, "invincibility_frames")) or 0
        pcall(ComponentSetValue2, damage_component, "invincibility_frames", math.max(current_frames, tonumber(invincibility_frames) or 0))
        pcall(ComponentSetValue2, damage_component, "kill_now", false)
    end
end

function human_restore.polymorph_effect_components(entity)
    local result = {}
    if entity == nil or entity == 0 then return result end

    for _, effect_name in ipairs(POLYMORPH_EFFECTS) do
        local lookup_succeeded, component = pcall(GameGetGameEffect, entity, effect_name)
        if lookup_succeeded and valid_component(component) then result[#result + 1] = component end
    end
    if #result > 0 then return result end

    local queue, visited, index = { entity }, {}, 1
    while index <= #queue do
        local current_entity = queue[index]
        index = index + 1
        if current_entity ~= nil and current_entity ~= 0 and not visited[current_entity] then
            visited[current_entity] = true
            for _, component in ipairs(EntityGetComponentIncludingDisabled(current_entity, "GameEffectComponent") or {}) do
                local effect_name = valid_component(component) and ComponentGetValue2(component, "effect") or nil
                for _, wanted_effect in ipairs(POLYMORPH_EFFECTS) do
                    if effect_name == wanted_effect then
                        result[#result + 1] = component
                        break
                    end
                end
            end
            for _, child_entity in ipairs(EntityGetAllChildren(current_entity) or {}) do
                queue[#queue + 1] = child_entity
            end
        end
    end
    return result
end

function human_restore.serialized_backup_from_effects(components)
    for _, component in ipairs(components or {}) do
        local encoded_data = ComponentGetValue2(component, "mSerializedData")
        local serialized_backup = ew_serialization.decode_base64(encoded_data)
        if serialized_backup ~= nil then return serialized_backup end
    end
    return nil
end

function human_restore.deserialize_backup(bridge, serialized_backup, x, y, entity_name)
    if bridge == nil or type(bridge.DeserializeEntity) ~= "function" then return 0 end
    if type(serialized_backup) ~= "string" or serialized_backup == "" then return 0 end
    local restored_entity = EntityCreateNew(entity_name) or 0
    if restored_entity == 0 then return 0 end
    local deserialized = pcall(bridge.DeserializeEntity, restored_entity, serialized_backup, x, y)
    if not deserialized or not EntityGetIsAlive(restored_entity) then
        if EntityGetIsAlive(restored_entity) then EntityKill(restored_entity) end
        return 0
    end
    return restored_entity
end

return human_restore
