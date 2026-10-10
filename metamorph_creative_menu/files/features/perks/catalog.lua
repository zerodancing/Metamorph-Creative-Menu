if type(METAMORPH_CREATIVE_MENU_PERK_CATALOG) == "table" then return METAMORPH_CREATIVE_MENU_PERK_CATALOG end

local perk_catalog = {}
local unique_perks = nil

local function load_vanilla_perks()
    if unique_perks ~= nil then return true end
    pcall(dofile_once, "data/scripts/perks/perk.lua")
    pcall(dofile_once, "data/scripts/perks/perk_list.lua")
    if type(perk_list) ~= "table" then return false end

    unique_perks = {}
    local seen_perk_ids = {}
    for _, perk_data in ipairs(perk_list) do
        if type(perk_data) == "table" and type(perk_data.id) == "string"
            and perk_data.id ~= "" and not seen_perk_ids[perk_data.id]
        then
            seen_perk_ids[perk_data.id] = true
            unique_perks[#unique_perks + 1] = perk_data
        end
    end
    return true
end

function perk_catalog.all()
    if not load_vanilla_perks() then return nil end
    return unique_perks
end

METAMORPH_CREATIVE_MENU_PERK_CATALOG = perk_catalog
return perk_catalog
