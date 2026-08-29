if type(METAMORPH_CREATIVE_MENU_SPELL_INVENTORY_UI) == "table" then return METAMORPH_CREATIVE_MENU_SPELL_INVENTORY_UI end

local spell_inventory_ui = {}
local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local horizontal_strip = dofile("mods/metamorph_creative_menu/files/ui/widgets/horizontal_strip.lua")
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

    local strip = horizontal_strip.draw("spells.inventory_slots", layout.capacity, panel_width - 10, ui.ICON_STEP, function(index)
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
    end, {
        gui=ui.gui(), screen_width=screen_width, screen_height=screen_height,
    })

    if layout.capacity > strip.visible_count then
        ui.white_text(0, 0, tostring(strip.first + 1) .. "-" .. tostring(strip.last + 1) .. " / " .. tostring(layout.capacity)
            .. "   " .. ui.tr("$mcm_wand_strip_hint", "wheel to scroll"))
    end
    return layout, "ok"
end

METAMORPH_CREATIVE_MENU_SPELL_INVENTORY_UI = spell_inventory_ui
return spell_inventory_ui
