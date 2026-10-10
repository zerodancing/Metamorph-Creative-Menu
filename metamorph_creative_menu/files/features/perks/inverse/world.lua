local common = dofile("mods/metamorph_creative_menu/files/features/perks/inverse/common.lua")
local world_inverse = {}
local gold_lifetime_service = nil

local function gold_lifetimes()
    if gold_lifetime_service == nil then
        gold_lifetime_service = dofile("mods/metamorph_creative_menu/files/features/world_rules/gold_lifetime.lua")
    end
    return gold_lifetime_service
end

local function set_world_number_delta(field_name, amount)
    local world_entity_id = GameGetWorldStateEntity()
    if world_entity_id == nil or world_entity_id == 0 then return false end
    local world_state_component = EntityGetFirstComponentIncludingDisabled(world_entity_id, "WorldStateComponent")
    if not common.valid_component(world_state_component) then return false end
    local read_succeeded, current_value = pcall(ComponentGetValue2, world_state_component, field_name)
    if not read_succeeded or tonumber(current_value) == nil then
        read_succeeded, current_value = pcall(ComponentGetValue, world_state_component, field_name)
    end
    if not read_succeeded or tonumber(current_value) == nil then return false end
    local target_value = tonumber(current_value) + (tonumber(amount) or 0)
    local write_succeeded = pcall(ComponentSetValue2, world_state_component, field_name, target_value)
    if not write_succeeded then
        write_succeeded = pcall(ComponentSetValue, world_state_component, field_name, tostring(target_value))
    end
    return write_succeeded
end

local function restore_gold_lifetimes()
    return gold_lifetimes().restore_missing_lifetimes() > 0
end

local function remove_gold_is_forever()
    local world_entity_id = GameGetWorldStateEntity()
    local world_state_component = world_entity_id ~= nil and world_entity_id ~= 0
        and EntityGetFirstComponentIncludingDisabled(world_entity_id, "WorldStateComponent") or nil
    local changed = false
    if common.valid_component(world_state_component) then
        local write_succeeded = pcall(ComponentSetValue2, world_state_component, "perk_gold_is_forever", false)
        if not write_succeeded then
            write_succeeded = pcall(ComponentSetValue, world_state_component, "perk_gold_is_forever", "0")
        end
        changed = write_succeeded or changed
    end
    changed = restore_gold_lifetimes() or changed
    return changed, changed and "inverse_gold_forever" or "inverse_no_change"
end

local function post_gold_is_forever()
    restore_gold_lifetimes()
    return true, "post_tracked_gold_lifetime"
end

local function remove_extra_shop_item()
    local current_item_count = tonumber(GlobalsGetValue("TEMPLE_SHOP_ITEM_COUNT", "5")) or 5
    GlobalsSetValue("TEMPLE_SHOP_ITEM_COUNT", tostring(math.max(5, current_item_count - 1)))
    return true, "inverse_extra_shop_item"
end

local function remove_genome_hatred(player_entity_id)
    local world_changed = set_world_number_delta("global_genome_relations_modifier", 25)
    local halo_changed = common.adjust_halo(player_entity_id, 1)
    local changed = world_changed or halo_changed
    return changed, changed and "inverse_genome_hatred" or "inverse_no_change"
end

local function remove_genome_love(player_entity_id)
    local world_changed = set_world_number_delta("global_genome_relations_modifier", -25)
    local halo_changed = common.adjust_halo(player_entity_id, -1)
    local changed = world_changed or halo_changed
    return changed, changed and "inverse_genome_love" or "inverse_no_change"
end

local function expire_charm_on_steves()
    local changed = false
    if type(EntityGetWithTag) ~= "function" then return false end
    local query_succeeded, steve_entities = pcall(EntityGetWithTag, "necromancer_shop")
    if not query_succeeded or type(steve_entities) ~= "table" then return false end
    for _, steve_entity_id in ipairs(steve_entities) do
        if steve_entity_id ~= nil and steve_entity_id ~= 0 and EntityGetIsAlive(steve_entity_id) then
            local effect_lookup_succeeded, charm_component = pcall(GameGetGameEffect, steve_entity_id, "CHARM")
            if effect_lookup_succeeded and common.valid_component(charm_component) then
                pcall(ComponentSetValue2, charm_component, "frames", 1)
                changed = true
            end
        end
    end
    return changed
end

local function reset_peace_globals()
    GlobalsSetValue("TEMPLE_PEACE_WITH_GODS", "0")
    GlobalsSetValue("TEMPLE_SPAWN_GUARDIAN", "0")
    return true
end

local function remove_peace_with_gods(player_entity_id)
    local changed = reset_peace_globals()
    changed = expire_charm_on_steves() or changed
    changed = common.adjust_halo(player_entity_id, -1) or changed
    return changed, "inverse_peace_with_gods"
end

local function post_peace_with_gods()
    expire_charm_on_steves()
    return true, "post_tracked_peace_charm"
end

local function remove_no_more_shuffle_untracked()
    -- Existing wands were rewritten globally on pickup. Without our transaction there
    -- is no safe way to infer which wands used to shuffle.
    return false, "inverse_requires_tracked_copy"
end

world_inverse.handlers = {
    GOLD_IS_FOREVER = remove_gold_is_forever,
    EXTRA_SHOP_ITEM = remove_extra_shop_item,
    GENOME_MORE_HATRED = remove_genome_hatred,
    GENOME_MORE_LOVE = remove_genome_love,
    PEACE_WITH_GODS = remove_peace_with_gods,
    NO_MORE_SHUFFLE = remove_no_more_shuffle_untracked,
}

world_inverse.post_tracked_handlers = {
    GOLD_IS_FOREVER = post_gold_is_forever,
    PEACE_WITH_GODS = post_peace_with_gods,
}

return world_inverse
