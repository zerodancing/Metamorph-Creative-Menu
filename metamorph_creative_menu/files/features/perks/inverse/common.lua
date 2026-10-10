local common = {}

function common.valid_component(component_id)
    return component_id ~= nil and component_id ~= 0
end

function common.component_effect(component_id)
    if not common.valid_component(component_id) then return "" end
    local effect_id = tostring(ComponentGetValue2(component_id, "effect") or "")
    if effect_id == "CUSTOM" then
        local custom_effect_id = tostring(ComponentGetValue2(component_id, "custom_effect_id") or "")
        if custom_effect_id ~= "" then return custom_effect_id end
    end
    return effect_id
end

function common.expire_one_effect(player_entity_id, wanted_effect_id)
    for _, child_entity_id in ipairs(EntityGetAllChildren(player_entity_id) or {}) do
        local game_effect_component = EntityGetFirstComponentIncludingDisabled(child_entity_id, "GameEffectComponent")
        if common.valid_component(game_effect_component)
            and common.component_effect(game_effect_component) == wanted_effect_id
        then
            pcall(ComponentSetValue2, game_effect_component, "frames", 1)
            return true
        end
    end
    local lookup_succeeded, game_effect_component = pcall(GameGetGameEffect, player_entity_id, wanted_effect_id)
    if lookup_succeeded and common.valid_component(game_effect_component) then
        pcall(ComponentSetValue2, game_effect_component, "frames", 1)
        return true
    end
    return false
end

function common.walk_descendants(root_entity_id, visitor)
    local pending_entity_ids = { root_entity_id }
    local next_index = 1
    local visited_entity_ids = {}
    while next_index <= #pending_entity_ids do
        local entity_id = pending_entity_ids[next_index]
        next_index = next_index + 1
        if entity_id ~= nil and entity_id ~= 0 and not visited_entity_ids[entity_id] and EntityGetIsAlive(entity_id) then
            visited_entity_ids[entity_id] = true
            if entity_id ~= root_entity_id then visitor(entity_id) end
            for _, child_entity_id in ipairs(EntityGetAllChildren(entity_id) or {}) do
                pending_entity_ids[#pending_entity_ids + 1] = child_entity_id
            end
        end
    end
end

function common.sprite_mentions(entity_id, filename_fragment)
    filename_fragment = string.lower(tostring(filename_fragment or ""))
    for _, sprite_component in ipairs(EntityGetComponentIncludingDisabled(entity_id, "SpriteComponent") or {}) do
        local image_filename = string.lower(tostring(ComponentGetValue2(sprite_component, "image_file") or ""))
        if filename_fragment ~= "" and string.find(image_filename, filename_fragment, 1, true) then return true end
    end
    return false
end

function common.root_has_component_tag(player_entity_id, component_tag)
    for _, component_id in ipairs(EntityGetAllComponents(player_entity_id) or {}) do
        local query_succeeded, has_tag = pcall(ComponentHasTag, component_id, component_tag)
        if query_succeeded and has_tag == true then return true end
    end
    return false
end

function common.perk_count(perk_id)
    return math.max(0, tonumber(GlobalsGetValue("PERK_PICKED_" .. tostring(perk_id) .. "_PICKUP_COUNT", "0")) or 0)
end

function common.adjust_halo(player_entity_id, amount)
    if type(add_halo_level) ~= "function" then
        pcall(dofile_once, "data/scripts/perks/perk_utilities.lua")
    end
    if type(add_halo_level) ~= "function" then return false end
    return pcall(add_halo_level, player_entity_id, amount)
end

return common
