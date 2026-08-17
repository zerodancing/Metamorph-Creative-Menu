local spells_tab = {}

local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local audit = ui.audit
local spell_service = dofile("mods/metamorph_creative_menu/files/features/spells/service.lua")
local spell_catalog = dofile("mods/metamorph_creative_menu/files/features/spells/catalog.lua")

local action_by_id, filters = nil, nil
local selected_filter = 1
local selected_slot = 0
local slot_page = 0
local tracked_wand = 0
local search = ""

-- Spell definitions are static after gun_actions.lua is loaded, while translating
-- every name/description for every tile on every GUI frame is comparatively costly.
-- Cache presentation by action id/source keys and invalidate the whole cache whenever
-- a small set of our own localized strings changes (e.g. language switched in options).
local presentation_cache = {}
local presentation_locale_signature = nil
local presentation_generation = 0
local search_result_cache_key = nil
local search_result_cache_value = nil

local function refresh_presentation_locale()
    local signature = table.concat({
        ui.translated("$mcm_tab_spells"),
        ui.translated("$mcm_delete"),
    }, "\30")
    if signature ~= presentation_locale_signature then
        presentation_locale_signature = signature
        presentation_generation = presentation_generation + 1
        presentation_cache = {}
        search_result_cache_key = nil
        search_result_cache_value = nil
    end
end

local function action_presentation(action)
    if type(action) ~= "table" then return "", "" end
    local key = tostring(action.id or "")
    local name_key = tostring(action.name or "")
    local description_key = tostring(action.description or "")
    local cached = presentation_cache[key]
    if cached ~= nil and cached.name_key == name_key and cached.description_key == description_key then
        return cached.name, cached.description
    end
    local name = ui.translated(action.name)
    local description = ui.translated(action.description)
    presentation_cache[key] = {
        name_key = name_key, description_key = description_key,
        name = name, description = description,
    }
    return name, description
end


local function load_actions()
    if action_by_id ~= nil then return true end
    if not spell_catalog.load() then return false end
    action_by_id = spell_catalog.by_id()
    filters = spell_catalog.filters()
    return type(action_by_id) == "table" and type(filters) == "table"
end

local function actions_for_filter(filter_index)
    return spell_catalog.for_filter(filter_index)
end

local function actions_for_search(index, query)
    query = tostring(query or "")
    if query == "" then return actions_for_filter(index) end
    local key = tostring(index) .. "\31" .. query .. "\31" .. tostring(presentation_generation)
    if key == search_result_cache_key and search_result_cache_value ~= nil then
        return search_result_cache_value
    end
    local result = {}
    for _, action in ipairs(actions_for_filter(index)) do
        local name, description = action_presentation(action)
        if ui.matches_search(query, name, action.id, description) then
            result[#result + 1] = action
        end
    end
    search_result_cache_key = key
    search_result_cache_value = result
    return result
end

local function background(action)
    return spell_catalog.background_path(action) or ui.EMPTY_SLOT
end

local function icon(action)
    return type(action) == "table" and type(action.sprite) == "string" and action.sprite ~= "" and action.sprite or ui.EMPTY_SLOT
end

function spells_tab.draw(player, panel_width, screen_height)
    if not load_actions() then
        ui.white_text(0, 2, ui.tr("$mcm_spells_failed", "Spell list failed to load")); return
    end
    refresh_presentation_locale()
    local wand = spell_service.held_wand(player)
    if wand == 0 then ui.white_text(0, 2, ui.tr("$mcm_hold_wand", "Hold a wand")); return end

    local columns = ui.columns(panel_width)
    local slots, highest, permanent, entries = spell_service.contents(wand)
    local cap = spell_service.capacity(wand, highest, permanent)
    if tracked_wand ~= wand then tracked_wand, selected_slot, slot_page = wand, 0, 0 end
    selected_slot = math.max(0, math.min(selected_slot, cap - 1))
    local pages = math.max(1, math.ceil(cap / columns))
    slot_page = math.max(0, math.min(slot_page, pages - 1))

    GuiLayoutBeginVertical(ui.gui(), 0, 2, true)
    GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
    ui.white_text(0, 0, ui.tr("$mcm_slot", "SLOT") .. " " .. tostring(selected_slot + 1))
    if pages > 1 then
        if ui.button(0, 0, " < ") then slot_page = (slot_page - 1 + pages) % pages end
        ui.white_text(0, 0, tostring(slot_page + 1) .. "/" .. tostring(pages))
        if ui.button(0, 0, " > ") then slot_page = (slot_page + 1) % pages end
    end
    if ui.button(0, 0, ui.tr("$mcm_delete", "DELETE")) and slots[selected_slot] ~= nil then
        local ok = spell_service.remove(player, wand, slots[selected_slot], entries, false)
        audit("spell.delete", "slot="..tostring(selected_slot+1).." result="..tostring(ok))
    end
    if ui.button(0, 0, ui.tr("$mcm_drop", "DROP")) and slots[selected_slot] ~= nil then
        local ok = spell_service.remove(player, wand, slots[selected_slot], entries, true)
        audit("spell.drop", "slot="..tostring(selected_slot+1).." result="..tostring(ok))
    end
    GuiLayoutEnd(ui.gui())

    GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
    local first = slot_page * columns
    for slot = first, math.min(cap - 1, first + columns - 1) do
        local entry = slots[slot]
        local action = entry and action_by_id[entry.action_id] or nil
        local slot_name = action and select(1, action_presentation(action)) or ui.tr("$mcm_empty", "Empty")
        local clicked, right = ui.tile(0, 0, background(action), icon(action), ui.EMPTY_SLOT,
            ui.tr("$mcm_slot", "SLOT") .. " " .. tostring(slot + 1),
            slot_name, slot == selected_slot,
            { target_size = 18, max_scale = 2.0 })
        if clicked then selected_slot = slot elseif right and entry ~= nil then
            selected_slot = slot
            local ok = spell_service.remove(player, wand, entry, entries, true)
            audit("spell.drop", "slot="..tostring(slot+1).." result="..tostring(ok))
        end
    end
    GuiLayoutEnd(ui.gui())

    for _, row in ipairs({ {1,2,3,4}, {5,6,7}, {8,9} }) do
        GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
        for _, index in ipairs(row) do
            local f = filters[index]
            if ui.button(0, 0, ui.tr(f.key, f.fallback), selected_filter == index) then selected_filter = index end
        end
        GuiLayoutEnd(ui.gui())
    end
    search = ui.search_input(search, math.max(88, panel_width - 54), 64, "spells")

    local grid_h = ui.grid_height(screen_height, 168, 174)
    GuiBeginScrollContainer(ui.gui(), 8200 + selected_filter, 0, 0, panel_width - 4, grid_h, false, 1, 1)
    local _, _, hov = GuiGetPreviousWidgetInfo(ui.gui()); ui.mark_hovered(hov)
    local picked, visible = nil, 0
    for _, action in ipairs(actions_for_search(selected_filter, search)) do
        local name, description = action_presentation(action)
        local i = visible; visible = visible + 1
        local clicked = ui.tile((i % columns) * ui.ICON_STEP, math.floor(i / columns) * ui.ICON_STEP,
            background(action), icon(action), ui.EMPTY_SLOT,
            name .. " [" .. action.id .. "]", description, false,
            { target_size = 18, max_scale = 2.0 })
        if clicked then picked = action end
    end
    GuiEndScrollContainer(ui.gui())
    GuiLayoutEnd(ui.gui())

    if picked ~= nil then
        local ok = spell_service.replace(player, wand, selected_slot, picked.id, slots[selected_slot], entries)
        audit("spell.replace", "slot="..tostring(selected_slot+1).." action="..tostring(picked.id).." result="..tostring(ok))
    end
end

return spells_tab
