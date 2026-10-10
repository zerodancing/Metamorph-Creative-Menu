local metadata = dofile("mods/metamorph_creative_menu/files/features/creatures/metadata.lua")
local classification = dofile("mods/metamorph_creative_menu/files/features/creatures/classification.lua")

local builder = {}

local STATIC_CATALOG_PATH = "mods/metamorph_creative_menu/files/features/creatures/catalog.lua"
local REGISTRY_PATH = "mods/metamorph_creative_menu/files/creature_registry.lua"
local ANIMAL_ICON_DIR = "data/ui_gfx/animal_icons/"
local ANIMAL_ICON_LIST = ANIMAL_ICON_DIR .. "_list.txt"

local static_catalog_cache = nil
local progress_ids_cache = nil
local progress_index_cache = nil
local catalog_cache = nil
local catalog_seen = nil
local catalog_version = 0
local warmup_state = nil
local static_candidates_cache = nil

local basename = metadata.basename
local read_text = metadata.read_text
local base_files = metadata.base_files
local translated = metadata.translated
local entity_name = metadata.entity_name
local known_playable_exception = classification.known_playable_exception
local unsafe_reason = classification.unsafe_reason
local path_is_technical = classification.path_is_technical
local structural_creature = classification.structural_creature
local internal_helper_path = classification.internal_helper_path
local probable_creature = classification.probable_creature
local catalog_creature = classification.catalog_creature

local function load_static_catalog()
    if static_catalog_cache ~= nil then
        return static_catalog_cache
    end
    local ok, catalog = pcall(dofile, STATIC_CATALOG_PATH)
    static_catalog_cache = ok and type(catalog) == "table" and catalog or {}
    return static_catalog_cache
end

local function load_progress_ids()
    if progress_ids_cache ~= nil then
        return progress_ids_cache
    end
    local result = {}
    local index_map = {}
    local ok, content = pcall(ModTextFileGetContent, ANIMAL_ICON_LIST)
    if ok and type(content) == "string" then
        for line in string.gmatch(content, "[^\r\n]+") do
            local id = string.match(line, "^%s*(.-)%s*$")
            if id ~= nil and id ~= "" and id ~= "player" and index_map[id] == nil then
                result[#result + 1] = id
                index_map[id] = #result
            end
        end
    end
    progress_ids_cache = result
    progress_index_cache = index_map
    return result
end

local function progress_index(id)
    if progress_index_cache == nil then
        load_progress_ids()
    end
    return progress_index_cache[id]
end

local function path_depth(path)
    local _, count = string.gsub(path or "", "/", "")
    return count
end

local function static_candidates_by_id()
    if static_candidates_cache ~= nil then return static_candidates_cache end
    local buckets = {}
    for _, value in ipairs(load_static_catalog()) do
        local path = type(value) == "table" and value.path or value
        if type(path) == "string" and path ~= "" then
            local id = basename(path)
            if id ~= "" then
                buckets[id] = buckets[id] or {}
                buckets[id][#buckets[id] + 1] = path
            end
        end
    end
    for id, candidates in pairs(buckets) do
        table.sort(candidates, function(a, b)
            local a_exact = a == ("data/entities/animals/" .. id .. ".xml")
            local b_exact = b == ("data/entities/animals/" .. id .. ".xml")
            if a_exact ~= b_exact then return a_exact end
            local a_helper = path_is_technical(a) or internal_helper_path(a)
            local b_helper = path_is_technical(b) or internal_helper_path(b)
            if a_helper ~= b_helper then return not a_helper end
            local ad, bd = path_depth(a), path_depth(b)
            if ad ~= bd then return ad < bd end
            return a < b
        end)
    end
    static_candidates_cache = buckets
    return buckets
end

local function category_for(path, id, display_name)
    local lower = string.lower((path or "") .. " " .. (id or "") .. " " .. (display_name or ""))
    if string.find(lower, "boss", 1, true)
        or id == "maggot" or id == "maggot_tiny" or id == "boss_dragon"
        or id == "ultimate_killer"
    then
        return "BOSSES"
    end
    if string.find(lower, "robot", 1, true) or string.find(lower, "drone", 1, true)
        or string.find(lower, "turret", 1, true) or string.find(lower, "tank", 1, true)
        or string.find(lower, "basebot", 1, true) or string.find(lower, "spearbot", 1, true)
    then
        return "MACHINES"
    end
    if string.find(lower, "sheep", 1, true) or string.find(lower, "fish", 1, true)
        or string.find(lower, "deer", 1, true) or string.find(lower, "duck", 1, true)
        or string.find(lower, "wolf", 1, true) or string.find(lower, "rat", 1, true)
        or string.find(lower, "frog", 1, true) or string.find(lower, "bat", 1, true)
        or string.find(lower, "eel", 1, true) or string.find(lower, "ant", 1, true)
        or string.find(lower, "scorpion", 1, true) or string.find(lower, "elk", 1, true)
    then
        return "ANIMALS"
    end
    if string.find(lower, "miner", 1, true) or string.find(lower, "shotgunner", 1, true)
        or string.find(lower, "scavenger", 1, true) or string.find(lower, "wizard", 1, true)
        or string.find(lower, "mage", 1, true) or string.find(lower, "alchemist", 1, true)
        or string.find(lower, "shaman", 1, true) or string.find(lower, "assassin", 1, true)
        or string.find(lower, "monk", 1, true) or string.find(lower, "necromancer", 1, true)
    then
        return "HUMANOIDS"
    end
    return "OTHER"
end

local function normalize(path, source, options)
    options = options or {}
    if type(path) ~= "string" or path == "" or not ModDoesFileExist(path) then
        return nil
    end
    -- Creature identity and transform compatibility are separate concerns. Registry/
    -- manifest metadata never bypasses structural creature admission. Exact manual-safe
    -- paths and Noita's own polymorph tables are compatibility evidence, not filename rules.
    if unsafe_reason(path) ~= nil then return nil end
    local trusted_progress = options.trusted_vanilla == true and source == "vanilla_progress"
    local exact_playable = known_playable_exception(path)
    if not trusted_progress and not exact_playable and not catalog_creature(path) then return nil end
    local id = options.id or basename(path)
    local name_key = options.name or entity_name(path, {}, 0) or ("$animal_" .. id)
    local display_name = translated(name_key)
    if display_name == name_key and string.sub(name_key, 1, 1) == "$" then
        display_name = translated("$animal_" .. id)
    end
    if display_name == "" or string.sub(display_name, 1, 1) == "$" then
        display_name = id
    end
    local icon = options.icon
    if icon == nil and id ~= "" then
        local candidate = ANIMAL_ICON_DIR .. id .. ".png"
        if ModDoesFileExist(candidate) then
            icon = candidate
        end
    end
    return {
        path = path,
        id = id,
        name = name_key,
        display_name = display_name,
        icon = icon,
        category = options.category or category_for(path, id, display_name),
        source = source,
        polymorph_table = options.polymorph_table == true,
        progress_index = options.progress_index or progress_index(id),
        special = options.special,
    }
end

local function merged_options(defaults, explicit)
    local result = {}
    for key, value in pairs(type(defaults) == "table" and defaults or {}) do result[key] = value end
    for key, value in pairs(type(explicit) == "table" and explicit or {}) do
        if key ~= "path" then result[key] = value end
    end
    return result
end

local function add(result, seen, path, source, options)
    if type(path) == "table" then
        local entry_table = path
        path = entry_table.path
        -- Caller options are metadata defaults. Table entries override only fields they
        -- explicitly provide; neither source priority nor metadata bypasses admission.
        options = merged_options(options, entry_table)
    end
    local entry = normalize(path, source, options)
    if entry == nil or seen[entry.path] then return false end
    seen[entry.path] = true
    result[#result + 1] = entry
    return true
end

local function add_progress_creatures(result, seen)
    local candidates_by_id = static_candidates_by_id()
    for index, id in ipairs(load_progress_ids()) do
        local candidates = candidates_by_id[id] or {}
        for _, path in ipairs(candidates) do
            -- Noita's progress/icon list is authoritative for "this is a real creature"
            -- presentation, but not for transform safety. Transform compatibility is
            -- tracked separately by exact path/native polymorph evidence.
            if ModDoesFileExist(path) then
                if add(result, seen, path, "vanilla_progress", {
                    id = id,
                    name = "$animal_" .. id,
                    icon = ANIMAL_ICON_DIR .. id .. ".png",
                    progress_index = index,
                    -- _list.txt is Noita's own enemy-progress/icon index. Trusting that
                    -- curated list avoids recursively parsing hundreds of vanilla XMLs
                    -- just to open MOBS for the first time.
                    trusted_vanilla = true,
                }) then break end
            end
        end
    end
end

local function add_external_manifests(result, seen)
    METAMORPH_CREATIVE_MENU_EXTERNAL_CREATURES = nil
    pcall(dofile, REGISTRY_PATH)
    if type(METAMORPH_CREATIVE_MENU_EXTERNAL_CREATURES) == "table" then
        for _, entry in ipairs(METAMORPH_CREATIVE_MENU_EXTERNAL_CREATURES) do
            add(result, seen, entry, "registry", {})
        end
    end

    local ok, mods = pcall(ModGetActiveModIDs)
    if not ok or type(mods) ~= "table" then return end
    for _, mod_id in ipairs(mods) do
        if mod_id ~= "metamorph_creative_menu" then
            local manifest = "mods/" .. mod_id .. "/metamorph_creative_menu_creatures.lua"
            if ModDoesFileExist(manifest) then
                local manifest_ok, entries = pcall(dofile, manifest)
                if manifest_ok and type(entries) == "table" then
                    for _, entry in ipairs(entries) do
                        add(result, seen, entry, "manifest:" .. mod_id, {})
                    end
                end
            end
        end
    end
end

local function sort_catalog(result)
    table.sort(result, function(a, b)
        local ai, bi = tonumber(a.progress_index), tonumber(b.progress_index)
        if ai ~= nil or bi ~= nil then
            if ai == nil then return false end
            if bi == nil then return true end
            if ai ~= bi then return ai < bi end
        end
        local ac, bc = tostring(a.category or ""), tostring(b.category or "")
        if ac ~= bc then return ac < bc end
        local an = string.lower(tostring(a.display_name or a.id or a.path))
        local bn = string.lower(tostring(b.display_name or b.id or b.path))
        if an ~= bn then return an < bn end
        return tostring(a.path) < tostring(b.path)
    end)
    return result
end

local function add_raw_target(result, seen, value)
    local path = type(value) == "table" and value.path or value
    if type(path) ~= "string" or path == "" or seen[path] or not ModDoesFileExist(path) then return end
    if not catalog_creature(path) then return end
    seen[path] = true
    result[#result + 1] = path
end

local function add_explicit_safe_targets(result, seen, entries)
    if type(entries) ~= "table" then
        return
    end
    for _, entry in ipairs(entries) do
        if type(entry) == "table" and entry.transform_safe == true then
            add_raw_target(result, seen, entry)
        end
    end
end



function builder.collect_transform_target_paths()
    local result = {}
    local seen = {}

    for _, rare in ipairs({ false, true }) do
        local ok, entries = pcall(PolymorphTableGet, rare)
        if ok and type(entries) == "table" then
            for _, path in ipairs(entries) do
                add_raw_target(result, seen, path)
            end
        end
    end

    METAMORPH_CREATIVE_MENU_EXTERNAL_CREATURES = nil
    pcall(dofile, REGISTRY_PATH)
    add_explicit_safe_targets(result, seen, METAMORPH_CREATIVE_MENU_EXTERNAL_CREATURES)

    local ok_mods, mods = pcall(ModGetActiveModIDs)
    if ok_mods and type(mods) == "table" then
        for _, mod_id in ipairs(mods) do
            if mod_id ~= "metamorph_creative_menu" then
                local manifest = "mods/" .. mod_id .. "/metamorph_creative_menu_creatures.lua"
                if ModDoesFileExist(manifest) then
                    local ok_manifest, entries = pcall(dofile, manifest)
                    if ok_manifest then
                        add_explicit_safe_targets(result, seen, entries)
                    end
                end
            end
        end
    end

    return result
end

function builder.collect_target_paths()
    return builder.collect_transform_target_paths()
end

function builder.collect()
    if catalog_cache ~= nil then return catalog_cache end
    local result, seen = {}, {}
    add(result, seen, "data/entities/player.xml", "vanilla_player", {
        id = "player", name = "$mcm_creature_player",
        icon = "data/ui_gfx/animal_icons/player.png", category = "HUMANOIDS",
        special = "player",
    })
    add_progress_creatures(result, seen)
    -- The progress list is immediately available. Every additional vanilla/static XML
    -- must pass structural validation during incremental warmup before it can become a
    -- playable form; static-catalog membership alone is not a safety guarantee.
    catalog_cache = sort_catalog(result)
    catalog_seen = seen
    warmup_state = { stage="static", index=1, poly_common=nil, poly_rare=nil, external_done=false }
    catalog_version = catalog_version + 1
    return catalog_cache
end

local function warmup_add_static(path)
    if type(path) ~= "string" or catalog_seen[path] or (not known_playable_exception(path) and not probable_creature(path)) then return false end
    -- Different XML paths are different authored entities even when their basenames are
    -- equal (for example vault/tank.xml versus animals/tank.xml). Exact-path de-duplication
    -- already happens in add(); do not collapse variants by filename.
    local before = #catalog_cache
    add(catalog_cache, catalog_seen, path, "vanilla_extra", {})
    return #catalog_cache > before
end

local function warmup_poly_list(list, source)
    if type(list) ~= "table" then return false end
    local path = list[warmup_state.index]
    if path == nil then return nil end
    warmup_state.index = warmup_state.index + 1
    local id = basename(path)
    if catalog_seen[path] or (not known_playable_exception(path) and not catalog_creature(path)) then return false end
    local before = #catalog_cache
    add(catalog_cache, catalog_seen, path, source, {
        polymorph_table=true, id=id,
    })
    if #catalog_cache > before then return true end
    return false
end

function builder.warmup_step(budget)
    builder.collect()
    budget = math.max(1, math.floor(tonumber(budget) or 4))
    local was_active = warmup_state ~= nil
    local changed = false
    while budget > 0 and warmup_state ~= nil do
        if warmup_state.stage == "static" then
            local values = load_static_catalog()
            local value = values[warmup_state.index]
            if value == nil then
                warmup_state.stage, warmup_state.index = "poly_common", 1
            else
                warmup_state.index = warmup_state.index + 1
                local path = type(value) == "table" and value.path or value
                if warmup_add_static(path) then changed = true end
                budget = budget - 1
            end
        elseif warmup_state.stage == "poly_common" then
            if warmup_state.poly_common == nil then
                local ok, list = pcall(PolymorphTableGet, false)
                warmup_state.poly_common = ok and type(list)=="table" and list or {}
            end
            local added = warmup_poly_list(warmup_state.poly_common, "polymorph_common")
            if added == nil then warmup_state.stage, warmup_state.index = "poly_rare", 1
            else changed = changed or added; budget = budget - 1 end
        elseif warmup_state.stage == "poly_rare" then
            if warmup_state.poly_rare == nil then
                local ok, list = pcall(PolymorphTableGet, true)
                warmup_state.poly_rare = ok and type(list)=="table" and list or {}
            end
            local added = warmup_poly_list(warmup_state.poly_rare, "polymorph_rare")
            if added == nil then warmup_state.stage = "external"
            else changed = changed or added; budget = budget - 1 end
        elseif warmup_state.stage == "external" then
            local before = #catalog_cache
            add_external_manifests(catalog_cache, catalog_seen)
            if #catalog_cache > before then changed = true end
            warmup_state = nil
        end
    end
    local finished_now = was_active and warmup_state == nil
    if warmup_state == nil then sort_catalog(catalog_cache) end
    if changed or finished_now then catalog_version = catalog_version + 1 end
    return warmup_state == nil, changed or finished_now
end

function builder.catalog_version()
    builder.collect()
    return catalog_version
end

function builder.static_candidates_by_id()
    return static_candidates_by_id()
end

function builder.progress_index(id)
    return progress_index(id)
end

function builder.static_catalog()
    return load_static_catalog()
end

function builder.has_catalog_path(path)
    builder.collect()
    return catalog_seen ~= nil and catalog_seen[path] == true
end

return builder
