if type(METAMORPH_CREATIVE_MENU_NOITA_KEYCODES) == "table" then return METAMORPH_CREATIVE_MENU_NOITA_KEYCODES end

local keycodes = {}
local KEYCODE_SOURCE = "data/scripts/debug/keycodes.lua"
local parsed_codes_by_name = nil
local globals_load_attempted = false

-- Noita's executed keycodes.lua is the authoritative source because InputIsKeyJustDown
-- consumes those runtime key values. Parsing the source text is only a fallback for
-- isolated tests/runtimes where dofile_once is unavailable.
local function ensure_noita_globals()
    if globals_load_attempted then return end
    globals_load_attempted = true
    if type(dofile_once) == "function" then
        pcall(dofile_once, KEYCODE_SOURCE)
    end
end

local function parse_numeric_literal(raw_value)
    local decimal_value = tonumber(raw_value)
    if decimal_value ~= nil then return decimal_value end
    local hexadecimal_digits = string.match(tostring(raw_value or ""), "^0[xX]([0-9a-fA-F]+)$")
    if hexadecimal_digits ~= nil then return tonumber(hexadecimal_digits, 16) end
    return nil
end

local function load_parsed_codes()
    if parsed_codes_by_name ~= nil then return parsed_codes_by_name end
    parsed_codes_by_name = {}

    if type(ModTextFileGetContent) ~= "function" then return parsed_codes_by_name end
    local read_succeeded, source = pcall(ModTextFileGetContent, KEYCODE_SOURCE)
    if not read_succeeded or type(source) ~= "string" then return parsed_codes_by_name end

    for key_name, raw_value in string.gmatch(source, "([%w_]+)%s*=%s*([%-%w]+)") do
        local key_code = parse_numeric_literal(raw_value)
        if key_code ~= nil then parsed_codes_by_name[key_name] = key_code end
    end
    return parsed_codes_by_name
end

local function global_keycode(key_name)
    ensure_noita_globals()
    if type(key_name) ~= "string" or key_name == "" then return nil end
    local value = rawget(_G, key_name)
    return tonumber(value)
end

function keycodes.resolve(...)
    for index = 1, select("#", ...) do
        local key_name = select(index, ...)
        local key_code = global_keycode(key_name)
        if key_code ~= nil then return key_code end
    end

    local parsed_codes = load_parsed_codes()
    for index = 1, select("#", ...) do
        local key_name = select(index, ...)
        if type(key_name) == "string" and parsed_codes[key_name] ~= nil then return parsed_codes[key_name] end
    end
    return nil
end

function keycodes.resolve_binding(binding_name, fallback_name)
    local requested_name = type(binding_name) == "string" and binding_name or ""
    local requested_code = requested_name ~= "" and keycodes.resolve(requested_name) or nil
    if requested_code ~= nil then return requested_code, requested_name end

    local fallback_code = type(fallback_name) == "string" and keycodes.resolve(fallback_name) or nil
    return fallback_code, fallback_name
end

function keycodes.matching_name_fragment(fragment)
    fragment = string.upper(tostring(fragment or ""))
    if fragment == "" then return {} end

    ensure_noita_globals()
    local matching_codes = {}
    local seen_codes = {}

    -- Prefer the actual globals Noita loaded. Only Key_* entries are relevant here.
    for key_name, raw_value in pairs(_G) do
        if type(key_name) == "string" and string.sub(key_name, 1, 4) == "Key_"
            and string.find(string.upper(key_name), fragment, 1, true) ~= nil
        then
            local key_code = tonumber(raw_value)
            if key_code ~= nil and not seen_codes[key_code] then
                seen_codes[key_code] = true
                matching_codes[#matching_codes + 1] = key_code
            end
        end
    end

    if #matching_codes == 0 then
        for key_name, key_code in pairs(load_parsed_codes()) do
            if string.find(string.upper(key_name), fragment, 1, true) ~= nil and not seen_codes[key_code] then
                seen_codes[key_code] = true
                matching_codes[#matching_codes + 1] = key_code
            end
        end
    end

    table.sort(matching_codes)
    return matching_codes
end

METAMORPH_CREATIVE_MENU_NOITA_KEYCODES = keycodes
return keycodes
