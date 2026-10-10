if type(METAMORPH_CREATIVE_MENU_WAND_BLUEPRINT_CODEC) == "table" then return METAMORPH_CREATIVE_MENU_WAND_BLUEPRINT_CODEC end

local codec = {}
local CURRENT_HEADER = "MCM_WAND_V2"
local LEGACY_HEADER = "MCM_WAND_V1"

function codec.escape(value)
    return (tostring(value or ""):gsub("([^%w%-%._~])", function(char)
        return string.format("%%%02X", string.byte(char))
    end))
end

function codec.unescape(value)
    return (tostring(value or ""):gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end))
end

local function value_encode(value)
    if type(value) == "boolean" then return value and "b1" or "b0" end
    if type(value) == "number" then return "n" .. string.format("%.17g", value) end
    return "s" .. codec.escape(value)
end

local function value_decode(value)
    value = tostring(value or "")
    local kind, body = string.sub(value, 1, 1), string.sub(value, 2)
    if kind == "b" then
        if body == "1" then return true end
        if body == "0" then return false end
        return nil
    end
    if kind == "n" then return tonumber(body) end
    if kind == "s" then return codec.unescape(body) end
    return nil
end

local function encode_map(lines, prefix, values)
    local ids = {}
    for id, value in pairs(type(values) == "table" and values or {}) do
        if value ~= nil then ids[#ids + 1] = tostring(id) end
    end
    table.sort(ids)
    for _, id in ipairs(ids) do
        lines[#lines + 1] = prefix .. codec.escape(id) .. "=" .. value_encode(values[id])
    end
end

function codec.encode(blueprint)
    blueprint = type(blueprint) == "table" and blueprint or {}
    local lines = {CURRENT_HEADER}
    if blueprint.mana ~= nil then lines[#lines + 1] = "mana=" .. value_encode(blueprint.mana) end
    lines[#lines + 1] = "sprite=" .. value_encode(blueprint.sprite_file or "")
    encode_map(lines, "stat:", blueprint.stats)
    encode_map(lines, "meta:", blueprint.meta)
    for _, spell in ipairs(type(blueprint.spells) == "table" and blueprint.spells or {}) do
        lines[#lines + 1] = table.concat({
            "spell", codec.escape(spell.action_id or ""), tostring(math.floor(tonumber(spell.slot) or -1)),
            spell.permanent == true and "1" or "0",
            spell.uses_remaining == nil and "" or tostring(math.floor(tonumber(spell.uses_remaining) or -1)),
            spell.frozen == true and "1" or "0",
            tostring(math.floor(tonumber(spell.slot_y) or (spell.permanent == true and -1 or 0))),
        }, "\t")
    end
    return table.concat(lines, "\n")
end

local function decode_spell(line)
    local fields = {}
    for token in string.gmatch(line .. "\t", "([^\t]*)\t") do fields[#fields + 1] = token end
    if fields[1] ~= "spell" or fields[2] == nil or fields[2] == "" then return nil end
    local permanent = fields[4] == "1"
    return {
        action_id=codec.unescape(fields[2]),
        slot=tonumber(fields[3]) or -1,
        permanent=permanent,
        uses_remaining=fields[5] ~= "" and tonumber(fields[5]) or nil,
        frozen=fields[6] == "1",
        slot_y=fields[7] ~= nil and fields[7] ~= "" and (tonumber(fields[7]) or 0) or (permanent and -1 or 0),
    }
end

function codec.decode(encoded)
    encoded = tostring(encoded or "")
    local first = string.match(encoded, "^([^\n]*)")
    if first ~= CURRENT_HEADER and first ~= LEGACY_HEADER then return nil, "version" end
    local version = first == CURRENT_HEADER and 2 or 1
    local blueprint = {version=version, stats={}, meta={}, spells={}}
    for line in string.gmatch(encoded .. "\n", "([^\n]*)\n") do
        if line ~= first and line ~= "" then
            local key, value = string.match(line, "^([^=]+)=(.*)$")
            if key == "mana" then
                blueprint.mana = value_decode(value)
            elseif key == "sprite" then
                blueprint.sprite_file = value_decode(value) or ""
            elseif key ~= nil and string.sub(key, 1, 5) == "stat:" then
                blueprint.stats[codec.unescape(string.sub(key, 6))] = value_decode(value)
            elseif key ~= nil and string.sub(key, 1, 5) == "meta:" then
                blueprint.meta[codec.unescape(string.sub(key, 6))] = value_decode(value)
            else
                local spell = decode_spell(line)
                if spell ~= nil then blueprint.spells[#blueprint.spells + 1] = spell end
            end
        end
    end
    return blueprint, "ok"
end

function codec.current_version() return 2 end

METAMORPH_CREATIVE_MENU_WAND_BLUEPRINT_CODEC = codec
return codec
