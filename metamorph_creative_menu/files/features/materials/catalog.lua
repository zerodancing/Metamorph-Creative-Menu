if type(METAMORPH_CREATIVE_MENU_MATERIAL_CATALOG) == "table" then return METAMORPH_CREATIVE_MENU_MATERIAL_CATALOG end

local material_catalog = {}

-- Noita's CellFactory cell classes are implementation details, not useful UI categories.
-- In particular, authored/static terrain is commonly backed by CellData with
-- cell_type="liquid", while Box2D materials are reported as solids.  The base game's own
-- materials.xml documents semantic tags for the intended families ([liquid], [static],
-- [sand_*], [gas], [fire], [box2d], [hax]).  Prefer those tags and use the enumeration API
-- only as a compatibility fallback for third-party materials that omit semantic tags.
local ENUMERATORS = {
    { id="LIQUIDS", api="CellFactory_GetAllLiquids" },
    { id="SANDS", api="CellFactory_GetAllSands" },
    { id="GASES", api="CellFactory_GetAllGases" },
    { id="FIRES", api="CellFactory_GetAllFires" },
    { id="SOLIDS", api="CellFactory_GetAllSolids" },
    { id="SPECIAL", api="vanilla_definitions" },
}

local ALL_ENUMERATOR_IDS = { 1, 2, 3, 4, 5, 6 }
local CATEGORY_DEFINITIONS = {
    { id="ALL", key="$mcm_material_filter_all", fallback="ALL", sources=ALL_ENUMERATOR_IDS,
        icon="data/ui_gfx/items/material_pouch.png" },
    { id="LIQUIDS", key="$mcm_material_filter_liquids", fallback="LIQUIDS", sources=ALL_ENUMERATOR_IDS,
        icon="data/ui_gfx/items/potion.png" },
    { id="SANDS", key="$mcm_material_filter_sands", fallback="POWDERS", sources=ALL_ENUMERATOR_IDS,
        icon="data/ui_gfx/items/material_pouch.png" },
    { id="STATIC", key="$mcm_material_filter_static", fallback="STATIC TERRAIN", sources=ALL_ENUMERATOR_IDS,
        icon="data/ui_gfx/items/material_pouch.png" },
    { id="GASES", key="$mcm_material_filter_gases", fallback="GASES", sources=ALL_ENUMERATOR_IDS,
        icon="data/ui_gfx/items/material_pouch.png" },
    { id="FIRES", key="$mcm_material_filter_fires", fallback="FIRES", sources=ALL_ENUMERATOR_IDS,
        icon="data/ui_gfx/items/thunderstone.png" },
    { id="SOLIDS", key="$mcm_material_filter_solids", fallback="PHYSICS SOLIDS", sources=ALL_ENUMERATOR_IDS,
        icon="data/ui_gfx/items/material_pouch.png" },
    { id="SPECIAL", key="$mcm_material_filter_special", fallback="SPECIAL", sources=ALL_ENUMERATOR_IDS,
        icon="data/ui_gfx/items/material_pouch.png" },
}

local definitions_by_id = {}
for _, definition in ipairs(CATEGORY_DEFINITIONS) do definitions_by_id[definition.id] = definition end

local states = nil
local all_entries = nil
local by_id = nil
local source_cache = {}

local function reset_state()
    states, all_entries, by_id = {}, {}, {}
    for index = 1, #CATEGORY_DEFINITIONS do
        local definition = CATEGORY_DEFINITIONS[index]
        states[definition.id] = {
            source_cursor=1, raw=nil, cursor=1, entries={}, seen={}, done=false,
        }
    end
    source_cache = {}
end
reset_state()

local function translate_material(material_name, material_type, translate)
    local ok_name, ui_key = pcall(CellFactory_GetUIName, material_type)
    if not ok_name or type(ui_key) ~= "string" or ui_key == "" then return tostring(material_name), nil end
    local translated = type(translate) == "function" and translate(ui_key) or ui_key
    if type(translated) ~= "string" or translated == "" or translated == ui_key then return tostring(material_name), ui_key end
    return translated, ui_key
end

local function collect_vanilla_definitions()
    local source = {values={}, static={}, particle={}, families={}, from_definitions=true}
    if type(ModTextFileGetContent) ~= "function" then return source end
    local ok, content = pcall(ModTextFileGetContent, "data/materials.xml")
    if not ok or type(content) ~= "string" then return source end
    content = content:gsub("<!%-%-.-%-%->", "")
    local seen = {}
    for block in content:gmatch("<CellData[%w_]*%s+([^>]+)>") do
        local attrs = {}
        for key, value in block:gmatch('([%w_]+)%s*=%s*"([^"]*)"') do attrs[key] = value end
        local name = attrs.name
        if name and not seen[name] then
            source.values[#source.values + 1] = name
            seen[name] = true
        end
        if name then
            source.static[name] = attrs.liquid_static == "1" or nil
            source.families[name] = ({liquid=attrs.liquid_sand == "1" and "SANDS" or "LIQUIDS",
                gas="GASES", fire="FIRES", solid="SOLIDS"})[attrs.cell_type]
        end
    end
    return source
end

local function collect_from_api(api_name)
    if source_cache[api_name] ~= nil then return source_cache[api_name] end
    if api_name == "vanilla_definitions" then
        local source = collect_vanilla_definitions()
        source_cache[api_name] = source
        return source
    end
    local callback = _G[api_name]
    local source = { values={}, static={}, particle={} }
    if type(callback) ~= "function" then return source end
    local ok, values = pcall(callback, true, true)
    if not ok or type(values) ~= "table" then ok, values = pcall(callback) end
    source.values = ok and type(values) == "table" and values or {}
    -- The API explicitly separates statics and particle-FX materials. Use those
    -- differences for materials without semantic tags, including third-party terrain.
    local normal_ok, normal = pcall(callback, true, false)
    local dynamic_ok, dynamic = pcall(callback, false, false)
    if normal_ok and type(normal) == "table" then
        local normal_set, dynamic_set = {}, {}
        for _, name in ipairs(normal) do normal_set[name] = true end
        if dynamic_ok and type(dynamic) == "table" then
            for _, name in ipairs(dynamic) do dynamic_set[name] = true end
            for _, name in ipairs(normal) do
                if not dynamic_set[name] then source.static[name] = true end
            end
        end
        for _, name in ipairs(source.values) do
            if not normal_set[name] then source.particle[name] = true end
        end
    end
    source_cache[api_name] = source
    return source
end

local function tag_set(material_type)
    local result = {}
    if type(CellFactory_GetTags) == "function" then
        local ok, tags = pcall(CellFactory_GetTags, material_type)
        if ok and type(tags) == "table" then
            for _, tag in ipairs(tags) do
                -- Vanilla returns literal [static]/[liquid]/[hax] tokens. Accept
                -- unwrapped tokens too for compatibility with API wrappers.
                local name = tostring(tag):match("^%s*(.-)%s*$")
                name = name:match("^%[(.-)%]$") or name
                result[name] = true
            end
        end
    end
    return result
end

local function has_sand_tag(tags)
    return tags.sand_ground == true or tags.sand_metal == true or tags.sand_other == true
end

local function semantic_category(material_type, fallback_category, source, material_name)
    local tags = tag_set(material_type)
    -- Explicit special/hax tags win before fallback.  The other order mirrors the
    -- semantic grouping documented at the top of data/materials.xml.
    if tags.hax == true or source.particle[material_name] then return "SPECIAL", tags end
    if tags.static == true or source.static[material_name] then return "STATIC", tags end
    if tags.liquid == true then return "LIQUIDS", tags end
    if has_sand_tag(tags) then return "SANDS", tags end
    if tags.gas == true then return "GASES", tags end
    if tags.fire == true then return "FIRES", tags end
    if tags.box2d == true then return "SOLIDS", tags end
    -- Mod materials are not required to use vanilla semantic tags.  Keep them usable by
    -- falling back to the CellFactory family that actually reported the material.
    if fallback_category ~= nil and fallback_category ~= "ALL" then return fallback_category, tags end
    return "SPECIAL", tags
end

local function ensure_source(definition, state)
    while not state.done and state.raw == nil do
        local source_slot = definition.sources and definition.sources[state.source_cursor] or nil
        if source_slot == nil then
            state.done = true
            break
        end
        local enumerator = ENUMERATORS[source_slot]
        state.source_cursor = state.source_cursor + 1
        if enumerator ~= nil then
            state.source = collect_from_api(enumerator.api)
            state.raw = state.source.values
            state.raw_source = enumerator.id
            state.cursor = 1
            if #state.raw == 0 then state.raw = nil end
        end
    end
end

local function entry_for(material_name, material_type, primary_category, tags, translate, icon)
    local entry = by_id[material_name]
    if entry == nil then
        local display_name, name_key = translate_material(material_name, material_type, translate)
        entry = {
            id=material_name,
            material_type=material_type,
            name_key=name_key,
            display_name=display_name,
            category=primary_category,
            categories={},
            material_tags=tags,
            icon=icon,
        }
        entry.categories[primary_category] = true
        by_id[material_name] = entry
        all_entries[#all_entries + 1] = entry
    else
        entry.categories[primary_category] = true
        if entry.category == nil or entry.category == "SPECIAL" then entry.category = primary_category end
    end
    return entry
end

local function process_category(definition, translate, budget)
    local state = states[definition.id]
    if state == nil or state.done then return 0, true end
    local used = 0
    budget = math.max(1, math.floor(tonumber(budget) or 1))

    while not state.done and used < budget do
        ensure_source(definition, state)
        if state.done then break end

        local raw_name = state.raw[state.cursor]
        state.cursor = state.cursor + 1
        used = used + 1
        if raw_name ~= nil then
            local material_name = tostring(raw_name or "")
            if material_name ~= "" and not state.seen[material_name] then
                state.seen[material_name] = true
                local ok_type, material_type = pcall(CellFactory_GetType, material_name)
                material_type = ok_type and tonumber(material_type) or nil
                -- Unknown material names can resolve to air (0). XML is only a
                -- discovery fallback: never offer an unloaded definition as paintable.
                local loaded = material_type ~= nil and material_type >= 0
                if loaded and state.source.from_definitions then
                    loaded = material_type ~= 0 or material_name == "air"
                    if loaded and type(CellFactory_GetName) == "function" then
                        local ok_name, resolved = pcall(CellFactory_GetName, material_type)
                        loaded = ok_name and resolved == material_name
                    end
                end
                if loaded then
                    material_type = math.floor(material_type)
                    local primary_category, tags = semantic_category(material_type, state.source.families and state.source.families[material_name] or state.raw_source, state.source, material_name)
                    if definition.id == "ALL" or primary_category == definition.id then
                        local entry = entry_for(material_name, material_type, primary_category, tags, translate, definition.icon)
                        state.entries[#state.entries + 1] = entry
                    end
                end
            end
        end

        if state.cursor > #(state.raw or {}) then
            state.raw = nil
            state.raw_source = nil
            state.cursor = 1
        end
    end
    ensure_source(definition, state)
    return used, state.done
end

local function sort_entries(values)
    table.sort(values, function(a, b)
        local an = string.lower(tostring(a.display_name or a.id))
        local bn = string.lower(tostring(b.display_name or b.id))
        if an == bn then return tostring(a.id) < tostring(b.id) end
        return an < bn
    end)
end

function material_catalog.step(category_id, translate, budget)
    category_id = tostring(category_id or "ALL")
    budget = math.max(1, math.floor(tonumber(budget) or 32))
    if category_id ~= "ALL" then
        local definition = definitions_by_id[category_id]
        if definition == nil then return true, 0 end
        local state = states[category_id]
        local was_done = state.done
        local used, done = process_category(definition, translate, budget)
        if done and not was_done then sort_entries(state.entries) end
        return done, used
    end

    local definition = definitions_by_id.ALL
    local state = states.ALL
    local was_done = state.done
    local used, done = process_category(definition, translate, budget)
    if done and not was_done then
        sort_entries(state.entries)
        sort_entries(all_entries)
    end
    return done, used
end

function material_catalog.is_ready(category_id)
    category_id = tostring(category_id or "ALL")
    return states[category_id] ~= nil and states[category_id].done == true
end

-- Synchronous compatibility API for tests/tools. UI code must use step() so merely
-- opening MATERIALS never performs a full all-material scan in one frame.
function material_catalog.collect(translate)
    local guard = 0
    while not material_catalog.is_ready("ALL") and guard < 10000 do
        material_catalog.step("ALL", translate, 512)
        guard = guard + 1
    end
    return states.ALL.entries
end

function material_catalog.categories()
    local result = {}
    for index, category in ipairs(CATEGORY_DEFINITIONS) do result[index] = category end
    return result
end

function material_catalog.entries_for(category_id)
    category_id = tostring(category_id or "ALL")
    return states[category_id] and states[category_id].entries or {}
end

function material_catalog.get(material_id)
    return by_id[tostring(material_id or "")]
end

function material_catalog.reset_cache()
    reset_state()
end

METAMORPH_CREATIVE_MENU_MATERIAL_CATALOG = material_catalog
return material_catalog
