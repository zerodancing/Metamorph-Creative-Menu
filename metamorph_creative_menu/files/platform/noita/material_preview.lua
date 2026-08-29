if type(METAMORPH_CREATIVE_MENU_MATERIAL_PREVIEW) == "table" then
    return METAMORPH_CREATIVE_MENU_MATERIAL_PREVIEW
end

local preview = {}

local MATERIALS_XML = "data/materials.xml"
local PROBE_ENTITY_PATH = "data/entities/items/pickup/potion_empty.xml"
local POTION_ICON = "data/ui_gfx/items/potion.png"
local PROBE_VERTICAL_OFFSET = -100000
local MATERIAL_AMOUNT = 1000

local definitions = nil
local resolved_texture = {}
local resolved_tint = {}
local liquid_colors = {}

local function valid_entity(entity_id)
    return entity_id ~= nil and entity_id ~= 0 and EntityGetIsAlive(entity_id)
end

local function attribute(text, name)
    return string.match(tostring(text or ""), "%f[%w_]" .. name
        .. '%f[^%w_]%s*=%s*"([^"]*)"')
end

local function decode_argb(value)
    value = tostring(value or "")
    value = string.gsub(value, "^0[xX]", "")
    if #value == 6 then value = "ff" .. value end
    if #value ~= 8 then return nil end
    local alpha = tonumber(string.sub(value, 1, 2), 16)
    local red = tonumber(string.sub(value, 3, 4), 16)
    local green = tonumber(string.sub(value, 5, 6), 16)
    local blue = tonumber(string.sub(value, 7, 8), 16)
    if alpha == nil or red == nil or green == nil or blue == nil then return nil end
    return { red / 255, green / 255, blue / 255, alpha / 255 }
end

local function load_definitions()
    if definitions ~= nil then return definitions end
    definitions = {}
    if type(ModTextFileGetContent) ~= "function" then return definitions end
    local ok, content = pcall(ModTextFileGetContent, MATERIALS_XML)
    if not ok or type(content) ~= "string" or content == "" then return definitions end

    local cursor = 1
    while cursor <= #content do
        local open_start, open_end, tag, attributes = string.find(content,
            "<(CellData[%a]*)%s+([^>]*)>", cursor)
        if open_start == nil then break end
        cursor = open_end + 1
        if tag == "CellData" or tag == "CellDataChild" then
            local body = ""
            if not string.match(attributes, "/%s*$") then
                local close_start, close_end = string.find(content, "</" .. tag .. "%s*>", cursor)
                if close_start ~= nil then
                    body = string.sub(content, cursor, close_start - 1)
                    cursor = close_end + 1
                end
            end
            local name = attribute(attributes, "name")
            if type(name) == "string" and name ~= "" then
                local graphics = string.match(body, "<Graphics%s*([^>]*)>") or ""
                definitions[name] = {
                    parent=attribute(attributes, "_parent"),
                    texture=attribute(graphics, "texture_file"),
                    tint=decode_argb(attribute(graphics, "color")),
                }
            end
        end
    end
    return definitions
end

local function inherited_field(material_id, field, visited)
    local values = load_definitions()
    local definition = values[tostring(material_id or "")]
    if definition == nil then return nil end
    if definition[field] ~= nil then return definition[field] end
    local parent = tostring(definition.parent or "")
    if parent == "" then return nil end
    visited = visited or {}
    if visited[parent] then return nil end
    visited[parent] = true
    return inherited_field(parent, field, visited)
end

local function decode_potion_color(packed_color)
    packed_color = tonumber(packed_color)
    if packed_color == nil then return nil end
    -- GameGetPotionColorUint is encoded as 0xBBGGRR: low byte is red.
    local red = packed_color % 256
    local green = math.floor(packed_color / 256) % 256
    local blue = math.floor(packed_color / 65536) % 256
    return { red / 255, green / 255, blue / 255, 0.96 }
end

local function sample_liquid_color(player_entity_id, material_id)
    if not valid_entity(player_entity_id) or type(material_id) ~= "string" or material_id == "" then return nil end
    local player_x, player_y = EntityGetTransform(player_entity_id)
    if player_x == nil then return nil end
    local probe_entity_id = EntityLoad(PROBE_ENTITY_PATH, player_x,
        (player_y or 0) + PROBE_VERTICAL_OFFSET) or 0
    if probe_entity_id == 0 then return nil end

    local color = nil
    local operation_succeeded = pcall(function()
        RemoveMaterialInventoryMaterial(probe_entity_id)
        AddMaterialInventoryMaterial(probe_entity_id, material_id, MATERIAL_AMOUNT)
        color = decode_potion_color(GameGetPotionColorUint(probe_entity_id))
    end)
    if EntityGetIsAlive(probe_entity_id) then EntityKill(probe_entity_id) end
    if not operation_succeeded then return nil end
    return color
end

function preview.texture(material_id)
    material_id = tostring(material_id or "")
    if resolved_texture[material_id] ~= nil then
        return resolved_texture[material_id] or nil
    end
    local texture = inherited_field(material_id, "texture")
    if type(texture) ~= "string" or texture == "" then texture = false end
    resolved_texture[material_id] = texture
    return texture or nil
end

function preview.tint(material_id)
    material_id = tostring(material_id or "")
    if resolved_tint[material_id] ~= nil then return resolved_tint[material_id] or nil end
    local tint = inherited_field(material_id, "tint") or false
    resolved_tint[material_id] = tint
    return tint or nil
end

function preview.liquid_icon() return POTION_ICON end

function preview.liquid_color(material_id)
    local value = liquid_colors[tostring(material_id or "")]
    return type(value) == "table" and value or nil
end

function preview.sample_liquid_color(player_entity_id, material_id)
    material_id = tostring(material_id or "")
    if liquid_colors[material_id] ~= nil then return preview.liquid_color(material_id) end
    liquid_colors[material_id] = sample_liquid_color(player_entity_id, material_id) or false
    return preview.liquid_color(material_id)
end

function preview.new_liquid_warmup()
    return { cursor=1, count=-1, complete=false }
end

function preview.warm_liquid_colors(player_entity_id, entries, state, budget)
    entries = type(entries) == "table" and entries or {}
    state = type(state) == "table" and state or preview.new_liquid_warmup()
    budget = math.max(1, math.floor(tonumber(budget) or 2))
    if state.count ~= #entries then
        state.cursor, state.count, state.complete = 1, #entries, false
    end
    if state.complete or #entries == 0 then state.complete = true; return true end

    local sampled, scanned = 0, 0
    while sampled < budget and scanned < #entries do
        if state.cursor > #entries then state.cursor = 1 end
        local entry = entries[state.cursor]
        state.cursor = state.cursor + 1
        scanned = scanned + 1
        local material_id = type(entry) == "table" and entry.id or entry
        material_id = tostring(material_id or "")
        if material_id ~= "" and liquid_colors[material_id] == nil then
            preview.sample_liquid_color(player_entity_id, material_id)
            sampled = sampled + 1
        end
    end
    state.complete = true
    for _, entry in ipairs(entries) do
        local material_id = tostring(type(entry) == "table" and entry.id or entry or "")
        if material_id ~= "" and liquid_colors[material_id] == nil then
            state.complete = false
            break
        end
    end
    return state.complete
end

function preview.reset()
    definitions, resolved_texture, resolved_tint, liquid_colors = nil, {}, {}, {}
end

METAMORPH_CREATIVE_MENU_MATERIAL_PREVIEW = preview
return preview
