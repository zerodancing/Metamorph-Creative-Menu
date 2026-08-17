local perks_tab = {}

local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local audit = ui.audit
local perk_service = dofile("mods/metamorph_creative_menu/files/features/perks/service.lua")
local perk_catalog = dofile("mods/metamorph_creative_menu/files/features/perks/catalog.lua")

local catalog = nil
local remove_mode = false
local search = ""
local PERK_STEP = ui.ICON_STEP
local PERK_ICON_SIZE = 18
local warmup_cursor = 1
local perk_icon_cache = {}
local PERK_ICON_FALLBACK = ui.EMPTY_SLOT
local page, last_page_key = 1, nil
local PAGE_ROWS = 7

local function ensure_catalog()
    if catalog ~= nil then return true end
    local vanilla_perks = perk_catalog.all()
    if type(vanilla_perks) ~= "table" then return false end
    catalog = {}
    for _, perk in ipairs(vanilla_perks) do
        local name = ui.translated(perk.ui_name)
        if name == "" or name == perk.ui_name then name = perk.id end
        catalog[#catalog + 1] = {
            id = perk.id,
            name = name,
            description = ui.translated(perk.ui_description),
            icon = perk.ui_icon,
            data = perk,
        }
    end
    table.sort(catalog, function(a,b)
        local an, bn = string.lower(a.name or a.id), string.lower(b.name or b.id)
        return an == bn and a.id < b.id or an < bn
    end)
    return true
end


local function display_icon(perk, force_resolve)
    local key = tostring(perk.id or perk.icon or "")
    if perk_icon_cache[key] ~= nil then return perk_icon_cache[key] end
    if force_resolve ~= true then return PERK_ICON_FALLBACK end
    if type(perk.icon) == "string" and perk.icon ~= "" then
        local resolved = ui.resolve(perk.icon)
        if resolved ~= nil then
            ui.dimensions(resolved)
            perk_icon_cache[key] = resolved
            return resolved
        end
    end
    perk_icon_cache[key] = PERK_ICON_FALLBACK
    return PERK_ICON_FALLBACK
end

local function apply_or_spawn(player_entity_id, perk_entry, take_immediately)
    local perk_data = type(perk_entry.data) == "table" and perk_entry.data or perk_entry
    if take_immediately then
        local applied, reason = perk_service.apply(player_entity_id, perk_data)
        if not applied and reason == "pickup_failed" then
            GamePrint(ui.tr("$mcm_perk_apply_failed", "Could not apply perk") .. ": " .. tostring(perk_entry.name or perk_data.id))
        end
        return applied, reason
    end
    return perk_service.spawn(player_entity_id, perk_data)
end

function perks_tab.draw(player, panel_width, screen_height)
    if not ensure_catalog() then ui.white_text(0, 2, ui.tr("$mcm_perks_failed", "Perk list failed to load")); return end
    perks_tab.warmup_step(1)
    GuiLayoutBeginVertical(ui.gui(), 0, 2, true)
    GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
    if ui.button(0, 0, ui.tr("$mcm_perk_mode_add", "ADD"), not remove_mode) then remove_mode = false end
    if ui.button(0, 0, ui.tr("$mcm_perk_mode_remove", "REMOVE"), remove_mode) then remove_mode = true end
    GuiLayoutEnd(ui.gui())
    ui.white_text(0, 0, remove_mode and ui.tr("$mcm_perk_remove_controls", "LMB: -1   RMB: REMOVE ALL")
        or ui.tr("$mcm_perk_add_controls", "LMB: SPAWN   RMB: TAKE"))
    search = ui.search_input(search, math.max(88, panel_width - 54), 64, "perks")

    local columns = ui.columns(panel_width, PERK_STEP)
    -- Build a cheap matching index, but instantiate GUI widgets only for one page.
    -- Widget creation is the expensive part on weak CPUs; all perks remain reachable.
    local matches = {}
    for _, perk in ipairs(catalog) do
        local count = remove_mode and perk_service.count(perk.id) or 0
        if (not remove_mode or count > 0) and ui.matches_search(search, perk.name, perk.id, perk.description) then
            matches[#matches + 1] = {perk=perk, count=count}
        end
    end
    local page_key = tostring(remove_mode) .. "\31" .. tostring(search)
    if page_key ~= last_page_key then page, last_page_key = 1, page_key end
    local page_size = math.max(columns, columns * PAGE_ROWS)
    local page_count = math.max(1, math.ceil(#matches / page_size))
    page = math.max(1, math.min(page, page_count))
    GuiLayoutBeginHorizontal(ui.gui(), 0, 0, true)
    if ui.button(0, 0, "<", false) and page > 1 then page = page - 1 end
    ui.white_text(0, 0, tostring(page) .. "/" .. tostring(page_count))
    if ui.button(0, 0, ">", false) and page < page_count then page = page + 1 end
    GuiLayoutEnd(ui.gui())

    local h = ui.grid_height(screen_height, 212, 145)
    GuiBeginScrollContainer(ui.gui(), 10100 + (remove_mode and 1000 or 0) + page, 0, 0, panel_width - 4, h, false, 1, 1)
    local _, _, hov = GuiGetPreviousWidgetInfo(ui.gui()); ui.mark_hovered(hov)
    local first = (page - 1) * page_size + 1
    local last = math.min(#matches, first + page_size - 1)
    local visible = 0
    for index = first, last do
        local perk = matches[index].perk
        local count = matches[index].count
        local can_remove, reason = true, nil
        if remove_mode then
            -- Perks are peer-local state. A removal click must never mutate another player.
            can_remove, reason = perk_service.can_remove(perk.data, player)
        end
        local desc = perk.description or ""
        if remove_mode then
            desc = desc .. "\n" .. ui.tr("$mcm_perk_count", "Count") .. ": " .. tostring(count)
            if not can_remove then
                desc = desc .. "\n" .. ui.tr("$mcm_perk_remove_unsafe", "This perk has no safe inverse yet")
                    .. " [" .. tostring(reason) .. "]"
            end
        end
        local i = visible; visible = visible + 1
        local clicked, right, hovered = ui.tile((i % columns) * PERK_STEP, math.floor(i / columns) * PERK_STEP,
            ui.EMPTY_SLOT, display_icon(perk, false), PERK_ICON_FALLBACK, perk.name, desc, remove_mode and count > 0,
            { target_size=PERK_ICON_SIZE, icon_box_size=PERK_ICON_SIZE, max_scale=8.0, fill=1.15, padding=0 })
        if hovered and perk_icon_cache[tostring(perk.id or perk.icon or "")] == nil then display_icon(perk, true) end
        if remove_mode then
            if clicked and count > 0 then
                local ok, reason = perk_service.remove_one(player, perk.data)
                audit("perk.remove_one", "id="..tostring(perk.id).." result="..tostring(ok).." reason="..tostring(reason).." scope=peer_local")
                if not ok then GamePrint(ui.tr("$mcm_perk_remove_failed", "Could not safely remove perk") .. ": " .. perk.name) end
            elseif right and count > 0 then
                local removed, reason = perk_service.remove_all(player, perk.data)
                audit("perk.remove_all", "id="..tostring(perk.id).." removed="..tostring(removed).." reason="..tostring(reason).." scope=peer_local")
                if removed == 0 then GamePrint(ui.tr("$mcm_perk_remove_failed", "Could not safely remove perk") .. ": " .. perk.name) end
            end
        else
            if clicked then local ok=apply_or_spawn(player, perk, false); audit("perk.spawn", "id="..tostring(perk.id).." result="..tostring(ok)) elseif right then local ok=apply_or_spawn(player, perk, true); audit("perk.take", "id="..tostring(perk.id).." result="..tostring(ok)) end
        end
    end
    GuiEndScrollContainer(ui.gui())
    GuiLayoutEnd(ui.gui())
end

function perks_tab.warmup_step(budget)
    if not ensure_catalog() then return true end
    budget = math.max(1, tonumber(budget) or 8)
    for _ = 1, budget do
        local perk = catalog[warmup_cursor]
        if perk == nil then return true end
        display_icon(perk, true)
        warmup_cursor = warmup_cursor + 1
    end
    return warmup_cursor > #catalog
end

return perks_tab
