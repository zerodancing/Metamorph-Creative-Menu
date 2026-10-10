local common = dofile("mods/metamorph_creative_menu/files/features/perks/inverse/common.lua")
local lukki = {}

local locomotion_baseline_by_player = {}

local function set_visual_state(player_entity_id, enabled)
    pcall(EntitySetComponentsWithTagEnabled, player_entity_id, "lukki_enable", enabled == true)
    pcall(EntitySetComponentsWithTagEnabled, player_entity_id, "attack_foot", enabled == true)
    pcall(EntitySetComponentsWithTagEnabled, player_entity_id, "lukki_disable", enabled ~= true)
    for _, sprite_component in ipairs(EntityGetComponentIncludingDisabled(player_entity_id, "SpriteComponent", "lukki_disable") or {}) do
        pcall(ComponentSetValue2, sprite_component, "alpha", enabled and 0.0 or 1.0)
    end
end

local function adjust_speed(player_entity_id, factor)
    factor = tonumber(factor) or 1
    if factor == 0 then return end
    for _, platforming_component in ipairs(EntityGetComponentIncludingDisabled(player_entity_id, "CharacterPlatformingComponent") or {}) do
        for _, field_name in ipairs({"run_velocity", "velocity_min_x", "velocity_max_x"}) do
            if type(ComponentGetMetaCustom) == "function" and type(ComponentSetMetaCustom) == "function" then
                local read_succeeded, current_value = pcall(ComponentGetMetaCustom, platforming_component, field_name)
                current_value = read_succeeded and tonumber(current_value) or nil
                if current_value ~= nil then
                    pcall(ComponentSetMetaCustom, platforming_component, field_name, current_value * factor)
                end
            end
        end
    end
end

local function matching_walkers(player_entity_id, perk_id)
    local wanted_tag = perk_id == "LEGGY_FEET" and "leggy_foot_walker" or "attack_foot_walker"
    local matching_entity_ids = {}
    common.walk_descendants(player_entity_id, function(entity_id)
        if EntityHasTag(entity_id, wanted_tag) then matching_entity_ids[#matching_entity_ids + 1] = entity_id end
    end)
    return matching_entity_ids
end

local function platform_meta(component_id, field_name)
    if type(ComponentGetMetaCustom) ~= "function" then return nil end
    local read_succeeded, current_value = pcall(ComponentGetMetaCustom, component_id, field_name)
    return read_succeeded and tonumber(current_value) or nil
end

local function capture_locomotion(player_entity_id)
    local baseline = {}
    for _, platforming_component in ipairs(EntityGetComponentIncludingDisabled(player_entity_id, "CharacterPlatformingComponent") or {}) do
        local gravity_read, pixel_gravity = pcall(ComponentGetValue2, platforming_component, "pixel_gravity")
        local frames_read, frames_not_swimming = pcall(ComponentGetValue2, platforming_component, "mFramesNotSwimming")
        baseline[#baseline + 1] = {
            pixel_gravity = gravity_read and tonumber(pixel_gravity) or nil,
            frames = frames_read and tonumber(frames_not_swimming) or nil,
            run = platform_meta(platforming_component, "run_velocity"),
            minx = platform_meta(platforming_component, "velocity_min_x"),
            maxx = platform_meta(platforming_component, "velocity_max_x"),
        }
    end
    return baseline
end

local function nearly_equal(left, right)
    left, right = tonumber(left), tonumber(right)
    if left == nil or right == nil then return false end
    return math.abs(left - right) <= math.max(0.001, math.abs(right) * 0.0001)
end

local function desired_world_gravity(fallback)
    local rules_loaded, world_rules = pcall(dofile, "mods/metamorph_creative_menu/files/features/world_rules/service.lua")
    if rules_loaded and type(world_rules) == "table" and type(world_rules.gravity_factor) == "function" then
        local factor_read, factor_value = pcall(world_rules.gravity_factor)
        if factor_read and tonumber(factor_value) ~= nil then return 350 * tonumber(factor_value) end
    end
    return fallback
end

-- Final Lukki cleanup is deliberately conservative for a tracked pickup: the mutation
-- journal already restored every synchronous write. We repair only values that still
-- look exactly like Lukki residue (zero gravity or the known 1.1 locomotion multiplier),
-- so a world-rule/mod change made while the perk was active is not overwritten.
local function restore_locomotion(player_entity_id, only_known_residue)
    set_visual_state(player_entity_id, false)
    local baseline = locomotion_baseline_by_player[player_entity_id]
    local platforming_components = EntityGetComponentIncludingDisabled(player_entity_id, "CharacterPlatformingComponent") or {}
    for component_index, platforming_component in ipairs(platforming_components) do
        local baseline_record = type(baseline) == "table" and baseline[component_index] or nil
        local gravity_read, current_gravity = pcall(ComponentGetValue2, platforming_component, "pixel_gravity")
        current_gravity = gravity_read and tonumber(current_gravity) or nil
        local baseline_gravity = baseline_record and baseline_record.pixel_gravity or nil
        local gravity_target = desired_world_gravity(baseline_gravity or 350)
        local gravity_scale = math.max(1, math.abs(tonumber(gravity_target) or tonumber(baseline_gravity) or 350))
        local residue_threshold = math.max(0.01, gravity_scale * 0.02)
        local looks_like_lukki_zero_gravity = current_gravity ~= nil
            and math.abs(tonumber(gravity_target) or 350) > residue_threshold
            and math.abs(current_gravity) <= residue_threshold
        if only_known_residue ~= true or current_gravity == nil or looks_like_lukki_zero_gravity then
            if gravity_target ~= nil then pcall(ComponentSetValue2, platforming_component, "pixel_gravity", gravity_target) end
        end

        if baseline_record and only_known_residue ~= true and baseline_record.frames ~= nil then
            pcall(ComponentSetValue2, platforming_component, "mFramesNotSwimming", baseline_record.frames)
        end
        if baseline_record and type(ComponentSetMetaCustom) == "function" then
            for field_name, baseline_value in pairs({
                run_velocity=baseline_record.run,
                velocity_min_x=baseline_record.minx,
                velocity_max_x=baseline_record.maxx,
            }) do
                if baseline_value ~= nil then
                    local read_ok, current_value = pcall(ComponentGetMetaCustom, platforming_component, field_name)
                    current_value = read_ok and tonumber(current_value) or nil
                    local looks_like_lukki = current_value ~= nil and nearly_equal(current_value, baseline_value * 1.1)
                    if only_known_residue ~= true or looks_like_lukki then
                        pcall(ComponentSetMetaCustom, platforming_component, field_name, baseline_value)
                    end
                end
            end
        end
    end
    pcall(GameRemoveFlagRun, "ATTACK_FOOT_CLIMBER")
    if type(RemoveFlagPersistent) == "function" then pcall(RemoveFlagPersistent, "player_status_lukky") end
end

local function remove_lukki(player_entity_id, current_count, perk_id)
    local stack_count = math.max(1, tonumber(current_count) or 1)
    local other_perk_id = perk_id == "ATTACK_FOOT" and "LEGGY_FEET" or "ATTACK_FOOT"
    local other_stack_count = common.perk_count(other_perk_id)

    if stack_count > 1 then
        if other_stack_count > 0 then return false, "inverse_shared_lukki_state" end
        local walkers = matching_walkers(player_entity_id, perk_id)
        local walkers_to_remove = perk_id == "LEGGY_FEET" and 1 or 2
        for walker_index = #walkers, math.max(1, #walkers - walkers_to_remove + 1), -1 do
            local walker_entity_id = walkers[walker_index]
            if walker_entity_id ~= nil and EntityGetIsAlive(walker_entity_id) then EntityKill(walker_entity_id) end
            table.remove(walkers, walker_index)
        end
        for _, walker_entity_id in ipairs(walkers) do
            local limb_component = EntityGetFirstComponentIncludingDisabled(walker_entity_id, "IKLimbComponent")
            if common.valid_component(limb_component) then
                local length_read, limb_length = pcall(ComponentGetValue2, limb_component, "length")
                limb_length = length_read and tonumber(limb_length) or nil
                if limb_length ~= nil then pcall(ComponentSetValue2, limb_component, "length", limb_length / 1.5) end
            end
        end
        local lukkiness_level = tonumber(GlobalsGetValue("PLAYER_LUKKINESS_LEVEL", "0")) or 0
        if lukkiness_level > 0 then
            if lukkiness_level == 3 then
                set_visual_state(player_entity_id, false)
                adjust_speed(player_entity_id, 1 / 1.1)
                if type(RemoveFlagPersistent) == "function" then pcall(RemoveFlagPersistent, "player_status_lukky") end
            end
            GlobalsSetValue("PLAYER_LUKKINESS_LEVEL", tostring(math.max(0, lukkiness_level - 1)))
        end
        local event_count = tonumber(GlobalsGetValue("LUKKI_PERK_TOTAL_COUNT", "0")) or 0
        if event_count > 0 then GlobalsSetValue("LUKKI_PERK_TOTAL_COUNT", tostring(event_count - 1)) end
        return true, "inverse_lukki_stack"
    end

    if other_stack_count > 0 then return false, "inverse_shared_lukki_state" end
    local changed = common.root_has_component_tag(player_entity_id, "lukki_enable")
        or common.root_has_component_tag(player_entity_id, "attack_foot")
    local victim_entity_ids = {}
    common.walk_descendants(player_entity_id, function(entity_id)
        local filename = string.lower(tostring(EntityGetFilename(entity_id) or ""))
        local entity_name = string.lower(tostring(EntityGetName(entity_id) or ""))
        if EntityHasTag(entity_id, "attack_foot_walker") or EntityHasTag(entity_id, "leggy_foot_walker")
            or string.find(filename, "/perks/attack_foot/", 1, true)
            or string.find(filename, "/perks/attack_leggy/", 1, true)
            or string.find(entity_name, "attack_foot", 1, true)
            or common.sprite_mentions(entity_id, "/perks/attack_foot/")
        then
            victim_entity_ids[#victim_entity_ids + 1] = entity_id
        end
    end)
    for _, victim_entity_id in ipairs(victim_entity_ids) do
        if EntityGetIsAlive(victim_entity_id) then
            for _, script_component in ipairs(EntityGetComponentIncludingDisabled(victim_entity_id, "LuaComponent") or {}) do
                pcall(EntitySetComponentIsEnabled, victim_entity_id, script_component, false)
            end
            EntityKill(victim_entity_id)
            changed = true
        end
    end
    set_visual_state(player_entity_id, false)
    restore_locomotion(player_entity_id, false)
    changed = true
    local character_data_component = EntityGetFirstComponentIncludingDisabled(player_entity_id, "CharacterDataComponent")
    if common.valid_component(character_data_component) then
        local velocity_read, velocity_x, velocity_y = pcall(ComponentGetValue2, character_data_component, "mVelocity")
        if velocity_read and math.abs(tonumber(velocity_y) or 0) < 4 then
            pcall(ComponentSetValue2, character_data_component, "mVelocity", tonumber(velocity_x) or 0, 8)
        end
    end
    GlobalsSetValue("PLAYER_LUKKINESS_LEVEL", "0")
    GlobalsSetValue("LUKKI_PERK_TOTAL_COUNT", "0")
    pcall(GameRemoveFlagRun, "ATTACK_FOOT_CLIMBER")
    if type(RemoveFlagPersistent) == "function" then pcall(RemoveFlagPersistent, "player_status_lukky") end
    return changed or true, "inverse_lukki_final"
end

local function cleanup_zero(player_entity_id)
    if common.perk_count("ATTACK_FOOT") > 0 or common.perk_count("LEGGY_FEET") > 0 then
        return true, "zero_lukki_shared_active"
    end
    restore_locomotion(player_entity_id, true)
    locomotion_baseline_by_player[player_entity_id] = nil
    GlobalsSetValue("PLAYER_LUKKINESS_LEVEL", "0")
    GlobalsSetValue("LUKKI_PERK_TOTAL_COUNT", "0")
    return true, "zero_lukki_locomotion_clean"
end

local function post_tracked_cleanup(_)
    -- Exact synchronous locomotion/global writes are already owned by the transaction.
    -- Do not divide speed here: doing so applied a second inverse on tracked stacks.
    return true, "post_tracked_lukki_transaction_owned"
end

function lukki.capture_pre_pickup(player_entity_id, perk_id)
    if perk_id ~= "ATTACK_FOOT" and perk_id ~= "LEGGY_FEET" then return true end
    local lukkiness_level = tonumber(GlobalsGetValue("PLAYER_LUKKINESS_LEVEL", "0")) or 0
    if lukkiness_level <= 0 and common.perk_count("ATTACK_FOOT") <= 0 and common.perk_count("LEGGY_FEET") <= 0 then
        locomotion_baseline_by_player[player_entity_id] = capture_locomotion(player_entity_id)
    end
    return true
end

function lukki.rebind_player(old_player_entity_id, new_player_entity_id)
    if old_player_entity_id == new_player_entity_id then return true end
    if locomotion_baseline_by_player[old_player_entity_id] ~= nil then
        locomotion_baseline_by_player[new_player_entity_id] = locomotion_baseline_by_player[old_player_entity_id]
        locomotion_baseline_by_player[old_player_entity_id] = nil
    end
    return true
end

lukki.handlers = {
    ATTACK_FOOT = function(player_entity_id, current_count) return remove_lukki(player_entity_id, current_count, "ATTACK_FOOT") end,
    LEGGY_FEET = function(player_entity_id, current_count) return remove_lukki(player_entity_id, current_count, "LEGGY_FEET") end,
}

lukki.zero_cleanup_handlers = {
    ATTACK_FOOT = cleanup_zero,
    LEGGY_FEET = cleanup_zero,
}

lukki.post_tracked_handlers = {
    ATTACK_FOOT = post_tracked_cleanup,
    LEGGY_FEET = post_tracked_cleanup,
}

return lukki
