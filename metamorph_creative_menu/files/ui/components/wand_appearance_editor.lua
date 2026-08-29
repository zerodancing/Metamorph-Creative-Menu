if type(METAMORPH_CREATIVE_MENU_WAND_APPEARANCE_EDITOR_UI) == "table" then return METAMORPH_CREATIVE_MENU_WAND_APPEARANCE_EDITOR_UI end

local appearance_editor = {}
local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local appearance = dofile("mods/metamorph_creative_menu/files/features/wands/appearance.lua")
local history = dofile("mods/metamorph_creative_menu/files/features/wands/history.lua")
local numeric = dofile("mods/metamorph_creative_menu/files/ui/components/fixed_numeric_editor.lua")
local skin_picker = dofile("mods/metamorph_creative_menu/files/ui/components/wand_skin_picker.lua")

local expanded = false
local tracked_wand = 0
local name_draft = ""
local sprite_draft = ""
local last_error = nil

local function report_error(reason)
    if reason == nil then return end
    reason = tostring(reason)
    if last_error == reason then return end
    last_error = reason
    local message = ui.tr("$mcm_wand_appearance_error", "Could not change appearance") .. ": " .. reason
    if type(GamePrint) == "function" then pcall(GamePrint, message) end
    if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE) == "function" then
        pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE, "wand.appearance", reason)
    end
end

local function clear_error()
    last_error = nil
end

local function perform(player, wand, label, callback, options)
    local ok, reason = history.perform(player, wand, label, callback, options)
    if ok then clear_error() else report_error(reason) end
    return ok, reason
end

local function reset(snapshot)
    name_draft = tostring(snapshot.name or "")
    sprite_draft = tostring(snapshot.sprite_file or snapshot.image_file or "")
    numeric.reset("wand.appearance.")
end

local function draw_unavailable(label, tooltip)
    local unavailable = ui.tr("$mcm_wand_geometry_unavailable", "NOT AVAILABLE FOR THIS WAND")
    ui.white_text(0, 1, tostring(label or "") .. ": " .. unavailable)
    if type(GuiTooltip) == "function" then GuiTooltip(ui.gui(), tostring(label or ""), tostring(tooltip or unavailable)) end
end

local function draw_geometry(player, wand, snapshot, id, label, value, key, panel_width, tooltip)
    if value == nil then
        draw_unavailable(label, tooltip)
        return
    end
    local _, reason = numeric.draw("wand.appearance." .. tostring(wand) .. "." .. id, label, value, {
        step=1, label_width=112, value_width=58, value_chars=18,
        max_width=math.max(64, (tonumber(panel_width) or 220) - 12),
        label_tooltip_description=tooltip,
        on_apply=function(new_value)
            local values = {}; values[key] = new_value
            return perform(player, wand, "appearance " .. id, function()
                return appearance.set_visual(player, wand, values)
            end, {coalesce_key="appearance." .. id,coalesce_frames=45})
        end,
    })
    if reason ~= nil then report_error(reason) end
end

function appearance_editor.draw(player, wand, panel_width)
    panel_width = math.max(48, tonumber(panel_width) or 220)
    local snapshot, reason = appearance.snapshot(wand)
    if snapshot == nil then return false, reason end
    if tracked_wand ~= wand then
        tracked_wand = wand
        reset(snapshot)
        clear_error()
    end

    local label = (expanded and "- " or "+ ") .. ui.tr("$mcm_wand_appearance", "APPEARANCE & LOCKS")
    if ui.button_grid({{label=label,selected=expanded,tooltip_title=ui.tr("$mcm_wand_appearance", "APPEARANCE & LOCKS")}},
        math.max(32,panel_width-12)) == 1 then expanded = not expanded end
    if not expanded then return true end

    -- Keep the native name field on its own row so narrow layouts cannot displace it;
    -- its semantic focus key preserves native input identity and the in-progress draft.
    ui.white_text(0, 1, ui.tr("$mcm_wand_name", "NAME"))
    name_draft = ui.text_input(name_draft, math.max(36, panel_width - 12), 80,
        "wand.name." .. tostring(wand), {escape_clears=false})
    if ui.button(0, 0, "  " .. ui.tr("$mcm_apply", "APPLY") .. "  ") then
        local current = select(1, appearance.snapshot(wand)) or snapshot
        local ok = perform(player, wand, "wand name", function()
            return appearance.set_name(player, wand, name_draft, current.show_name_in_ui)
        end, {coalesce_key="appearance.name",coalesce_frames=8})
        if ok then snapshot = select(1, appearance.snapshot(wand)) or snapshot end
    end

    local on_text = ui.tr("$mcm_rule_on", "ON")
    local off_text = ui.tr("$mcm_rule_off", "OFF")
    local mixed_text = ui.tr("$mcm_mixed", "MIXED")
    local all_frozen, mixed, spell_count = appearance.spell_freeze_state(wand)
    local spell_state = mixed and mixed_text or (all_frozen and on_text or off_text)
    local lock_clicked = ui.button_grid({
        {label=ui.tr("$mcm_wand_show_name", "SHOW NAME") .. ": " .. (snapshot.show_name_in_ui and on_text or off_text), selected=snapshot.show_name_in_ui},
        {label=ui.tr("$mcm_wand_lock", "WAND LOCK") .. ": " .. (snapshot.wand_frozen and on_text or off_text), selected=snapshot.wand_frozen},
        {label=ui.tr("$mcm_wand_spell_lock", "SPELL LOCK") .. ": " .. spell_state, selected=all_frozen or mixed},
    }, math.max(32, panel_width - 12))
    if lock_clicked == 1 then
        local current = select(1, appearance.snapshot(wand)) or snapshot
        local ok = perform(player, wand, "show wand name", function()
            return appearance.set_name(player, wand, name_draft, not current.show_name_in_ui)
        end)
        if ok then snapshot = select(1, appearance.snapshot(wand)) or snapshot end
    elseif lock_clicked == 2 then
        local current = select(1, appearance.snapshot(wand)) or snapshot
        local ok = perform(player, wand, "wand lock", function()
            return appearance.set_wand_frozen(player, wand, not current.wand_frozen)
        end)
        if ok then snapshot = select(1, appearance.snapshot(wand)) or snapshot end
    elseif lock_clicked == 3 and spell_count > 0 then
        local actual_all_frozen = select(1, appearance.spell_freeze_state(wand))
        local ok = perform(player, wand, "spell locks", function()
            return appearance.set_spells_frozen(player, wand, not actual_all_frozen)
        end)
        if ok then
            snapshot = select(1, appearance.snapshot(wand)) or snapshot
            all_frozen, mixed, spell_count = appearance.spell_freeze_state(wand)
        end
    end

    ui.white_text(0, 1, ui.tr("$mcm_wand_skin", "SKIN"))
    sprite_draft = ui.text_input(sprite_draft, math.max(36, panel_width - 12), 180,
        "wand.skin." .. tostring(wand), {escape_clears=false})
    if ui.button_grid({{label=ui.tr("$mcm_apply", "APPLY")}}, math.max(32, panel_width - 12)) == 1 then
        local ok = perform(player, wand, "skin path", function()
            return appearance.set_visual(player, wand, {sprite_file=sprite_draft})
        end, {coalesce_key="appearance.skin",coalesce_frames=8})
        if ok then snapshot = select(1, appearance.snapshot(wand)) or snapshot end
    end

    local skin_changed, skin_error = skin_picker.draw(player, wand, snapshot, panel_width)
    if skin_changed then
        snapshot = select(1, appearance.snapshot(wand)) or snapshot
        sprite_draft = tostring(snapshot.sprite_file or "")
        clear_error()
    elseif skin_error ~= nil then
        report_error(skin_error)
    end

    draw_geometry(player, wand, snapshot, "offset_x", ui.tr("$mcm_wand_sprite_x", "IMAGE OFFSET X"), snapshot.offset_x,
        "offset_x", panel_width, ui.tr("$mcm_wand_sprite_x_desc", "Horizontal offset of the visible wand image in pixels."))
    draw_geometry(player, wand, snapshot, "offset_y", ui.tr("$mcm_wand_sprite_y", "IMAGE OFFSET Y"), snapshot.offset_y,
        "offset_y", panel_width, ui.tr("$mcm_wand_sprite_y_desc", "Vertical offset of the visible wand image in pixels."))
    draw_geometry(player, wand, snapshot, "tip_x", ui.tr("$mcm_wand_tip_x", "SHOOT TIP X"), snapshot.tip_x,
        "tip_x", panel_width, nil)
    draw_geometry(player, wand, snapshot, "tip_y", ui.tr("$mcm_wand_tip_y", "SHOOT TIP Y"), snapshot.tip_y,
        "tip_y", panel_width, nil)

    return true
end

METAMORPH_CREATIVE_MENU_WAND_APPEARANCE_EDITOR_UI = appearance_editor
return appearance_editor
