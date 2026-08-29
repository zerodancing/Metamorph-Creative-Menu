if type(METAMORPH_CREATIVE_MENU_WAND_PRESETS_UI) == "table" then return METAMORPH_CREATIVE_MENU_WAND_PRESETS_UI end

local wand_presets = {}
local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local presets = dofile("mods/metamorph_creative_menu/files/features/wands/presets.lua")
local history = dofile("mods/metamorph_creative_menu/files/features/wands/history.lua")

local expanded = false
local name = ""
local confirm_delete = nil
local LIST_GUI_ID = 17820
local DEFAULT_WAND_ICON = "data/items_gfx/handgun.xml"

local function set_status(ok, reason)
    if ok then ui.clear_error_notice("wand.presets")
    else ui.report_error_once("wand.presets", ui.tr("$mcm_wand_preset_error", "Preset error"), reason, "wand.presets") end
    return ok
end

local function preset_icon(preset)
    local blueprint = type(preset) == "table" and preset.blueprint or nil
    local meta = type(blueprint) == "table" and type(blueprint.meta) == "table" and blueprint.meta or {}
    return ui.resolve(meta.image_file) or ui.resolve(type(blueprint) == "table" and blueprint.sprite_file or nil)
        or ui.resolve(DEFAULT_WAND_ICON) or DEFAULT_WAND_ICON
end

local function draw_preset_icon(preset)
    local icon = preset_icon(preset)
    local width, height = ui.dimensions(icon)
    width, height = math.max(1, tonumber(width) or 16), math.max(1, tonumber(height) or 16)
    local scale = math.min(14 / width, 14 / height, 1.5)
    GuiZSetForNextWidget(ui.gui(), -103)
    GuiImage(ui.gui(), ui.next_id(), 0, 0, icon, 1, scale, scale)
end

local function draw_preset_card(index, preset, player, wand, content_width)
    content_width = math.max(48, tonumber(content_width) or 120)
    GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
    draw_preset_icon(preset)
    ui.white_text(2, 1, ui.truncate_text(tostring(preset.name), math.max(24, content_width - 20)))
    GuiLayoutEnd(ui.gui())

    local apply_label = ui.tr("$mcm_wand_preset_apply", "APPLY")
    local copy_label = ui.tr("$mcm_wand_preset_copy", "GET COPY")
    local delete_label = confirm_delete == index and ui.tr("$mcm_confirm", "CONFIRM") or "X"
    local clicked = ui.button_grid({
        {label=apply_label,tooltip_title=apply_label,tooltip_description=ui.tr("$mcm_wand_preset_apply_hint", "Apply to the held wand")},
        {label=copy_label,tooltip_title=copy_label,tooltip_description=ui.tr("$mcm_wand_preset_copy_hint", "Create a separate saved wand")},
        {label=delete_label},
    }, math.max(32, content_width - 16))
    if clicked == 1 then
        local ok, reason = history.perform(player, wand, "load preset", function()
            return presets.load(index, player, wand)
        end)
        set_status(ok, reason); confirm_delete = nil
    elseif clicked == 2 then
        local ok, reason = presets.give(index, player)
        set_status(ok, reason); confirm_delete = nil
    elseif clicked == 3 then
        if confirm_delete == index then
            local ok, reason = presets.delete(index)
            set_status(ok, reason); confirm_delete = nil
        else
            confirm_delete = index
        end
    end
    GuiLayoutAddVerticalSpacing(ui.gui(), 2)
end

function wand_presets.draw(player, wand, panel_width)
    panel_width = math.max(48, tonumber(panel_width) or 220)
    local label = (expanded and "- " or "+ ") .. ui.tr("$mcm_wand_presets", "WAND PRESETS")
    if ui.button_grid({{label=label,selected=expanded,tooltip_title=ui.tr("$mcm_wand_presets", "WAND PRESETS")}},
        math.max(32,panel_width-12)) == 1 then expanded = not expanded end
    if not expanded then return end

    name = ui.text_input(name, math.max(36, panel_width - 12), 40, "wand.preset_name", {
        escape_clears=false,
    })
    if ui.button_grid({{label=ui.tr("$mcm_save", "SAVE")}}, math.max(32, panel_width - 12)) == 1 then
        local ok, reason = presets.save(name, wand)
        set_status(ok, reason)
    end

    local list = presets.all()
    if #list == 0 then
        ui.white_text(0, 0, ui.tr("$mcm_wand_no_presets", "No saved wands"))
    else
        local height = math.min(96, math.max(28, #list * 31 + 4))
        local scroll = ui.begin_scroll_viewport("wand.presets", LIST_GUI_ID, 0, 0, panel_width - 8, height)
        for index, preset in ipairs(list) do
            draw_preset_card(index, preset, player, wand, scroll.content_width)
        end
        ui.end_scroll_viewport(scroll)
    end
end

METAMORPH_CREATIVE_MENU_WAND_PRESETS_UI = wand_presets
return wand_presets
