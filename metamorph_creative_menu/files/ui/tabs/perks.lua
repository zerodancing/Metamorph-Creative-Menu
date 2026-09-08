local perks_tab = {}

local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local audit = ui.audit
local perk_service = dofile("mods/metamorph_creative_menu/files/features/perks/service.lua")
local perk_catalog = dofile("mods/metamorph_creative_menu/files/features/perks/catalog.lua")
local drag_drop = dofile("mods/metamorph_creative_menu/files/ui/drag_drop.lua")
local non_perk_states = nil
do
    local ok, module = pcall(dofile, "mods/metamorph_creative_menu/files/features/perks/non_perk_states.lua")
    if ok and type(module) == "table" then non_perk_states = module
    else non_perk_states = { list=function() return {} end, remove=function() return false, "unavailable" end } end
end

local catalog = nil
local remove_mode = false
local take_amount = 1
local right_latched = false
local search = ""
local PERK_STEP = ui.ICON_STEP
local PERK_ICON_SIZE = 18
local warmup_cursor = 1
local perk_icon_cache = {}
local PERK_ICON_FALLBACK = ui.EMPTY_SLOT

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
            name_key = perk.ui_name,
            description = ui.translated(perk.ui_description),
            description_key = perk.ui_description,
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

local function active_job()
    return type(perk_service.job_status) == "function" and perk_service.job_status() or nil
end

local function report_busy()
    GamePrint(ui.tr("$mcm_perk_job_busy", "Finish or cancel the current perk job first"))
end

local function apply_or_spawn(player_entity_id, perk_entry, take_immediately)
    local perk_data = type(perk_entry.data) == "table" and perk_entry.data or perk_entry
    if take_immediately then
        if active_job() ~= nil then return false, "busy" end
        if take_amount > 1 and type(perk_service.start_take_job) == "function" then
            return perk_service.start_take_job(player_entity_id, perk_data, take_amount)
        end
        local applied, reason = perk_service.apply(player_entity_id, perk_data)
        if not applied and reason == "pickup_failed" then
            GamePrint(ui.tr("$mcm_perk_apply_failed", "Could not apply perk") .. ": " .. tostring(perk_entry.name or perk_data.id))
        end
        return applied, reason
    end
    if active_job() ~= nil then return false, "busy" end
    return perk_service.spawn(player_entity_id, perk_data)
end

local function point_inside(bounds, x, y)
    return type(bounds) == "table" and tonumber(x) ~= nil and tonumber(y) ~= nil
        and tonumber(x) >= tonumber(bounds.x or 0) and tonumber(x) <= tonumber(bounds.x or 0) + tonumber(bounds.width or 0)
        and tonumber(y) >= tonumber(bounds.y or 0) and tonumber(y) <= tonumber(bounds.y or 0) + tonumber(bounds.height or 0)
end

local function drag_bounds(x, y, width, height)
    x, y, width, height = tonumber(x), tonumber(y), tonumber(width), tonumber(height)
    if x == nil or y == nil or width == nil or height == nil or width <= 0 or height <= 0 then return nil end
    return {x=x, y=y, width=width, height=height}
end

local function report_spawn_failure(name)
    GamePrint(ui.tr("$mcm_perk_spawn_failed", "Could not spawn perk") .. ": " .. tostring(name or ""))
end

local function handle_completed_drag(player)
    local result = drag_drop.take_result()
    if result == nil or type(result.payload) ~= "table" then return end
    local payload = result.payload
    if payload.kind ~= "catalog_perk" then return end

    if result.click == true then
        local ok, reason = apply_or_spawn(player, payload.data or {id=payload.id}, false)
        audit("perk.spawn", "id=" .. tostring(payload.id) .. " result=" .. tostring(ok) .. " reason=" .. tostring(reason))
        if reason == "busy" then report_busy() elseif not ok then report_spawn_failure(payload.display_name) end
        return
    end
    if result.target ~= nil then return end

    local release_x, release_y = tonumber(result.release_x), tonumber(result.release_y)
    local menu_bounds = type(ui.panel_bounds) == "function" and ui.panel_bounds() or nil
    if release_x == nil or release_y == nil or point_inside(menu_bounds, release_x, release_y) then
        audit("perk.drag.cancel", "id=" .. tostring(payload.id) .. " reason=in_menu")
        return
    end
    local world_x, world_y = tonumber(result.world_x), tonumber(result.world_y)
    if world_x == nil or world_y == nil then
        audit("perk.drag.world", "id=" .. tostring(payload.id) .. " result=false reason=position")
        report_spawn_failure(payload.display_name)
        return
    end
    if active_job() ~= nil then report_busy(); return end
    local ok, reason = perk_service.spawn_at(payload.data or {id=payload.id}, world_x, world_y)
    audit("perk.drag.world", "id=" .. tostring(payload.id) .. " result=" .. tostring(ok)
        .. " reason=" .. tostring(reason) .. " x=" .. tostring(world_x) .. " y=" .. tostring(world_y))
    if not ok then report_spawn_failure(payload.display_name) end
end

local function draw_job_status(panel_width)
    if type(perk_service.consume_job_notice) == "function" then
        local notice = perk_service.consume_job_notice()
        if type(notice) == "table" and notice.state ~= "cancelled" then
            GamePrint(ui.tr("$mcm_perk_job_failed", "Perk job stopped") .. ": " .. tostring(notice.reason or notice.state or "unknown"))
        end
    end
    local job = active_job()
    if job == nil then return false end
    local label = job.kind == "remove_all" and ui.tr("$mcm_perk_job_remove", "REMOVING")
        or ui.tr("$mcm_perk_job_take", "TAKING")
    local wait = job.waiting_async and (" " .. ui.tr("$mcm_perk_job_waiting", "WAIT")) or ""
    ui.wrapped_text(0, 0, label .. " " .. tostring(job.perk_id or "") .. " "
        .. tostring(job.completed or 0) .. "/" .. tostring(job.total or 0) .. wait, math.max(32, panel_width - 10))
    if ui.button_grid({{label=ui.tr("$mcm_perk_job_cancel", "CANCEL")}}, math.max(32, panel_width - 10)) == 1
        and type(perk_service.cancel_job) == "function"
    then
        perk_service.cancel_job()
    end
    return true
end

function perks_tab.draw(player, panel_width, screen_height)
    if not ensure_catalog() then ui.white_text(0, 2, ui.tr("$mcm_perks_failed", "Perk list failed to load")); return end
    perks_tab.warmup_step(1)
    handle_completed_drag(player)
    GuiLayoutBeginVertical(ui.gui(), 0, 2, true)
    local mode_clicked = ui.button_grid({
        {label=ui.tr("$mcm_perk_mode_add", "ADD"),selected=not remove_mode},
        {label=ui.tr("$mcm_perk_mode_remove", "REMOVE"),selected=remove_mode},
    }, math.max(32, panel_width - 10))
    if mode_clicked == 1 then remove_mode = false elseif mode_clicked == 2 then remove_mode = true end
    local control_text = remove_mode and ui.tr("$mcm_perk_remove_controls", "LMB: -1   RMB: REMOVE ALL")
        or (ui.tr("$mcm_perk_add_controls", "LMB: SPAWN   RMB: TAKE") .. "   "
            .. ui.tr("$mcm_creature_drag_spawn", "DRAG: spawn at cursor"))
    ui.wrapped_text(0, 0, control_text, math.max(24,panel_width-10))
    if not remove_mode then
        ui.white_text(0, 0, ui.tr("$mcm_perk_take_amount", "TAKE") .. ":")
        local amounts={1,10,100}; local amount_buttons={}
        for index, amount in ipairs(amounts) do amount_buttons[index]={label=tostring(amount),selected=take_amount==amount} end
        local amount_clicked=ui.button_grid(amount_buttons,math.max(32,panel_width-10))
        if amount_clicked~=nil then take_amount=amounts[amount_clicked] end
    end
    draw_job_status(panel_width)

    search = ui.search_input(search, math.max(68, panel_width - 28), 64, "perks")

    local eligible = {}
    for _, perk in ipairs(catalog) do
        local count = remove_mode and perk_service.count(perk.id) or 0
        if not remove_mode or count > 0 then
            eligible[#eligible + 1] = {perk=perk, count=count}
        end
    end
    -- Active essences/curses use the same removal grid, search, counters and mouse
    -- controls as perks. They never appear in ADD or enter the perk transaction journal.
    if remove_mode then
        for _, state in ipairs(non_perk_states.list(player)) do
            local name = ui.translated(state.name_key)
            if name == "" or name == state.name_key then name = state.id end
            eligible[#eligible + 1] = { count=state.count, perk={
                id=state.id, name=name, name_key=state.name_key,
                description=ui.translated(state.description_key), description_key=state.description_key,
                icon=state.icon, removable_state=true,
            } }
        end
    end
    local matches = ui.rank_entries(search, eligible, function(record)
        local perk = record.perk
        return {perk.name_key, perk.description_key, perk.name, perk.id, perk.description}
    end, function(record) return record.perk.id end)
    ui.search_status(search, #matches)
    local h = ui.scroll_height(screen_height, 132)
    local scroll = ui.begin_scroll_viewport("perks.catalog." .. tostring(remove_mode),
        10100 + (remove_mode and 1000 or 0), 0, 0, panel_width - 4, h, {layout="free"})
    local columns = ui.columns(scroll.content_width, PERK_STEP, {reserve_scrollbar=false})
    local right_down = false
    if type(InputIsMouseButtonDown) == "function" then
        local ok, down = pcall(InputIsMouseButtonDown, tonumber(rawget(_G, "Mouse_right")) or tonumber(rawget(_G, "MOUSE_RIGHT")) or 2)
        right_down = ok and down == true
    end
    local visible = 0
    for index, match in ipairs(matches) do
        local perk = match.perk
        local count = match.count
        local can_remove, reason = true, nil
        if remove_mode and not perk.removable_state then
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
        local clicked, right, hovered, tile_x, tile_y, tile_w, tile_h = ui.tile(scroll.padding_left + (i % columns) * PERK_STEP,
            ui.scroll_y(scroll, math.floor(i / columns) * PERK_STEP),
            ui.EMPTY_SLOT, display_icon(perk, perk.removable_state == true), PERK_ICON_FALLBACK, perk.name, desc,
            remove_mode and count > 0 and can_remove,
            { target_size=PERK_ICON_SIZE, icon_box_size=PERK_ICON_SIZE, max_scale=8.0, fill=1.15, padding=0,
              icon_tint=remove_mode and not can_remove and {0.48,0.48,0.48,0.82} or nil,
              marker_color=remove_mode and not can_remove and {1.0,0.25,0.20,0.92} or nil })
        if hovered and perk_icon_cache[tostring(perk.id or perk.icon or "")] == nil then display_icon(perk, true) end
        if not remove_mode then
            local bounds = drag_bounds(tile_x, tile_y, tile_w, tile_h)
            if bounds ~= nil then
                drag_drop.source("perks.catalog." .. tostring(perk.id), {
                    kind="catalog_perk", id=perk.id, data=perk.data, display_name=perk.name,
                    background=ui.EMPTY_SLOT, icon=display_icon(perk, false),
                }, bounds, {x=scroll.x, y=scroll.y, width=scroll.width, height=scroll.height})
            end
        end
        local right_command = right and not right_latched
        if right_command and right_down then right_latched = true end
        local job_running = active_job() ~= nil
        if remove_mode then
            if can_remove and clicked and count > 0 then
                if job_running then
                    report_busy()
                else
                    local ok, reason
                    if perk.removable_state then ok, reason = non_perk_states.remove_one(player, perk.id)
                    else ok, reason = perk_service.remove_one(player, perk.data) end
                    audit("perk.remove_one", "id="..tostring(perk.id).." result="..tostring(ok).." reason="..tostring(reason).." scope=peer_local")
                    if not ok then GamePrint(ui.tr("$mcm_perk_remove_failed", "Could not safely remove perk") .. ": " .. perk.name) end
                end
            elseif can_remove and right_command and count > 0 then
                if job_running then
                    report_busy()
                else
                    local queued, reason
                    if perk.removable_state then queued, reason = non_perk_states.remove(player, perk.id)
                    else queued, reason = perk_service.start_remove_all_job(player, perk.data) end
                    audit("perk.remove_all.queue", "id="..tostring(perk.id).." queued="..tostring(queued).." reason="..tostring(reason).." scope=peer_local")
                    if not queued then GamePrint(ui.tr("$mcm_perk_remove_failed", "Could not safely remove perk") .. ": " .. tostring(reason)) end
                end
            end
        else
            -- LMB is owned by drag_drop: a short press becomes exactly one spawn on the
            -- next frame, while a real drag may place the perk at world coordinates.
            -- Do not also consume ui.tile's click signal or short clicks would duplicate.
            if right_command then
                local ok, reason=apply_or_spawn(player, perk, true)
                audit("perk.take", "id="..tostring(perk.id).." amount="..tostring(take_amount).." result="..tostring(ok).." reason="..tostring(reason))
                if reason == "busy" then report_busy() end
            end
        end
    end
    if not right_down then right_latched = false end
    ui.end_scroll_viewport(scroll, math.ceil(visible / columns) * PERK_STEP)
    if drag_drop.active() then
        local payload = drag_drop.payload()
        local mouse_x, mouse_y = drag_drop.mouse_position()
        if type(payload) == "table" and payload.kind == "catalog_perk" then
            ui.drag_ghost(payload.background, payload.icon, mouse_x, mouse_y)
        end
    end
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
