dofile("data/scripts/lib/mod_settings.lua")
pcall(dofile, "data/scripts/debug/keycodes.lua")

local mod_id = "metamorph_creative_menu"
mod_settings_version = 2

local capture_setting_id = nil
local capture_started_frame = -1
local key_records = nil
local mouse_labels = nil

local function frame_num()
    local ok, frame = pcall(GameGetFrameNum)
    return ok and (tonumber(frame) or 0) or 0
end

local PRETTY_KEYS = {
    RETURN = "ENTER", ESCAPE = "ESC", BACKSPACE = "BACKSPACE", SPACE = "SPACE",
    TAB = "TAB", DELETE = "DELETE", INSERT = "INSERT", HOME = "HOME", END = "END",
    PAGEUP = "PAGE UP", PAGEDOWN = "PAGE DOWN", LEFT = "LEFT", RIGHT = "RIGHT",
    UP = "UP", DOWN = "DOWN", LSHIFT = "LEFT SHIFT", RSHIFT = "RIGHT SHIFT",
    LCTRL = "LEFT CTRL", RCTRL = "RIGHT CTRL", LALT = "LEFT ALT", RALT = "RIGHT ALT",
    CAPSLOCK = "CAPS LOCK", NUMLOCKCLEAR = "NUM LOCK", PRINTSCREEN = "PRINT SCREEN",
    SCROLLLOCK = "SCROLL LOCK", PAUSE = "PAUSE",
}

local function translated(value, fallback)
    local text = GameTextGetTranslatedOrNot(value)
    if type(text) ~= "string" or text == "" or text == value then return fallback or value end
    return text
end

local function pretty_key(name)
    local raw = string.gsub(tostring(name or ""), "^Key_", "")
    if PRETTY_KEYS[raw] ~= nil then return PRETTY_KEYS[raw] end
    if string.match(raw, "^[a-z]$") then return string.upper(raw) end
    if string.match(raw, "^%d$") then return raw end
    if string.match(raw, "^F%d+$") then return raw end
    raw = string.gsub(raw, "^KP_", "NUM ")
    raw = string.gsub(raw, "_", " ")
    return string.upper(raw)
end

local function collect_keys()
    if key_records ~= nil then return key_records end
    local by_code = {}
    for name, value in pairs(_G) do
        if type(name) == "string" and string.match(name, "^Key_") and type(value) == "number" then
            -- TAB is the menu/return lifecycle key and cannot safely mean possession too.
            if name ~= "Key_TAB" then
                local current = by_code[value]
                if current == nil or #name < #current then by_code[value] = name end
            end
        end
    end
    local result = {}
    for code, name in pairs(by_code) do
        result[#result + 1] = { code=code, name=name, label=pretty_key(name) }
    end
    table.sort(result, function(a, b)
        if a.code == b.code then return a.name < b.name end
        return a.code < b.code
    end)
    key_records = result
    return result
end

local function collect_mouse_labels()
    if mouse_labels ~= nil then return mouse_labels end
    local result = {}
    -- Different Noita builds expose slightly different symbolic names. We don't depend
    -- on them for capture: the raw numeric button id is what InputIsMouseButtonJustDown
    -- actually consumes. Symbols are used only to make the settings label nicer.
    for name, value in pairs(_G) do
        if type(name) == "string" and type(value) == "number"
            and (string.match(name, "^[Mm]ouse_") or string.match(name, "^MOUSE_"))
        then
            local label = string.gsub(name, "^[Mm][Oo][Uu][Ss][Ee]_", "")
            label = string.gsub(label, "_", " ")
            result[value] = "MOUSE " .. string.upper(label)
        end
    end
    mouse_labels = result
    return result
end

local function pretty_binding(value)
    value = tostring(value or "")
    local code = string.match(value, "^Mouse:(%-?%d+)$")
    if code ~= nil then
        code = tonumber(code)
        local names = collect_mouse_labels()
        return names[code] or ("MOUSE BUTTON " .. tostring(code))
    end
    return pretty_key(value)
end

local function keybind_ui(mod_id_value, gui, in_main_menu, im_id, setting)
    local id = mod_setting_get_id(mod_id_value, setting)
    local value = ModSettingGetNextValue(id)
    if type(value) ~= "string" or value == "" then value = setting.value_default end
    local waiting = capture_setting_id == id
    local title = translated(setting.ui_name, "Possession key")
    local label = waiting
        and translated("$mcm_setting_key_waiting", "PRESS A KEY OR MOUSE BUTTON...")
        or pretty_binding(value)

    if GuiButton(gui, im_id, mod_setting_group_x_offset, 0, title .. ": " .. label) then
        if waiting then
            capture_setting_id = nil
            capture_started_frame = -1
        else
            capture_setting_id = id
            capture_started_frame = frame_num()
        end
        waiting = capture_setting_id == id
    end
    mod_setting_tooltip(mod_id_value, gui, in_main_menu, setting)

    if not waiting then return end
    -- Don't capture the click that opened capture mode itself.
    local frame = frame_num()
    if frame <= capture_started_frame then return end

    for _, record in ipairs(collect_keys()) do
        local ok, pressed = pcall(InputIsKeyJustDown, record.code)
        if ok and pressed == true then
            ModSettingSetNextValue(id, record.name, false)
            capture_setting_id = nil
            capture_started_frame = -1
            return
        end
    end

    -- Raw probing means X1/X2 and other additional mouse buttons work even if keycodes.lua
    -- has no human-readable symbol for them. 0..31 comfortably covers normal mouse devices.
    for button = 0, 31 do
        local ok, pressed = pcall(InputIsMouseButtonJustDown, button)
        if ok and pressed == true then
            ModSettingSetNextValue(id, "Mouse:" .. tostring(button), false)
            capture_setting_id = nil
            capture_started_frame = -1
            return
        end
    end
end

mod_settings = {
    {
        id = "possession_key",
        ui_name = "$mcm_setting_possession_key",
        ui_description = "$mcm_setting_possession_key_desc",
        value_default = "Key_g",
        scope = MOD_SETTING_SCOPE_RUNTIME,
        ui_fn = keybind_ui,
    },
}

function ModSettingsUpdate(init_scope)
    mod_settings_update(mod_id, mod_settings, init_scope)
end

function ModSettingsGuiCount()
    return mod_settings_gui_count(mod_id, mod_settings)
end

function ModSettingsGui(gui, in_main_menu)
    mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end
