if type(METAMORPH_CREATIVE_MENU_PERK_LOCOMOTION_GUARD) == "table" then return METAMORPH_CREATIVE_MENU_PERK_LOCOMOTION_GUARD end

-- Some mutation perks (notably the Lukki family) apply part of their locomotion state
-- asynchronously, so a later perk can legitimately capture that temporary value as its
-- own "before" state. When the final tracked perk transaction disappears, this guard
-- repairs only pathological near-zero player gravity back to the pre-session/world-rule
-- baseline. It never rewrites ordinary nonzero gravity values.
local locomotion_guard = {}
local baseline_by_player = {}

local function valid(entity_id)
    return entity_id ~= nil and entity_id ~= 0 and type(EntityGetIsAlive) == "function" and EntityGetIsAlive(entity_id)
end

local function capture(player_entity_id)
    local result = {}
    for index, component_id in ipairs(EntityGetComponentIncludingDisabled(player_entity_id, "CharacterPlatformingComponent") or {}) do
        local ok, gravity = pcall(ComponentGetValue2, component_id, "pixel_gravity")
        result[index] = {gravity=ok and tonumber(gravity) or nil}
    end
    return result
end

local function world_target(fallback)
    local ok, world_rules = pcall(dofile, "mods/metamorph_creative_menu/files/features/world_rules/service.lua")
    if ok and type(world_rules) == "table" and type(world_rules.gravity_factor) == "function" then
        local read_ok, factor = pcall(world_rules.gravity_factor)
        if read_ok and tonumber(factor) ~= nil then return 350 * tonumber(factor) end
    end
    return fallback
end

function locomotion_guard.capture_if_idle(player_entity_id, active_transaction_count)
    if not valid(player_entity_id) or (tonumber(active_transaction_count) or 0) > 0 then return false end
    if baseline_by_player[player_entity_id] == nil then baseline_by_player[player_entity_id] = capture(player_entity_id) end
    return true
end

function locomotion_guard.repair_if_idle(player_entity_id, active_transaction_count)
    if not valid(player_entity_id) or (tonumber(active_transaction_count) or 0) > 0 then return false, "transactions_active" end
    local baseline = baseline_by_player[player_entity_id]
    if type(baseline) ~= "table" then return false, "no_baseline" end
    local repaired = 0
    for index, component_id in ipairs(EntityGetComponentIncludingDisabled(player_entity_id, "CharacterPlatformingComponent") or {}) do
        local record = baseline[index]
        local fallback = type(record) == "table" and tonumber(record.gravity) or 350
        local target = world_target(fallback or 350)
        local ok, current = pcall(ComponentGetValue2, component_id, "pixel_gravity")
        current = ok and tonumber(current) or nil
        local target_number = tonumber(target)
        if current ~= nil and target_number ~= nil then
            local threshold = math.max(0.01, math.abs(target_number) * 0.02)
            -- A deliberate zero-gravity world rule has target==0 and is preserved.
            if math.abs(target_number) > threshold and math.abs(current) <= threshold then
                pcall(ComponentSetValue2, component_id, "pixel_gravity", target_number)
                repaired = repaired + 1
            end
        end
    end
    baseline_by_player[player_entity_id] = nil
    return true, "idle_gravity_repair:" .. tostring(repaired)
end

function locomotion_guard.rebind_player(old_player_entity_id, new_player_entity_id)
    if tonumber(old_player_entity_id) == tonumber(new_player_entity_id) then return true end
    if baseline_by_player[old_player_entity_id] ~= nil then
        baseline_by_player[new_player_entity_id] = baseline_by_player[old_player_entity_id]
        baseline_by_player[old_player_entity_id] = nil
    end
    return true
end

function locomotion_guard.baseline_count()
    local count = 0
    for _ in pairs(baseline_by_player) do count = count + 1 end
    return count
end

METAMORPH_CREATIVE_MENU_PERK_LOCOMOTION_GUARD = locomotion_guard
return locomotion_guard
