if type(METAMORPH_CREATIVE_MENU_ENTITY_CATALOG) == "table" then return METAMORPH_CREATIVE_MENU_ENTITY_CATALOG end

local creature_ui_catalog = {}
local menu_visibility = dofile("mods/metamorph_creative_menu/files/features/creatures/menu_visibility.lua")
local cache = nil
local source_version = -1

local function is_player_definition(path, id)
    local lower = string.lower(tostring(path or ""))
    local key = string.lower(tostring(id or ""))
    return lower == "data/entities/player.xml"
        or lower == "data/entities/player_base.xml"
        or string.find(lower, "/player.xml", 1, true) ~= nil
        or key == "player" or key == "mina" or key == "minä"
end

local function add(result, seen, entry)
    if type(entry) ~= "table" then return end
    local path = tostring(entry.path or "")
    local special = tostring(entry.special or "")
    local key = special ~= "" and ("special|" .. special) or path
    if (path == "" and special == "") or seen[key] then return end
    seen[key] = true
    result[#result + 1] = entry
end

local function creature_module()
    local ok, module = pcall(dofile, "mods/metamorph_creative_menu/files/features/creatures/service.lua")
    return ok and type(module) == "table" and module or nil
end

local function add_creatures(result, seen)
    local creature_service = creature_module()
    if type(creature_service) ~= "table" or type(creature_service.collect) ~= "function" then return end
    -- Presentation must consume full creature records. Prewarm candidates intentionally
    -- contain only paths and are not a UI data source.
    local ok_values, values = pcall(creature_service.collect)
    if not ok_values or type(values) ~= "table" then return end
    for _, creature in ipairs(values) do
        if type(creature) == "table" and not is_player_definition(creature.path, creature.id)
            and menu_visibility.visible(creature.path) then
            local copy = {}
            for k, v in pairs(creature) do copy[k] = v end
            copy.role = "creature"
            add(result, seen, copy)
        end
    end
end

function creature_ui_catalog.collect()
    local creature_service = creature_module()
    local version = type(creature_service) == "table" and type(creature_service.catalog_version) == "function"
        and tonumber(creature_service.catalog_version()) or 0
    if cache ~= nil and version == source_version then return cache end
    local result, seen = {}, {}
    add_creatures(result, seen)
    add(result, seen, {
        id = "mcm:player",
        path = "metamorph_creative_menu://player",
        display_name = "$mcm_creature_player",
        display_description = "",
        category = "OTHER",
        role = "player",
        source = "metamorph_creative_menu",
        icon = "data/ui_gfx/animal_icons/player.png",
        special = "player",
    })
    cache = result
    source_version = version
    return cache
end

function creature_ui_catalog.warmup_step(budget)
    local creature_service = creature_module()
    if type(creature_service) ~= "table" or type(creature_service.warmup_step) ~= "function" then return true, false end
    local ok, done, changed = pcall(creature_service.warmup_step, budget)
    if not ok then return false, false end
    if changed == true then cache = nil end
    return done == true, changed == true
end

function creature_ui_catalog.invalidate() cache = nil; source_version = -1 end

METAMORPH_CREATIVE_MENU_ENTITY_CATALOG = creature_ui_catalog
return creature_ui_catalog
