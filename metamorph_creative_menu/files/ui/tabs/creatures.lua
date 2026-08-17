local creatures_tab = {}
local DEV_MODE = METAMORPH_CREATIVE_MENU_DEV_MODE == true

local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local audit = ui.audit
local form_manager = dofile("mods/metamorph_creative_menu/files/features/forms/manager.lua")
local entity_catalog = dofile("mods/metamorph_creative_menu/files/features/creatures/ui_catalog.lua")
local player_avatar = dofile("mods/metamorph_creative_menu/files/features/companion/player_avatar.lua")

local creature_service, catalog, filters, filtered = nil, nil, nil, {}
local selected_filter = 1
local icon_cache = {}
local search = ""
local review_mode = "play"
local review_marks = {}
local search_cache_key = nil
local search_cache_value = nil
local warmup_cursor = 1
local catalog_scan_complete = false
local ICON_ALIASES = {
    scorpion="scorpion", drone_physics="drone_physics", fireskull="fireskull",
    slimeshooter="slimeshooter", wand_ghost="wand_ghost",
    boss_centipede_minion="boss_centipede",
    slimeshooter_boss_limbs="slimeshooter", slimeshooter_boss="slimeshooter",
    scorpion_watchtower="scorpion", fireskull_weak="fireskull",
    slimeshooter_nontoxic="slimeshooter", fungus_tiny="fungus",
    wand_ghost_charmed="wand_ghost", wand_ghost_with_sampo="wand_ghost",
    darkghost="wraith", apparition="playerghost",
}


local function localize_name(value, fallback)
    local translated = ui.translated(value)
    if translated == nil or translated == "" or translated == value then return fallback or value end
    return translated
end

local function ensure_catalog()
    if catalog ~= nil then return true end
    local ok_api, module = pcall(dofile, "mods/metamorph_creative_menu/files/features/creatures/service.lua")
    if not ok_api or type(module) ~= "table" then return false end
    local ok_values, values = pcall(entity_catalog.collect)
    if not ok_values or type(values) ~= "table" then return false end
    creature_service, catalog = module, values
    for _, entry in ipairs(catalog) do
        if entry.special == "player" then
            entry.display_name = ui.tr("$mcm_creature_player", "PLAYER")
        elseif type(entry.display_name) ~= "string" or entry.display_name == "" or string.sub(entry.display_name, 1, 1) == "$" then
            entry.display_name = localize_name(entry.display_name, entry.id or entry.path)
        end
    end
    filters = {
        {"$mcm_creature_filter_all","ALL"},
        {"$mcm_creature_filter_bosses","BOSSES","BOSSES"},
        {"$mcm_creature_filter_humanoids","HUMANOIDS","HUMANOIDS"},
        {"$mcm_creature_filter_animals","ANIMALS","ANIMALS"},
        {"$mcm_creature_filter_machines","MACHINES","MACHINES"},
        {"$mcm_creature_filter_other","OTHER","OTHER"},
    }
    return true
end

local function values_for(index)
    if filtered[index] ~= nil then return filtered[index] end
    local f = filters[index]
    local result = {}
    for _, entry in ipairs(catalog or {}) do
        if f[3] == nil or entry.category == f[3] then result[#result + 1] = entry end
    end
    filtered[index] = result
    return result
end

local function search_values(index, query)
    query = tostring(query or "")
    local values = values_for(index)
    if query == "" then return values end
    local key = tostring(index) .. "\31" .. query
    if key == search_cache_key and search_cache_value ~= nil then return search_cache_value end
    local result = {}
    for _, entry in ipairs(values) do
        if ui.matches_search(query, entry.display_name, entry.id, entry.path, entry.display_description) then
            result[#result + 1] = entry
        end
    end
    search_cache_key, search_cache_value = key, result
    return result
end

local CREATURE_ICON_FALLBACK = "data/ui_gfx/animal_icons/sheep.png"

local function icon(entry, force_resolve)
    local key = tostring(entry.path)
    if icon_cache[key] ~= nil then return icon_cache[key] end
    -- Direct catalog icons are cheap filesystem assets: show them immediately on the
    -- visible page instead of rendering an egg while background XML warmup catches up.
    -- Only entities without a real/aliased animal icon defer expensive entity XML scan.
    if force_resolve ~= true then
        local direct_path = tostring(entry.icon or "")
        if direct_path ~= "" and ModDoesFileExist(direct_path) then
            icon_cache[key] = direct_path
            return direct_path
        end
        local alias = ICON_ALIASES[tostring(entry.id or "")]
        if alias ~= nil then
            local candidate = "data/ui_gfx/animal_icons/" .. alias .. ".png"
            if ModDoesFileExist(candidate) then
                icon_cache[key] = candidate
                return candidate
            end
        end
        return CREATURE_ICON_FALLBACK
    end
    if entry.special == "player" then
        icon_cache[key] = ui.resolve(entry.icon) or "data/ui_gfx/items/wandstone.png"
        return icon_cache[key]
    end
    local direct = ui.resolve(entry.icon)
    if direct ~= nil then icon_cache[key] = direct; return direct end
    local alias = ICON_ALIASES[tostring(entry.id or "")]
    if alias ~= nil then
        local candidate = "data/ui_gfx/animal_icons/" .. alias .. ".png"
        local aliased = ui.resolve(candidate)
        if aliased ~= nil then icon_cache[key] = aliased; return aliased end
    end
    local resolved = ui.entity_icon(entry.path, "creature")
    icon_cache[key] = resolved or CREATURE_ICON_FALLBACK
    return icon_cache[key]
end

local function presentation(entry)
    local text = tostring(entry.display_description or "")
    if text ~= "" then text = text .. "\n" end
    text = text .. tostring(entry.path or "")
    if review_mode == "play" then
        text = text .. "\n" .. ui.tr("$mcm_left_spawn", "LMB: spawn nearby")
            .. "\n" .. ui.tr("$mcm_right_transform", "RMB: transform")
    else
        local mode_key = "$mcm_mobs_mode_log_retest"
        local mode_fallback = "LOG RETEST"
        if review_mode == "safe" then mode_key, mode_fallback = "$mcm_mobs_mode_log_safe", "LOG SAFE" end
        if review_mode == "unsafe" then mode_key, mode_fallback = "$mcm_mobs_mode_log_unsafe", "LOG UNSAFE" end
        text = text .. "\n" .. ui.tr("$mcm_mobs_review_click", "CLICK: log") .. " " .. ui.tr(mode_key, mode_fallback)
        if creature_service ~= nil and type(creature_service.compatibility_status) == "function" then
            local checked, status, reason = pcall(creature_service.compatibility_status, entry.path)
            if checked then text = text .. "\nAUTO: " .. tostring(status or "unknown") .. " / " .. tostring(reason or "unknown") end
        end
        local marked = review_marks[tostring(entry.path)]
        if marked ~= nil then
            local marked_key, marked_fallback = "$mcm_mobs_mode_log_retest", "LOG RETEST"
            if marked == "safe" then marked_key, marked_fallback = "$mcm_mobs_mode_log_safe", "LOG SAFE" end
            if marked == "unsafe" then marked_key, marked_fallback = "$mcm_mobs_mode_log_unsafe", "LOG UNSAFE" end
            text = text .. "\n" .. ui.tr("$mcm_mobs_marked", "MARKED") .. ": " .. ui.tr(marked_key, marked_fallback)
        end
    end
    return { description = text }
end

local function spawn(player, entry)
    if entry.special == "player" then
        local ok = player_avatar.request_spawn(player, 32, -4)
        return ok == true
    end
    if creature_service == nil or type(creature_service.spawn_near_player) ~= "function" then return false end
    return (creature_service.spawn_near_player(player, entry.path, 32, -4) or 0) ~= 0
end

local function transform_creature(player, creature)
    if creature_service ~= nil and type(creature_service.compatibility_status) == "function" then
        local checked, status, reason = pcall(creature_service.compatibility_status, creature.path)
        if checked and status == "unsafe" then
            GamePrint(ui.tr("$mcm_creature_poly_failed", "Could not transform") .. ": " .. tostring(creature.display_name or creature.path))
            audit("creature.transform.blocked", "path="..tostring(creature.path).." reason="..tostring(reason or "known_unsafe"))
            return false, tostring(reason or "known_unsafe")
        end
    end
    local target = creature.path
    local transform_mode = "direct"
    local transform_reason = "direct"
    if creature_service ~= nil and type(creature_service.transform_plan) == "function" then
        local ok, plan = pcall(creature_service.transform_plan, creature.path)
        if ok and type(plan) == "table" then
            if type(plan.target_path) == "string" and plan.target_path ~= "" then target = plan.target_path end
            transform_mode = tostring(plan.mode or "direct")
            transform_reason = tostring(plan.reason or "direct")
        end
    elseif creature_service ~= nil and type(creature_service.canonical_transform_path) == "function" then
        local ok, canonical = pcall(creature_service.canonical_transform_path, creature.path)
        if ok and type(canonical) == "string" and canonical ~= "" then target = canonical end
    end
    -- Spawn identity and transform identity are intentionally separate for confirmed
    -- crash-prone placement wrappers: LMB keeps the authored biome XML, while player
    -- polymorph may use its same-species base body. requested_target preserves the
    -- exact menu/G identity for diagnostics and UI.
    if form_manager.exact_effect_path_for_target(target) == nil then
        pcall(form_manager.prepare_exact_effect_paths, {target})
    end
    -- Persist intent before entering native polymorph code. If Noita hard-crashes during
    -- transformation, the diagnostics log still has the exact requested/canonical path
    -- and the non-destructive compatibility preflight verdict from before the attempt.
    local compatibility_status, compatibility_reason = "unknown", "unavailable"
    if creature_service ~= nil and type(creature_service.compatibility_status) == "function" then
        local checked, status, reason = pcall(creature_service.compatibility_status, creature.path)
        if checked then
            compatibility_status = tostring(status or "unknown")
            compatibility_reason = tostring(reason or "unknown")
        end
    end
    audit("creature.transform.begin", "path="..tostring(creature.path).." target="..tostring(target)
        .." transform_mode="..transform_mode.." transform_reason="..transform_reason
        .." compatibility="..compatibility_status.." compatibility_reason="..compatibility_reason)
    local ok, reason = form_manager.transform_creature(player, target, nil, true, {
        requested_target=creature.path,
        compatibility_mode=transform_mode,
        profile_target=target,
    })
    if not ok then
        GamePrint(ui.tr("$mcm_creature_poly_failed", "Could not transform") .. ": " .. creature.display_name)
        return false, reason
    end
    GamePrint(ui.tr("$mcm_creature_transformed", "Transforming into") .. ": " .. creature.display_name)
    return true, reason
end

local function transform(player, entry)
    if entry.special == "player" then
        local ok = form_manager.return_to_human()
        GamePrint(ok and ui.tr("$mcm_creature_returning_human", "Returning to human form") or ui.tr("$mcm_creature_already_human", "Already in player form"))
        return ok
    end
    return transform_creature(player, entry)
end

function creatures_tab.draw(player, panel_width, screen_height)
    if not ensure_catalog() then ui.white_text(0, 2, ui.tr("$mcm_creatures_failed", "Creature list failed to load")); return end
    catalog_scan_complete = creatures_tab.warmup_step(1) == true
    GuiLayoutBeginVertical(ui.gui(), 0, 2, true)
    for start = 1, #filters, 4 do
        GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
        for i = start, math.min(start + 3, #filters) do
            local f = filters[i]
            if ui.button(0, 0, ui.tr(f[1], f[2]), selected_filter == i) then selected_filter = i end
        end
        GuiLayoutEnd(ui.gui())
    end
    if DEV_MODE then
        GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
        if ui.button(0, 0, ui.tr("$mcm_mobs_mode_play", "PLAY"), review_mode == "play") then review_mode = "play" end
        if ui.button(0, 0, ui.tr("$mcm_mobs_mode_log_safe", "LOG SAFE"), review_mode == "safe") then review_mode = "safe" end
        if ui.button(0, 0, ui.tr("$mcm_mobs_mode_log_unsafe", "LOG UNSAFE"), review_mode == "unsafe") then review_mode = "unsafe" end
        if ui.button(0, 0, ui.tr("$mcm_mobs_mode_log_retest", "LOG RETEST"), review_mode == "retest") then review_mode = "retest" end
        GuiLayoutEnd(ui.gui())
    else
        review_mode = "play"
    end
    if review_mode == "play" then
        ui.white_text(0, 0, ui.tr("$mcm_creature_controls", "LMB: SPAWN   RMB: TRANSFORM   TAB: HUMAN"))
    else
        ui.white_text(0, 0, ui.tr("$mcm_mobs_review_help", "REVIEW: click a mob to log its exact path; no transform/spawn occurs"))
    end
    search = ui.search_input(search, math.max(88, panel_width - 54), 64, "creatures")

    local columns = ui.columns(panel_width)
    local results = search_values(selected_filter, search)
    -- ALL is one continuous list; direct/alias icons are cached and deeper XML icon
    -- resolution is deferred until an entry is actually hovered.
    local catalog_status = ""
    if not catalog_scan_complete then
        catalog_status = "  |  " .. ui.tr("$mcm_mobs_scanning", "SCANNING...")
    end
    ui.white_text(0, 0, ui.tr("$mcm_mobs_showing", "SHOWING") .. " " .. tostring(#results) .. " / " .. tostring(#(catalog or {})) .. catalog_status)
    local h = ui.grid_height(screen_height, 220, 145)
    GuiBeginScrollContainer(ui.gui(), 12100 + selected_filter * 100, 0, 0, panel_width - 4, h, false, 1, 1)
    local _, _, hov = GuiGetPreviousWidgetInfo(ui.gui()); ui.mark_hovered(hov)
    for index, entry in ipairs(results) do
        local p = presentation(entry)
        local i = index - 1
        local clicked, right, hovered = ui.tile((i % columns) * ui.ICON_STEP, math.floor(i / columns) * ui.ICON_STEP,
            ui.EMPTY_SLOT, icon(entry, false), CREATURE_ICON_FALLBACK, entry.display_name, p.description, false,
            {target_size=18, max_scale=18, padding=0})
        if hovered and icon_cache[tostring(entry.path)] == nil then icon(entry, true) end
        if review_mode ~= "play" and (clicked or right) then
            review_marks[tostring(entry.path)] = review_mode
            local compatibility_status, compatibility_reason = "unknown", "unavailable"
            if creature_service ~= nil and type(creature_service.compatibility_status) == "function" then
                local checked, status, reason = pcall(creature_service.compatibility_status, entry.path)
                if checked then compatibility_status, compatibility_reason = tostring(status or "unknown"), tostring(reason or "unknown") end
            end
            audit("creature.review", "verdict="..tostring(review_mode).." path="..tostring(entry.path).." id="..tostring(entry.id or "")
                .." name="..tostring(entry.display_name or "").." auto="..compatibility_status.." auto_reason="..compatibility_reason)
            local label = ui.tr("$mcm_mobs_mode_log_retest", "LOG RETEST")
            if review_mode == "safe" then label = ui.tr("$mcm_mobs_mode_log_safe", "LOG SAFE") end
            if review_mode == "unsafe" then label = ui.tr("$mcm_mobs_mode_log_unsafe", "LOG UNSAFE") end
            GamePrint(ui.tr("$mcm_mobs_review_logged", "MOBS REVIEW") .. " " .. label .. ": " .. tostring(entry.path))
        elseif clicked then
            local ok=spawn(player, entry)
            audit("creature.spawn", "path="..tostring(entry.path).." result="..tostring(ok))
        elseif right then
            local ok, reason=transform(player, entry)
            audit("creature.transform", "path="..tostring(entry.path).." result="..tostring(ok).." reason="..tostring(reason))
        end
    end
    GuiEndScrollContainer(ui.gui())
    GuiLayoutEnd(ui.gui())
end

function creatures_tab.warmup_step(budget)
    budget = math.max(1, math.floor(tonumber(budget) or 6))
    local catalog_done, changed = true, false
    if type(entity_catalog.warmup_step) == "function" then
        local ok, done, did_change = pcall(entity_catalog.warmup_step, budget)
        if ok then catalog_done, changed = done == true, did_change == true end
    end
    if changed then
        -- The incremental vanilla/polymorph scanner appended real creature entries.
        -- Rebuild only this cheap presentation copy; XML validation remains budgeted
        -- inside creature_service.warmup_step rather than returning to the first-open spike.
        catalog, filters, filtered = nil, nil, {}
        search_cache_key, search_cache_value = nil, nil
        warmup_cursor = 1
    end
    if not ensure_catalog() then return catalog_done end
    for _ = 1, budget do
        local entry = catalog[warmup_cursor]
        if entry == nil then return catalog_done end
        icon(entry, true)
        warmup_cursor = warmup_cursor + 1
    end
    return catalog_done and warmup_cursor > #catalog
end

return creatures_tab
