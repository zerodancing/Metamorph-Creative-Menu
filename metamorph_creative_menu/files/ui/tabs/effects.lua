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
    GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
    for _, f in ipairs({ {"all","$mcm_effect_filter_all","ALL"}, {"status","$mcm_effect_filter_status","STATUS"}, {"game_effect","$mcm_effect_filter_timed","EFFECTS"} }) do
        if ui.button(0,0,ui.tr(f[2],f[3]),filter==f[1]) then filter=f[1] end
    end
    GuiLayoutEnd(ui.gui())
    GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
    ui.white_text(0, 1, ui.tr("$mcm_effect_duration", "DURATION"))
    if ui.button(0,0,"  -  ") then duration_index=math.max(1,duration_index-1) end
    local d = DURATIONS[duration_index]
    ui.white_text(0,1,ui.tr(d.key,d.fallback))
    if ui.button(0,0,"  +  ") then duration_index=math.min(#DURATIONS,duration_index+1) end
    if ui.button(0,0,ui.tr("$mcm_effect_remove_all","REMOVE ALL")) then
        local removed=effect_service.remove_all(player)
        audit("effect.remove_all", "removed="..tostring(removed))
    end
    GuiLayoutEnd(ui.gui())
    search = ui.search_input(search, math.max(88, panel_width - 54), 64, "effects")

    local columns=ui.columns(panel_width)
    local h=ui.grid_height(screen_height,205,145)
    GuiBeginScrollContainer(ui.gui(), 11100, 0,0,panel_width-4,h,false,1,1)
    local _,_,hov=GuiGetPreviousWidgetInfo(ui.gui()); ui.mark_hovered(hov)
    local visible=0
    local active_snapshot = effect_service.active_snapshot(player)
    for _,entry in ipairs(catalog) do
        if (filter=="all" or entry.kind==filter) and ui.matches_search(search, entry.display_name, entry.id, entry.path, entry.display_description) then
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
            local clicked,right=ui.tile((i%columns)*ui.ICON_STEP,math.floor(i/columns)*ui.ICON_STEP,
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
    end
    GuiEndScrollContainer(ui.gui())
    GuiLayoutEnd(ui.gui())
end

return effects_tab
