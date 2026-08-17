if type(METAMORPH_CREATIVE_MENU_LIQUID_PREVIEW) == "table" then return METAMORPH_CREATIVE_MENU_LIQUID_PREVIEW end

local liquid_preview = {}

local PROBE_ENTITY_PATH = "data/entities/items/pickup/potion_empty.xml"
local PROBE_VERTICAL_OFFSET = -100000
local MATERIAL_AMOUNT = 1000

local function valid_entity(entity_id)
    return entity_id ~= nil and entity_id ~= 0 and EntityGetIsAlive(entity_id)
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

function liquid_preview.sample_color(player_entity_id, material_id)
    if not valid_entity(player_entity_id) or type(material_id) ~= "string" or material_id == "" then return nil end

    local player_x, player_y = EntityGetTransform(player_entity_id)
    if player_x == nil then return nil end

    local probe_entity_id = EntityLoad(PROBE_ENTITY_PATH, player_x, (player_y or 0) + PROBE_VERTICAL_OFFSET) or 0
    if probe_entity_id == 0 then return nil end

    local color = nil
    local operation_succeeded = pcall(function()
        RemoveMaterialInventoryMaterial(probe_entity_id)
        AddMaterialInventoryMaterial(probe_entity_id, material_id, MATERIAL_AMOUNT)
        local packed_color = GameGetPotionColorUint(probe_entity_id)
        color = decode_potion_color(packed_color)
    end)

    if EntityGetIsAlive(probe_entity_id) then EntityKill(probe_entity_id) end
    if not operation_succeeded then return nil end
    return color
end

METAMORPH_CREATIVE_MENU_LIQUID_PREVIEW = liquid_preview
return liquid_preview
