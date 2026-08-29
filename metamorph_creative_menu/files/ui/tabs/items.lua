local items_tab = {}

local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local audit = ui.audit
local item_service = dofile("mods/metamorph_creative_menu/files/features/items/service.lua")
local item_catalog = dofile("mods/metamorph_creative_menu/files/features/items/ui_catalog.lua")
local material_preview = dofile("mods/metamorph_creative_menu/files/platform/noita/material_preview.lua")
local drag_drop = dofile("mods/metamorph_creative_menu/files/ui/drag_drop.lua")
local inventory_slots = dofile("mods/metamorph_creative_menu/files/platform/noita/inventory_slots.lua")

local catalog, filters = nil, nil
local selected_filter = 1
local search = ""
local icon_cache = {}
local liquid_warmup = material_preview.new_liquid_warmup()
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

local function point_inside(bounds, x, y)
    return type(bounds) == "table" and tonumber(x) ~= nil and tonumber(y) ~= nil
        and tonumber(x) >= tonumber(bounds.x or 0) and tonumber(x) <= tonumber(bounds.x or 0) + tonumber(bounds.width or 0)
        and tonumber(y) >= tonumber(bounds.y or 0) and tonumber(y) <= tonumber(bounds.y or 0) + tonumber(bounds.height or 0)
end

local function drag_bounds(x, y, width, height)
    x, y, width, height = tonumber(x), tonumber(y), tonumber(width), tonumber(height)
    if x == nil or y == nil or width == nil or height == nil or width <= 0 or height <= 0 then return nil end
    return {x=x, y=y, width=width, height=height}
end

local function report_create_failure(name)
    GamePrint(ui.tr("$mcm_item_create_failed", "Could not create item") .. ": " .. tostring(name or ""))
end

local function handle_completed_drag(player, screen_width, screen_height)
    local result = drag_drop.take_result()
    if result == nil or type(result.payload) ~= "table" then return end
    local payload = result.payload
    if payload.kind ~= "catalog_item" and payload.kind ~= "catalog_liquid" then return end

    if result.click == true then
        if payload.kind == "catalog_liquid" then
            local ok, reason = item_service.spawn_filled_flask(player, payload.material_id, false)
            audit("item.spawn_liquid", "id=" .. tostring(payload.material_id) .. " result=" .. tostring(ok) .. " reason=" .. tostring(reason))
            if not ok then report_create_failure(payload.display_name) end
        else
            local entity, reason = item_service.spawn_near(player, payload.path)
            audit("item.spawn", "path=" .. tostring(payload.path) .. " entity=" .. tostring(entity) .. " reason=" .. tostring(reason))
            if entity ~= 0 then
                GamePrint(ui.tr("$mcm_created_nearby", "Spawned nearby") .. ": " .. tostring(payload.display_name or ""))
            else
                report_create_failure(payload.display_name)
            end
        end
        return
    end

    -- Catalog cards are immutable templates. A completed drag creates exactly one entity
    -- only after the release destination has been classified. Missing targets inside the
    -- menu are a cancel; outside the menu, native inventory wins over the game world.
    if result.target ~= nil then return end
    local release_x, release_y = tonumber(result.release_x), tonumber(result.release_y)
    local menu_bounds = type(ui.panel_bounds) == "function" and ui.panel_bounds() or nil
    if release_x == nil or release_y == nil or point_inside(menu_bounds, release_x, release_y) then
        audit("item.drag.cancel", "kind=" .. tostring(payload.kind) .. " reason=in_menu")
        return
    end

    local native_inventory = inventory_slots.native_drop_bounds(player, "inventory_quick", screen_width, screen_height)
    if point_inside(native_inventory, release_x, release_y) then
        local ok, reason
        if payload.kind == "catalog_liquid" then
            ok, reason = item_service.give_filled_flask_strict(player, payload.material_id)
        else
            ok, reason = item_service.give_strict(player, payload.path, payload.category ~= "WANDS")
        end
        audit("item.drag.native_inventory", "kind=" .. tostring(payload.kind) .. " result=" .. tostring(ok) .. " reason=" .. tostring(reason))
        if ok then
            GamePrint(ui.tr("$mcm_received", "Received") .. ": " .. tostring(payload.display_name or ""))
        else
            GamePrint(ui.tr("$mcm_item_receive_failed", "Item was not added to inventory") .. ": " .. tostring(payload.display_name or ""))
        end
        return
    end

    local world_x, world_y = tonumber(result.world_x), tonumber(result.world_y)
    if world_x == nil or world_y == nil then
        audit("item.drag.world", "kind=" .. tostring(payload.kind) .. " result=false reason=position")
        report_create_failure(payload.display_name)
        return
    end

    if payload.kind == "catalog_liquid" then
        local ok, reason = item_service.spawn_filled_flask_at(payload.material_id, world_x, world_y)
        audit("item.drag.world_liquid", "id=" .. tostring(payload.material_id) .. " result=" .. tostring(ok)
            .. " reason=" .. tostring(reason) .. " x=" .. tostring(world_x) .. " y=" .. tostring(world_y))
        if not ok then report_create_failure(payload.display_name) end
    else
        local entity, reason = item_service.spawn_at(payload.path, world_x, world_y)
        audit("item.drag.world", "path=" .. tostring(payload.path) .. " entity=" .. tostring(entity)
            .. " reason=" .. tostring(reason) .. " x=" .. tostring(world_x) .. " y=" .. tostring(world_y))
        if entity == 0 then report_create_failure(payload.display_name) end
    end
end

local function search_values(index, query, values, is_liquid)
    query = tostring(query or "")
    if query == "" then return values end
    local key = tostring(index) .. "\31" .. query .. "\31" .. (is_liquid and "L" or "I")
    if key == search_cache_key and search_cache_value ~= nil then return search_cache_value end
    local result = ui.rank_entries(query, values, function(entry)
        local description = is_liquid and tostring(entry.id) or tostring(entry.display_description or "")
        return {entry.name, entry.description, entry.display_name, entry.id, entry.path, description}
    end, function(entry) return entry.id or entry.path end)
    search_cache_key, search_cache_value = key, result
    return result
end

function items_tab.draw(player, panel_width, screen_height)
    if not ensure_catalog() then ui.white_text(0, 2, ui.tr("$mcm_items_failed", "Item catalog failed to load")); return end
    local screen_width, actual_screen_height = GuiGetScreenDimensions(ui.gui())
    handle_completed_drag(player, screen_width, actual_screen_height)
    GuiLayoutBeginVertical(ui.gui(), 0, 2, true)

    local filter_buttons = {}
    for index, f in ipairs(filters) do
        filter_buttons[index] = {label=ui.tr(f[1], f[2]),selected=selected_filter == index}
    end
    local clicked_filter = ui.button_grid(filter_buttons, panel_width - 10)
    if clicked_filter ~= nil then selected_filter = clicked_filter end
    search = ui.search_input(search, math.max(68, panel_width - 28), 64, "items")

    local filter = filters[selected_filter]
    local values = filter[4] == "LIQUIDS" and item_catalog.liquids(ui.translated) or entries_for(selected_filter)

    -- Both ITEMS and MATERIALS use this same bounded probe/cache. A real filled flask
    -- is the engine-authoritative preview for liquids; two new materials per frame keep
    -- catalogue opening independent of the number of installed materials.
    if filter[4] == "LIQUIDS" then
        material_preview.warm_liquid_colors(player, values, liquid_warmup, 2)
    end

    local is_liquid = filter[4] == "LIQUIDS"
    local results = search_values(selected_filter, search, values, is_liquid)
    ui.search_status(search, #results)
    ui.wrapped_text(0, 0, ui.tr("$mcm_item_controls", "LMB: SPAWN  DRAG: DROP  RMB: TAKE"), math.max(24, panel_width - 8))
    local grid_h = ui.scroll_height(screen_height, 160)
    local scroll = ui.begin_scroll_viewport("items.catalog." .. tostring(selected_filter),
        9100 + selected_filter, 0, 0, panel_width - 4, grid_h, {layout="free"})
    local columns = ui.columns(scroll.content_width, ui.ICON_STEP, {reserve_scrollbar=false})
    local visible = 0
    for _, entry in ipairs(results) do
        local description = is_liquid and tostring(entry.id) or tostring(entry.display_description or "")
        local i = visible; visible = visible + 1
        local entry_icon = is_liquid and material_preview.liquid_icon() or icon(entry)
        local _, right, _, tile_x, tile_y, tile_w, tile_h = ui.tile(
            scroll.padding_left + (i % columns) * ui.ICON_STEP,
            ui.scroll_y(scroll, math.floor(i / columns) * ui.ICON_STEP),
            ui.EMPTY_SLOT, entry_icon, ui.EMPTY_SLOT, entry.display_name, description, false,
            { target_size=18, max_scale=3.0,
              bottle_fill_color=is_liquid and material_preview.liquid_color(entry.id) or nil })
        local bounds = drag_bounds(tile_x, tile_y, tile_w, tile_h)
        if bounds ~= nil then
            drag_drop.source("items.catalog." .. (is_liquid and ("liquid." .. tostring(entry.id)) or tostring(entry.path)), {
                kind=is_liquid and "catalog_liquid" or "catalog_item",
                material_id=is_liquid and entry.id or nil, path=not is_liquid and entry.path or nil,
                category=not is_liquid and entry.category or nil, display_name=entry.display_name,
                background=ui.EMPTY_SLOT, icon=entry_icon,
                bottle_fill_color=is_liquid and material_preview.liquid_color(entry.id) or nil,
            }, bounds, {x=scroll.x, y=scroll.y, width=scroll.width, height=scroll.height})
        end
        if right then
            if is_liquid then
                local ok, reason = item_service.spawn_filled_flask(player, entry.id, true)
                audit("item.take_liquid", "id="..tostring(entry.id).." result="..tostring(ok).." reason="..tostring(reason))
                if not ok and reason == "full" then
                    GamePrint(ui.tr("$mcm_inventory_full_spawned", "Inventory full — spawned nearby") .. ": " .. entry.display_name)
                elseif not ok then
                    report_create_failure(entry.display_name)
                end
            else
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
    ui.end_scroll_viewport(scroll, math.ceil(visible / columns) * ui.ICON_STEP)
    if drag_drop.active() then
        local payload = drag_drop.payload()
        local mouse_x, mouse_y = drag_drop.mouse_position()
        if type(payload) == "table" and (payload.kind == "catalog_item" or payload.kind == "catalog_liquid") then
            ui.drag_ghost(payload.background, payload.icon, mouse_x, mouse_y, {bottle_fill_color=payload.bottle_fill_color})
        end
    end
    GuiLayoutEnd(ui.gui())
end

return items_tab
