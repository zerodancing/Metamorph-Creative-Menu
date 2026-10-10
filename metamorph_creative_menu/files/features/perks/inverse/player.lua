local common = dofile("mods/metamorph_creative_menu/files/features/perks/inverse/common.lua")
local player_inverse = {}
local pending_cleanup = dofile("mods/metamorph_creative_menu/files/features/perks/transactions/pending_cleanup.lua")

local function remove_laser_aim(player_entity_id, current_count)
    if (tonumber(current_count) or 1) > 1 then return false, "inverse_requires_tracked_copy" end
    local changed = false
    local victim_entity_ids = {}
    common.walk_descendants(player_entity_id, function(entity_id)
        local filename = string.lower(tostring(EntityGetFilename(entity_id) or ""))
        local entity_name = string.lower(tostring(EntityGetName(entity_id) or ""))
        local has_laser = #(EntityGetComponentIncludingDisabled(entity_id, "LaserEmitterComponent") or {}) > 0
        local looks_owned = EntityHasTag(entity_id, "perk_entity")
            or string.find(filename, "/perks/laser", 1, true)
            or string.find(filename, "laser_aim", 1, true)
            or string.find(entity_name, "laser_aim", 1, true)
            or common.sprite_mentions(entity_id, "laser_aim")
        if has_laser and looks_owned then victim_entity_ids[#victim_entity_ids + 1] = entity_id end
    end)
    for _, victim_entity_id in ipairs(victim_entity_ids) do
        if EntityGetIsAlive(victim_entity_id) then EntityKill(victim_entity_id); changed = true end
    end

    -- A human player may receive LASER_AIM directly on the root. A polymorphed creature
    -- can own native emitters, so root emitters are never removed from a polymorphed body.
    if not EntityHasTag(player_entity_id, "polymorphed_player") then
        for _, laser_component in ipairs(EntityGetComponentIncludingDisabled(player_entity_id, "LaserEmitterComponent") or {}) do
            pcall(EntityRemoveComponent, player_entity_id, laser_component)
            changed = true
        end
    end
    return changed
end

local function remove_enemy_radar(player_entity_id)
    -- RADAR_ENEMY has one precise persistent mechanic: a perk_component LuaComponent
    -- executing data/scripts/perks/radar.lua every frame. Removing one matching component
    -- is therefore a safe inverse even for a pickup observed before transaction tracking.
    for _, lua_component in ipairs(EntityGetComponentIncludingDisabled(player_entity_id, "LuaComponent") or {}) do
        local script_read, script_source = pcall(ComponentGetValue2, lua_component, "script_source_file")
        local tag_read, has_perk_tag = pcall(ComponentHasTag, lua_component, "perk_component")
        if script_read and tostring(script_source or "") == "data/scripts/perks/radar.lua"
            and (not tag_read or has_perk_tag == true)
        then
            if type(EntitySetComponentIsEnabled) == "function" then
                pcall(EntitySetComponentIsEnabled, player_entity_id, lua_component, false)
            end
            local ok, reason = pending_cleanup.retire_component(player_entity_id, lua_component, "inverse:RADAR_ENEMY")
            return ok == true, ok and "inverse_enemy_radar" or tostring(reason)
        end
    end
    -- If the component is already gone, retiring the stale pickup count is safe.
    return true, "inverse_enemy_radar_already_clean"
end

local function remove_respawn(player_entity_id)
    return common.expire_one_effect(player_entity_id, "RESPAWN")
end

local function remove_saving_grace(player_entity_id)
    local effect_changed = common.expire_one_effect(player_entity_id, "SAVING_GRACE")
    local halo_changed = common.adjust_halo(player_entity_id, -1)
    return true, (effect_changed or halo_changed) and "inverse_saving_grace" or "inverse_saving_grace_state_only"
end

local function cleanup_saving_grace_zero(player_entity_id)
    local expired_count = 0
    common.walk_descendants(player_entity_id, function(entity_id)
        local game_effect_component = EntityGetFirstComponentIncludingDisabled(entity_id, "GameEffectComponent")
        if common.valid_component(game_effect_component) and common.component_effect(game_effect_component) == "SAVING_GRACE" then
            pcall(ComponentSetValue2, game_effect_component, "frames", 1)
            expired_count = expired_count + 1
        end
    end)
    return true, "zero_saving_grace:" .. tostring(expired_count)
end

local function remove_global_gore(player_entity_id)
    local effect_changed = common.expire_one_effect(player_entity_id, "GLOBAL_GORE")
    local halo_changed = common.adjust_halo(player_entity_id, 1)
    local changed = effect_changed or halo_changed
    return changed, changed and "inverse_global_gore" or "inverse_no_change"
end

local function remove_fast_projectiles(player_entity_id)
    for _, shot_effect_component in ipairs(EntityGetComponentIncludingDisabled(player_entity_id, "ShotEffectComponent") or {}) do
        local extra_modifier = tostring(ComponentGetValue2(shot_effect_component, "extra_modifier") or "")
        local tag_query_succeeded, has_perk_tag = pcall(ComponentHasTag, shot_effect_component, "perk_component")
        if extra_modifier == "fast_projectiles" and tag_query_succeeded and has_perk_tag == true then
            local remove_succeeded = pcall(EntityRemoveComponent, player_entity_id, shot_effect_component)
            return remove_succeeded, remove_succeeded and "inverse_fast_projectiles" or "inverse_remove_failed"
        end
    end
    return false, "inverse_no_modifier"
end

local function restore_invisibility_sprites(player_entity_id)
    local changed = false
    for _, sprite_component in ipairs(EntityGetComponentIncludingDisabled(player_entity_id, "SpriteComponent") or {}) do
        local alpha_read, current_alpha = pcall(ComponentGetValue2, sprite_component, "alpha")
        if alpha_read and tonumber(current_alpha) ~= nil and tonumber(current_alpha) ~= 1 then
            pcall(ComponentSetValue2, sprite_component, "alpha", 1.0)
            changed = true
        end
    end
    return changed, changed and "inverse_invisibility_alpha" or "already_visible"
end

local function has_external_invisibility(player_entity_id)
    for _, child_entity_id in ipairs(EntityGetAllChildren(player_entity_id) or {}) do
        local game_effect_component = EntityGetFirstComponentIncludingDisabled(child_entity_id, "GameEffectComponent")
        if common.valid_component(game_effect_component)
            and common.component_effect(game_effect_component) == "INVISIBILITY"
            and not EntityHasTag(child_entity_id, "perk_entity")
        then
            local enabled = true
            if type(ComponentGetIsEnabled) == "function" then
                local ok_enabled, value = pcall(ComponentGetIsEnabled, game_effect_component)
                if ok_enabled then enabled = value == true end
            end
            local remaining_frames = tonumber(ComponentGetValue2(game_effect_component, "frames") or 0) or 0
            if enabled and (remaining_frames == -1 or remaining_frames > 1) then return true end
        end
    end
    return false
end

local function retire_perk_invisibility(player_entity_id)
    local changed = false
    for _, child_entity_id in ipairs(EntityGetAllChildren(player_entity_id) or {}) do
        local game_effect_component = EntityGetFirstComponentIncludingDisabled(child_entity_id, "GameEffectComponent")
        if common.valid_component(game_effect_component)
            and common.component_effect(game_effect_component) == "INVISIBILITY"
            and EntityHasTag(child_entity_id, "perk_entity")
        then
            if type(EntitySetComponentIsEnabled) == "function" then
                pcall(EntitySetComponentIsEnabled, child_entity_id, game_effect_component, false)
            end
            pending_cleanup.retire_entity(child_entity_id, "inverse:INVISIBILITY")
            changed = true
        end
    end
    return changed
end

local function remove_invisibility(player_entity_id)
    local effect_changed = retire_perk_invisibility(player_entity_id)
    local sprites_changed = false
    if not has_external_invisibility(player_entity_id) then sprites_changed = select(1, restore_invisibility_sprites(player_entity_id)) end
    return effect_changed or sprites_changed or true,
        (effect_changed or sprites_changed) and "inverse_invisibility" or "inverse_invisibility_already_clean"
end

local function post_invisibility(player_entity_id)
    retire_perk_invisibility(player_entity_id)
    if not has_external_invisibility(player_entity_id) then restore_invisibility_sprites(player_entity_id) end
    return true, "post_tracked_invisibility"
end

local function cleanup_zero_invisibility(player_entity_id)
    retire_perk_invisibility(player_entity_id)
    if not has_external_invisibility(player_entity_id) then restore_invisibility_sprites(player_entity_id) end
    return true
end

local function remove_personal_laser(player_entity_id, current_count)
    local stack_count = math.max(1, tonumber(current_count) or 1)
    local root_entity_ids = {}
    local laser_emitter_components = {}
    common.walk_descendants(player_entity_id, function(entity_id)
        if EntityGetRootEntity(entity_id) == player_entity_id then
            local filename = string.lower(tostring(EntityGetFilename(entity_id) or ""))
            if EntityHasTag(entity_id, "perk_entity") and string.find(filename, "/perks/personal_laser.xml", 1, true) then
                root_entity_ids[#root_entity_ids + 1] = entity_id
            end
            if EntityHasTag(entity_id, "personal_laser") then
                local laser_emitter_component = EntityGetFirstComponentIncludingDisabled(entity_id, "LaserEmitterComponent")
                if common.valid_component(laser_emitter_component) then
                    laser_emitter_components[#laser_emitter_components + 1] = laser_emitter_component
                end
            end
        end
    end)

    if stack_count > 1 then
        local remaining_stacks = stack_count - 1
        for _, laser_emitter_component in ipairs(laser_emitter_components) do
            pcall(ComponentObjectSetValue2, laser_emitter_component, "laser", "damage_to_entities", 0.15 + (remaining_stacks - 1) * 0.025)
            pcall(ComponentObjectSetValue2, laser_emitter_component, "laser", "damage_to_cells", 3000 + (remaining_stacks - 1) * 350)
            pcall(ComponentObjectSetValue2, laser_emitter_component, "laser", "max_length", 54 + (remaining_stacks - 1) * 12)
        end
        return #laser_emitter_components > 0,
            #laser_emitter_components > 0 and "inverse_scaled" or "inverse_no_emitter"
    end

    local changed = false
    for _, root_entity_id in ipairs(root_entity_ids) do
        if EntityGetIsAlive(root_entity_id) then EntityKill(root_entity_id); changed = true end
    end
    for _, shot_effect_component in ipairs(EntityGetComponentIncludingDisabled(player_entity_id, "ShotEffectComponent") or {}) do
        local extra_modifier = tostring(ComponentGetValue2(shot_effect_component, "extra_modifier") or "")
        if extra_modifier == "slow_firing" and ComponentHasTag(shot_effect_component, "perk_component") then
            pcall(EntityRemoveComponent, player_entity_id, shot_effect_component)
            changed = true
            break
        end
    end
    return changed
end

local function remove_fungal_disease(player_entity_id)
    local victim_entity_ids = {}
    for _, child_entity_id in ipairs(EntityGetAllChildren(player_entity_id) or {}) do
        if string.lower(tostring(EntityGetFilename(child_entity_id) or "")) == "data/entities/misc/perks/fungal_disease.xml" then
            victim_entity_ids[#victim_entity_ids + 1] = child_entity_id
        end
    end
    local victim_entity_id = victim_entity_ids[#victim_entity_ids]
    if victim_entity_id ~= nil and EntityGetIsAlive(victim_entity_id) then
        for _, lua_component in ipairs(EntityGetComponentIncludingDisabled(victim_entity_id, "LuaComponent") or {}) do
            pcall(EntitySetComponentIsEnabled, victim_entity_id, lua_component, false)
        end
        EntityKill(victim_entity_id)
    end
    local total_count = tonumber(GlobalsGetValue("FUNGI_PERK_TOTAL_COUNT", "0")) or 0
    if total_count > 0 then GlobalsSetValue("FUNGI_PERK_TOTAL_COUNT", tostring(total_count - 1)) end
    return victim_entity_id ~= nil or total_count > 0, "inverse_fungal_disease"
end

local function remove_gamble_counter_only()
    -- GAMBLE's two random rewards are independent real pickups. Guessing ownership here
    -- could delete unrelated later stacks, so only GAMBLE's own counter is retired.
    return true, "inverse_gamble_counter_only"
end

local function remove_extra_perk()
    local current_perk_count = tonumber(GlobalsGetValue("TEMPLE_PERK_COUNT", "3")) or 3
    GlobalsSetValue("TEMPLE_PERK_COUNT", tostring(math.max(3, current_perk_count - 1)))
    return true, "inverse_extra_perk"
end

player_inverse.handlers = {
    GAMBLE = remove_gamble_counter_only,
    RESPAWN = remove_respawn,
    LASER_AIM = remove_laser_aim,
    PERSONAL_LASER = remove_personal_laser,
    SAVING_GRACE = remove_saving_grace,
    GLOBAL_GORE = remove_global_gore,
    FAST_PROJECTILES = remove_fast_projectiles,
    RADAR_ENEMY = remove_enemy_radar,
    INVISIBILITY = remove_invisibility,
    FUNGAL_DISEASE = remove_fungal_disease,
    EXTRA_PERK = remove_extra_perk,
}

player_inverse.zero_cleanup_handlers = {
    SAVING_GRACE = cleanup_saving_grace_zero,
    INVISIBILITY = cleanup_zero_invisibility,
}

player_inverse.maintenance_handlers = {
    INVISIBILITY = cleanup_zero_invisibility,
}

player_inverse.post_tracked_handlers = {
    INVISIBILITY = post_invisibility,
}

player_inverse.fallback_after_stale_transaction = {
    SAVING_GRACE = true,
}

return player_inverse
