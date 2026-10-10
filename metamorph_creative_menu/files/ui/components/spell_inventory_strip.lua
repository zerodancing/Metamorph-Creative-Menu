if type(METAMORPH_CREATIVE_MENU_SPELL_INVENTORY_UI) == "table" then return METAMORPH_CREATIVE_MENU_SPELL_INVENTORY_UI end

local spell_inventory_ui = {}
local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local drag_drop = dofile("mods/metamorph_creative_menu/files/ui/drag_drop.lua")
local inventory_service = dofile("mods/metamorph_creative_menu/files/features/spells/inventory_service.lua")

local function bounds(x,y,width,height)
    if x == nil or y == nil or width == nil or height == nil then return nil end
    return {x=x,y=y,width=width,height=height}
end

function spell_inventory_ui.draw(player, panel_width, screen_width, screen_height, presentation, options)
    options = type(options) == "table" and options or {}
    local layout, reason = inventory_service.contents(player)
    if layout == nil then return nil, reason end
    ui.white_text(0, 0, ui.tr("$mcm_spell_inventory", "SPELL INVENTORY"))

    -- The vanilla spell inventory is small (16 cells in the stock player) and should stay
    -- visible as one logical surface. Pagination made a narrow MCM panel show only a subset
    -- even though there was plenty of vertical room. Render every cell and wrap only the
    -- presentation rows; target_index still maps to Noita's original inventory coordinates.
    -- These are the native 18 px inventory cells, not catalog entries. Do not charge the
    -- catalog's 20 px pitch plus an artificial 10 px reserve: at the minimum MCM width
    -- that caused an early 8+8 wrap with visibly unused room. Pack by the actual slot
    -- footprint and wrap only when the next native cell genuinely cannot fit.
    local slot_pitch = 18
    local columns = math.max(1, math.floor(math.max(slot_pitch, (tonumber(panel_width) or slot_pitch) - 2) / slot_pitch))
    local function draw_slot(index)
        local entry = layout.by_index[index]
        local action = entry and options.action_by_id and options.action_by_id[entry.action_id] or nil
        local name, description
        if entry == nil then
            name, description = ui.tr("$mcm_empty", "Empty"), ""
        elseif action ~= nil and type(presentation) == "function" then
            name, description = presentation(action)
        else
            name = ui.tr("$mcm_spell_unknown", "Unknown/modded spell") .. " [" .. tostring(entry.action_id or "?") .. "]"
            description = ""
        end
        local background = type(options.background) == "function" and options.background(action) or ui.EMPTY_SLOT
        local icon = type(options.icon) == "function" and options.icon(action) or ui.EMPTY_SLOT
        local clicked, right, hovered, x, y, width, height = ui.tile(0, 0, background, icon, ui.EMPTY_SLOT,
            ui.tr("$mcm_inventory_slot", "INVENTORY") .. " " .. tostring(index + 1), name .. (description ~= "" and ("\n" .. description) or ""), false,
            {target_size=18,max_scale=2.0})
        local target_bounds = bounds(x,y,width,height)
        if entry ~= nil and target_bounds ~= nil then
            drag_drop.source("spells.inventory." .. tostring(entry.entity), {
                kind="inventory_spell", entity=entry.entity, index=index, action_id=entry.action_id,
                icon=icon, background=background,
            }, target_bounds, options.clip_bounds)
        end
        if target_bounds ~= nil then
            drag_drop.target("spells.inventory_target." .. tostring(index), target_bounds,
                function(payload)
                    return type(payload) == "table" and (payload.kind == "catalog_spell"
                        or payload.kind == "wand_spell" or payload.kind == "wand_permanent_spell"
                        or payload.kind == "inventory_spell")
                end,
                function(payload)
                    if type(options.on_drop) ~= "function" then return false, "drop_unavailable" end
                    return options.on_drop(index, entry, payload, layout)
                end, 95)
        end
        if right and entry ~= nil and type(options.on_right_click) == "function" then options.on_right_click(entry, layout) end
        return clicked, false, hovered, x, y, width, height
    end

    local cursor = 0
    while cursor < layout.capacity do
        GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true, 0, 0)
        for _ = 1, columns do
            if cursor >= layout.capacity then break end
            draw_slot(cursor)
            cursor = cursor + 1
        end
        GuiLayoutEnd(ui.gui())
    end

    return layout, "ok"
end

METAMORPH_CREATIVE_MENU_SPELL_INVENTORY_UI = spell_inventory_ui
return spell_inventory_ui
