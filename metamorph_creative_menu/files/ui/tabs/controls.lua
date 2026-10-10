local controls_tab = {}
local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local bindings = dofile("mods/metamorph_creative_menu/files/platform/noita/action_bindings.lua")

local search = ""

function controls_tab.draw(_, panel_width, screen_height)
    bindings.update()
    GuiLayoutBeginVertical(ui.gui(), 0, 2, true)
    ui.wrapped_text(0, 0, ui.tr("$mcm_controls_hint", "Click a binding, then press a key or mouse button. Modifiers are supported."), panel_width - 12)
    ui.wrapped_text(0, 0, ui.tr("$mcm_controls_clear_hint", "DELETE/BACKSPACE clears; ESC cancels capture."), panel_width - 12)
    search = ui.search_input(search, math.max(68, panel_width - 28), 64, "controls")

    if ui.confirm_button("controls.reset_all", ui.tr("$mcm_controls_reset_all", "RESET ALL"),
        ui.tr("$mcm_controls_reset_confirm", "CLICK AGAIN TO RESET ALL"), nil, math.max(32,panel_width-12))
    then
        bindings.reset_all()
    end

    local active_capture = bindings.capture_action()
    if active_capture ~= nil then
        local action = bindings.registry().get(active_capture)
        ui.colored_text(0, 2, ui.tr("$mcm_controls_waiting", "PRESS A KEY...") .. "  "
            .. (action and ui.tr(action.key, action.fallback) or active_capture), {1.0,0.78,0.2,1.0})
    end

    local registry = bindings.registry()
    local visible_actions = ui.rank_entries(search, registry.actions(), function(action)
        return {action.key, ui.tr(action.key, action.fallback), action.id, bindings.label(action.id)}
    end, function(action) return action.id end)
    local actions_by_section = {}
    for _, action in ipairs(visible_actions) do
        actions_by_section[action.section] = actions_by_section[action.section] or {}
        actions_by_section[action.section][#actions_by_section[action.section] + 1] = action
    end
    ui.search_status(search, #visible_actions)

    local height = ui.scroll_height(screen_height, 116)
    local scroll = ui.begin_scroll_viewport("controls.main", 16100, 0, 0, panel_width - 4, height)
    for _, section in ipairs(registry.sections()) do
        local section_actions = actions_by_section[section.id] or {}
        if #section_actions > 0 then
            ui.colored_text(0, 4, ui.tr(section.key, section.fallback), {1.0,0.78,0.2,1.0})
            for _, action in ipairs(section_actions) do
                ui.wrapped_text(0, 1, ui.tr(action.key, action.fallback), math.max(24, scroll.content_width - 4))
                local waiting = active_capture == action.id
                local label = waiting and ui.tr("$mcm_controls_waiting_short", "PRESS...") or bindings.label(action.id)
                local action_buttons = {
                    {label="[ " .. label .. " ]",selected=waiting,tooltip_title=ui.tr(action.key,action.fallback)},
                    {label="X",tooltip_title=ui.tr("$mcm_controls_clear", "Clear binding")},
                }
                local has_reset = bindings.get(action.id) ~= action.default
                if has_reset then action_buttons[#action_buttons+1]={label="R",tooltip_title=ui.tr("$mcm_controls_reset", "Restore default")} end
                local action_clicked=ui.button_grid(action_buttons,math.max(24,scroll.content_width-4))
                if action_clicked==1 then bindings.start_capture(action.id)
                elseif action_clicked==2 then bindings.set(action.id,"NONE")
                elseif action_clicked==3 and has_reset then bindings.reset(action.id) end
                local conflicts = bindings.conflicts(action.id)
                if #conflicts > 0 then
                    local names = {}
                    for _, conflict in ipairs(conflicts) do names[#names + 1] = ui.tr(conflict.key, conflict.fallback) end
                    ui.wrapped_text(4, 0, ui.tr("$mcm_controls_conflict", "CONFLICT") .. ": "
                        .. table.concat(names, ", "), math.max(24, scroll.content_width - 8), {1.0,0.35,0.25,1.0})
                end
            end
        end
    end
    ui.end_scroll_viewport(scroll)
    GuiLayoutEnd(ui.gui())
end

return controls_tab
