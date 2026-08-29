if type(METAMORPH_CREATIVE_MENU_BINDING_CODEC) == "table" then
    return METAMORPH_CREATIVE_MENU_BINDING_CODEC
end

local codec = {}
local MODIFIER_ORDER = { "CTRL", "SHIFT", "ALT" }
local MODIFIER_SET = { CTRL=true, SHIFT=true, ALT=true }

local function trim(value)
    value = tostring(value or "")
    return (string.gsub(string.gsub(value, "^%s+", ""), "%s+$", ""))
end

function codec.parse(value)
    value = trim(value)
    if value == "" or string.upper(value) == "NONE" then
        return { kind="none", canonical="NONE", modifiers={} }
    end
    local modifiers, base = {}, nil
    for token in string.gmatch(value, "[^+]+") do
        token = trim(token)
        local upper = string.upper(token)
        if MODIFIER_SET[upper] then
            modifiers[upper] = true
        elseif base ~= nil then
            return nil, "multiple_base"
        else
            base = token
        end
    end
    if base == nil or base == "" then return nil, "missing_base" end
    local mouse = string.match(base, "^[Mm][Oo][Uu][Ss][Ee]:(%-?%d+)$")
    local kind, code = "key", nil
    if mouse ~= nil then
        kind, code, base = "mouse", tonumber(mouse), "Mouse:" .. tostring(tonumber(mouse))
        if code == nil or code < 0 or code > 31 then return nil, "mouse_range" end
    elseif not string.match(base, "^Key_[%w_]+$") then
        return nil, "key_name"
    end
    local parts = {}
    for _, modifier in ipairs(MODIFIER_ORDER) do if modifiers[modifier] then parts[#parts + 1] = modifier end end
    parts[#parts + 1] = base
    return { kind=kind, base=base, mouse_code=code, modifiers=modifiers, canonical=table.concat(parts, "+") }
end

function codec.normalize(value, fallback)
    if value == nil or trim(value) == "" then value = fallback end
    local parsed = codec.parse(value)
    if parsed ~= nil then return parsed.canonical end
    parsed = codec.parse(fallback)
    return parsed and parsed.canonical or "NONE"
end

function codec.compose(base, ctrl, shift, alt)
    if type(base) ~= "string" or base == "" then return "NONE" end
    local parts = {}
    if ctrl == true then parts[#parts + 1] = "CTRL" end
    if shift == true then parts[#parts + 1] = "SHIFT" end
    if alt == true then parts[#parts + 1] = "ALT" end
    parts[#parts + 1] = base
    return codec.normalize(table.concat(parts, "+"), "NONE")
end

function codec.modifier_order() return MODIFIER_ORDER end

METAMORPH_CREATIVE_MENU_BINDING_CODEC = codec
return codec
