local materials_tab = {}

local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local audit = ui.audit
local material_catalog = dofile("mods/metamorph_creative_menu/files/features/materials/catalog.lua")
local painter = dofile("mods/metamorph_creative_menu/files/features/materials/painter.lua")
local bindings = dofile("mods/metamorph_creative_menu/files/platform/noita/action_bindings.lua")
local material_preview = dofile("mods/metamorph_creative_menu/files/platform/noita/material_preview.lua")

local categories = nil
local selected_filter = 2
local search = ""
local search_cache_key = nil
local search_cache_value = nil

local CATALOG_BUDGET_PER_FRAME = 24
local active_catalog_request = nil
local liquid_warmup = material_preview.new_liquid_warmup()

local function ensure_catalog(category_id)
    if categories == nil then categories = material_catalog.categories() end
    if type(categories) ~= "table" then return false, false end
    -- Do not enumerate CellFactory on the exact GUI frame that opens MATERIALS (or
    -- switches category). In EW that frame also carries inventory/network work; the old
    -- all-material scan could stall it long enough for the proxy channel to disconnect.
    -- The next draw starts one category only, and expensive per-material work is bounded.
    if active_catalog_request ~= category_id then
        active_catalog_request = category_id
        return true, material_catalog.is_ready(category_id)
    end
    local ready = material_catalog.step(category_id, ui.translated, CATALOG_BUDGET_PER_FRAME)
    local values = material_catalog.entries_for(category_id)
    if painter.get_material() == nil and type(values) == "table" and values[1] ~= nil then
        painter.set_material(values[1].id, { solid=values[1].categories and values[1].categories.SOLIDS == true })
    end
    return true, ready == true
end

local function visible_entries(category_id, query)
    local values = material_catalog.entries_for(category_id)
    query = tostring(query or "")
    if query == "" then return values end
    local key = tostring(category_id) .. "\31" .. query .. "\31" .. tostring(#(values or {}))
    if key == search_cache_key and search_cache_value ~= nil then return search_cache_value end
    local result = ui.rank_entries(query, values, function(entry)
        return {entry.name_key, entry.display_name, entry.id, entry.category}
    end, function(entry) return entry.id end)
    search_cache_key, search_cache_value = key, result
    return result
end

function materials_tab.draw(player, panel_width, screen_height)
    if categories == nil then categories = material_catalog.categories() end
    local category = categories and (categories[selected_filter] or categories[2] or categories[1]) or nil
    if category == nil then
        ui.white_text(0, 2, ui.tr("$mcm_materials_failed", "Material catalog failed to load"))
        return
    end
    local catalog_ok, catalog_ready = ensure_catalog(category.id)
    if not catalog_ok then
        ui.white_text(0, 2, ui.tr("$mcm_materials_failed", "Material catalog failed to load"))
        return
    end
    GuiLayoutBeginVertical(ui.gui(), 0, 2, true)

    local category_buttons = {}
    for index, entry in ipairs(categories) do
        category_buttons[index] = {label=ui.tr(entry.key, entry.fallback),selected=selected_filter == index}
    end
    local clicked_category = ui.button_grid(category_buttons, panel_width - 10)
    if clicked_category ~= nil then
        selected_filter = clicked_category
        search_cache_key, search_cache_value = nil, nil
    end

    search = ui.search_input(search, math.max(88, panel_width - 54), 64, "materials")

    local brush_delta = ui.stepper(ui.tr("$mcm_material_brush", "BRUSH"),
        tostring(painter.brush_diameter()) .. " px")
    if brush_delta ~= 0 then painter.adjust_brush(brush_delta) end

    local selected_id = painter.get_material()
    local selected = selected_id and material_catalog.get(selected_id) or nil
    if selected ~= nil then
        ui.wrapped_text(0, 0, ui.tr("$mcm_material_selected", "Selected") .. ": "
            .. tostring(selected.display_name) .. "  [" .. tostring(selected.id) .. "]", panel_width - 12)
    end
    if painter.is_enabled() then
        if ui.button(0, 0, ui.tr("$mcm_material_paint_cancel", "CANCEL PAINT"), true) then
            painter.set_enabled(false)
            audit("material.paint_mode", "enabled=false")
        end
        local armed = ui.tr("$mcm_material_paint_armed_dynamic", "ARMED - close inventory; hold {BIND}")
        ui.wrapped_text(0, 1, string.gsub(armed, "{BIND}", "[" .. bindings.label("paint_draw") .. "]"), panel_width - 12)
    else
        if ui.button(0, 0, ui.tr("$mcm_material_paint_start", "START PAINTING")) then
            local ok, reason = painter.set_enabled(true)
            audit("material.paint_mode", "enabled=" .. tostring(ok) .. " material=" .. tostring(painter.get_material()) .. " reason=" .. tostring(reason))
            if not ok and type(GamePrint) == "function" then
                local message = ui.tr("$mcm_material_backend_failed", "Material brush unavailable")
                pcall(GamePrint, "[MCM] " .. message .. ": " .. tostring(reason or "backend"))
            end
        end
    end
    local controls = ui.tr("$mcm_material_controls_dynamic", "Close inventory then hold {BIND} in the world. Reopen to stop.")
    ui.wrapped_text(0, 0, string.gsub(controls, "{BIND}", "[" .. bindings.label("paint_draw") .. "]"), panel_width - 12)

    if not catalog_ready then
        ui.white_text(0, 0, ui.tr("$mcm_material_loading", "Loading materials...") )
    end
    local values = visible_entries(category.id, search)
    ui.search_status(search, #values)
    local liquid_entries = {}
    for _, entry in ipairs(values) do
        if type(entry.categories) == "table" and entry.categories.LIQUIDS == true then
            liquid_entries[#liquid_entries + 1] = entry
        end
    end
    material_preview.warm_liquid_colors(player, liquid_entries, liquid_warmup, 2)
    local grid_h = ui.scroll_height(screen_height, 194)
    local scroll = ui.begin_scroll_viewport("materials.catalog." .. tostring(selected_filter),
        9700 + selected_filter, 0, 0, panel_width - 4, grid_h, {layout="free"})
    local columns = ui.columns(scroll.content_width, ui.ICON_STEP, {reserve_scrollbar=false})
    for index, entry in ipairs(values) do
        local i = index - 1
        local is_liquid = type(entry.categories) == "table" and entry.categories.LIQUIDS == true
        local texture = not is_liquid and material_preview.texture(entry.id) or nil
        local tint = texture ~= nil and material_preview.tint(entry.id) or nil
        if not is_liquid and texture == nil and entry.preview_color == nil then
            entry.preview_color = painter.material_color(entry.id) or {0.45,0.45,0.45,0.96}
        end
        local clicked = ui.tile(scroll.padding_left + (i % columns) * ui.ICON_STEP, ui.scroll_y(scroll, math.floor(i / columns) * ui.ICON_STEP),
            ui.EMPTY_SLOT, is_liquid and material_preview.liquid_icon() or texture, nil,
            entry.display_name, tostring(entry.id) .. "\n" .. tostring(entry.category),
            selected_id == entry.id, {
                swatch_color=not is_liquid and texture == nil and entry.preview_color or nil,
                bottle_fill_color=is_liquid and material_preview.liquid_color(entry.id) or nil,
                icon_tint=tint, target_size=18, max_scale=3.0, padding=1,
            })
        if clicked then
            local ok, reason = painter.set_material(entry.id, { solid=entry.categories and entry.categories.SOLIDS == true })
            audit("material.select", "id=" .. tostring(entry.id) .. " result=" .. tostring(ok) .. " reason=" .. tostring(reason))
        end
    end
    ui.end_scroll_viewport(scroll, math.ceil(#values / columns) * ui.ICON_STEP)
    GuiLayoutEnd(ui.gui())
end

return materials_tab
