local spells_tab = {}

local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local audit = ui.audit
local spell_service = dofile("mods/metamorph_creative_menu/files/features/spells/service.lua")
local spell_catalog = dofile("mods/metamorph_creative_menu/files/features/spells/catalog.lua")
local horizontal_strip = dofile("mods/metamorph_creative_menu/files/ui/widgets/horizontal_strip.lua")
local wand_editor = dofile("mods/metamorph_creative_menu/files/ui/components/wand_editor.lua")
local wand_presets = dofile("mods/metamorph_creative_menu/files/ui/components/wand_presets.lua")
local drag_drop = dofile("mods/metamorph_creative_menu/files/ui/drag_drop.lua")
local wand_history = dofile("mods/metamorph_creative_menu/files/features/wands/history.lua")
local spell_inventory_ui = dofile("mods/metamorph_creative_menu/files/ui/components/spell_inventory_strip.lua")
local spell_inventory_service = dofile("mods/metamorph_creative_menu/files/features/spells/inventory_service.lua")
local permanent_service = dofile("mods/metamorph_creative_menu/files/features/spells/permanent_service.lua")
local always_cast_ui = dofile("mods/metamorph_creative_menu/files/ui/components/wand_always_cast_strip.lua")
local inventory_slots = dofile("mods/metamorph_creative_menu/files/platform/noita/inventory_slots.lua")

local action_by_id, filters = nil, nil
local selected_filter = 1
local selected_slot = 0
local workspace = "catalog"
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
    local result = ui.rank_entries(query, actions_for_filter(index), function(action)
        local name, description = action_presentation(action)
        return {action.name, action.description, name, action.id, description}
    end, function(action) return action.id end)
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

local function drag_payload_for_action(action)
    return {
        kind="catalog_spell", action_id=action.id,
        icon=icon(action), background=background(action),
    }
end

local function drag_bounds(x, y, width, height)
    if x == nil or y == nil or width == nil or height == nil then return nil end
    return {x=x, y=y, width=width, height=height}
end

local function point_inside(bounds, x, y)
    if type(bounds) ~= "table" or tonumber(x) == nil or tonumber(y) == nil then return false end
    local bx, by = tonumber(bounds.x), tonumber(bounds.y)
    local bw, bh = tonumber(bounds.width), tonumber(bounds.height)
    return bx ~= nil and by ~= nil and bw ~= nil and bh ~= nil
        and x >= bx and x <= bx + bw and y >= by and y <= by + bh
end

local function record_result(scope, ok, reason)
    audit(scope, "result=" .. tostring(ok) .. " reason=" .. tostring(reason or ""))
    return ok, reason
end


local function mutate_wand(player, wand, label, callback, options)
    return wand_history.perform(player, wand, label, callback, options)
end

local function source_entry_for_payload(payload, slots, entries)
    if type(payload) ~= "table" or payload.kind ~= "wand_spell" then return nil end
    local direct = slots[tonumber(payload.slot)]
    if direct ~= nil and tonumber(direct.entity) == tonumber(payload.entity) then return direct end
    for _, entry in ipairs(entries or {}) do
        if tonumber(entry.entity) == tonumber(payload.entity) then return entry end
    end
    return nil
end

local function permanent_entry_for_payload(payload, permanent_entries)
    if type(payload) ~= "table" or payload.kind ~= "wand_permanent_spell" then return nil end
    for _, entry in ipairs(permanent_entries or {}) do
        if tonumber(entry.entity) == tonumber(payload.entity) then return entry end
    end
    return nil
end

local function inventory_entry_for_payload(payload, layout)
    if type(payload) ~= "table" or payload.kind ~= "inventory_spell" or type(layout) ~= "table" then return nil end
    local direct = layout.by_index and layout.by_index[tonumber(payload.index)] or nil
    if direct ~= nil and tonumber(direct.entity) == tonumber(payload.entity) then return direct end
    for _, entry in ipairs(layout.entries or {}) do
        if tonumber(entry.entity) == tonumber(payload.entity) then return entry end
    end
    return nil
end

function spells_tab.draw(player, panel_width, screen_height)
    if not load_actions() then
        ui.white_text(0, 2, ui.tr("$mcm_spells_failed", "Spell list failed to load")); return
    end
    refresh_presentation_locale()
    local wand = spell_service.held_wand(player)
    if wand == 0 then ui.white_text(0, 2, ui.tr("$mcm_hold_wand", "Hold a wand")); return end

    local screen_width, actual_screen_height = GuiGetScreenDimensions(ui.gui())
    local workspace_content_width = math.max(ui.ICON_STEP, panel_width - 16)
    local slots, highest, permanent, entries, permanent_entries = spell_service.contents(wand)
    local cap = spell_service.capacity(wand, highest, permanent)
    if tracked_wand ~= wand then
        tracked_wand, selected_slot = wand, 0
        horizontal_strip.reset("spells.wand_slots")
        horizontal_strip.reset("spells.inventory_slots")
        horizontal_strip.reset("spells.always_cast")
    end
    selected_slot = math.max(0, math.min(selected_slot, cap - 1))

    -- A short catalog click keeps the fast "click -> selected slot" workflow. A real
    -- drag is resolved by where the press is released: native spell inventory if the
    -- pointer is over it, otherwise the game world when released outside this menu.
    local previous_drag = drag_drop.take_result()
    if previous_drag ~= nil and previous_drag.click == true and type(previous_drag.payload) == "table"
        and previous_drag.payload.kind == "catalog_spell"
    then
        local ok, reason = mutate_wand(player, wand, "replace spell", function()
            return spell_service.replace(player, wand, selected_slot,
                previous_drag.payload.action_id, slots[selected_slot], entries)
        end)
        record_result("spell.replace", ok, reason)
        slots, highest, permanent, entries, permanent_entries = spell_service.contents(wand)
        cap = spell_service.capacity(wand, highest, permanent)
        selected_slot = math.max(0, math.min(selected_slot, cap - 1))
    elseif previous_drag ~= nil and previous_drag.click ~= true and previous_drag.target == nil
        and type(previous_drag.payload) == "table"
    then
        local release_x, release_y = tonumber(previous_drag.release_x), tonumber(previous_drag.release_y)
        local menu_bounds = type(ui.panel_bounds) == "function" and ui.panel_bounds() or nil
        -- Missing a target inside the creative menu means "cancel", not "spawn a card".
        -- Only crossing the actual menu boundary turns the gesture into a world/native-UI drop.
        if release_x ~= nil and release_y ~= nil and not point_inside(menu_bounds, release_x, release_y) then
            local payload = previous_drag.payload
            local native_inventory = inventory_slots.native_drop_bounds(player, "inventory_full", screen_width, actual_screen_height)
            local over_native_inventory = point_inside(native_inventory, release_x, release_y)
            local ok, reason

            if over_native_inventory then
                if payload.kind == "catalog_spell" then
                    ok, reason = spell_service.give(player, payload.action_id)
                elseif payload.kind == "inventory_spell" then
                    ok, reason = true, "already_in_inventory"
                elseif payload.kind == "wand_permanent_spell" then
                    local source_entry = permanent_entry_for_payload(payload, permanent_entries)
                    if source_entry == nil then ok, reason = false, "source_missing"
                    else ok, reason = permanent_service.move_to_inventory(player, wand, source_entry) end
                elseif payload.kind == "wand_spell" then
                    local source_entry = source_entry_for_payload(payload, slots, entries)
                    if source_entry == nil then ok, reason = false, "source_missing"
                    else ok, reason = spell_service.move_to_inventory(player, wand, source_entry, entries) end
                end
                if ok ~= nil then record_result("spell.drag.native_inventory", ok, reason) end
            else
                local target_x, target_y = tonumber(previous_drag.world_x), tonumber(previous_drag.world_y)
                if payload.kind == "catalog_spell" then
                    ok, reason = spell_service.throw_catalog(player, payload.action_id, target_x, target_y)
                elseif payload.kind == "inventory_spell" then
                    local layout = select(1, spell_inventory_service.contents(player))
                    local source_entry = inventory_entry_for_payload(payload, layout)
                    if source_entry == nil then
                        ok, reason = false, "source_missing"
                    else
                        ok, reason = spell_inventory_service.drop_to_world(player, source_entry, target_x, target_y)
                    end
                elseif payload.kind == "wand_permanent_spell" then
                    local source_entry = permanent_entry_for_payload(payload, permanent_entries)
                    if source_entry == nil then
                        ok, reason = false, "source_missing"
                    else
                        ok, reason = permanent_service.drop_to_world(player, wand, source_entry, target_x, target_y)
                    end
                elseif payload.kind == "wand_spell" then
                    local source_entry = source_entry_for_payload(payload, slots, entries)
                    if source_entry == nil then
                        ok, reason = false, "source_missing"
                    else
                        ok, reason = spell_service.drop_to_world(player, wand, source_entry, entries, target_x, target_y)
                    end
                end
                if ok ~= nil then record_result("spell.drag.world", ok, reason) end
            end

            if ok and (payload.kind == "wand_spell" or payload.kind == "wand_permanent_spell") then
                slots, highest, permanent, entries, permanent_entries = spell_service.contents(wand)
                cap = spell_service.capacity(wand, highest, permanent)
                selected_slot = math.max(0, math.min(selected_slot, cap - 1))
            end
        end
    end

    local inventory_layout = nil
    local workspace_drag_clip = nil

    local function draw_trash_zone()
        local _, _, _, x, y, width, height = ui.tile(0, 0,
            "data/ui_gfx/inventory/full_inventory_box.png",
            "data/ui_gfx/cross_red.png", ui.EMPTY_SLOT,
            ui.tr("$mcm_delete", "DELETE"), "", false,
            {target_size=14, max_scale=2.0, padding=2})
        local bounds = drag_bounds(x, y, width, height)
        if bounds == nil then return end
        drag_drop.target("spells.zone.trash", bounds,
            function(payload)
                return type(payload) == "table" and (payload.kind == "catalog_spell"
                    or payload.kind == "wand_spell" or payload.kind == "wand_permanent_spell"
                    or payload.kind == "inventory_spell")
            end,
            function(payload)
                if payload.kind == "catalog_spell" then
                    audit("spell.drag.discard_template", "action=" .. tostring(payload.action_id or ""))
                    return true, "discarded_template"
                elseif payload.kind == "inventory_spell" then
                    local layout = inventory_layout or select(1, spell_inventory_service.contents(player))
                    local source_entry = inventory_entry_for_payload(payload, layout)
                    if source_entry == nil then return false, "source_missing" end
                    local ok, reason = spell_inventory_service.remove(player, source_entry, false)
                    return record_result("spell.drag.inventory_delete", ok, reason)
                elseif payload.kind == "wand_permanent_spell" then
                    local source_entry = permanent_entry_for_payload(payload, permanent_entries)
                    if source_entry == nil then return false, "source_missing" end
                    local ok, reason = mutate_wand(player, wand, "delete always cast", function()
                        return permanent_service.remove(player, wand, source_entry, false)
                    end)
                    return record_result("spell.drag.always_delete", ok, reason)
                end
                local source_entry = source_entry_for_payload(payload, slots, entries)
                if source_entry == nil then return false, "source_missing" end
                local ok, reason = mutate_wand(player, wand, "delete spell", function()
                    return spell_service.remove(player, wand, source_entry, entries, false)
                end)
                return record_result("spell.drag.delete", ok, reason)
            end, 200)
    end

    local function draw_slot_strip()
        GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
        ui.white_text(0, 1, ui.tr("$mcm_spell_wand_slots", "WAND SLOTS"))
        ui.white_text(0, 1, "  " .. ui.tr("$mcm_slot", "SLOT") .. " " .. tostring(selected_slot + 1) .. "/" .. tostring(cap))
        GuiLayoutAddHorizontalSpacing(ui.gui(), 4)
        draw_trash_zone()
        GuiLayoutEnd(ui.gui())

        local strip = horizontal_strip.draw("spells.wand_slots", cap, math.max(ui.ICON_STEP, workspace_content_width - 8), ui.ICON_STEP, function(slot)
            local entry = slots[slot]
            local action = entry and action_by_id[entry.action_id] or nil
            local slot_name
            if entry == nil then
                slot_name = ui.tr("$mcm_empty", "Empty")
            elseif action ~= nil then
                slot_name = select(1, action_presentation(action))
            else
                slot_name = ui.tr("$mcm_spell_unknown", "Unknown/modded spell") .. " [" .. tostring(entry.action_id or "?") .. "]"
            end
            local clicked, right, hovered, x, y, width, height = ui.tile(0, 0, background(action), icon(action), ui.EMPTY_SLOT,
                ui.tr("$mcm_slot", "SLOT") .. " " .. tostring(slot + 1), slot_name, slot == selected_slot,
                { target_size = 18, max_scale = 2.0 })
            local slot_bounds = drag_bounds(x, y, width, height)
            if entry ~= nil and slot_bounds ~= nil then
                drag_drop.source("spells.slot." .. tostring(entry.entity), {
                    kind="wand_spell", slot=slot, entity=entry.entity, action_id=entry.action_id,
                    icon=icon(action), background=background(action),
                }, slot_bounds, workspace_drag_clip)
            end
            if slot_bounds ~= nil then
                drag_drop.target("spells.slot_target." .. tostring(slot), slot_bounds,
                    function(payload)
                        return type(payload) == "table" and (payload.kind == "catalog_spell" or payload.kind == "wand_spell"
                            or payload.kind == "wand_permanent_spell" or payload.kind == "inventory_spell")
                    end,
                    function(payload)
                        local ok, reason
                        if payload.kind == "catalog_spell" then
                            ok, reason = mutate_wand(player, wand, "replace spell", function()
                                return spell_service.replace(player, wand, slot, payload.action_id, slots[slot], entries)
                            end)
                        elseif payload.kind == "inventory_spell" then
                            local source_entry = inventory_entry_for_payload(payload, inventory_layout)
                            if source_entry == nil then return false, "source_missing" end
                            ok, reason = spell_service.adopt_inventory(player, wand, source_entry, slot, slots[slot], entries)
                        elseif payload.kind == "wand_permanent_spell" then
                            local source_entry = permanent_entry_for_payload(payload, permanent_entries)
                            if source_entry == nil then return false, "source_missing" end
                            if slots[slot] ~= nil then
                                ok, reason = mutate_wand(player, wand, "swap always cast", function()
                                    return permanent_service.swap_with_slot(player, wand, source_entry, slots[slot])
                                end)
                            else
                                ok, reason = mutate_wand(player, wand, "demote always cast", function()
                                    return permanent_service.demote(player, wand, source_entry, slot)
                                end)
                            end
                        else
                            local source_entry = source_entry_for_payload(payload, slots, entries)
                            if source_entry == nil then return false, "source_missing" end
                            ok, reason = mutate_wand(player, wand, "move spell", function()
                                return spell_service.move(player, wand, source_entry, slot, slots[slot], entries)
                            end)
                        end
                        if ok then selected_slot = slot end
                        return record_result("spell.drag.slot", ok, reason)
                    end, 100)
            end
            return clicked, right, hovered, x, y, width, height
        end, {
            gui=ui.gui(), screen_width=screen_width, screen_height=screen_height,
        })
        if strip.clicked ~= nil then selected_slot = strip.clicked end
        if strip.right_clicked ~= nil and slots[strip.right_clicked] ~= nil then
            selected_slot = strip.right_clicked
            local ok, reason = spell_service.remove(player, wand, slots[selected_slot], entries, true)
            record_result("spell.drop", ok, reason)
        end
        if cap > strip.visible_count then
            ui.white_text(0, 0, tostring(strip.first + 1) .. "-" .. tostring(strip.last + 1) .. " / " .. tostring(cap)
                .. "   " .. ui.tr("$mcm_wand_strip_hint", "wheel to scroll"))
        end
    end

    local function draw_always_cast()
        always_cast_ui.draw(permanent_entries, workspace_content_width, screen_width, screen_height, action_presentation, {
            action_by_id=action_by_id, background=background, icon=icon,
            on_add_click=function()
                local entry = slots[selected_slot]
                if entry == nil then return record_result("spell.always.promote", false, "empty_slot") end
                local ok, reason = mutate_wand(player, wand, "promote always cast", function()
                    return permanent_service.promote(player, wand, entry)
                end)
                return record_result("spell.always.promote", ok, reason)
            end,
            on_add_drop=function(payload)
                local ok, reason
                if payload.kind == "catalog_spell" then
                    ok, reason = mutate_wand(player, wand, "add always cast", function()
                        return permanent_service.add(player, wand, payload.action_id)
                    end)
                elseif payload.kind == "wand_spell" then
                    local source_entry = source_entry_for_payload(payload, slots, entries)
                    if source_entry == nil then return false, "source_missing" end
                    ok, reason = mutate_wand(player, wand, "promote always cast", function()
                        return permanent_service.promote(player, wand, source_entry)
                    end)
                elseif payload.kind == "inventory_spell" then
                    local source_entry = inventory_entry_for_payload(payload, inventory_layout)
                    if source_entry == nil then return false, "source_missing" end
                    ok, reason = permanent_service.adopt_inventory(player, wand, source_entry)
                else
                    return false, "unsupported_source"
                end
                return record_result("spell.drag.always", ok, reason)
            end,
            on_replace_drop=function(permanent_entry, payload)
                local ok, reason
                if payload.kind == "catalog_spell" then
                    ok, reason = mutate_wand(player, wand, "replace always cast", function()
                        return permanent_service.replace(player, wand, permanent_entry, payload.action_id)
                    end)
                elseif payload.kind == "wand_spell" then
                    local source_entry = source_entry_for_payload(payload, slots, entries)
                    if source_entry == nil then return false, "source_missing" end
                    ok, reason = mutate_wand(player, wand, "swap always cast", function()
                        return permanent_service.swap_with_slot(player, wand, permanent_entry, source_entry)
                    end)
                elseif payload.kind == "inventory_spell" then
                    local source_entry = inventory_entry_for_payload(payload, inventory_layout)
                    if source_entry == nil then return false, "source_missing" end
                    ok, reason = permanent_service.swap_with_inventory(player, wand, permanent_entry, source_entry)
                else
                    return false, "unsupported_source"
                end
                return record_result("spell.drag.always_replace", ok, reason)
            end,
            on_right_click=function(entry)
                local ok, reason = permanent_service.remove(player, wand, entry, true)
                record_result("spell.always.drop", ok, reason)
            end,
            clip_bounds=workspace_drag_clip,
        })
    end

    local function draw_inventory()
        inventory_layout = select(1, spell_inventory_ui.draw(player, workspace_content_width, screen_width, screen_height, action_presentation, {
            action_by_id=action_by_id, background=background, icon=icon,
            on_drop=function(target_index, target_entry, payload, layout)
                local ok, reason
                if payload.kind == "catalog_spell" then
                    ok, reason = spell_inventory_service.create_at(player, payload.action_id, target_index)
                elseif payload.kind == "inventory_spell" then
                    local source_entry = inventory_entry_for_payload(payload, layout)
                    if source_entry == nil then return false, "source_missing" end
                    ok, reason = spell_inventory_service.move(player, source_entry, target_index)
                elseif payload.kind == "wand_permanent_spell" then
                    local source_entry = permanent_entry_for_payload(payload, permanent_entries)
                    if source_entry == nil then return false, "source_missing" end
                    if target_entry ~= nil then
                        ok, reason = permanent_service.swap_with_inventory(player, wand, source_entry, target_entry)
                    else
                        local x = target_index % layout.width
                        local y = math.floor(target_index / layout.width)
                        ok, reason = permanent_service.export_to_inventory_slot(player, wand, source_entry, x, y)
                    end
                else
                    local source_entry = source_entry_for_payload(payload, slots, entries)
                    if source_entry == nil then return false, "source_missing" end
                    if target_entry ~= nil then
                        ok, reason = spell_service.adopt_inventory(player, wand, target_entry, source_entry.slot, source_entry, entries)
                    else
                        local x = target_index % layout.width
                        local y = math.floor(target_index / layout.width)
                        ok, reason = spell_service.export_to_inventory_slot(player, wand, source_entry, entries, x, y)
                    end
                end
                return record_result("spell.drag.inventory_slot", ok, reason)
            end,
            on_right_click=function(entry)
                local ok, reason = spell_inventory_service.remove(player, entry, true)
                record_result("spell.inventory.drop", ok, reason)
            end,
            clip_bounds=workspace_drag_clip,
        }))
    end

    local function draw_catalog()
        ui.wrapped_text(0, 0, ui.tr("$mcm_spell_controls_hint",
            "LMB spell: replace selected slot. Drag: slot / Always Cast / inventory."),
            math.max(96, workspace_content_width - 8))
        draw_slot_strip()
        draw_always_cast()
        draw_inventory()

        local filter_buttons = {}
        for index, f in ipairs(filters) do
            filter_buttons[index] = {label=ui.tr(f.key, f.fallback),selected=selected_filter == index}
        end
        local clicked_filter = ui.button_grid(filter_buttons, math.max(72, workspace_content_width - 8))
        if clicked_filter ~= nil then selected_filter = clicked_filter end
        search = ui.search_input(search, math.max(88, workspace_content_width - 44), 64, "spells")
        local visible_actions = actions_for_search(selected_filter, search)
        ui.search_status(search, #visible_actions)
        if #visible_actions == 0 then
            if search == "" then ui.white_text(2, 2, ui.tr("$mcm_no_results", "No results")) end
            return
        end

        local columns = ui.columns(workspace_content_width, ui.ICON_STEP, {reserve_scrollbar=false})
        local cursor = 1
        while cursor <= #visible_actions do
            GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
            for _ = 1, columns do
                local action = visible_actions[cursor]
                if action == nil then break end
                local name, description = action_presentation(action)
                local _, _, _, tile_x, tile_y, tile_w, tile_h = ui.tile(0, 0, background(action), icon(action), ui.EMPTY_SLOT,
                    name .. " [" .. action.id .. "]", description, false,
                    { target_size = 18, max_scale = 2.0 })
                local tile_bounds = drag_bounds(tile_x, tile_y, tile_w, tile_h)
                if tile_bounds ~= nil then
                    drag_drop.source("spells.catalog." .. tostring(action.id), drag_payload_for_action(action),
                        tile_bounds, workspace_drag_clip)
                end
                cursor = cursor + 1
            end
            GuiLayoutEnd(ui.gui())
        end
    end

    local function draw_wand_tools()
        wand_editor.draw(player, wand, workspace_content_width)
        wand_presets.draw(player, wand, workspace_content_width)
    end

    GuiLayoutBeginVertical(ui.gui(), 0, 2, true)
    local workspace_items = {
        {label=ui.tr("$mcm_spell_workspace_catalog", "CATALOG"), selected=workspace == "catalog"},
        {label=ui.tr("$mcm_spell_workspace_wand", "WAND"), selected=workspace == "wand"},
    }
    local workspace_clicked = ui.button_grid(workspace_items, panel_width - 10)
    if workspace_clicked == 1 then workspace = "catalog"
    elseif workspace_clicked == 2 then workspace = "wand" end

    -- The entire active workspace lives inside one bounded vertical viewport. This is the
    -- key containment rule for the spells tab: no combination of translated labels,
    -- expanded wand tools or inventory rows is allowed to grow the menu beyond its panel.
    local workspace_height = ui.scroll_height(screen_height, 26, 8)
    workspace_height = math.max(28, math.min(workspace_height, math.max(28, screen_height - 22)))
    local workspace_id = workspace == "catalog" and (8300 + selected_filter) or 8402
    local workspace_scroll = ui.begin_scroll_viewport("spells.workspace." .. workspace, workspace_id,
        0, 0, panel_width - 4, workspace_height)
    workspace_content_width = workspace_scroll.content_width
    workspace_drag_clip = {
        x=workspace_scroll.x, y=workspace_scroll.y,
        width=math.max(1, workspace_scroll.width - workspace_scroll.scrollbar_width),
        height=workspace_scroll.height,
    }

    if workspace == "wand" then draw_wand_tools()
    else draw_catalog() end

    ui.end_scroll_viewport(workspace_scroll)

    if drag_drop.active() then
        local payload = drag_drop.payload()
        local mouse_x, mouse_y = drag_drop.mouse_position()
        if type(payload) == "table" then ui.drag_ghost(payload.background, payload.icon, mouse_x, mouse_y) end
    end
    GuiLayoutEnd(ui.gui())
end

return spells_tab
