local effects_tab = {}

local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local audit = ui.audit
local effect_service = dofile("mods/metamorph_creative_menu/files/features/effects/service.lua")

local catalog = nil
local filter = "all"
local duration_index = 3
local search = ""
local DURATIONS = {
    { frames=600, key="$mcm_effect_duration_10s", fallback="10s" },
    { frames=1800, key="$mcm_effect_duration_30s", fallback="30s" },
    { frames=3600, key="$mcm_effect_duration_60s", fallback="60s" },
    { frames=18000, key="$mcm_effect_duration_5m", fallback="5m" },
    { frames=-1, key="$mcm_effect_duration_inf", fallback="∞" },
}

local function ensure_catalog()
    if catalog ~= nil then return true end
    local ok, values = pcall(effect_service.catalog)
    if not ok or type(values) ~= "table" then return false end
    catalog = values
    return true
end

local function icon(entry)
    if type(entry) ~= "table" then return ui.EMPTY_SLOT end
    local path = entry.icon or entry.ui_icon or entry.sprite
    if type(path) == "string" and path ~= "" then
        local resolved = ui.resolve(path)
        if resolved ~= nil then return resolved end
    end
    if type(entry.path) == "string" and entry.path ~= "" then
        local resolved = ui.entity_icon(entry.path, "effect")
        if resolved ~= nil then return resolved end
    end
    -- A number of status entries omit ui_icon even though vanilla ships the standard
    -- status indicator under a predictable id-based filename. Only use it when the
    -- file really exists; otherwise leave the neutral slot instead of caching a bad path.
    local id = string.lower(tostring(entry.id or ""))
    if id ~= "" then
        local candidate = "data/ui_gfx/status_indicators/" .. id .. ".png"
        if ModDoesFileExist(candidate) then
            local resolved = ui.resolve(candidate)
            if resolved ~= nil then return resolved end
        end
    end
    return ui.EMPTY_SLOT
end

function effects_tab.draw(player, panel_width, screen_height)
    if not ensure_catalog() then ui.white_text(0, 2, ui.tr("$mcm_effects_failed", "Effect list failed to load")); return end
    GuiLayoutBeginVertical(ui.gui(), 0, 2, true)
    local filter_records = { {"all","$mcm_effect_filter_all","ALL"}, {"status","$mcm_effect_filter_status","STATUS"}, {"game_effect","$mcm_effect_filter_timed","EFFECTS"} }
    local filter_buttons = {}
    for index, f in ipairs(filter_records) do filter_buttons[index] = {label=ui.tr(f[2],f[3]),selected=filter==f[1]} end
    local clicked_filter = ui.button_grid(filter_buttons, panel_width - 10)
    if clicked_filter ~= nil then filter = filter_records[clicked_filter][1] end
    local d = DURATIONS[duration_index]
    local duration_delta = ui.stepper(ui.tr("$mcm_effect_duration", "DURATION"), ui.tr(d.key, d.fallback), {
        decrease_enabled=duration_index > 1, increase_enabled=duration_index < #DURATIONS,
        max_width=math.max(32, panel_width - 10),
    })
    duration_index = math.max(1, math.min(#DURATIONS, duration_index + duration_delta))
    d = DURATIONS[duration_index]
    local remove_all_label = ui.tr("$mcm_effect_remove_all", "REMOVE ALL")
    if ui.confirm_button("effects.remove_all", remove_all_label,
        ui.tr("$mcm_confirm", "CONFIRM") .. ": " .. remove_all_label, nil, math.max(32,panel_width-10))
    then
        local removed=effect_service.remove_all(player)
        audit("effect.remove_all", "removed="..tostring(removed))
    end
    search = ui.search_input(search, math.max(68, panel_width - 28), 64, "effects")
    ui.wrapped_text(0, 0, ui.tr("$mcm_effect_controls", "LMB: APPLY   RMB: REMOVE"), math.max(24,panel_width-10))

    local filtered = {}
    for _, entry in ipairs(catalog) do
        if filter == "all" or entry.kind == filter then filtered[#filtered + 1] = entry end
    end
    local results = ui.rank_entries(search, filtered, function(entry)
        return {entry.name_key, entry.description_key, entry.display_name, entry.id, entry.path, entry.display_description}
    end, function(entry) return entry.id or entry.path end)
    ui.search_status(search, #results)

    local h=ui.scroll_height(screen_height,168)
    local scroll=ui.begin_scroll_viewport("effects.catalog",11100,0,0,panel_width-4,h,{layout="free"})
    local columns=ui.columns(scroll.content_width,ui.ICON_STEP,{reserve_scrollbar=false})
    local visible=0
    local active_snapshot = effect_service.active_snapshot(player)
    for _,entry in ipairs(results) do
        local active=effect_service.is_active(player,entry,active_snapshot)
        local description=tostring(entry.display_description or "")
        local detail=tostring(entry.id or entry.path or "")
        if detail~="" then description=description .. (description~="" and "\n" or "") .. detail end
        if entry.kind=="status" then
            description=description.."\n"..ui.tr("$mcm_effect_status_native_decay","Applied at 100%; Noita controls natural decay")
        else
            description=description.."\n"..ui.tr("$mcm_effect_selected_duration","Selected duration")..": "..ui.tr(d.key,d.fallback)
        end
        local i=visible; visible=visible+1
        local clicked,right=ui.tile(scroll.padding_left+(i%columns)*ui.ICON_STEP,ui.scroll_y(scroll,math.floor(i/columns)*ui.ICON_STEP),
            ui.EMPTY_SLOT,icon(entry),ui.EMPTY_SLOT,entry.display_name or detail,description,active,{target_size=18,max_scale=3.0,fill=1.15})
        if clicked then
            local frames=entry.kind=="status" and nil or d.frames
            local ok,reason=effect_service.add(player,entry,frames)
            audit("effect.add", "id="..tostring(entry.id or entry.path).." result="..tostring(ok).." reason="..tostring(reason))
        elseif right then
            local removed=effect_service.remove(player,entry)
            audit("effect.remove", "id="..tostring(entry.id or entry.path).." removed="..tostring(removed))
        end
    end
    ui.end_scroll_viewport(scroll,math.ceil(visible/columns)*ui.ICON_STEP)
    GuiLayoutEnd(ui.gui())
end

return effects_tab
