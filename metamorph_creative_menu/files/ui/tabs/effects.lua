local effects_tab = {}

local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local audit = ui.audit
local effect_service = dofile("mods/metamorph_creative_menu/files/features/effects/service.lua")

local catalog = nil
local filter = "all"
local search = ""
local selected_key = nil
local selected_variant = {}
-- Duration is remembered per logical effect family. Changing the editor for one effect must
-- never rewrite the active time or next-click preset of another effect.
local duration_index_by_key = {}
local DEFAULT_DURATION_INDEX = 2
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
    return ui.EMPTY_SLOT
end

local function family_key(entry)
    if type(effect_service.family_key) == "function" then return effect_service.family_key(entry) end
    return tostring(entry and (entry.id or entry.path) or "")
end

local function find_selected(entries)
    if selected_key == nil then return nil end
    for _, entry in ipairs(entries or catalog or {}) do
        if family_key(entry) == selected_key then return entry end
    end
    return nil
end

local function search_fields(entry)
    local fields = {entry.name_key, entry.description_key, entry.display_name, entry.id, entry.path, entry.display_description}
    for _, variant in ipairs(type(entry.variants) == "table" and entry.variants or {}) do
        fields[#fields+1] = variant.name_key
        fields[#fields+1] = variant.description_key
        fields[#fields+1] = variant.display_name
        fields[#fields+1] = variant.id
        fields[#fields+1] = variant.path
    end
    return fields
end

local function chosen_variant(player, entry, snapshot)
    local key = family_key(entry)
    if selected_variant[key] == nil then
        selected_variant[key] = type(effect_service.active_variant_index) == "function"
            and effect_service.active_variant_index(player, entry, snapshot) or 1
    end
    local count = math.max(1, tonumber(effect_service.variant_count(entry)) or 1)
    selected_variant[key] = math.max(1, math.min(count, tonumber(selected_variant[key]) or 1))
    return selected_variant[key]
end

local function duration_index_for(entry)
    local key = family_key(entry)
    local index = tonumber(duration_index_by_key[key]) or DEFAULT_DURATION_INDEX
    index = math.max(1, math.min(#DURATIONS, math.floor(index)))
    duration_index_by_key[key] = index
    return index
end

local function click_duration(entry)
    if type(effect_service.duration_policy) == "function" and effect_service.duration_policy(entry) ~= "editable" then
        return nil
    end
    local index = duration_index_for(entry)
    return DURATIONS[index] and DURATIONS[index].frames or nil
end

local function apply_tile(player, entry, snapshot)
    local index = chosen_variant(player, entry, snapshot)
    local selected = effect_service.resolve_variant(entry, index)
    local frames = click_duration(selected)
    local ok, reason
    if type(effect_service.set_variant) == "function" then
        ok, reason = effect_service.set_variant(player, entry, index, frames)
    else
        ok, reason = effect_service.add(player, selected, frames)
    end
    audit("effect.add", "id="..tostring(selected.id or selected.path).." variant="..tostring(index).." result="..tostring(ok).." reason="..tostring(reason))
    return ok, reason
end

local function draw_duration_bar(player, entry, panel_width, snapshot)
    if type(entry) ~= "table" then return 0 end
    local variant_index = chosen_variant(player, entry, snapshot)
    local resolved = effect_service.resolve_variant(entry, variant_index)
    if type(effect_service.duration_policy) == "function" and effect_service.duration_policy(resolved) ~= "editable" then
        return 0
    end
    local key = family_key(entry)
    local current_index = duration_index_for(entry)
    local buttons = {}
    for i, duration in ipairs(DURATIONS) do
        buttons[#buttons+1] = {
            label=ui.tr(duration.key,duration.fallback), selected=i==current_index,
            tooltip_title=ui.tr("$mcm_effect_duration","DURATION"),
        }
    end
    local picked = ui.button_grid(buttons, math.max(48,panel_width-10))
    if picked ~= nil and DURATIONS[picked] ~= nil then
        duration_index_by_key[key] = picked
        -- This editor is contextual: changing BERSERK to 60s can update an already-active
        -- BERSERK, but it must never touch ALCOHOLIC or any other selected family.
        local active = type(effect_service.is_active)=="function" and effect_service.is_active(player,resolved,snapshot)
        if active and type(effect_service.set_remaining)=="function" then
            local frames=DURATIONS[picked].frames
            local ok,reason=effect_service.set_remaining(player,resolved,frames)
            audit("effect.duration", "id="..tostring(resolved.id or resolved.path).." value="..tostring(frames).." result="..tostring(ok).." reason="..tostring(reason))
        end
    end
    return 13
end

local function draw_editor(player, entry, panel_width, snapshot)
    if type(entry) ~= "table" then return 0 end
    local height = 0
    local key = family_key(entry)
    local count = math.max(1, tonumber(effect_service.variant_count(entry)) or 1)
    if count > 1 then
        local index = chosen_variant(player, entry, snapshot)
        local active = type(effect_service.is_family_active)=="function" and effect_service.is_family_active(player,entry,snapshot)
            or effect_service.is_active(player,effect_service.resolve_variant(entry,index),snapshot)
        local buttons = {}
        for variant_index=1,count do
            local resolved = effect_service.resolve_variant(entry,variant_index)
            buttons[#buttons+1] = {
                label=tostring(variant_index), selected=variant_index==index,
                tooltip_title=tostring(resolved.display_name or ""),
                tooltip_description=tostring(resolved.display_description or ""),
            }
        end
        local picked = ui.button_grid(buttons, math.max(48,panel_width-10))
        if picked ~= nil and picked ~= index then
            selected_variant[key] = picked
            if active and type(effect_service.switch_variant) == "function" then
                local ok, reason = effect_service.switch_variant(player,entry,picked)
                audit("effect.variant", "id="..tostring(entry.id or entry.path).." variant="..tostring(picked).." result="..tostring(ok).." reason="..tostring(reason))
            end
        end
        height = height + 13
    end
    height = height + draw_duration_bar(player, entry, panel_width, snapshot)
    return height
end

function effects_tab.draw(player, panel_width, screen_height)
    if not ensure_catalog() then ui.white_text(0, 2, ui.tr("$mcm_effects_failed", "Effect list failed to load")); return end
    GuiLayoutBeginVertical(ui.gui(), 0, 2, true)

    local filter_records = { {"all","$mcm_effect_filter_all","ALL"}, {"status","$mcm_effect_filter_status","STATUS"}, {"game_effect","$mcm_effect_filter_timed","EFFECTS"} }
    local filter_buttons = {}
    for index, f in ipairs(filter_records) do filter_buttons[index] = {label=ui.tr(f[2],f[3]),selected=filter==f[1]} end
    local clicked_filter = ui.button_grid(filter_buttons, panel_width - 10)
    if clicked_filter ~= nil then filter = filter_records[clicked_filter][1] end

    search = ui.search_input(search, math.max(68, panel_width - 28), 64, "effects")

    local filtered = {}
    for _, entry in ipairs(catalog) do if filter == "all" or entry.kind == filter then filtered[#filtered+1] = entry end end
    local results = ui.rank_entries(search, filtered, search_fields, function(entry) return family_key(entry) end)
    ui.search_status(search, #results)

    local snapshot = effect_service.active_snapshot(player)
    local selected = find_selected(catalog)
    local editor_height = selected ~= nil and draw_editor(player,selected,panel_width,snapshot) or 0

    local remove_all_label = ui.tr("$mcm_effect_remove_all", "REMOVE ALL")
    if ui.confirm_button("effects.remove_all", remove_all_label,
        ui.tr("$mcm_confirm", "CONFIRM") .. ": " .. remove_all_label, nil, math.max(32,panel_width-10))
    then
        local removed=effect_service.remove_all(player)
        audit("effect.remove_all", "removed="..tostring(removed))
    end

    local h=ui.scroll_height(screen_height, 142 + editor_height)
    local scroll=ui.begin_scroll_viewport("effects.catalog",11100,0,0,panel_width-4,h,{layout="free"})
    local columns=ui.columns(scroll.content_width,ui.ICON_STEP,{reserve_scrollbar=false})
    local visible=0
    for _,entry in ipairs(results) do
        local key=family_key(entry)
        local family_active = type(effect_service.is_family_active)=="function" and effect_service.is_family_active(player,entry,snapshot)
            or effect_service.is_active(player,entry,snapshot)
        local description=tostring(entry.display_description or "")
        local i=visible; visible=visible+1
        local clicked,right=ui.tile(scroll.padding_left+(i%columns)*ui.ICON_STEP,ui.scroll_y(scroll,math.floor(i/columns)*ui.ICON_STEP),
            ui.EMPTY_SLOT,icon(entry),ui.EMPTY_SLOT,entry.display_name or "",description,
            selected_key==key or family_active,{target_size=18,max_scale=3.0,fill=1.15})
        if clicked then
            selected_key=key
            apply_tile(player,entry,snapshot)
        elseif right then
            selected_key=key
            local removed=type(effect_service.remove_family)=="function" and effect_service.remove_family(player,entry)
                or effect_service.remove(player,entry)
            audit("effect.remove", "id="..tostring(entry.id or entry.path).." family=true removed="..tostring(removed))
        end
    end
    ui.end_scroll_viewport(scroll,math.ceil(visible/columns)*ui.ICON_STEP)
    GuiLayoutEnd(ui.gui())
end

return effects_tab
