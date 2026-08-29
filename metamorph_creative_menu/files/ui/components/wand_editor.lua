if type(METAMORPH_CREATIVE_MENU_WAND_EDITOR_UI) == "table" then return METAMORPH_CREATIVE_MENU_WAND_EDITOR_UI end

local wand_editor = {}
local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local wand_service = dofile("mods/metamorph_creative_menu/files/features/wands/service.lua")
local history = dofile("mods/metamorph_creative_menu/files/features/wands/history.lua")
local history_bar = dofile("mods/metamorph_creative_menu/files/ui/components/wand_history_bar.lua")
local numeric = dofile("mods/metamorph_creative_menu/files/ui/components/fixed_numeric_editor.lua")
local appearance_editor = dofile("mods/metamorph_creative_menu/files/ui/components/wand_appearance_editor.lua")

local expanded = true
local tracked_wand = 0
local last_error = nil

local FIELDS = {
    {id="slots", key="$mcm_wand_slots", fallback="SLOTS"},
    {id="actions_per_round", key="$mcm_wand_spells_per_cast", fallback="SPELLS/CAST"},
    {id="reload_time", key="$mcm_wand_recharge", fallback="RECHARGE",
        tooltip_key="$mcm_wand_recharge_desc", tooltip_fallback="Recharge time in game frames."},
    {id="fire_rate_wait", key="$mcm_wand_cast_delay", fallback="CAST DELAY",
        tooltip_key="$mcm_wand_cast_delay_desc", tooltip_fallback="Delay between casts in game frames."},
    {id="spread_degrees", key="$mcm_wand_spread", fallback="SPREAD",
        tooltip_key="$mcm_wand_spread_desc", tooltip_fallback="Spread angle in degrees."},
    {id="speed_multiplier", key="$mcm_wand_speed", fallback="SPEED", step=0.05},
    {id="mana_max", key="$mcm_wand_mana_max", fallback="MANA MAX"},
    {id="mana_charge_speed", key="$mcm_wand_mana_charge", fallback="MANA CHARGE"},
    {id="item_recoil_recovery_speed", key="$mcm_wand_recoil_recovery", fallback="RECOIL REC."},
    {id="gun_level", key="$mcm_wand_level", fallback="LEVEL"},
}

local function perform(player, wand, label, callback, options)
    local ok, reason = history.perform(player, wand, label, callback, options)
    last_error = ok and nil or reason
    return ok, reason
end

local function reset_controls(wand)
    numeric.reset("wand.stat." .. tostring(wand) .. ".")
end

local function draw_stat(player, wand, snapshot, field, panel_width)
    local definition = wand_service.definition(field.id) or {}
    local _, reason = numeric.draw("wand.stat." .. tostring(wand) .. "." .. field.id,
        ui.tr(field.key, field.fallback), snapshot.stats[field.id], {
            integer=definition.integer == true,
            step=field.step or definition.step or 1,
            min=definition.min,
            max=definition.max,
            label_tooltip_description=field.tooltip_key and ui.tr(field.tooltip_key, field.tooltip_fallback) or nil,
            label_width=94,
            value_width=58,
            value_chars=24,
            max_width=math.max(96, (tonumber(panel_width) or 220) - 12),
            on_apply=function(value)
                return perform(player, wand, field.id, function()
                    return wand_service.set_stat(player, wand, field.id, value)
                end, {coalesce_key="stat." .. field.id,coalesce_frames=45})
            end,
        })
    if reason ~= nil then last_error = reason end
end

function wand_editor.draw(player, wand, panel_width)
    local snapshot, reason = wand_service.snapshot(wand)
    if snapshot == nil then return false, reason end
    if tracked_wand ~= wand then
        tracked_wand = wand
        reset_controls(wand)
        last_error = nil
    end

    local history_changed, history_error = history_bar.draw(player, wand)
    if history_changed then
        snapshot = select(1, wand_service.snapshot(wand)) or snapshot
        reset_controls(wand)
        last_error = nil
    elseif history_error ~= nil then
        last_error = history_error
    end

    local toggle = (expanded and "- " or "+ ") .. ui.tr("$mcm_wand_stats", "WAND STATS")
    if ui.button(0, 0, toggle, expanded) then expanded = not expanded end
    if expanded then
        snapshot = select(1, wand_service.snapshot(wand)) or snapshot
        for _, field in ipairs(FIELDS) do draw_stat(player, wand, snapshot, field, panel_width) end

        local on_text = ui.tr("$mcm_rule_on", "ON")
        local off_text = ui.tr("$mcm_rule_off", "OFF")
        local toggles = {
            {label=ui.tr("$mcm_wand_shuffle", "SHUFFLE") .. ": " .. (snapshot.stats.shuffle and on_text or off_text), selected=snapshot.stats.shuffle},
            {label=ui.tr("$mcm_wand_never_reload", "NO RELOAD") .. ": " .. (snapshot.stats.never_reload and on_text or off_text), selected=snapshot.stats.never_reload},
        }
        local toggle_clicked = ui.button_grid(toggles, math.max(96, panel_width - 12))
        if toggle_clicked == 1 then
            perform(player, wand, "shuffle", function()
                return wand_service.set_boolean(player, wand, "shuffle", not snapshot.stats.shuffle)
            end)
        elseif toggle_clicked == 2 then
            perform(player, wand, "never_reload", function()
                return wand_service.set_boolean(player, wand, "never_reload", not snapshot.stats.never_reload)
            end)
        end
    end

    appearance_editor.draw(player, wand, panel_width)

    if last_error ~= nil then
        ui.wrapped_text(0, 0, ui.tr("$mcm_wand_edit_error", "Could not change wand") .. ": " .. tostring(last_error), panel_width - 12)
    end
    return true
end

METAMORPH_CREATIVE_MENU_WAND_EDITOR_UI = wand_editor
return wand_editor
