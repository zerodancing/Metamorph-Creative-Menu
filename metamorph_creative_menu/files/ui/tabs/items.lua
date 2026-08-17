local items_tab = {}

local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local audit = ui.audit
local item_service = dofile("mods/metamorph_creative_menu/files/features/items/service.lua")
local item_catalog = dofile("mods/metamorph_creative_menu/files/features/items/ui_catalog.lua")
local liquid_preview = dofile("mods/metamorph_creative_menu/files/features/items/liquid_preview.lua")

local catalog, filters = nil, nil
local selected_filter = 1
local search = ""
local icon_cache = {}
local liquid_color_cache = {}
local liquid_color_cursor = 1
local liquid_colors_complete = false
local POTION_ICON = "data/ui_gfx/items/potion.png"
local search_cache_key = nil
local search_cache_value = nil

local FALLBACK = {
    CONTAINERS = "data/ui_gfx/items/potion.png",
    STONES = "data/ui_gfx/items/waterstone.png",
    EGGS = "data/ui_gfx/items/egg.png",
    WANDS = "data/ui_gfx/items/wandstone.png",
    BOOKS = "data/ui_gfx/items/emerald_tablet.png",
    BONUSES = "data/ui_gfx/items/goldnugget.png",
    ORBS = "data/ui_gfx/items/orb_gold.png",
    QUEST = "data/ui_gfx/items/emerald_tablet.png",
    OTHER = "data/ui_gfx/items/ingredient_1.png",
}

local function ensure_catalog()
    if catalog ~= nil then return true end
    catalog = item_catalog.collect(ui.translated, ui.tr)
    filters = item_catalog.filters()
    return type(catalog) == "table" and type(filters) == "table"
end

local function entries_for(index)
    return item_catalog.entries_for(index, ui.translated, ui.tr)
end

local function icon(item)
    if type(item) ~= "table" then return ui.EMPTY_SLOT end
    if icon_cache[item.path] ~= nil then return icon_cache[item.path] end

    -- The hand-maintained catalogue often points at the canonical Sprite XML (hearts,
    -- orbs, spell refresh). Prefer that over an ItemComponent.ui_sprite atlas, otherwise
    -- GuiImage scales the whole animation sheet into one tiny tile. Placeholder inventory
    -- boxes are deliberately ignored so physics-only pickups can discover their real body.
    local explicit = tostring(item.icon or "")
    local meaningful_explicit = explicit ~= "" and explicit ~= ui.EMPTY_SLOT
        and explicit ~= "data/ui_gfx/inventory/inventory_box.png"
    local resolved = meaningful_explicit and ui.resolve(explicit) or nil
    if resolved == nil then resolved = ui.entity_icon(item.path, "item") end
    if resolved == nil and explicit ~= "" then resolved = ui.resolve(explicit) end
    if resolved == nil then resolved = ui.resolve(FALLBACK[item.category]) end
    resolved = resolved or ui.EMPTY_SLOT
    icon_cache[item.path] = resolved
    return resolved
end

local function search_values(index, query, values, is_liquid)
    query = tostring(query or "")
    if query == "" then return values end
    local key = tostring(index) .. "\31" .. query .. "\31" .. (is_liquid and "L" or "I")
    if key == search_cache_key and search_cache_value ~= nil then return search_cache_value end
    local result = {}
    for _, entry in ipairs(values or {}) do
        local description = is_liquid and tostring(entry.id) or tostring(entry.display_description or "")
        if ui.matches_search(query, entry.display_name, entry.id, entry.path, description) then
            result[#result + 1] = entry
        end
    end
    search_cache_key, search_cache_value = key, result
    return result
end

function items_tab.draw(player, panel_width, screen_height)
    if not ensure_catalog() then ui.white_text(0, 2, ui.tr("$mcm_items_failed", "Item catalog failed to load")); return end
    GuiLayoutBeginVertical(ui.gui(), 0, 2, true)

    for start = 1, #filters, 4 do
        GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
        for index = start, math.min(start + 3, #filters) do
            local f = filters[index]
            if ui.button(0, 0, ui.tr(f[1], f[2]), selected_filter == index) then selected_filter = index end
        end
        GuiLayoutEnd(ui.gui())
    end
    search = ui.search_input(search, math.max(88, panel_width - 54), 64, "items")

    local filter = filters[selected_filter]
    local values = filter[4] == "LIQUIDS" and item_catalog.liquids(ui.translated) or entries_for(selected_filter)

    -- Lazily sample two liquid colors per frame. GameGetPotionColorUint needs a real
    -- material inventory entity; doing every material in one frame would recreate the
    -- old multi-second catalogue hitch. The cache fills progressively while the tab is
    -- open and is reused for the rest of the run.
    if filter[4] == "LIQUIDS" and #values > 0 and not liquid_colors_complete then
        local sampled = 0
        local scanned = 0
        while sampled < 2 and scanned < #values do
            if liquid_color_cursor > #values then liquid_color_cursor = 1 end
            local entry = values[liquid_color_cursor]
            liquid_color_cursor = liquid_color_cursor + 1
            scanned = scanned + 1
            if liquid_color_cache[entry.id] == nil then
                liquid_color_cache[entry.id] = liquid_preview.sample_color(player, entry.id) or false
                sampled = sampled + 1
            end
        end
        local complete = true
        for _, entry in ipairs(values) do if liquid_color_cache[entry.id] == nil then complete = false; break end end
        liquid_colors_complete = complete
    end

    local columns = ui.columns(panel_width)
    local grid_h = ui.grid_height(screen_height, 190, 160)
    ui.white_text(0, 0, ui.tr("$mcm_item_controls", "LMB: SPAWN   RMB: TAKE"))
    GuiBeginScrollContainer(ui.gui(), 9100 + selected_filter, 0, 0, panel_width - 4, grid_h, false, 1, 1)
    local _, _, hov = GuiGetPreviousWidgetInfo(ui.gui()); ui.mark_hovered(hov)
    local visible = 0
    local is_liquid = filter[4] == "LIQUIDS"
    for _, entry in ipairs(search_values(selected_filter, search, values, is_liquid)) do
        local description = is_liquid and tostring(entry.id) or tostring(entry.display_description or "")
        local i = visible; visible = visible + 1
        local entry_icon = is_liquid and POTION_ICON or icon(entry)
        local clicked, right = ui.tile((i % columns) * ui.ICON_STEP, math.floor(i / columns) * ui.ICON_STEP,
            ui.EMPTY_SLOT, entry_icon, ui.EMPTY_SLOT, entry.display_name, description, false,
            { target_size=18, max_scale=3.0, bottle_fill_color=is_liquid and (liquid_color_cache[entry.id] or nil) or nil })
        if is_liquid then
            if clicked or right then
                local ok, reason, entity = item_service.spawn_filled_flask(player, entry.id, right)
                audit(right and "item.take_liquid" or "item.spawn_liquid", "id="..tostring(entry.id).." result="..tostring(ok).." reason="..tostring(reason))
                if not ok and reason == "full" then
                    GamePrint(ui.tr("$mcm_inventory_full_spawned", "Inventory full — spawned nearby") .. ": " .. entry.display_name)
                elseif not ok then
                    GamePrint(ui.tr("$mcm_item_create_failed", "Could not create item") .. ": " .. entry.display_name)
                end
            end
        else
            if clicked then
                local entity, reason = item_service.spawn_near(player, entry.path)
                audit("item.spawn", "path="..tostring(entry.path).." entity="..tostring(entity).." reason="..tostring(reason))
                if entity ~= 0 then
                    GamePrint(ui.tr("$mcm_created_nearby", "Spawned nearby") .. ": " .. entry.display_name)
                else
                    GamePrint(ui.tr("$mcm_item_create_failed", "Could not create item") .. ": " .. entry.display_name)
                end
            elseif right then
                local ok, reason, entity, spawned_nearby = item_service.give(player, entry.path, entry.category ~= "WANDS")
                audit("item.take", "path="..tostring(entry.path).." result="..tostring(ok).." reason="..tostring(reason).." entity="..tostring(entity))
                if ok then
                    GamePrint(ui.tr("$mcm_received", "Received") .. ": " .. entry.display_name)
                elseif reason == "full" then
                    GamePrint(ui.tr("$mcm_inventory_full_spawned", "Inventory full — spawned nearby") .. ": " .. entry.display_name)
                elseif spawned_nearby then
                    GamePrint(ui.tr("$mcm_item_receive_failed", "Item was not added to inventory") .. " — "
                        .. ui.tr("$mcm_created_nearby", "spawned nearby") .. ": " .. entry.display_name)
                else
                    GamePrint(ui.tr("$mcm_item_receive_failed", "Item was not added to inventory") .. ": " .. entry.display_name)
                end
            end
        end
    end
    GuiEndScrollContainer(ui.gui())
    GuiLayoutEnd(ui.gui())
end

return items_tab
