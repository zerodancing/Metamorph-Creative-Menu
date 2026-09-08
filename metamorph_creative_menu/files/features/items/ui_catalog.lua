local item_catalog = {}

local ITEM_CATALOG_PATH = "mods/metamorph_creative_menu/files/features/items/catalog.lua"
local VANILLA_OUTLIERS_PATH = "mods/metamorph_creative_menu/files/features/items/vanilla_outliers.lua"
local ITEM_REGISTRY_PATH = "mods/metamorph_creative_menu/files/item_registry.lua"
local POTION_ICON = "data/ui_gfx/items/potion.png"

local NAME_OVERRIDES = {
    ["data/entities/items/pickup/potion_empty.xml"] = "$mcm_empty_flask",
    ["data/entities/items/pickup/potion_water.xml"] = "$mcm_flask_water",
    ["data/entities/items/pickup/potion_milk.xml"] = "$mcm_flask_milk",
    ["data/entities/items/pickup/potion_alcohol.xml"] = "$mcm_flask_alcohol",
    ["data/entities/items/pickup/potion_beer.xml"] = "$mcm_flask_beer",
    ["data/entities/items/pickup/potion_slime.xml"] = "$mcm_flask_slime",
    ["data/entities/items/pickup/potion_vomit.xml"] = "$mcm_flask_vomit",
    ["data/entities/items/pickup/potion_porridge.xml"] = "$mcm_flask_porridge",
    ["data/entities/items/pickup/potion_random_material.xml"] = "$mcm_flask_random_material",
    ["data/entities/items/pickup/potion_starting.xml"] = "$mcm_flask_starting_random",
    ["data/entities/items/pickup/potion_secret.xml"] = "$mcm_flask_secret",
    ["data/entities/items/pickup/potion_aggressive.xml"] = "$mcm_flask_alchemist",
    ["data/entities/items/pickup/potion.xml"] = "$mcm_flask_random_liquid",
    ["data/entities/items/pickup/potion_mimic.xml"] = "$mcm_flask_mimic",
    ["data/entities/items/pickup/jar_of_urine.xml"] = "$mcm_jar_urine",
    ["data/entities/items/pickup/jar.xml"] = "$mcm_jar",
    ["data/entities/items/pickup/powder_stash.xml"] = "$mcm_powder_pouch",
}

local FILTERS = {
    { "$mcm_item_filter_all", "ALL" },
    { "$mcm_item_filter_containers", "BOTTLES", "CONTAINERS" },
    { "$mcm_item_filter_liquids", "LIQUIDS", nil, "LIQUIDS" },
    { "$mcm_item_filter_stones", "STONES", "STONES" },
    { "$mcm_item_filter_eggs", "EGGS", "EGGS" },
    { "$mcm_item_filter_wands", "WANDS", "WANDS" },
    { "$mcm_item_filter_books", "BOOKS", "BOOKS" },
    { "$mcm_item_filter_bonuses", "BONUSES", "BONUSES" },
    { "$mcm_item_filter_orbs", "ORBS", "ORBS" },
    { "$mcm_item_filter_quest", "QUEST", "QUEST" },
    { "$mcm_item_filter_other", "OTHER", "OTHER" },
}

local cached_catalog = nil
local cached_filter_entries = {}
local cached_liquids = nil

local function guessed_category(path)
    local normalized_path = string.lower(tostring(path or ""))
    if string.find(normalized_path, "potion", 1, true) or string.find(normalized_path, "jar", 1, true)
        or string.find(normalized_path, "powder", 1, true) then return "CONTAINERS" end
    if string.find(normalized_path, "wand", 1, true) then return "WANDS" end
    if string.find(normalized_path, "egg", 1, true) then return "EGGS" end
    if string.find(normalized_path, "book", 1, true) or string.find(normalized_path, "tablet", 1, true)
        or string.find(normalized_path, "note", 1, true) then return "BOOKS" end
    if string.find(normalized_path, "orb", 1, true) then return "ORBS" end
    if string.find(normalized_path, "heart", 1, true) or string.find(normalized_path, "gold", 1, true)
        or string.find(normalized_path, "chest", 1, true) or string.find(normalized_path, "perk_reroll", 1, true)
        or string.find(normalized_path, "spell_refresh", 1, true) then return "BONUSES" end
    return "OTHER"
end

local function add_entry(target, seen_paths, item, translate, translate_with_fallback)
    if type(item) ~= "table" or type(item.path) ~= "string" or item.path == ""
        or seen_paths[item.path] or not ModDoesFileExist(item.path)
    then
        return
    end
    seen_paths[item.path] = true
    local entry = {}
    for key, value in pairs(item) do entry[key] = value end
    entry.category = entry.category or guessed_category(entry.path)
    entry.name = entry.name or entry.display_name or (string.match(entry.path, "([^/]+)%.xml$") or entry.path)
    entry.description = entry.description or ""
    entry.display_name = translate(entry.name)
    local override_key = NAME_OVERRIDES[entry.path]
    if override_key ~= nil then entry.display_name = translate_with_fallback(override_key, entry.display_name) end
    if entry.display_name == "" or entry.display_name == entry.name then
        entry.display_name = string.match(entry.path, "([^/]+)%.xml$") or entry.path
    end
    entry.display_description = translate(entry.description)
    entry.kind = entry.kind or "item"
    target[#target + 1] = entry
end

local function add_external_entries(target, seen_paths, translate, translate_with_fallback)
    METAMORPH_CREATIVE_MENU_EXTERNAL_ITEMS = nil
    pcall(dofile, ITEM_REGISTRY_PATH)
    if type(METAMORPH_CREATIVE_MENU_EXTERNAL_ITEMS) == "table" then
        for _, item in ipairs(METAMORPH_CREATIVE_MENU_EXTERNAL_ITEMS) do
            add_entry(target, seen_paths, item, translate, translate_with_fallback)
        end
    end
    local ids_loaded, active_mod_ids = pcall(ModGetActiveModIDs)
    if not ids_loaded or type(active_mod_ids) ~= "table" then return end
    for _, mod_id in ipairs(active_mod_ids) do
        if mod_id ~= "metamorph_creative_menu" then
            local manifest_path = "mods/" .. mod_id .. "/metamorph_creative_menu_items.lua"
            if ModDoesFileExist(manifest_path) then
                local manifest_loaded, entries = pcall(dofile, manifest_path)
                if manifest_loaded and type(entries) == "table" then
                    for _, item in ipairs(entries) do
                        add_entry(target, seen_paths, item, translate, translate_with_fallback)
                    end
                end
            end
        end
    end
end

function item_catalog.prewarm_icons(asset_service)
    if type(asset_service) ~= "table" or type(asset_service.prewarm) ~= "function" then return 0, 0 end
    local identity = function(value) return tostring(value or "") end
    local identity_fallback = function(_, fallback) return tostring(fallback or "") end
    local entries, seen_paths = {}, {}

    local catalog_loaded, base_entries = pcall(dofile, ITEM_CATALOG_PATH)
    if catalog_loaded and type(base_entries) == "table" then
        for _, item in ipairs(base_entries) do add_entry(entries, seen_paths, item, identity, identity_fallback) end
    end
    local outliers_loaded, outliers = pcall(dofile, VANILLA_OUTLIERS_PATH)
    if outliers_loaded and type(outliers) == "table" then
        for _, item in ipairs(outliers) do add_entry(entries, seen_paths, item, identity, identity_fallback) end
    end
    -- External manifests are intentionally excluded from init-time prewarming. Their
    -- files may not exist yet, and executing another mod's registry during our lifecycle
    -- phase can freeze a transient fallback in the presentation cache. Runtime collect()
    -- still discovers every active mod and resolves its icons lazily after initialization.

    local icon_paths, seen_icons = {}, {}
    local entity_paths = {}
    for _, item in ipairs(entries) do
        local icon = tostring(item.icon or "")
        if icon ~= "" and not seen_icons[icon] then
            seen_icons[icon] = true
            icon_paths[#icon_paths + 1] = icon
        elseif icon == "" then
            entity_paths[#entity_paths + 1] = item.path
        end
    end

    local prepared, failed = asset_service.prewarm(icon_paths)
    if type(asset_service.prewarm_entity) == "function" then
        for _, entity_path in ipairs(entity_paths) do
            if asset_service.prewarm_entity(entity_path, "item") then prepared = prepared + 1 else failed = failed + 1 end
        end
    end
    return prepared, failed
end

function item_catalog.collect(translate, translate_with_fallback)
    if cached_catalog ~= nil then return cached_catalog end
    translate = type(translate) == "function" and translate or tostring
    translate_with_fallback = type(translate_with_fallback) == "function" and translate_with_fallback
        or function(key, fallback) local value = translate(key); return value == "" or value == key and fallback or value end
    local catalog_loaded, base_entries = pcall(dofile, ITEM_CATALOG_PATH)
    if not catalog_loaded or type(base_entries) ~= "table" then return nil end
    local entries = {}
    local seen_paths = {}
    for _, item in ipairs(base_entries) do add_entry(entries, seen_paths, item, translate, translate_with_fallback) end
    local outliers_loaded, outliers = pcall(dofile, VANILLA_OUTLIERS_PATH)
    if outliers_loaded and type(outliers) == "table" then
        for _, item in ipairs(outliers) do
            add_entry(entries, seen_paths, item, translate, translate_with_fallback)
        end
    end
    add_external_entries(entries, seen_paths, translate, translate_with_fallback)
    table.sort(entries, function(left, right)
        local left_name = string.lower(left.display_name or left.path)
        local right_name = string.lower(right.display_name or right.path)
        return left_name == right_name and left.path < right.path or left_name < right_name
    end)
    cached_catalog = entries
    return cached_catalog
end

function item_catalog.filters()
    return FILTERS
end

function item_catalog.entries_for(filter_index, translate, translate_with_fallback)
    if cached_filter_entries[filter_index] ~= nil then return cached_filter_entries[filter_index] end
    local entries = item_catalog.collect(translate, translate_with_fallback)
    local filter = FILTERS[filter_index]
    if entries == nil or filter == nil or filter[4] == "LIQUIDS" then return {} end
    local matches = {}
    for _, item in ipairs(entries) do
        if filter[3] == nil or item.category == filter[3] then matches[#matches + 1] = item end
    end
    -- ALL is a real union of the item and liquid catalogues. Liquids used to live only in
    -- their dedicated filter, which made ALL incomplete and also meant a global item search
    -- could never find a filled flask by material name.
    if filter_index == 1 then
        for _, liquid in ipairs(item_catalog.liquids(translate)) do matches[#matches + 1] = liquid end
        table.sort(matches, function(left, right)
            local left_name = string.lower(tostring(left.display_name or left.id or left.path or ""))
            local right_name = string.lower(tostring(right.display_name or right.id or right.path or ""))
            if left_name ~= right_name then return left_name < right_name end
            return tostring(left.id or left.path or "") < tostring(right.id or right.path or "")
        end)
    end
    cached_filter_entries[filter_index] = matches
    return matches
end

local function material_presentation(material_name, translate)
    local id_loaded, material_id = pcall(CellFactory_GetType, material_name)
    if not id_loaded or material_id == nil or material_id < 0 then return material_name, "" end
    local ui_name_loaded, ui_name_key = pcall(CellFactory_GetUIName, material_id)
    if not ui_name_loaded or type(ui_name_key) ~= "string" or ui_name_key == "" then return material_name, "" end
    local translated_name = translate(ui_name_key)
    return (translated_name == "" or translated_name == ui_name_key) and material_name or translated_name, ui_name_key
end

function item_catalog.liquids(translate)
    if cached_liquids ~= nil then return cached_liquids end
    translate = type(translate) == "function" and translate or tostring
    local liquids_loaded, liquid_names = pcall(CellFactory_GetAllLiquids, true, false)
    if not liquids_loaded or type(liquid_names) ~= "table" then
        liquids_loaded, liquid_names = pcall(CellFactory_GetAllLiquids)
    end
    local entries = {}
    if not liquids_loaded or type(liquid_names) ~= "table" then cached_liquids = entries; return entries end
    local seen_names = {}
    for _, liquid_name in ipairs(liquid_names) do
        if type(liquid_name) == "string" and liquid_name ~= "" and liquid_name ~= "unknown" and not seen_names[liquid_name] then
            seen_names[liquid_name] = true
            local display_name, ui_name_key = material_presentation(liquid_name, translate)
            entries[#entries + 1] = {
                id = liquid_name,
                display_name = display_name,
                ui_name_key = ui_name_key,
                icon = POTION_ICON,
                kind = "liquid",
            }
        end
    end
    local priority = {
        water=1, blood=2, milk=3, oil=4, alcohol=5, acid=6, lava=7, slime=8,
        magic_liquid_teleportation=9, magic_liquid_polymorph=10,
    }
    table.sort(entries, function(left, right)
        local left_priority = priority[left.id] or 9999
        local right_priority = priority[right.id] or 9999
        if left_priority ~= right_priority then return left_priority < right_priority end
        return string.lower(left.display_name) < string.lower(right.display_name)
    end)
    cached_liquids = entries
    return entries
end

return item_catalog
