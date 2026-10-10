local world_rules_tab = {}
local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local audit = ui.audit
local world_rule_service = dofile("mods/metamorph_creative_menu/files/features/world_rules/service.lua")

local search = ""
local ICONS = {
    relations = "data/ui_gfx/perk_icons/peace_with_gods.png",
    gold_forever = "data/ui_gfx/perk_icons/gold_is_forever.png",
    infinite_spells = "data/ui_gfx/perk_icons/unlimited_spells.png",
    reveal_world = "data/ui_gfx/perk_icons/remove_fog_of_war.png",
    blood_money = "data/ui_gfx/perk_icons/trick_blood_money.png",
    hp_drops = "data/ui_gfx/perk_icons/extra_hp.png",
    rats_friendly = "data/ui_gfx/perk_icons/plague_rats.png",
    gore = "data/ui_gfx/perk_icons/global_gore.png",
    trick_gold = "data/ui_gfx/perk_icons/extra_money_trick_kill.png",
    damage_flash = "data/ui_gfx/status_indicators/protection_all.png",
    stain_drop = "data/ui_gfx/status_indicators/wet.png",
    physics_gravity = "data/ui_gfx/status_indicators/faster_levitation.png",
    physics_damping = "data/ui_gfx/status_indicators/movement_faster.png",
    blood_amount = "data/ui_gfx/perk_icons/global_gore.png",
    kick_force = "data/ui_gfx/perk_icons/strong_kick.png",
    joint_strength = "data/ui_gfx/status_indicators/protection_all.png",
    day_speed = "data/ui_gfx/status_indicators/nightvision.png",
}

local function choice_text(rule)
    local label = world_rule_service.choice_label(rule)
    if string.sub(label, 1, 1) == "$" then return ui.tr(label, label) end
    return label
end

local function run_rule_action(action_name, fn, ...)
    local call_ok, result, reason = pcall(fn, ...)
    if not call_ok then
        local detail=tostring(result)
        audit(action_name, "result=false reason=exception:" .. detail)
        ui.report_error_once("world_rules.action", ui.tr("$mcm_rules_error", "RULE ERROR"), detail, "ui.rules.action")
        return false, "exception"
    end
    if result == true then
        ui.clear_error_notice("world_rules.action")
    else
        ui.report_error_once("world_rules.action", ui.tr("$mcm_rules_error", "RULE ERROR"), tostring(reason or "failed"), "ui.rules.action")
    end
    return result == true, reason
end

function world_rules_tab.draw(_, panel_width, screen_height)
    local can_edit, mode = world_rule_service.can_edit()
    GuiLayoutBeginVertical(ui.gui(), 0, 2, true)
    local reset_label = ui.tr("$mcm_rules_reset", "RESET")
    if world_rule_service.has_overrides() and can_edit and ui.confirm_button("rules.reset", reset_label,
        ui.tr("$mcm_confirm", "CONFIRM") .. ": " .. reset_label, nil, math.max(32,panel_width-10))
    then
        local ok, reason = run_rule_action("rules.reset", world_rule_service.reset)
        audit("rules.reset", "result="..tostring(ok).." reason="..tostring(reason))
    end
    if not can_edit then ui.white_text(0, 0, ui.tr("$mcm_rules_unavailable", "World-rule editing unavailable")) end
    search = ui.search_input(search, math.max(68, panel_width - 28), 64, "world_rules")

    local rules = ui.rank_entries(search, world_rule_service.rules(), function(rule)
        return {rule.label, rule.description, ui.tr(rule.label, rule.id), rule.id, choice_text(rule)}
    end, function(rule) return rule.id end)
    ui.search_status(search, #rules)
    local h = ui.scroll_height(screen_height, 132)
    local scroll = ui.begin_scroll_viewport("world_rules.catalog", 13100, 0, 0, panel_width - 4, h, {layout="free"})
    local columns = ui.columns(scroll.content_width, ui.ICON_STEP, {reserve_scrollbar=false})
    local visible = 0
    for _, rule in ipairs(rules) do
        local title = ui.tr(rule.label, rule.id)
        local desc = ui.tr(rule.description, "")
        local value_text
        local selected
        selected = world_rule_service.is_overridden(rule)
        value_text = choice_text(rule)
        desc = desc .. "\n" .. ui.tr("$mcm_rule_value", "VALUE") .. ": " .. value_text
            .. "\n" .. ui.tr("$mcm_rule_click_cycle", "LMB: next   RMB: previous")
        if not world_rule_service.supported(rule) then desc = desc .. "\n" .. ui.tr("$mcm_rule_unsupported", "UNSUPPORTED IN THIS BUILD") end
        local i = visible; visible = visible + 1
        local clicked, right = ui.tile(scroll.padding_left + (i % columns) * ui.ICON_STEP, ui.scroll_y(scroll, math.floor(i / columns) * ui.ICON_STEP),
            ui.EMPTY_SLOT, ICONS[rule.id], ui.EMPTY_SLOT, title, desc, selected,
            { target_size=18, icon_box_size=18, max_scale=6, fill=1.1, padding=0 })
        if can_edit and (clicked or right) then
            local ok, reason
            ok, reason = run_rule_action("rule.step", world_rule_service.step, rule, right and -1 or 1)
            audit("rule.step", "id="..tostring(rule.id).." direction="..tostring(right and -1 or 1).." result="..tostring(ok).." reason="..tostring(reason))
        end
    end
    ui.end_scroll_viewport(scroll, math.ceil(visible / columns) * ui.ICON_STEP)
    local mode_label = mode == "ew_host" and ui.tr("$mcm_weather_mode_ew_host", "EW HOST")
        or (mode == "ew_peer" and ui.tr("$mcm_weather_mode_ew_client", "EW CLIENT")
        or ui.tr("$mcm_weather_mode_local", "LOCAL"))
    ui.white_text(0, 1, mode_label)
    GuiLayoutEnd(ui.gui())
end

return world_rules_tab
