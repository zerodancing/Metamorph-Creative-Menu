if type(METAMORPH_CREATIVE_MENU_DEATH_RECOVERY_SERVICE) == "table" then
    return METAMORPH_CREATIVE_MENU_DEATH_RECOVERY_SERVICE
end

local death_recovery = {}

local player_locator = dofile("mods/metamorph_creative_menu/files/platform/noita/player_locator.lua")
local bridge_api = dofile("mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua")
local native_gameover = dofile("mods/metamorph_creative_menu/files/platform/noita/native_gameover_patch.lua")
local human_restore = dofile("mods/metamorph_creative_menu/files/features/forms/human_restore.lua")
local post_revive_cleanup = dofile("mods/metamorph_creative_menu/files/features/death_recovery/post_revive_cleanup.lua")
local ew_runtime = dofile("mods/metamorph_creative_menu/files/integrations/ew/runtime.lua")

local INVINCIBILITY_FRAMES = 30 * 60
local BACKUP_INTERVAL_FRAMES = 60
local LOW_HP_INTERVAL_FRAMES = 10

local state = {
    last_snapshot = nil,
    last_snapshot_frame = -1000000,
    last_x = 0,
    last_y = 0,
    last_player = 0,
    pending_entity = 0,
    last_native_error = nil,
    revive_count = 0,
    last_cleanup_reason = nil,
    install_notice = nil,
}

local function ew_active()
    return ew_runtime.enabled() == true
end

local function frame_number()
    if type(GameGetFrameNum) ~= "function" then return 0 end
    local ok, value = pcall(GameGetFrameNum)
    return ok and (tonumber(value) or 0) or 0
end

local function alive(entity)
    if entity == nil or entity == 0 or type(EntityGetIsAlive) ~= "function" then return false end
    local ok, result = pcall(EntityGetIsAlive, entity)
    return ok and result == true
end

local function bridge_with(capability)
    return bridge_api.get({ bootstrap_if_installed=true, capability=capability })
end

local function position_of(entity, fallback_x, fallback_y)
    local x, y = tonumber(fallback_x) or state.last_x, tonumber(fallback_y) or state.last_y
    if entity ~= nil and entity ~= 0 and type(EntityGetTransform) == "function" then
        local ok, value_x, value_y = pcall(EntityGetTransform, entity)
        if ok then x, y = tonumber(value_x) or x, tonumber(value_y) or y end
    end
    return x, y
end

local function damage_component(entity)
    if entity == nil or entity == 0 or type(EntityGetFirstComponentIncludingDisabled) ~= "function" then return 0 end
    local ok, component = pcall(EntityGetFirstComponentIncludingDisabled, entity, "DamageModelComponent")
    return ok and (tonumber(component) or 0) or 0
end

local function snapshot_interval_for(entity)
    local component = damage_component(entity)
    if component == 0 or type(ComponentGetValue2) ~= "function" then return BACKUP_INTERVAL_FRAMES end
    local ok_hp, hp = pcall(ComponentGetValue2, component, "hp")
    local ok_max, max_hp = pcall(ComponentGetValue2, component, "max_hp")
    hp, max_hp = tonumber(hp), tonumber(max_hp)
    if ok_hp and ok_max and hp ~= nil and max_hp ~= nil and max_hp > 0 and hp <= max_hp * 0.25 then
        return LOW_HP_INTERVAL_FRAMES
    end
    return BACKUP_INTERVAL_FRAMES
end

local function serialize_entity(entity)
    local bridge = bridge_with("SerializeEntity")
    if bridge == nil or type(bridge.SerializeEntity) ~= "function" then return nil, "serialize_unavailable" end
    local ok, serialized = pcall(bridge.SerializeEntity, entity)
    if not ok or type(serialized) ~= "string" or serialized == "" then
        return nil, ok and "serialize_empty" or tostring(serialized)
    end
    return serialized
end

local function track_live_player()
    local player = 0
    local ok, value = pcall(player_locator.get_human)
    if ok then player = tonumber(value) or 0 end
    if player == 0 or not alive(player) then return false, "no_human" end

    state.last_player = player
    state.last_x, state.last_y = position_of(player)

    local frame = frame_number()
    if frame - state.last_snapshot_frame < snapshot_interval_for(player) then
        return false, "tracked"
    end

    local serialized, reason = serialize_entity(player)
    if serialized == nil then return false, reason end
    state.last_snapshot = serialized
    state.last_snapshot_frame = frame
    return true, "captured"
end

local function set_full_health_and_protection(entity)
    if entity == nil or entity == 0 then return false end
    local damage = damage_component(entity)
    if damage ~= 0 and type(ComponentGetValue2) == "function" and type(ComponentSetValue2) == "function" then
        local ok_max, max_hp = pcall(ComponentGetValue2, damage, "max_hp")
        max_hp = ok_max and tonumber(max_hp) or nil
        if max_hp == nil or max_hp <= 0 then max_hp = 4 end
        pcall(ComponentSetValue2, damage, "hp", max_hp)
        pcall(ComponentSetValue2, damage, "kill_now", false)
        local ok_frames, frames = pcall(ComponentGetValue2, damage, "invincibility_frames")
        frames = ok_frames and tonumber(frames) or 0
        pcall(ComponentSetValue2, damage, "invincibility_frames", math.max(frames or 0, INVINCIBILITY_FRAMES))
    end
    pcall(human_restore.restore_controls, entity)
    pcall(human_restore.protect_player, entity, INVINCIBILITY_FRAMES)
    return true
end

local function make_authoritative(bridge, entity)
    if bridge == nil or entity == nil or entity == 0 then return false, "bridge_or_entity_missing" end
    if type(bridge.SetPlayerEntity) ~= "function" then return false, "set_player_unavailable" end
    local ok, reason = pcall(bridge.SetPlayerEntity, entity)
    if not ok then return false, tostring(reason) end
    if type(bridge.RegisterPlayerEntityId) == "function" then pcall(bridge.RegisterPlayerEntityId, entity) end
    if type(bridge.GetPlayerEntity) == "function" then
        local read_ok, current = pcall(bridge.GetPlayerEntity)
        if read_ok and tonumber(current) ~= tonumber(entity) then return false, "authority_readback_mismatch" end
    end
    return true
end

local function restore_snapshot_entity(bridge)
    if type(state.last_snapshot) ~= "string" or state.last_snapshot == "" then return 0, "snapshot_missing" end
    if bridge == nil or type(bridge.DeserializeEntity) ~= "function" then return 0, "deserialize_unavailable" end
    if type(EntityCreateNew) ~= "function" then return 0, "entity_create_unavailable" end
    local entity = EntityCreateNew("mcm_death_recovery_player") or 0
    if entity == 0 then return 0, "entity_create_failed" end
    local ok, err = pcall(bridge.DeserializeEntity, entity, state.last_snapshot, state.last_x, state.last_y)
    if not ok then
        if type(EntityKill) == "function" then pcall(EntityKill, entity) end
        return 0, tostring(err)
    end
    if not alive(entity) then
        if type(EntityKill) == "function" then pcall(EntityKill, entity) end
        return 0, "deserialized_entity_dead"
    end
    set_full_health_and_protection(entity)
    return entity, "snapshot"
end

local function restore_fresh_entity()
    if type(EntityLoad) ~= "function" then return 0, "entity_load_unavailable" end
    local ok, entity = pcall(EntityLoad, "data/entities/player.xml", state.last_x, state.last_y)
    entity = ok and (tonumber(entity) or 0) or 0
    if entity == 0 or not alive(entity) then return 0, "fresh_player_failed" end
    set_full_health_and_protection(entity)
    return entity, "fresh"
end

local function find_existing_live_player(bridge)
    if bridge ~= nil and type(bridge.GetPlayerEntity) == "function" then
        local ok, entity = pcall(bridge.GetPlayerEntity)
        entity = ok and (tonumber(entity) or 0) or 0
        if entity ~= 0 and alive(entity) then return entity end
    end
    if type(EntityGetWithTag) == "function" then
        local ok, players = pcall(EntityGetWithTag, "player_unit")
        if ok then
            for _, entity in ipairs(players or {}) do
                if alive(entity) and not (type(EntityHasTag) == "function" and EntityHasTag(entity, "ew_client")) then
                    return entity
                end
            end
        end
    end
    return 0
end

local function acquire_recovery_player(bridge)
    local existing = find_existing_live_player(bridge)
    if existing ~= 0 then
        set_full_health_and_protection(existing)
        return existing, "existing"
    end

    local pending = tonumber(state.pending_entity) or 0
    if pending ~= 0 and alive(pending) then
        set_full_health_and_protection(pending)
        return pending, "pending"
    end

    local entity, source = restore_snapshot_entity(bridge)
    if entity == 0 then entity, source = restore_fresh_entity() end
    if entity ~= 0 then state.pending_entity = entity end
    return entity, source
end

local function handle_revive_request()
    if ew_active() then return false, "disabled_in_entangled_worlds" end
    if not native_gameover.has_revive_request() then return false, "idle" end

    -- This function runs from OnWorldPreUpdate, outside the Game Over button click stack.
    -- The native bridge only raises a request byte; all engine-state recovery stays here.
    -- First restore/attach the player; only then release the engine Game Over state.
    local bridge = bridge_with("SetPlayerEntity")
    if bridge == nil then return false, "patcher_unavailable" end

    local entity, source = acquire_recovery_player(bridge)
    if entity == 0 then
        state.last_native_error = "restore:" .. tostring(source)
        return false, source
    end

    local authoritative, authority_reason = make_authoritative(bridge, entity)
    if not authoritative then
        state.last_native_error = "authority:" .. tostring(authority_reason)
        return false, authority_reason
    end

    local cleared, clear_reason = native_gameover.cancel_game_over_state()
    if not cleared then
        state.last_native_error = "gameover:" .. tostring(clear_reason)
        return false, clear_reason
    end

    local cleanup_ok, cleanup_reason = post_revive_cleanup.apply(entity)
    state.last_cleanup_reason = tostring(cleanup_reason or (cleanup_ok and "post_revive_cleaned" or "unknown"))

    native_gameover.clear_revive_request()
    state.pending_entity = 0
    state.revive_count = state.revive_count + 1
    state.last_player = entity
    state.last_x, state.last_y = position_of(entity)
    state.last_snapshot_frame = -1000000
    return true, source, entity
end

function death_recovery.install()
    if ew_active() then
        state.last_native_error = "disabled_in_entangled_worlds"
        return false, state.last_native_error
    end
    local patched, reason = native_gameover.install()
    if not patched then state.last_native_error = reason end
    return patched, reason
end

local function report_native_install_once(installed, reason)
    local signature = installed and "installed" or tostring(reason or "unknown")
    if state.install_notice == signature then return end
    state.install_notice = signature
    local message = installed
        and "[MCM] native Game Over button patch: installed"
        or "[MCM] native Game Over button patch unavailable: " .. signature
    print(message)
    if type(GamePrint) == "function" then pcall(GamePrint, message) end
end

function death_recovery.update()
    -- Form-death restoration is owned by files/features/forms and remains active in EW.
    -- Only the post-Game-Over "I didn't die" feature is disabled here.
    if ew_active() then
        state.last_native_error = "disabled_in_entangled_worlds"
        return false, state.last_native_error
    end
    if not native_gameover.is_installed() then
        local patched, reason = death_recovery.install()
        if not patched then
            state.last_native_error = reason
            -- During development this is intentionally visible: a missing native button
            -- must never again look indistinguishable from a successfully installed patch.
            report_native_install_once(false, reason)
        else
            report_native_install_once(true, reason)
        end
    elseif state.install_notice == nil then
        report_native_install_once(true, "installed")
    end

    -- Snapshot ownership is independent from native Game Over UI installation. Keeping the
    -- rolling backup alive even when the button patch is temporarily unavailable means a
    -- later successful install never starts with an empty recovery state.
    track_live_player()

    if not native_gameover.is_installed() then
        return false, state.last_native_error or "native_button_unavailable"
    end

    local handled, source, entity = handle_revive_request()
    if handled ~= false or source ~= "idle" then return handled, source, entity end
    return false, "idle"
end

-- Manual/test entry point. It follows the exact same post-UI ordering as the button path;
-- it does not synthesize a death or touch pause-state.
function death_recovery.revive()
    if ew_active() then return false, "disabled_in_entangled_worlds" end
    return handle_revive_request()
end

function death_recovery.pause_update()
    return false, "world_preupdate_owned"
end

function death_recovery.status()
    return {
        snapshot_available = type(state.last_snapshot) == "string" and state.last_snapshot ~= "",
        last_snapshot_frame = state.last_snapshot_frame,
        last_player = state.last_player,
        last_x = state.last_x,
        last_y = state.last_y,
        pending_entity = state.pending_entity,
        native_error = state.last_native_error,
        revive_count = state.revive_count,
        last_cleanup_reason = state.last_cleanup_reason,
        cleanup = post_revive_cleanup.status(),
        native = native_gameover.status(),
        network_disabled = ew_active(),
    }
end

METAMORPH_CREATIVE_MENU_DEATH_RECOVERY_SERVICE = death_recovery
return death_recovery
