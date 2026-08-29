if type(METAMORPH_CREATIVE_MENU_WAND_HISTORY_UI) == "table" then return METAMORPH_CREATIVE_MENU_WAND_HISTORY_UI end

local history_bar = {}
local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local history = dofile("mods/metamorph_creative_menu/files/features/wands/history.lua")

function history_bar.draw(player, wand)
    local changed, error_reason = false, nil
    GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)

    local undo_label = history.undo_label(wand)
    local undo_tip = undo_label and (ui.tr("$mcm_wand_undo", "Undo") .. ": " .. undo_label)
        or ui.tr("$mcm_wand_nothing_undo", "Nothing to undo")
    if ui.button(0, 0, "  " .. ui.tr("$mcm_wand_undo", "UNDO") .. "  ", false, undo_tip, "") then
        if history.can_undo(wand) then
            local ok, reason = history.undo(player, wand)
            changed, error_reason = ok, ok and nil or reason
        end
    end

    local redo_label = history.redo_label(wand)
    local redo_tip = redo_label and (ui.tr("$mcm_wand_redo", "Redo") .. ": " .. redo_label)
        or ui.tr("$mcm_wand_nothing_redo", "Nothing to redo")
    if ui.button(0, 0, "  " .. ui.tr("$mcm_wand_redo", "REDO") .. "  ", false, redo_tip, "") then
        if history.can_redo(wand) then
            local ok, reason = history.redo(player, wand)
            changed, error_reason = ok, ok and nil or reason
        end
    end

    GuiLayoutEnd(ui.gui())
    return changed, error_reason
end

METAMORPH_CREATIVE_MENU_WAND_HISTORY_UI = history_bar
return history_bar
