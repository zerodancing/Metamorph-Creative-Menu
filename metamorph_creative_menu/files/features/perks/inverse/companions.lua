local common = dofile("mods/metamorph_creative_menu/files/features/perks/inverse/common.lua")
local companions = {}

local function kill_matching_descendants(player_entity_id, predicate, limit)
    local victim_entity_ids = {}
    common.walk_descendants(player_entity_id, function(entity_id)
        if predicate(entity_id) then victim_entity_ids[#victim_entity_ids + 1] = entity_id end
    end)
    local killed_count = 0
    for _, victim_entity_id in ipairs(victim_entity_ids) do
        if limit ~= nil and killed_count >= limit then break end
        if EntityGetIsAlive(victim_entity_id) then
            for _, script_component in ipairs(EntityGetComponentIncludingDisabled(victim_entity_id, "LuaComponent") or {}) do
                pcall(EntitySetComponentIsEnabled, victim_entity_id, script_component, false)
            end
            EntityKill(victim_entity_id)
            killed_count = killed_count + 1
        end
    end
    return killed_count
end

local function kill_ghost_descendants(player_entity_id, wanted_tag, filename_fragment, limit)
    return kill_matching_descendants(player_entity_id, function(entity_id)
        local filename = string.lower(tostring(EntityGetFilename(entity_id) or ""))
        return (wanted_tag ~= nil and EntityHasTag(entity_id, wanted_tag))
            or (filename_fragment ~= nil and string.find(filename, filename_fragment, 1, true) ~= nil)
    end, limit)
end

local function cleanup_ghost_family_zero(player_entity_id)
    local killed_count = 0
    if common.perk_count("ANGRY_GHOST") <= 0 then
        killed_count = killed_count + kill_ghost_descendants(player_entity_id, "angry_ghost", "angry_ghost")
    end
    if common.perk_count("HUNGRY_GHOST") <= 0 then
        killed_count = killed_count + kill_ghost_descendants(player_entity_id, "hungry_ghost", "hungry_ghost")
    end
    if common.perk_count("DEATH_GHOST") <= 0 then
        killed_count = killed_count + kill_ghost_descendants(player_entity_id, "death_ghost", "death_ghost")
    end
    if common.perk_count("ANGRY_GHOST") <= 0 or common.perk_count("HUNGRY_GHOST") <= 0 or common.perk_count("DEATH_GHOST") <= 0 then
        killed_count = killed_count + kill_ghost_descendants(player_entity_id, "ghostly_ghost", "ghostly_ghost")
    end
    return true, "zero_ghost_family:" .. tostring(killed_count)
end

local function remove_angry_ghost(player_entity_id)
    local killed_count = kill_ghost_descendants(player_entity_id, "angry_ghost", "angry_ghost", 1)
    return true, killed_count > 0 and "inverse_angry_ghost" or "inverse_angry_ghost_counter_only"
end

local function remove_death_ghost(player_entity_id)
    local killed_count = kill_ghost_descendants(player_entity_id, "death_ghost", "death_ghost", 1)
    return true, killed_count > 0 and "inverse_death_ghost" or "inverse_death_ghost_counter_only"
end

local function remove_hungry_ghost(player_entity_id)
    local killed_count = kill_matching_descendants(player_entity_id, function(entity_id)
        local filename = string.lower(tostring(EntityGetFilename(entity_id) or ""))
        return EntityHasTag(entity_id, "hungry_ghost")
            or filename == "data/entities/misc/perks/hungry_ghost.xml"
    end, 1)
    return true, killed_count > 0 and "inverse_hungry_ghost" or "inverse_hungry_ghost_counter_only"
end

local function remove_extra_mana_orphan()
    -- Exact menu-owned wand mutations are handled by transactions.lua. This fallback
    -- only retires a legacy/orphan pickup count when no transaction survives.
    return true, "inverse_extra_mana_orphan_counter_only"
end

local function remove_mega_beam_stone_counter()
    -- Detached beamstone ownership is handled by root_companions.lua. This fallback
    -- lets legacy/untracked pickup counts reach zero so that ownership cleanup can run.
    return true, "inverse_mega_beam_stone_counter"
end

local function cleanup_iron_stomach_zero(player_entity_id)
    local expired_count = 0
    common.walk_descendants(player_entity_id, function(entity_id)
        local game_effect_component = EntityGetFirstComponentIncludingDisabled(entity_id, "GameEffectComponent")
        if common.valid_component(game_effect_component) and common.component_effect(game_effect_component) == "IRON_STOMACH" then
            pcall(ComponentSetValue2, game_effect_component, "frames", 1)
            expired_count = expired_count + 1
        end
    end)
    local lookup_succeeded, game_effect_component = pcall(GameGetGameEffect, player_entity_id, "IRON_STOMACH")
    if lookup_succeeded and common.valid_component(game_effect_component) then
        pcall(ComponentSetValue2, game_effect_component, "frames", 1)
        expired_count = expired_count + 1
    end
    return true, "zero_iron_stomach:" .. tostring(expired_count)
end

local function remove_iron_stomach(player_entity_id)
    local changed = common.expire_one_effect(player_entity_id, "IRON_STOMACH")
    return changed, changed and "inverse_iron_stomach" or "inverse_iron_stomach_missing"
end

companions.handlers = {
    ANGRY_GHOST = remove_angry_ghost,
    HUNGRY_GHOST = remove_hungry_ghost,
    DEATH_GHOST = remove_death_ghost,
    EXTRA_MANA = remove_extra_mana_orphan,
    MEGA_BEAM_STONE = remove_mega_beam_stone_counter,
    IRON_STOMACH = remove_iron_stomach,
}

companions.zero_cleanup_handlers = {
    ANGRY_GHOST = cleanup_ghost_family_zero,
    HUNGRY_GHOST = cleanup_ghost_family_zero,
    DEATH_GHOST = cleanup_ghost_family_zero,
    IRON_STOMACH = cleanup_iron_stomach_zero,
}

companions.maintenance_handlers = {
    ANGRY_GHOST = cleanup_ghost_family_zero,
    HUNGRY_GHOST = cleanup_ghost_family_zero,
    DEATH_GHOST = cleanup_ghost_family_zero,
}

return companions
