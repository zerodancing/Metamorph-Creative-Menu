if type(METAMORPH_CREATIVE_MENU_ACTION_BINDINGS) == "table" then
    return METAMORPH_CREATIVE_MENU_ACTION_BINDINGS
end

local bindings = {}
local registry = dofile("mods/metamorph_creative_menu/files/core/action_registry.lua")
local codec = dofile("mods/metamorph_creative_menu/files/core/binding_codec.lua")
local keycodes = dofile("mods/metamorph_creative_menu/files/platform/noita/keycodes.lua")
local binding_capture = dofile("mods/metamorph_creative_menu/files/platform/noita/binding_capture.lua")
local input_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/input_guard.lua")
local text_entry_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/text_entry_guard.lua")

local cached = {}
local pressed = {}
local consumed = {}
local consumed_bindings = {}
local updated_frame = -100000
local capture = nil
local last_capture_event = nil
local REFRESH_FRAMES = 30

local function frame_number()
    if type(GameGetFrameNum) ~= "function" then return 0 end
    local ok, value = pcall(GameGetFrameNum)
    return ok and (tonumber(value) or 0) or 0
end

local function setting_value(action)
    local frame = frame_number()
    local record = cached[action.id]
    if record ~= nil and frame < record.refresh_frame then return record.value end
    local value = nil
    if type(ModSettingGet) == "function" then
        local ok, stored = pcall(ModSettingGet, action.setting_id)
        if ok and type(stored) == "string" and stored ~= "" then value = stored end
        if type(action.legacy_setting) == "string" then
            local marker_id = action.setting_id .. "_legacy_migrated_v1"
            local marker_ok, marker = pcall(ModSettingGet, marker_id)
            if not marker_ok or marker ~= true then
                local legacy_ok, legacy = pcall(ModSettingGet, action.legacy_setting)
                if legacy_ok and type(legacy) == "string" and legacy ~= ""
                    and (value == nil or codec.normalize(value, action.default) == codec.normalize(action.default, "NONE"))
                then
                    value = codec.normalize(legacy, action.default)
                    if type(ModSettingSet) == "function" then pcall(ModSettingSet, action.setting_id, value) end
                end
                if type(ModSettingSet) == "function" then pcall(ModSettingSet, marker_id, true) end
            end
        end
    end
    value = codec.normalize(value, action.default)
    cached[action.id] = { value=value, refresh_frame=frame + REFRESH_FRAMES }
    return value
end

local function current_modifiers()
    return binding_capture.current_modifiers()
end

local function modifiers_match(required, actual)
    if actual == nil then
        local ctrl, shift, alt = current_modifiers()
        actual = {CTRL=ctrl,SHIFT=shift,ALT=alt}
    end
    return actual.CTRL == (required.CTRL == true)
        and actual.SHIFT == (required.SHIFT == true)
        and actual.ALT == (required.ALT == true)
end

local function parsed_just_down(parsed, actual_modifiers)
    if parsed == nil or parsed.kind == "none" or not modifiers_match(parsed.modifiers or {}, actual_modifiers) then return false end
    if parsed.kind == "mouse" then
        if type(InputIsMouseButtonJustDown) ~= "function" then return false end
        local ok, down = pcall(InputIsMouseButtonJustDown, parsed.mouse_code)
        return ok and down == true
    end
    if type(InputIsKeyJustDown) ~= "function" then return false end
    local code = keycodes.resolve(parsed.base)
    if code == nil then return false end
    local ok, down = pcall(InputIsKeyJustDown, code)
    return ok and down == true
end

local function parsed_down(parsed)
    if parsed == nil or parsed.kind == "none" or not modifiers_match(parsed.modifiers or {}) then return false end
    if parsed.kind == "mouse" then
        if type(InputIsMouseButtonDown) ~= "function" then return false end
        local ok, down = pcall(InputIsMouseButtonDown, parsed.mouse_code)
        return ok and down == true
    end
    if type(InputIsKeyDown) ~= "function" then return false end
    local code = keycodes.resolve(parsed.base)
    if code == nil then return false end
    local ok, down = pcall(InputIsKeyDown, code)
    return ok and down == true
end

local function finish_capture(kind, value)
    local action_id = capture and capture.action_id or nil
    capture = nil
    if kind == "binding" and action_id ~= nil then bindings.set(action_id, value) end
    last_capture_event = { kind=kind, action_id=action_id, value=value }
end

local function update_capture(frame)
    if capture == nil or frame <= capture.started_frame then return capture ~= nil end
    if not input_guard.actions_allowed() then return true end
    local event = binding_capture.poll(capture.started_frame, frame)
    if event ~= nil then finish_capture(event.kind, event.value) end
    return true
end

function bindings.update()
    local frame = frame_number()
    if frame == updated_frame then return end
    updated_frame, pressed, consumed, consumed_bindings = frame, {}, {}, {}
    -- A physical key used to type into a focused field must never be dispatched again
    -- as a creative-menu/gameplay hotkey on the same frame.
    if text_entry_guard.active() then return end
    if update_capture(frame) then return end
    if not input_guard.actions_allowed() then return end
    local ctrl, shift, alt = current_modifiers()
    local actual_modifiers = {CTRL=ctrl,SHIFT=shift,ALT=alt}
    local binding_edges = {}
    for _, action in ipairs(registry.actions()) do
        local value = setting_value(action)
        local edge = binding_edges[value]
        if edge == nil then
            edge = parsed_just_down(codec.parse(value), actual_modifiers)
            binding_edges[value] = edge
        end
        if edge then pressed[action.id] = true end
    end
end

function bindings.just_pressed(action_id)
    bindings.update()
    action_id = tostring(action_id or "")
    local value = bindings.get(action_id)
    return pressed[action_id] == true and consumed[action_id] ~= true
        and consumed_bindings[value] ~= true
end

function bindings.consume(action_id)
    if not bindings.just_pressed(action_id) then return false end
    action_id = tostring(action_id)
    consumed[action_id] = true
    consumed_bindings[bindings.get(action_id)] = true
    return true
end

function bindings.is_down(action_id)
    if capture ~= nil or text_entry_guard.active() or not input_guard.actions_allowed() then return false end
    local action = registry.get(action_id)
    if action == nil then return false end
    return parsed_down(codec.parse(setting_value(action)))
end

function bindings.get(action_id)
    local action = registry.get(action_id)
    return action and setting_value(action) or "NONE"
end

function bindings.set(action_id, value)
    local action = registry.get(action_id)
    if action == nil then return false, "unknown_action" end
    local parsed, reason = codec.parse(value)
    if parsed == nil then return false, reason end
    local stored = parsed.canonical
    if type(ModSettingSet) == "function" then pcall(ModSettingSet, action.setting_id, stored) end
    if type(ModSettingSetNextValue) == "function" then pcall(ModSettingSetNextValue, action.setting_id, stored, false) end
    cached[action.id] = { value=stored, refresh_frame=frame_number() + REFRESH_FRAMES }
    return true, stored
end

function bindings.reset(action_id)
    local action = registry.get(action_id)
    if action == nil then return false end
    return bindings.set(action.id, action.default)
end

function bindings.reset_all()
    local changed = 0
    for _, action in ipairs(registry.actions()) do
        if bindings.reset(action.id) then changed = changed + 1 end
    end
    return changed
end

function bindings.start_capture(action_id)
    if registry.get(action_id) == nil then return false, "unknown_action" end
    capture = { action_id=tostring(action_id), started_frame=frame_number() }
    last_capture_event = nil
    pressed, consumed, consumed_bindings = {}, {}, {}
    return true
end

function bindings.cancel_capture()
    if capture == nil then return false end
    finish_capture("cancelled")
    return true
end

function bindings.capture_action() return capture and capture.action_id or nil end
function bindings.capture_event()
    local event = last_capture_event
    last_capture_event = nil
    return event
end

local function translated(key, fallback)
    if type(GameTextGetTranslatedOrNot) ~= "function" then return fallback end
    local ok, value = pcall(GameTextGetTranslatedOrNot, key)
    return ok and type(value) == "string" and value ~= "" and value ~= key and value or fallback
end
function bindings.label(action_id)
    return binding_capture.label(bindings.get(action_id), translated)
end

function bindings.conflicts(action_id)
    local value = bindings.get(action_id)
    if value == "NONE" then return {} end
    local result = {}
    for _, other in ipairs(registry.actions()) do
        if other.id ~= action_id and bindings.get(other.id) == value then result[#result + 1] = other end
    end
    return result
end

function bindings.registry() return registry end

METAMORPH_CREATIVE_MENU_ACTION_BINDINGS = bindings
return bindings
