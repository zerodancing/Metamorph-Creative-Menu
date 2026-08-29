if type(METAMORPH_CREATIVE_MENU_MATERIAL_CATALOG) == "table" then return METAMORPH_CREATIVE_MENU_MATERIAL_CATALOG end

local material_catalog = {}

local CATEGORY_DEFINITIONS = {
    { id="ALL", key="$mcm_material_filter_all", fallback="ALL", icon="data/ui_gfx/items/material_pouch.png" },
    { id="LIQUIDS", key="$mcm_material_filter_liquids", fallback="LIQUIDS", api="CellFactory_GetAllLiquids", icon="data/ui_gfx/items/potion.png" },
    { id="SANDS", key="$mcm_material_filter_sands", fallback="POWDERS", api="CellFactory_GetAllSands", icon="data/ui_gfx/items/material_pouch.png" },
    { id="GASES", key="$mcm_material_filter_gases", fallback="GASES", api="CellFactory_GetAllGases", icon="data/ui_gfx/items/material_pouch.png" },
    { id="FIRES", key="$mcm_material_filter_fires", fallback="FIRES", api="CellFactory_GetAllFires", icon="data/ui_gfx/items/thunderstone.png" },
    { id="SOLIDS", key="$mcm_material_filter_solids", fallback="SOLIDS", api="CellFactory_GetAllSolids", icon="data/ui_gfx/items/material_pouch.png" },
}

local definitions_by_id = {}
for _, definition in ipairs(CATEGORY_DEFINITIONS) do definitions_by_id[definition.id] = definition end

local states = nil
local all_entries = nil
local all_seen = nil
local by_id = nil
local all_step_cursor = 2

local function reset_state()
    states, all_entries, all_seen, by_id = {}, {}, {}, {}
    for index = 2, #CATEGORY_DEFINITIONS do
        local definition = CATEGORY_DEFINITIONS[index]
        states[definition.id] = { raw=nil, cursor=1, entries={}, seen={}, done=false }
    end
    all_step_cursor = 2
end
reset_state()

local function translate_material(material_name, material_type, translate)
    local ok_name, ui_key = pcall(CellFactory_GetUIName, material_type)
    if not ok_name or type(ui_key) ~= "string" or ui_key == "" then return tostring(material_name), nil end
    local translated = type(translate) == "function" and translate(ui_key) or ui_key
    if type(translated) ~= "string" or translated == "" or translated == ui_key then return tostring(material_name), ui_key end
    return translated, ui_key
end

local function collect_from_api(api_name)
    local callback = _G[api_name]
    if type(callback) ~= "function" then return {} end
    -- Material enumeration can be surprisingly large in heavily modded/EW runs. The
    -- expensive per-material validation/translation is intentionally amortized by step().
    local ok, values = pcall(callback, true, true)
    if not ok or type(values) ~= "table" then ok, values = pcall(callback) end
    return ok and type(values) == "table" and values or {}
end

local function ensure_raw(definition, state)
    if state.raw ~= nil then return end
    state.raw = collect_from_api(definition.api)
    state.cursor = 1
    if #state.raw == 0 then state.done = true end
end

local function process_category(definition, translate, budget)
    local state = states[definition.id]
    if state == nil or state.done then return 0, true end
    ensure_raw(definition, state)
    local used = 0
    budget = math.max(1, math.floor(tonumber(budget) or 1))
    while not state.done and used < budget do
        local raw_name = state.raw[state.cursor]
        state.cursor = state.cursor + 1
        used = used + 1
        if raw_name == nil then
            state.done = true
            state.raw = nil
            break
        end
        local material_name = tostring(raw_name or "")
        if material_name ~= "" and not state.seen[material_name] then
            state.seen[material_name] = true
            local ok_type, material_type = pcall(CellFactory_GetType, material_name)
            material_type = ok_type and tonumber(material_type) or nil
            if material_type ~= nil and material_type >= 0 then
                material_type = math.floor(material_type)
                local entry = by_id[material_name]
                if entry == nil then
                    local display_name, name_key = translate_material(material_name, material_type, translate)
                    entry = {
                        id=material_name,
                        material_type=material_type,
                        name_key=name_key,
                        display_name=display_name,
                        category=definition.id,
                        categories={},
                        icon=definition.icon,
                    }
                    by_id[material_name] = entry
                    all_entries[#all_entries + 1] = entry
                    all_seen[material_name] = true
                end
                entry.categories[definition.id] = true
                state.entries[#state.entries + 1] = entry
            end
        end
        if state.cursor > #(state.raw or {}) then
            state.done = true
            state.raw = nil
        end
    end
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
        if definition == nil or definition.api == nil then return true, 0 end
        local state = states[category_id]
        local was_done = state.done
        local used, done = process_category(definition, translate, budget)
        if done and not was_done then sort_entries(state.entries) end
        return done, used
    end

    local used = 0
    local complete = true
    local attempts = 0
    while used < budget and attempts < (#CATEGORY_DEFINITIONS - 1) * 2 do
        if all_step_cursor > #CATEGORY_DEFINITIONS then all_step_cursor = 2 end
        local definition = CATEGORY_DEFINITIONS[all_step_cursor]
        all_step_cursor = all_step_cursor + 1
        attempts = attempts + 1
        local state = states[definition.id]
        if not state.done then
            complete = false
            local consumed, done = process_category(definition, translate, budget - used)
            used = used + consumed
            if done then sort_entries(state.entries) end
        end
    end
    complete = true
    for index = 2, #CATEGORY_DEFINITIONS do
        if not states[CATEGORY_DEFINITIONS[index].id].done then complete = false; break end
    end
    if complete then sort_entries(all_entries) end
    return complete, used
end

function material_catalog.is_ready(category_id)
    category_id = tostring(category_id or "ALL")
    if category_id ~= "ALL" then return states[category_id] ~= nil and states[category_id].done == true end
    for index = 2, #CATEGORY_DEFINITIONS do
        if not states[CATEGORY_DEFINITIONS[index].id].done then return false end
    end
    return true
end

-- Synchronous compatibility API for tests/tools. UI code must use step() so merely
-- opening MATERIALS never performs a full all-material scan in one frame.
function material_catalog.collect(translate)
    local guard = 0
    while not material_catalog.is_ready("ALL") and guard < 10000 do
        material_catalog.step("ALL", translate, 512)
        guard = guard + 1
    end
    return all_entries
end

function material_catalog.categories()
    local result = {}
    for index, category in ipairs(CATEGORY_DEFINITIONS) do result[index] = category end
    return result
end

function material_catalog.entries_for(category_id)
    category_id = tostring(category_id or "ALL")
    if category_id == "ALL" then return all_entries end
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
