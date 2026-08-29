if type(METAMORPH_CREATIVE_MENU_WAND_ALWAYS_CAST_UI) == "table" then
    return METAMORPH_CREATIVE_MENU_WAND_ALWAYS_CAST_UI
end

local always_cast_ui = {}
local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local horizontal_strip = dofile("mods/metamorph_creative_menu/files/ui/widgets/horizontal_strip.lua")
local drag_drop = dofile("mods/metamorph_creative_menu/files/ui/drag_drop.lua")

local function bounds(x, y, width, height)
    if x == nil or y == nil or width == nil or height == nil then return nil end
    return {x=x, y=y, width=width, height=height}
end

local function payload_allowed(payload)
    return type(payload) == "table" and (payload.kind == "catalog_spell"
        or payload.kind == "wand_spell" or payload.kind == "inventory_spell")
end

function always_cast_ui.draw(permanent_entries, panel_width, screen_width, screen_height, presentation, options)
    permanent_entries = type(permanent_entries) == "table" and permanent_entries or {}
    options = type(options) == "table" and options or {}

    GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
    ui.white_text(0, 1, ui.tr("$mcm_wand_always_cast", "ALWAYS CAST"))
    local add_clicked, _, add_x, add_y, add_w, add_h = ui.button(0, 0, "   +   ")
    local add_bounds = bounds(add_x, add_y, add_w, add_h)
    if add_bounds ~= nil then
        drag_drop.target("spells.always_cast.add", add_bounds, payload_allowed, function(payload)
            if type(options.on_add_drop) ~= "function" then return false, "drop_unavailable" end
            return options.on_add_drop(payload)
        end, 110)
    end
    GuiLayoutEnd(ui.gui())
    if add_clicked and type(options.on_add_click) == "function" then options.on_add_click() end

    if #permanent_entries == 0 then
        ui.wrapped_text(0, 0, ui.tr("$mcm_wand_always_cast_empty", "Drop a spell on + to make it Always Cast."), panel_width - 12)
        return {first=0,last=-1,visible_count=0}
    end

    local strip = horizontal_strip.draw("spells.always_cast", #permanent_entries, panel_width - 10, ui.ICON_STEP,
        function(index)
            local entry = permanent_entries[index + 1]
            local action = entry and options.action_by_id and options.action_by_id[entry.action_id] or nil
            local name, description
            if action ~= nil and type(presentation) == "function" then
                name, description = presentation(action)
            else
                name = ui.tr("$mcm_spell_unknown", "Unknown/modded spell") .. " [" .. tostring(entry and entry.action_id or "?") .. "]"
                description = ""
            end
            local background = type(options.background) == "function" and options.background(action) or ui.EMPTY_SLOT
            local icon = type(options.icon) == "function" and options.icon(action) or ui.EMPTY_SLOT
            local _, right, hovered, x, y, width, height = ui.tile(0, 0, background, icon, ui.EMPTY_SLOT,
                ui.tr("$mcm_wand_always_cast", "ALWAYS CAST"), name .. (description ~= "" and ("\n" .. description) or ""), true,
                {target_size=18,max_scale=2.0})

            local target_bounds = bounds(x, y, width, height)
            if entry ~= nil and target_bounds ~= nil then
                drag_drop.source("spells.always_cast.source." .. tostring(entry.entity), {
                    kind="wand_permanent_spell", entity=entry.entity, action_id=entry.action_id,
                    icon=icon, background=background,
                }, target_bounds, options.clip_bounds)
            end
            if target_bounds ~= nil then
                drag_drop.target("spells.always_cast.target." .. tostring(entry.entity), target_bounds,
                    function(payload)
                        return type(payload) == "table" and (payload.kind == "catalog_spell"
                            or payload.kind == "wand_spell" or payload.kind == "inventory_spell")
                    end,
                    function(payload)
                        if type(options.on_replace_drop) ~= "function" then return false, "drop_unavailable" end
                        return options.on_replace_drop(entry, payload)
                    end, 120)
            end
            if right and type(options.on_right_click) == "function" then options.on_right_click(entry) end
            return false, false, hovered, x, y, width, height
        end,
        {gui=ui.gui(), screen_width=screen_width, screen_height=screen_height})

    if #permanent_entries > strip.visible_count then
        ui.white_text(0, 0, tostring(strip.first + 1) .. "-" .. tostring(strip.last + 1) .. " / " .. tostring(#permanent_entries)
            .. "   " .. ui.tr("$mcm_wand_strip_hint", "wheel to scroll"))
    end
    return strip
end

METAMORPH_CREATIVE_MENU_WAND_ALWAYS_CAST_UI = always_cast_ui
return always_cast_ui
