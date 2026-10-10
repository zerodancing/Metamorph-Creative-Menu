if type(METAMORPH_CREATIVE_MENU_BINDING_CAPTURE) == "table" then
    return METAMORPH_CREATIVE_MENU_BINDING_CAPTURE
end

local binding_capture = {}
local codec = dofile("mods/metamorph_creative_menu/files/core/binding_codec.lua")
local keycodes = dofile("mods/metamorph_creative_menu/files/platform/noita/keycodes.lua")

local MODIFIER_NAMES = {
    LCTRL=true, RCTRL=true, LCONTROL=true, RCONTROL=true,
    LSHIFT=true, RSHIFT=true,
    LALT=true, RALT=true,
}

local MODIFIER_KEYS = {
    CTRL = {
        {"Key_LCTRL", "KEY_LCTRL", "Key_LCONTROL"},
        {"Key_RCTRL", "KEY_RCTRL", "Key_RCONTROL"},
    },
    SHIFT = {
        {"Key_LSHIFT", "KEY_LSHIFT"},
        {"Key_RSHIFT", "KEY_RSHIFT"},
    },
    ALT = {
        {"Key_LALT", "KEY_LALT"},
        {"Key_RALT", "KEY_RALT"},
    },
}

local modifier_codes = nil

local function is_down(code)
    if code == nil or type(InputIsKeyDown) ~= "function" then return false end
    local ok, down = pcall(InputIsKeyDown, code)
    return ok and down == true
end

local function just_down(name)
    if type(InputIsKeyJustDown) ~= "function" then return false end
    local code = keycodes.resolve(name)
    if code == nil then return false end
    local ok, down = pcall(InputIsKeyJustDown, code)
    return ok and down == true
end

local function resolved_modifiers()
    if modifier_codes ~= nil then return modifier_codes end
    modifier_codes = { CTRL={}, SHIFT={}, ALT={} }
    for modifier, alternatives in pairs(MODIFIER_KEYS) do
        local seen = {}
        for _, names in ipairs(alternatives) do
            local code = keycodes.resolve(unpack(names))
            if code ~= nil and not seen[code] then
                seen[code] = true
                modifier_codes[modifier][#modifier_codes[modifier] + 1] = code
            end
        end
    end
    return modifier_codes
end

function binding_capture.is_modifier_name(name)
    local raw = string.upper(string.gsub(tostring(name or ""), "^Key_", ""))
    return MODIFIER_NAMES[raw] == true
end

function binding_capture.current_modifiers()
    local codes = resolved_modifiers()
    local function any(values)
        for _, code in ipairs(values or {}) do if is_down(code) then return true end end
        return false
    end
    return any(codes.CTRL), any(codes.SHIFT), any(codes.ALT)
end

function binding_capture.poll(started_frame, current_frame)
    if (tonumber(current_frame) or 0) <= (tonumber(started_frame) or -1) then return nil end
    if just_down("Key_ESCAPE") then return { kind="cancelled" } end
    if just_down("Key_DELETE") or just_down("Key_BACKSPACE") then
        return { kind="binding", value="NONE" }
    end

    local ctrl, shift, alt = binding_capture.current_modifiers()
    for _, record in ipairs(keycodes.available()) do
        if not binding_capture.is_modifier_name(record.name) then
            local ok, down = pcall(InputIsKeyJustDown, record.code)
            if ok and down == true then
                return { kind="binding", value=codec.compose(record.name, ctrl, shift, alt) }
            end
        end
    end
    if type(InputIsMouseButtonJustDown) == "function" then
        for button = 0, 31 do
            local ok, down = pcall(InputIsMouseButtonJustDown, button)
            if ok and down == true then
                return { kind="binding", value=codec.compose("Mouse:" .. tostring(button), ctrl, shift, alt) }
            end
        end
    end
    return nil
end

function binding_capture.label(value, translate)
    local parsed = codec.parse(value)
    if parsed == nil or parsed.kind == "none" then return "—" end
    translate = type(translate) == "function" and translate or function(_, fallback) return fallback end
    local parts = {}
    for _, modifier in ipairs(codec.modifier_order()) do
        if parsed.modifiers[modifier] then parts[#parts + 1] = modifier end
    end
    if parsed.kind == "mouse" then
        local mouse = translate("$mcm_key_mouse", "MOUSE")
        local middle = translate("$mcm_key_mouse_middle", "MIDDLE")
        parts[#parts + 1] = parsed.mouse_code == 3 and (mouse .. " " .. middle)
            or (mouse .. " " .. tostring(parsed.mouse_code))
    else
        parts[#parts + 1] = keycodes.pretty_name(parsed.base)
    end
    return table.concat(parts, " + ")
end

METAMORPH_CREATIVE_MENU_BINDING_CAPTURE = binding_capture
return binding_capture
