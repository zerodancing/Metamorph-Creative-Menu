-- Runs inside Entangled Worlds' own Lua context as part of the official extra-module
-- bootstrap. Unlike a source rewrite performed during OnModPreInit, this wrapper cannot
-- lose a mod-order race: EW has already created ctx.cap.health, but no world update has
-- run yet.
local form_death_intercept = {}

local ACK_KEY = "mcm_form_death_intercept_ack_v1"
local STATUS_KEY = "mcm_form_death_runtime_intercept_v2"
local COUNT_KEY = "mcm_form_death_runtime_rescues_v2"
local MARKER = "mcm_form_death_runtime_intercept_v2"
local NETWORK_FORM_TAG = "metamorph_creative_menu_network_form"
local POLYMORPH_EFFECT = {
    POLYMORPH=true,
    POLYMORPH_RANDOM=true,
    POLYMORPH_UNSTABLE=true,
    POLYMORPH_CESSATION=true,
}
local installed = false

local function frame_number()
    if type(GameGetFrameNum) ~= "function" then return 0 end
    local ok, value = pcall(GameGetFrameNum)
    return ok and (tonumber(value) or 0) or 0
end

local function publish_status(value)
    if type(GlobalsSetValue) == "function" then pcall(GlobalsSetValue, STATUS_KEY, tostring(value)) end
end

local function ack_matches(entity)
    if type(GlobalsGetValue) ~= "function" then return false end
    local ok, ack = pcall(GlobalsGetValue, ACK_KEY, "")
    if not ok then return false end
    local ack_entity, ack_frame = tostring(ack or ""):match("^(%-?%d+):(%-?%d+)$")
    if tonumber(ack_entity) ~= tonumber(entity) then return false end
    return math.abs(frame_number() - (tonumber(ack_frame) or -100000)) <= 2
end

local function active_player_is_restored_human(old_entity)
    if type(np) ~= "table" or type(np.GetPlayerEntity) ~= "function" then return false end
    local ok, current = pcall(np.GetPlayerEntity)
    current = ok and tonumber(current) or 0
    if current == 0 or current == tonumber(old_entity) then return false end
    if type(EntityGetIsAlive) == "function" then
        local alive_ok, alive = pcall(EntityGetIsAlive, current)
        if not alive_ok or alive ~= true then return false end
    end
    if type(EntityHasTag) == "function" then
        local player_ok, is_player = pcall(EntityHasTag, current, "player_unit")
        local poly_ok, is_poly = pcall(EntityHasTag, current, "polymorphed_player")
        if not player_ok or is_player ~= true or (poly_ok and is_poly == true) then return false end
    end
    return true
end

local function tagged_network_form(entity)
    if entity == nil or tonumber(entity) == 0 or type(EntityHasTag) ~= "function" then return false end
    local ok, tagged = pcall(EntityHasTag, entity, NETWORK_FORM_TAG)
    return ok and tagged == true
end

local function mark_rescued(entity, method)
    local count = 0
    if type(GlobalsGetValue) == "function" then
        local ok, value = pcall(GlobalsGetValue, COUNT_KEY, "0")
        if ok then count = tonumber(value) or 0 end
    end
    if type(GlobalsSetValue) == "function" then
        pcall(GlobalsSetValue, COUNT_KEY, tostring(count + 1))
    end
    local prefix = method == "native" and "rescued_native:" or "rescued:"
    publish_status(prefix .. tostring(tonumber(entity) or 0) .. ":" .. tostring(frame_number()))
end

local function human_candidate(entity)
    entity = tonumber(entity) or 0
    if entity == 0 then return false end
    if type(EntityGetIsAlive) ~= "function" or type(EntityHasTag) ~= "function" then return false end
    local alive_ok, alive = pcall(EntityGetIsAlive, entity)
    local player_ok, is_player = pcall(EntityHasTag, entity, "player_unit")
    local poly_ok, is_poly = pcall(EntityHasTag, entity, "polymorphed_player")
    return alive_ok and alive == true and player_ok and is_player == true
        and (not poly_ok or is_poly ~= true)
end

local function serialized_human_backup(entity)
    if type(EntityGetAllChildren) ~= "function"
        or type(EntityGetFirstComponentIncludingDisabled) ~= "function"
        or type(ComponentGetValue2) ~= "function"
    then
        return nil
    end
    local children_ok, children = pcall(EntityGetAllChildren, entity)
    if not children_ok then return nil end
    for _, child in ipairs(children or {}) do
        local component_ok, component = pcall(EntityGetFirstComponentIncludingDisabled, child, "GameEffectComponent")
        if component_ok and component ~= nil and component ~= 0 then
            local effect_ok, effect = pcall(ComponentGetValue2, component, "effect")
            if effect_ok and POLYMORPH_EFFECT[tostring(effect or "")] then
                local data_ok, encoded = pcall(ComponentGetValue2, component, "mSerializedData")
                if data_ok and type(encoded) == "string" and encoded ~= "" then return encoded end
            end
        end
    end
    return nil
end

local function discard_uncommitted_candidate(entity, old_entity)
    entity = tonumber(entity) or 0
    if entity == 0 or entity == tonumber(old_entity) or type(EntityKill) ~= "function"
        or type(EntityGetIsAlive) ~= "function"
    then
        return
    end
    -- Never delete an entity which SetPlayerEntity may already have committed despite
    -- an incomplete verification API. An uncommitted malformed deserialize is safe to
    -- clean up and must not leak into the world.
    if type(np) == "table" and type(np.GetPlayerEntity) == "function" then
        local current_ok, current = pcall(np.GetPlayerEntity)
        if current_ok and tonumber(current) == entity then return end
    end
    local alive_ok, alive = pcall(EntityGetIsAlive, entity)
    if alive_ok and alive == true then pcall(EntityKill, entity) end
end

local function protect_restored_human(entity)
    if type(EntityGetFirstComponentIncludingDisabled) ~= "function" then return end
    local ok, damage = pcall(EntityGetFirstComponentIncludingDisabled, entity, "DamageModelComponent")
    if not ok or damage == nil or damage == 0 or type(ComponentSetValue2) ~= "function" then return end
    local frames = 0
    if type(ComponentGetValue2) == "function" then
        local frames_ok, value = pcall(ComponentGetValue2, damage, "invincibility_frames")
        if frames_ok then frames = tonumber(value) or 0 end
    end
    pcall(ComponentSetValue2, damage, "invincibility_frames", math.max(frames, 12))
    pcall(ComponentSetValue2, damage, "kill_now", false)
end

-- Last-resort path wholly inside EW's VM. It mirrors EW local_health.end_poly_effect:
-- the native polymorph effect already contains a base64 NoitaPatcher serialization of
-- the original player. Restoring it here avoids relying on CrossCall registrations
-- being shared by two separately bundled NoitaPatcher instances.
local function try_native_restore(entity)
    if not tagged_network_form(entity) then return false end
    if type(np) ~= "table" or type(np.SetPlayerEntity) ~= "function"
        or type(np.GetPlayerEntity) ~= "function"
        or type(util) ~= "table" or type(util.deserialize_entity) ~= "function"
        or type(dofile_once) ~= "function"
    then
        return false
    end
    local encoded = serialized_human_backup(entity)
    if encoded == nil then return false end
    local codec_ok, codec = pcall(dofile_once, "mods/quant.ew/files/resource/base64.lua")
    if not codec_ok or type(codec) ~= "table" or type(codec.decode) ~= "function" then return false end
    local decode_ok, serialized = pcall(codec.decode, encoded)
    if not decode_ok or type(serialized) ~= "string" or serialized == "" then return false end

    local x, y = 0, 0
    if type(EntityGetTransform) == "function" then
        local transform_ok, value_x, value_y = pcall(EntityGetTransform, entity)
        if transform_ok then x, y = tonumber(value_x) or 0, tonumber(value_y) or 0 end
    end
    local restore_ok, restored = pcall(util.deserialize_entity, serialized, x, y)
    restored = restore_ok and (tonumber(restored) or 0) or 0
    if not human_candidate(restored) then
        discard_uncommitted_candidate(restored, entity)
        return false
    end
    local switch_ok = pcall(np.SetPlayerEntity, restored)
    if not switch_ok or not active_player_is_restored_human(entity) then
        discard_uncommitted_candidate(restored, entity)
        return false
    end

    protect_restored_human(restored)
    -- This is intentionally the same cleanup used by EW's own polymorph restoration.
    -- Only kill the old form after the new player pointer has been verified.
    if type(EntityKill) == "function" then pcall(EntityKill, entity) end
    mark_rescued(entity, "native")
    return true
end

local function try_rescue(entity)
    -- The form-side death callback may already have committed the human replacement and
    -- removed the form tag. Accept only a recent entity-scoped ack plus verified live
    -- human player pointer, so a stale value can never swallow an ordinary EW death.
    if ack_matches(entity) and active_player_is_restored_human(entity) then
        mark_rescued(entity, "crosscall")
        return true
    end
    if not tagged_network_form(entity) then return false end
    if type(np) == "table" and type(np.CrossCall) == "function" then
        if type(GlobalsSetValue) == "function" then pcall(GlobalsSetValue, ACK_KEY, "") end
        local ok, err = pcall(np.CrossCall, "metamorph_creative_menu_form_died",
            tonumber(entity) or 0, "ew_health_poly_death", 0, nil, 0)
        if not ok then publish_status("crosscall_failed:" .. tostring(err)) end
        if ok and ack_matches(entity) and active_player_is_restored_human(entity) then
            mark_rescued(entity, "crosscall")
            return true
        end
    end
    return try_native_restore(entity)
end

function form_death_intercept.install()
    if installed then return true, "already_installed" end
    if type(ctx) ~= "table" or type(ctx.cap) ~= "table" or type(ctx.cap.health) ~= "table" then
        publish_status("health_capability_unavailable")
        return false, "health_capability"
    end
    local health = ctx.cap.health
    if health[MARKER] == true then installed = true; return true, "already_installed" end
    local original = health.on_poly_death
    if type(original) ~= "function" then
        publish_status("handler_unavailable")
        return false, "handler"
    end

    health.on_poly_death = function(...)
        local entity = type(ctx.my_player) == "table" and tonumber(ctx.my_player.entity) or 0
        local ok, handled_or_error = pcall(try_rescue, entity)
        if ok and handled_or_error == true then return end
        if not ok then publish_status("intercept_error:" .. tostring(handled_or_error)) end
        -- Fail open: anything not positively acknowledged as an MCM human restore keeps
        -- the exact stock EW notplayer/game-over behavior.
        return original(...)
    end
    health[MARKER] = true
    installed = true
    publish_status("installed")
    return true, "installed"
end

return form_death_intercept
