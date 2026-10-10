if type(METAMORPH_CREATIVE_MENU_WAND_SKIN_PICKER_UI) == "table" then return METAMORPH_CREATIVE_MENU_WAND_SKIN_PICKER_UI end

local skin_picker = {}
local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local skins = dofile("mods/metamorph_creative_menu/files/features/wands/skins.lua")
local appearance = dofile("mods/metamorph_creative_menu/files/features/wands/appearance.lua")
local history = dofile("mods/metamorph_creative_menu/files/features/wands/history.lua")

local expanded = false
local search = ""
local SCROLL_ID = 17841

local function apply_skin(player, wand, entry)
    return history.perform(player, wand, "skin", function()
        return appearance.set_visual(player, wand, {
            sprite_file=entry.sprite_file, image_file=entry.image_file,
            offset_x=entry.offset_x, offset_y=entry.offset_y,
            tip_x=entry.tip_x, tip_y=entry.tip_y,
        })
    end, {coalesce_key="skin", coalesce_frames=8})
end

function skin_picker.draw(player, wand, current_visual, panel_width)
    local label = (expanded and "- " or "+ ") .. ui.tr("$mcm_wand_skins", "SKINS")
    if ui.button_grid({{label=label,selected=expanded,tooltip_title=ui.tr("$mcm_wand_skins", "SKINS")}},
        math.max(32,(tonumber(panel_width) or 220)-12)) == 1 then expanded = not expanded end
    if not expanded then return false, nil end

    search = ui.search_input(search, math.max(68, (tonumber(panel_width) or 220) - 28), 64, "wand.skins")
    local current_sprite = type(current_visual) == "table" and current_visual.sprite_file or current_visual
    local current_image = type(current_visual) == "table" and current_visual.image_file or current_sprite
    local all = skins.entries()
    local matched = {}
    for _, entry in ipairs(all) do
        if search == "" or ui.search_score(search, entry.name, entry.source_path, entry.sprite_file, entry.image_file) ~= nil then
            matched[#matched + 1] = entry
        end
    end

    if #matched == 0 then
        ui.white_text(0, 0, ui.tr("$mcm_no_results", "No results"))
        return false, nil
    end

    local preliminary_columns = math.max(1, ui.columns(panel_width - 8))
    local rows = math.ceil(#matched / preliminary_columns)
    local height = math.min(76, math.max(22, rows * ui.ICON_STEP + 4))
    local scroll = ui.begin_scroll_viewport("wand.skins", SCROLL_ID, 0, 0, panel_width - 8, height, {layout="free"})
    local columns = math.max(1, ui.columns(scroll.content_width, ui.ICON_STEP, {reserve_scrollbar=false}))
    rows = math.ceil(#matched / columns)
    local changed, reason = false, nil
    for index, entry in ipairs(matched) do
        local i = index - 1
        local name = ui.translated(entry.name)
        if name == tostring(entry.name or "") and string.sub(tostring(entry.name or ""), 1, 1) ~= "$" then
            name = tostring(entry.name or entry.source_path or "Wand")
        end
        local details = tostring(entry.sprite_file)
        if entry.image_file ~= nil and tostring(entry.image_file) ~= tostring(entry.sprite_file) then
            details = details .. "\nimage " .. tostring(entry.image_file)
        end
        if entry.offset_x ~= nil and entry.offset_y ~= nil then
            details = details .. "\n" .. string.format("offset %.2g, %.2g", entry.offset_x, entry.offset_y)
        end
        local clicked = ui.tile(scroll.padding_left + (i % columns) * ui.ICON_STEP,
            ui.scroll_y(scroll, math.floor(i / columns) * ui.ICON_STEP),
            ui.EMPTY_SLOT, entry.icon, ui.EMPTY_SLOT,
            name, details,
            tostring(current_sprite or "") == tostring(entry.sprite_file)
                and tostring(current_image or current_sprite or "") == tostring(entry.image_file or entry.sprite_file),
            {target_size=18,max_scale=2.0})
        if clicked then
            local ok, err = apply_skin(player, wand, entry)
            changed, reason = ok, ok and nil or err
            if ok then current_sprite, current_image = entry.sprite_file, entry.image_file or entry.sprite_file end
        end
    end
    ui.end_scroll_viewport(scroll, rows * ui.ICON_STEP)
    return changed, reason
end

METAMORPH_CREATIVE_MENU_WAND_SKIN_PICKER_UI = skin_picker
return skin_picker
