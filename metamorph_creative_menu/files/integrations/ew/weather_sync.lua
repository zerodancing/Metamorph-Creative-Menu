local sync = {}
local ew_runtime = dofile("mods/metamorph_creative_menu/files/integrations/ew/runtime.lua")

local OUTBOX_SEQUENCE_KEY = "mcm_weather_outbox_seq_v1"
local OUTBOX_VERSION_KEY = "mcm_weather_outbox_version_v1"
local OUTBOX_SNAPSHOT_KEY = "mcm_weather_outbox_snapshot_v1"
local REMOTE_SEQUENCE_KEY = "mcm_weather_remote_seq_v1"
local REMOTE_VERSION_KEY = "mcm_weather_remote_version_v1"
local REMOTE_SNAPSHOT_KEY = "mcm_weather_remote_snapshot_v1"
local SYNC_FIELDS = { "rain", "rain_target", "fog", "fog_target", "wind", "wind_speed" }

-- Initialized lazily after WorldState exists; top-level GlobalsGetValue is an engine
-- error during mod startup and used to poison crash-recovery logs.
local outbox_sequence = 0
local last_remote_sequence = ""
local last_publish_frame = -100000

local function finite_number(value)
    return type(value) == "number" and value == value and math.abs(value) < 100000000
end

local function encode_number(value)
    value = tonumber(value)
    return finite_number(value) and string.format("%.17g", value) or "~"
end

local function encode_state(state, world_component)
    local parts = {
        state.active and "1" or "0",
        encode_number(state.time),
        encode_number(state.rainfall),
        encode_number(state.lightning),
    }
    for _, field_name in ipairs(SYNC_FIELDS) do
        parts[#parts + 1] = encode_number(state.values[field_name])
    end

    local time_delta = nil
    local component = world_component()
    if component ~= nil then
        local read_succeeded, value = pcall(ComponentGetValue2, component, "time_dt")
        if read_succeeded then time_delta = tonumber(value) end
    end
    parts[#parts + 1] = encode_number(time_delta)
    return table.concat(parts, "|")
end

local function decode_state(encoded)
    if type(encoded) ~= "string" or encoded == "" then return nil end
    local parts = {}
    for value in string.gmatch(encoded .. "|", "([^|]*)|") do parts[#parts + 1] = value end
    if #parts ~= 11 or (parts[1] ~= "0" and parts[1] ~= "1") then return nil end

    local function number_at(index)
        if parts[index] == "~" or parts[index] == "" then return nil end
        local value = tonumber(parts[index])
        return finite_number(value) and value or nil
    end

    local state = {
        active = parts[1] == "1",
        time = number_at(2),
        rainfall = number_at(3) or 0,
        lightning = number_at(4) or 0,
        values = {},
        time_dt = number_at(11),
    }
    for index, field_name in ipairs(SYNC_FIELDS) do
        local value = number_at(4 + index)
        if value ~= nil then state.values[field_name] = value end
    end
    return state
end

function sync.enabled()
    return ew_runtime.enabled()
end

function sync.can_edit()
    local mode = ew_runtime.mode()
    if mode == "off" then return true, "singleplayer" end
    if mode == "host" then return true, "ew_host" end
    return true, "ew_peer"
end

function sync.publish(state, world_component, force)
    if not sync.enabled() then return end
    local frame = type(GameGetFrameNum) == "function" and GameGetFrameNum() or 0
    if not force and frame - last_publish_frame < 120 then return end
    last_publish_frame = frame
    outbox_sequence = math.max(outbox_sequence, tonumber(GlobalsGetValue(OUTBOX_SEQUENCE_KEY, "0")) or 0) + 1
    GlobalsSetValue(OUTBOX_VERSION_KEY, "1")
    GlobalsSetValue(OUTBOX_SNAPSHOT_KEY, encode_state(state, world_component))
    -- Sequence is written last so the EW bridge cannot observe a half-published state.
    GlobalsSetValue(OUTBOX_SEQUENCE_KEY, tostring(outbox_sequence))
end

function sync.consume(state, world_component, clear_state)
    if not sync.enabled() then return false end
    local sequence = GlobalsGetValue(REMOTE_SEQUENCE_KEY, "")
    if sequence == "" or sequence == last_remote_sequence then return false end
    last_remote_sequence = sequence
    if tonumber(GlobalsGetValue(REMOTE_VERSION_KEY, "0")) ~= 1 then return false end

    local remote_state = decode_state(GlobalsGetValue(REMOTE_SNAPSHOT_KEY, ""))
    if remote_state == nil then return false end
    local component = world_component()
    if not remote_state.active then
        clear_state()
        if component ~= nil and remote_state.time_dt ~= nil then
            pcall(ComponentSetValue2, component, "time_dt", remote_state.time_dt)
        end
        return true
    end

    if state.active ~= true and state.original_time_dt == nil and component ~= nil then
        local read_ok, current_time_dt = pcall(ComponentGetValue2, component, "time_dt")
        if read_ok then state.original_time_dt = tonumber(current_time_dt) end
    end
    state.active = true
    -- User rights are symmetric. The host is only the technical periodic rebroadcast
    -- point required by EW so late joiners receive the latest complete snapshot.
    state.remote = not GameHasFlagRun("ew_flag_this_is_host")
    state.time = remote_state.time
    state.values = remote_state.values
    state.rainfall = remote_state.rainfall
    state.lightning = remote_state.lightning
    state.next_lightning_frame = 0
    state.lightning_clear_frame = 0
    if component ~= nil and remote_state.time_dt ~= nil and state.time == nil then
        pcall(ComponentSetValue2, component, "time_dt", remote_state.time_dt)
    end
    return true
end

return sync
