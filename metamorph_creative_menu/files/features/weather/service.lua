local existing_weather_service = METAMORPH_CREATIVE_MENU_WEATHER_SERVICE or METAMORPH_CREATIVE_MENU_WEATHER_EDITOR
if type(existing_weather_service) == "table" then return existing_weather_service end

local weather_service = {}
local definitions = dofile("mods/metamorph_creative_menu/files/features/weather/definitions.lua")
local weather_sync = dofile("mods/metamorph_creative_menu/files/integrations/ew/weather_sync.lua")
local runtime_effects = dofile("mods/metamorph_creative_menu/files/features/weather/runtime_effects.lua")

local state = {
    active = false,
    time = nil,
    values = {},
    rainfall = 0,
    lightning = 0,
    next_lightning_frame = 0,
    lightning_clear_frame = 0,
    last_rain_emit_frame = -1,
    rain_emitted_total = 0,
    rain_stop_guard_until = 0,
    last_lightning_update_frame = -1,
    last_full_update_frame = -1,
    original_time_dt = nil,
    remote = false,
}

local function world_component()
    local world_entity = GameGetWorldStateEntity()
    if world_entity == nil or world_entity == 0 then return nil end
    local component = EntityGetFirstComponentIncludingDisabled(world_entity, "WorldStateComponent")
    return component ~= nil and component ~= 0 and component or nil
end

local function clear_state()
    state.active = false
    state.remote = false
    state.time = nil
    state.values = {}
    state.rainfall = 0
    state.lightning = 0
    state.next_lightning_frame = 0
    state.lightning_clear_frame = 0
    state.last_rain_emit_frame = -1
    state.rain_stop_guard_until = 0
    state.last_lightning_update_frame = -1
    state.last_full_update_frame = -1
    state.original_time_dt = nil
end

local function write_value(component, field_name, value)
    pcall(ComponentSetValue2, component, field_name, value)
end

local function values_equal(left, right)
    local a, b = tonumber(left), tonumber(right)
    if a ~= nil and b ~= nil then return math.abs(a - b) < 0.000001 end
    return left == right or tostring(left) == tostring(right)
end

local function read_value(component, field_name)
    local ok, value = pcall(ComponentGetValue2, component, field_name)
    return ok, value
end

local function write_value_verified(component, field_name, value)
    local wrote = pcall(ComponentSetValue2, component, field_name, value)
    local read_ok, after = read_value(component, field_name)
    return wrote and read_ok and values_equal(after, value), after
end

local function write_assignments_verified(component, assignments)
    local plan = {}
    for _, assignment in ipairs(assignments or {}) do
        local ok, before = read_value(component, assignment.field)
        if not ok then return false, "read:" .. tostring(assignment.field) end
        plan[#plan + 1] = {field=assignment.field, value=assignment.value, before=before}
    end
    local changed = {}
    for _, assignment in ipairs(plan) do
        if not values_equal(assignment.before, assignment.value) then
            local ok = write_value_verified(component, assignment.field, assignment.value)
            if not ok then
                local rollback_ok = true
                for index = #changed, 1, -1 do
                    local prior = changed[index]
                    if not write_value_verified(component, prior.field, prior.before) then rollback_ok = false end
                end
                return false, rollback_ok and ("write:" .. tostring(assignment.field)) or ("partial_rollback:" .. tostring(assignment.field))
            end
            changed[#changed + 1] = assignment
        end
    end
    return true, "ok"
end

local function begin_override(component)
    if not state.active and state.original_time_dt == nil then
        local ok, value = read_value(component, "time_dt")
        if ok then state.original_time_dt = tonumber(value) end
    end
    state.active = true
    state.remote = false
    pcall(ComponentSetValue2, component, "intro_weather", false)
end

local function clamp_field(field, value)
    value = tonumber(value)
    if value == nil then return nil end
    if field.wrap == true and field.min ~= nil and field.max ~= nil then
        local span = field.max - field.min
        if span > 0 then value = field.min + ((value - field.min) % span) end
    else
        if field.min ~= nil then value = math.max(field.min, value) end
        if field.max ~= nil then value = math.min(field.max, value) end
    end
    if field.integer then value = math.floor(value + 0.5) end
    return value
end

function weather_service.ew_enabled() return weather_sync.enabled() end
function weather_service.can_edit() return weather_sync.can_edit() end

function weather_service.fields() return definitions.fields end
function weather_service.time_presets() return definitions.time_presets end
function weather_service.weather_presets() return definitions.weather_presets end

function weather_service.get(field)
    if type(field) ~= "table" then return nil end
    if field.id == "rainfall" then return state.rainfall or 0 end
    if field.id == "lightning" then return state.lightning or 0 end
    local component = world_component()
    if component == nil then return nil end
    local read_succeeded, value = pcall(ComponentGetValue2, component, field.field)
    if not read_succeeded then return nil end
    return tonumber(value) or value
end

function weather_service.get_time()
    local component = world_component()
    return component ~= nil and tonumber(ComponentGetValue2(component, "time")) or nil
end

function weather_service.set_time_preset(preset_name)
    local allowed = weather_service.can_edit()
    if not allowed then return false, "edit_denied" end
    local value = definitions.time_presets[preset_name]
    if value == nil then return false, "preset" end
    local component = world_component()
    if component == nil then return false, "world" end
    local was_active = state.active == true
    begin_override(component)
    local wrote, reason = write_assignments_verified(component, {
        {field="time", value=value}, {field="time_dt", value=0},
    })
    if not wrote then
        if not was_active then clear_state() end
        return false, reason
    end
    state.time = value
    weather_sync.publish(state, world_component, true)
    return true, "ok"
end

function weather_service.set(field, value)
    local allowed = weather_service.can_edit()
    if not allowed then return false, "edit_denied" end
    if type(field) ~= "table" then return false, "field" end
    value = clamp_field(field, value)
    if value == nil then return false, "value" end
    local component = world_component()
    if component == nil then return false, "world" end
    local was_active = state.active == true
    begin_override(component)

    local assignments = {}
    if field.id == "lightning" and value <= 0 then
        assignments[#assignments + 1] = {field="lightning_count", value=0}
    elseif field.field == "time" then
        assignments[#assignments + 1] = {field="time", value=value}
        assignments[#assignments + 1] = {field="time_dt", value=0}
    elseif field.id ~= "rainfall" and field.id ~= "lightning" then
        assignments[#assignments + 1] = {field=field.field, value=value}
        if type(field.target) == "string" and field.target ~= "" then
            assignments[#assignments + 1] = {field=field.target, value=value}
        end
    end
    local wrote, reason = write_assignments_verified(component, assignments)
    if not wrote then
        if not was_active then clear_state() end
        return false, reason
    end

    if field.id == "rainfall" then
        state.rainfall = value
        state.rain_stop_guard_until = value <= 0 and ((tonumber(GameGetFrameNum()) or 0) + 90) or 0
    elseif field.id == "lightning" then
        state.lightning = value
        if value <= 0 then
            state.next_lightning_frame = 0
            state.lightning_clear_frame = 0
        end
    elseif field.field == "time" then
        state.time = value
    else
        state.values[field.field] = value
        if type(field.target) == "string" and field.target ~= "" then state.values[field.target] = value end
    end
    weather_sync.publish(state, world_component, true)
    return true, "ok"
end

function weather_service.apply_preset(preset_name)
    local allowed = weather_service.can_edit()
    if not allowed then return false, "edit_denied" end
    local values = definitions.weather_presets[preset_name]
    if values == nil then return false, "preset" end
    local component = world_component()
    if component == nil then return false, "world" end
    local was_active = state.active == true
    begin_override(component)

    local assignments = {}
    for field_name, value in pairs(values) do
        if field_name ~= "rainfall" and field_name ~= "lightning" then
            assignments[#assignments + 1] = {field=field_name, value=value}
        end
    end
    local lightning = tonumber(values.lightning) or 0
    if lightning <= 0 then assignments[#assignments + 1] = {field="lightning_count", value=0} end
    local wrote, reason = write_assignments_verified(component, assignments)
    if not wrote then
        if not was_active then clear_state() end
        return false, reason
    end

    state.values = {}
    state.rainfall = tonumber(values.rainfall) or 0
    state.lightning = lightning
    state.next_lightning_frame = 0
    state.lightning_clear_frame = 0
    state.rain_stop_guard_until = state.rainfall <= 0 and ((tonumber(GameGetFrameNum()) or 0) + 90) or 0
    for field_name, value in pairs(values) do
        if field_name ~= "rainfall" and field_name ~= "lightning" then state.values[field_name] = value end
    end
    weather_sync.publish(state, world_component, true)
    return true, "ok"
end

function weather_service.release()
    local allowed = weather_service.can_edit()
    if not allowed then return false, "edit_denied" end
    local component = world_component()
    if component == nil then return false, "world" end
    if state.original_time_dt ~= nil then
        local restored, reason = write_assignments_verified(component, {{field="time_dt", value=state.original_time_dt}})
        if not restored then return false, reason end
    end
    clear_state()
    weather_sync.publish(state, world_component, true)
    return true, "ok"
end

function weather_service.is_locked() return state.active == true end

function weather_service.update()
    local frame = tonumber(GameGetFrameNum()) or 0
    local first_update_this_frame = state.last_full_update_frame ~= frame
    if first_update_this_frame then
        state.last_full_update_frame = frame
        weather_sync.consume(state, world_component, clear_state)
        -- A consumed RELEASE resets the state table, including the frame marker.
        state.last_full_update_frame = frame
    end
    if not state.active then return end
    local allowed = weather_service.can_edit()
    if not allowed and not state.remote then
        clear_state()
        return
    end

    local component = world_component()
    if component == nil then return end
    pcall(ComponentSetValue2, component, "intro_weather", false)
    if state.time ~= nil then
        write_value(component, "time", state.time)
        write_value(component, "time_dt", 0)
    end
    for field_name, value in pairs(state.values) do write_value(component, field_name, value) end

    if (tonumber(state.rain_stop_guard_until) or 0) >= frame and (tonumber(state.rainfall) or 0) <= 0 then
        write_value(component, "rain", 0)
        write_value(component, "rain_target", 0)
    end
    -- init.lua calls update both before and after the engine tick: world fields must be
    -- reasserted twice, but network mailbox work and particle/lightning simulation only
    -- belong to the first call of a frame.
    if first_update_this_frame then
        runtime_effects.emit_rain(state)
        runtime_effects.update_lightning(state, component, write_value)
        if not state.remote then weather_sync.publish(state, world_component, false) end
    end
end

function weather_service.debug_state()
    local component = world_component()
    local result = {
        active = state.active == true,
        rainfall = tonumber(state.rainfall) or 0,
        lightning = tonumber(state.lightning) or 0,
        last_rain_emit_frame = tonumber(state.last_rain_emit_frame) or -1,
        rain_emitted_total = tonumber(state.rain_emitted_total) or 0,
        rain_stop_guard_until = tonumber(state.rain_stop_guard_until) or 0,
    }
    if component ~= nil then
        for _, field_name in ipairs({ "rain", "rain_target", "fog", "fog_target", "wind", "wind_speed" }) do
            local read_succeeded, value = pcall(ComponentGetValue2, component, field_name)
            if read_succeeded then result[field_name] = tonumber(value) or value end
        end
    end
    return result
end

METAMORPH_CREATIVE_MENU_WEATHER_SERVICE = weather_service
-- Legacy singleton alias kept for compatibility with older callers.
METAMORPH_CREATIVE_MENU_WEATHER_EDITOR = weather_service
return weather_service
