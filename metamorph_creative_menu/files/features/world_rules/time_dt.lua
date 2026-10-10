if type(METAMORPH_CREATIVE_MENU_TIME_DT_OWNER) == "table" then return METAMORPH_CREATIVE_MENU_TIME_DT_OWNER end

-- One owner for WorldStateComponent.time_dt.
-- Day Speed uses time_dt as a safe multiplier backend; Weather temporarily freezes the
-- same field while a fixed time-of-day is active. Keeping both features behind this
-- adapter prevents either one from restoring a stale value over the other.
local owner = {}
local rule_math = dofile("mods/metamorph_creative_menu/files/core/rule_math.lua")
local recovery = dofile("mods/metamorph_creative_menu/files/features/world_rules/recovery.lua")

local RECOVERY_SCOPE = "world_time"
local RECOVERY_ID = "time_dt"

local state = {
    baseline = nil,
    last_written = nil,
    day_multiplier = nil,
    weather_frozen = false,
}

local function same(a, b)
    return rule_math.same(tonumber(a), tonumber(b))
end

local function world_component()
    if type(GameGetWorldStateEntity) ~= "function" or type(EntityGetFirstComponentIncludingDisabled) ~= "function" then return nil end
    local world = GameGetWorldStateEntity()
    if world == nil or world == 0 then return nil end
    local comp = EntityGetFirstComponentIncludingDisabled(world, "WorldStateComponent")
    return comp ~= nil and comp ~= 0 and comp or nil
end

local function read(comp)
    comp = comp or world_component()
    if comp == nil or type(ComponentGetValue2) ~= "function" then return false, nil end
    local ok, value = pcall(ComponentGetValue2, comp, "time_dt")
    value = ok and tonumber(value) or nil
    return value ~= nil, value
end

local function write_verified(comp, target)
    if comp == nil or type(ComponentSetValue2) ~= "function" then return false, nil end
    local ok = pcall(ComponentSetValue2, comp, "time_dt", target)
    local read_ok, after = read(comp)
    return ok and read_ok and same(after, target), after
end

local function hydrate_recovery()
    if state.baseline ~= nil then return true end
    local record = recovery.read(RECOVERY_SCOPE, RECOVERY_ID)
    if type(record) ~= "table" then return false end
    local baseline = tonumber(record.original)
    if baseline == nil then return false end
    state.baseline = baseline
    state.last_written = tonumber(record.last)
    return true
end

local function capture(comp)
    if state.baseline ~= nil or hydrate_recovery() then return true end
    local ok, current = read(comp)
    if not ok then return false end
    if not recovery.capture(RECOVERY_SCOPE, RECOVERY_ID, current, "WorldStateComponent.time_dt") then return false end
    state.baseline = current
    state.last_written = nil
    return true
end

local function clear_capture()
    recovery.clear(RECOVERY_SCOPE, RECOVERY_ID)
    state.baseline = nil
    state.last_written = nil
end

local function mark_owned(value)
    state.last_written = value
    recovery.update_last(RECOVERY_SCOPE, RECOVERY_ID, value)
end

local function target_for(day_multiplier, weather_frozen)
    if state.baseline == nil then return nil end
    if weather_frozen == true then return 0 end
    if day_multiplier ~= nil then return state.baseline * day_multiplier end
    return nil
end

local function write_target(comp, target)
    if not capture(comp) then return false, "capture" end
    local ok, before = read(comp)
    if not ok then return false, "read" end
    if same(before, target) then return true, "ok" end
    local wrote, after = write_verified(comp, target)
    if wrote then
        mark_owned(after)
        return true, "ok"
    end
    -- A setter can fail after mutating its backing value. Keep that write owned so a
    -- later RESET/restart can still perform a verified CAS recovery.
    if after ~= nil and not same(after, before) then
        state.last_written = after
        recovery.mark_partial(RECOVERY_SCOPE, RECOVERY_ID, after)
    end
    return false, "write_readback"
end

local function release_if_inactive(comp)
    if state.day_multiplier ~= nil or state.weather_frozen then return true, "active" end
    if state.baseline == nil and not hydrate_recovery() then return true, "ok" end
    if state.last_written == nil then
        clear_capture()
        return true, "ok"
    end
    local ok, current = read(comp)
    if not ok then return false, "read" end
    -- Compare-and-swap: another mod/game wrote after MCM. Its newer value wins.
    if not same(current, state.last_written) then
        clear_capture()
        return true, "external_preserved"
    end
    local wrote, after = write_verified(comp or world_component(), state.baseline)
    if wrote then
        clear_capture()
        return true, "ok"
    end
    state.last_written = after or current
    recovery.mark_partial(RECOVERY_SCOPE, RECOVERY_ID, state.last_written)
    return false, "restore_readback"
end

function owner.supported()
    local comp = world_component()
    if comp == nil then return false end
    local ok = read(comp)
    return ok and type(ComponentSetValue2) == "function"
end

function owner.apply_day_multiplier(multiplier)
    multiplier = tonumber(multiplier)
    if multiplier == nil or multiplier ~= multiplier or math.abs(multiplier) > 100000 then return false, "factor" end
    local comp = world_component()
    if comp == nil then return false, "world" end
    if not capture(comp) then return false, "capture" end
    local target = target_for(multiplier, state.weather_frozen)
    local ok, reason = write_target(comp, target)
    if not ok then return false, reason end
    state.day_multiplier = multiplier
    return true, "ok"
end

function owner.release_day_multiplier()
    local previous = state.day_multiplier
    if previous == nil then return true, "ok" end
    state.day_multiplier = nil
    local ok, reason = release_if_inactive(world_component())
    if not ok then state.day_multiplier = previous end
    return ok, reason
end

function owner.set_weather_frozen(enabled)
    enabled = enabled == true
    if state.weather_frozen == enabled then
        return owner.reassert()
    end
    local comp = world_component()
    if comp == nil then return false, "world" end
    if enabled then
        if not capture(comp) then return false, "capture" end
        local ok, reason = write_target(comp, 0)
        if not ok then return false, reason end
        state.weather_frozen = true
        return true, "ok"
    end

    state.weather_frozen = false
    if state.day_multiplier ~= nil then
        local target = target_for(state.day_multiplier, false)
        local ok, reason = write_target(comp, target)
        if not ok then state.weather_frozen = true end
        return ok, reason
    end
    local ok, reason = release_if_inactive(comp)
    if not ok then state.weather_frozen = true end
    return ok, reason
end

function owner.reassert()
    if state.day_multiplier == nil and not state.weather_frozen then return true, "ok" end
    local comp = world_component()
    if comp == nil then return false, "world" end
    if not capture(comp) then return false, "capture" end
    local target = target_for(state.day_multiplier, state.weather_frozen)
    return write_target(comp, target)
end

function owner.day_multiplier() return state.day_multiplier end
function owner.has_day_override() return state.day_multiplier ~= nil end
function owner.is_weather_frozen() return state.weather_frozen == true end

-- Weather protocol v1 historically transports time_dt itself. New builds send the
-- native baseline rather than baseline*DaySpeed so an older peer, which still applies
-- Day Speed through DESIGN_DAY_CYCLE_SPEED, cannot multiply the same factor twice.
function owner.legacy_sync_value(comp)
    if state.baseline == nil then hydrate_recovery() end
    if state.baseline ~= nil then return state.baseline end
    local ok, current = read(comp)
    return ok and current or nil
end

-- Preserve the old weather-v1 convergence behaviour only while this owner has no active
-- Day Speed/freeze. If MCM currently owns time_dt, its local composed target is authoritative.
function owner.accept_legacy_sync_value(value, comp)
    value = tonumber(value)
    if value == nil then return false end
    if state.day_multiplier ~= nil or state.weather_frozen then return true end
    comp = comp or world_component()
    if comp == nil then return false end
    local ok, current = read(comp)
    if not ok then return false end
    if same(current, value) then return true end
    local wrote = write_verified(comp, value)
    return wrote == true
end

function owner.has_persisted_recovery()
    return recovery.read(RECOVERY_SCOPE, RECOVERY_ID) ~= nil
end

function owner.recover_persisted()
    local record = recovery.read(RECOVERY_SCOPE, RECOVERY_ID)
    if type(record) ~= "table" then return true end
    local comp = world_component()
    if comp == nil then return false end
    local original = tonumber(record.original)
    local last = tonumber(record.last)
    if original == nil then
        recovery.clear(RECOVERY_SCOPE, RECOVERY_ID)
        return true
    end
    if last == nil then
        recovery.clear(RECOVERY_SCOPE, RECOVERY_ID)
        state.baseline, state.last_written = nil, nil
        return true
    end
    local read_ok, current = read(comp)
    if not read_ok then return false end
    -- Same CAS rule on startup: never resurrect an old MCM baseline over a newer write.
    if not same(current, last) then
        recovery.clear(RECOVERY_SCOPE, RECOVERY_ID)
        state.baseline, state.last_written = nil, nil
        return true
    end
    local wrote, after = write_verified(comp, original)
    if not wrote then
        recovery.mark_partial(RECOVERY_SCOPE, RECOVERY_ID, after or current)
        state.baseline = original
        state.last_written = after or current
        return false
    end
    recovery.clear(RECOVERY_SCOPE, RECOVERY_ID)
    state.baseline, state.last_written = nil, nil
    state.day_multiplier = nil
    state.weather_frozen = false
    return true
end

function owner.debug_state()
    return {
        baseline=state.baseline,
        last_written=state.last_written,
        day_multiplier=state.day_multiplier,
        weather_frozen=state.weather_frozen,
    }
end

METAMORPH_CREATIVE_MENU_TIME_DT_OWNER = owner
return owner
