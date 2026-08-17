if type(METAMORPH_CREATIVE_MENU_QA_RUNNER) == "table" then return METAMORPH_CREATIVE_MENU_QA_RUNNER end

local qa_runner = {}
local diagnostics = dofile("mods/metamorph_creative_menu/files/diagnostics/service.lua")
local player_locator = dofile("mods/metamorph_creative_menu/files/platform/noita/player_locator.lua")
local form_manager = dofile("mods/metamorph_creative_menu/files/features/forms/manager.lua")
local creature_service = dofile("mods/metamorph_creative_menu/files/features/creatures/service.lua")
local weather = dofile("mods/metamorph_creative_menu/files/features/weather/service.lua")
local world_rules = dofile("mods/metamorph_creative_menu/files/features/world_rules/service.lua")
local perk_service = dofile("mods/metamorph_creative_menu/files/features/perks/service.lua")
local effect_service = dofile("mods/metamorph_creative_menu/files/features/effects/service.lua")
local item_catalog = dofile("mods/metamorph_creative_menu/files/features/items/catalog.lua")
local item_service = dofile("mods/metamorph_creative_menu/files/features/items/service.lua")
local possession = dofile("mods/metamorph_creative_menu/files/features/possession/service.lua")
local player_avatar = dofile("mods/metamorph_creative_menu/files/features/companion/player_avatar.lua")

local state = nil
local remote_peer_count = nil
local run_counter = 0
local spell_roundtrip = dofile("mods/metamorph_creative_menu/files/qa/spell_roundtrip.lua")
local qa_cases = dofile("mods/metamorph_creative_menu/files/qa/cases.lua")
local WAIT_SHORT = qa_cases.WAIT_SHORT
local WAIT_RULE = qa_cases.WAIT_RULE
local WAIT_WEATHER = qa_cases.WAIT_WEATHER
local FORM_DWELL = qa_cases.FORM_DWELL
local NETWORK_FORM_DWELL = qa_cases.NETWORK_FORM_DWELL
local NETWORK_FORM_SETTLE = qa_cases.NETWORK_FORM_SETTLE
local NETWORK_PEER_LOSS_GRACE = qa_cases.NETWORK_PEER_LOSS_GRACE
local NETWORK_FORM_CASES = qa_cases.NETWORK_FORM_CASES
local SINGLEPLAYER_ITEM_RUNTIME_CASES = qa_cases.SINGLEPLAYER_ITEM_RUNTIME_CASES
local NETWORK_ITEM_CASES = qa_cases.NETWORK_ITEM_CASES
local FORM_TIMEOUT = qa_cases.FORM_TIMEOUT
local RETURN_TIMEOUT = qa_cases.RETURN_TIMEOUT
local HEARTBEAT_INTERVAL = qa_cases.HEARTBEAT_INTERVAL
local QA_SKIP_PERKS = qa_cases.QA_SKIP_PERKS
local CORE_FORM_CASES = qa_cases.CORE_FORM_CASES
local QA_UNSAFE_FORMS = qa_cases.QA_UNSAFE_FORMS

local function frame() return tonumber(GameGetFrameNum()) or 0 end
local function real_time() local ok,v=pcall(GameGetRealWorldTimeSinceStarted); return ok and tonumber(v) or nil end
local function valid(e) return e ~= nil and e ~= 0 and EntityGetIsAlive(e) end
local function log(kind, details) diagnostics.event(kind, details) end
local function action(name, details) diagnostics.test_action(name, details) end
local function step_begin(name, details)
    if state then
        state.current_step = tostring(name); state.step_started_frame=frame(); state.step_started_time=real_time()
        GlobalsSetValue("mcm_qa_phase_v1", tostring(state.phase or ""))
        GlobalsSetValue("mcm_qa_step_v1", tostring(state.current_step or ""))
    end
    log("STEP BEGIN", "phase=" .. tostring(state and state.phase or "?") .. " step=" .. tostring(name) .. (details and (" " .. tostring(details)) or ""))
end
local function step_end(level, name, details)
    local timing=""
    if state and state.step_started_frame then
        timing=" frames="..tostring(frame()-state.step_started_frame)
        local t=real_time(); if t and state.step_started_time then timing=timing..string.format(" elapsed_ms=%.2f",(t-state.step_started_time)*1000) end
    end
    local n=tostring(name or "")
    -- For large deterministic loops, STEP BEGIN is the crash breadcrumb and the next
    -- BEGIN implies success. Persist every WARN/FAIL, but omit routine PASS duplicates.
    local mass = string.sub(n,1,5)=="perk." or string.sub(n,1,5)=="item." or string.sub(n,1,7)=="effect."
    if tostring(level)=="PASS" and mass then return end
    log("STEP " .. tostring(level), "phase=" .. tostring(state and state.phase or "?") .. " step=" .. n .. timing .. (details and (" " .. tostring(details)) or ""))
end

local function player()
    local ok, p = pcall(player_locator.get)
    p = ok and tonumber(p) or 0
    return valid(p) and p or 0
end

local baselines = dofile("mods/metamorph_creative_menu/files/qa/baselines.lua")
local snapshot_world_controls = baselines.snapshot_world_controls
local restore_world_controls = baselines.restore_world_controls
local world_controls_match = baselines.world_controls_match
local restore_player_baseline = baselines.restore_player
local snapshot_player = baselines.snapshot_player
local perk_guard_snapshot = baselines.perk_guard_snapshot
local perk_guard_diff = baselines.perk_guard_diff
local repair_perk_guard = baselines.repair_perk_guard
local compact_issues = baselines.compact_issues

local function heartbeat()
    if not state then return end
    local f=frame()
    if f-(state.last_heartbeat or -100000)<HEARTBEAT_INTERVAL then return end
    state.last_heartbeat=f
    local p=player()
    local path=p~=0 and tostring(EntityGetFilename(p) or "") or ""
    local x,y=0,0
    if p~=0 then x,y=EntityGetTransform(p) end
    log("HEARTBEAT", string.format("run=%s phase=%s step=%s player=%s file=%s pos=%.1f,%.1f form_phase=%s target=%s rules=%s weather_locked=%s",
        tostring(state.id),tostring(state.phase),tostring(state.current_step or ""),tostring(p),path,tonumber(x) or 0,tonumber(y) or 0,
        tostring(form_manager.session_phase()),tostring(form_manager.session_target() or ""),tostring(world_rules.has_overrides()),tostring(weather.is_locked())))
    if ModIsEnabled("quant.ew") then
        log("EW HEARTBEAT","remote_players="..tostring(remote_peer_count()).." bridge_ready="..tostring(GlobalsGetValue("mcm_world_rules_rpc_ready_v1","0"))..
            " world_sent="..tostring(GlobalsGetValue("mcm_world_sync_sent_chunks_v1","?")).."/"..tostring(GlobalsGetValue("mcm_world_sync_sent_bytes_v1","?"))..
            " world_recv="..tostring(GlobalsGetValue("mcm_world_sync_recv_chunks_v1","?")).."/"..tostring(GlobalsGetValue("mcm_world_sync_recv_bytes_v1","?"))..
            " trail="..tostring(GlobalsGetValue("mcm_world_sync_trail_backlog_v1","?")))
    end
end

local function set_wait(frames, next_phase)
    state.wait_until=frame()+math.max(1,tonumber(frames) or 1)
    state.next_phase=next_phase
    state.phase="wait"
end

local function restore_human_and_baseline()
    local p=player()
    if p~=0 and EntityHasTag(p,"polymorphed_player") then pcall(form_manager.return_to_human) end
    if state and state.world_baseline then restore_world_controls(state.world_baseline) else pcall(weather.release); pcall(world_rules.reset) end
end

local function finish(reason)
    if not state then return end
    restore_human_and_baseline()
    local final_reason = tostring(reason or "complete")
    local outcome = (string.find(final_reason, "aborted", 1, true) or string.find(final_reason, "_lost", 1, true) or string.find(final_reason, "exception", 1, true)) and "ABORTED"
        or ((state.fail > 0 or state.dirty) and "FAILED" or "PASS")
    log("AUTOTEST SUMMARY", string.format("run=%s outcome=%s reason=%s pass=%d warn=%d fail=%d dirty=%s spell=%s forms=%d/%d(catalog=%d) items=%d/%d(catalog=%d) item_runtime=%d/%d perks=%d/%d effects=%d/%d peers=%d->%d",
        tostring(state.id),outcome,final_reason,state.pass,state.warn,state.fail,tostring(state.dirty),tostring(state.spell_result or "not_run"),state.form_done,#state.forms,state.forms_catalog or #state.forms,state.item_done,#state.items,state.items_catalog or #state.items,state.item_runtime_done or 0,#(state.item_runtime_cases or {}),state.perk_done,#state.perks,state.effect_done,#state.effects,state.peer_baseline or 0,remote_peer_count()))
    log("=== EWCM AUTOTEST END", "run="..tostring(state.id).." outcome="..outcome.." result="..final_reason)
    GamePrintImportant("Metamorph: Creative Menu QA", outcome..": pass="..state.pass.." warn="..state.warn.." fail="..state.fail)
    METAMORPH_CREATIVE_MENU_QA_ACTIVE = false
    GlobalsSetValue("mcm_qa_active_v1", "0"); GlobalsSetValue("mcm_qa_phase_v1", "done"); GlobalsSetValue("mcm_qa_step_v1", tostring(reason or "complete"))
    state=nil
end

local function mark(level,name,details)
    if level=="PASS" then state.pass=state.pass+1 elseif level=="FAIL" then state.fail=state.fail+1 else state.warn=state.warn+1 end
    step_end(level,name,details)
end

local function reset_rules_checked(context)
    if not state or not state.can_rules then return true end
    local clean=false; local reason="unknown"
    for _=1,3 do
        local ok,res,why=pcall(world_rules.reset)
        reason=ok and tostring(why or res) or tostring(res)
        if ok and res==true and not world_rules.has_overrides() then clean=true; break end
    end
    if not clean then
        state.fail=state.fail+1; state.dirty=true
        log("STEP FAIL","phase=world_reset context="..tostring(context or "?").." reason="..tostring(reason).." overrides="..tostring(world_rules.has_overrides()))
    end
    return clean
end

remote_peer_count = function()
    if not ModIsEnabled("quant.ew") then return 0 end
    local ok, values = pcall(EntityGetWithTag, "ew_client")
    return ok and type(values) == "table" and #values or 0
end

local function select_named_entries(values, wanted, key_fn)
    local by_key, result = {}, {}
    for _, value in ipairs(values or {}) do by_key[key_fn(value)] = value end
    for _, key in ipairs(wanted or {}) do if by_key[key] ~= nil then result[#result+1] = by_key[key] end end
    return result
end

local function warmup_creature_catalog_for_qa()
    local ok_collect = pcall(creature_service.collect)
    if not ok_collect then return false, "collect_failed" end
    if type(creature_service.warmup_step) ~= "function" then return true, "no_warmup_api" end
    for _ = 1, 128 do
        local ok, done = pcall(creature_service.warmup_step, 64)
        if not ok then return false, "warmup_exception" end
        if done == true then return true, "complete" end
    end
    return false, "warmup_timeout"
end

local function build_catalogs()
    pcall(dofile_once,"data/scripts/perks/perk.lua")
    pcall(dofile_once,"data/scripts/perks/perk_list.lua")
    local perks=type(perk_list)=="table" and perk_list or {}
    local effects={}
    local ok_e,e=pcall(effect_service.catalog); if ok_e and type(e)=="table" then effects=e end

    -- Z is allowed to spend a bounded synchronous budget preparing the creature catalogue.
    -- The UI remains lazy during normal play, but QA must test the same catalogue the player sees.
    local warmup_ok, warmup_reason = warmup_creature_catalog_for_qa()
    -- QA must use the same fully-warmed, structurally admitted catalogue shown by MOBS.
    -- collect_prewarm_candidates() is intentionally broader and exists only for early exact-
    -- polymorph resource publication; treating that prewarm set as UI forms would test
    -- technical/unvalidated XML that the player cannot select.
    local ok_all, all = pcall(creature_service.collect)
    if not ok_all or type(all) ~= "table" then all = {} end
    local ui_mob_count = #all
    local ui_paths = {}
    for _, entry in ipairs(all) do
        if type(entry) == "table" and type(entry.path) == "string" and entry.path ~= "" then
            ui_paths[entry.path] = true
        end
    end

    -- Singleplayer QA tests the actual fully-warmed MOBS transform surface, not the
    -- smaller PolymorphTableGet() subset. If a path is selectable in PLAY mode, Z must
    -- attempt it too unless it is an evidence-backed exact unsafe exclusion.
    local forms={}
    local seen={}
    for _, entry in ipairs(all) do
        local path=type(entry)=="table" and tostring(entry.path or "") or tostring(entry or "")
        if path~="" and path~="data/entities/player.xml" and not seen[path] and QA_UNSAFE_FORMS[path]==nil then
            seen[path]=true
            forms[#forms+1]=path
        end
    end

    local items={}
    local ok_i,i=pcall(function() return item_catalog end); if ok_i and type(i)=="table" then items=i end
    return perks,effects,forms,items,ui_mob_count,warmup_ok,warmup_reason,ui_paths
end

local function catalog_preflight(perks, effects, forms, items, ui_mob_count, warmup_ok, warmup_reason, ui_paths)
    local fatal, warnings = {}, {}
    if warmup_ok ~= true then fatal[#fatal+1] = "creature_warmup="..tostring(warmup_reason) end
    if #(perks or {}) < 80 then fatal[#fatal+1] = "perks="..tostring(#(perks or {})) end
    if #(effects or {}) < 20 then fatal[#fatal+1] = "effects="..tostring(#(effects or {})) end
    if #(items or {}) < 100 then fatal[#fatal+1] = "items="..tostring(#(items or {})) end
    if tonumber(ui_mob_count) == nil or tonumber(ui_mob_count) < 50 then fatal[#fatal+1] = "mobs="..tostring(ui_mob_count) end
    if #(forms or {}) < 20 then fatal[#fatal+1] = "forms="..tostring(#(forms or {})) end
    local set = {}
    for _, path in ipairs(forms or {}) do set[tostring(path)] = true end
    local missing, unavailable = {}, {}
    for _, path in ipairs(CORE_FORM_CASES) do
        if not set[path] then
            if type(ui_paths)=="table" and ui_paths[path] then missing[#missing+1] = path
            else unavailable[#unavailable+1] = path end
        end
    end
    if #missing > 0 then warnings[#warnings+1] = "core_forms_not_selected="..table.concat(missing, ",") end
    if #unavailable > 0 then warnings[#warnings+1] = "core_forms_unavailable="..table.concat(unavailable, ",") end
    local gamble = nil
    for _, perk in ipairs(perks or {}) do if tostring(perk.id or "") == "GAMBLE" then gamble = perk; break end end
    if gamble ~= nil then
        local ok_can, can, why = pcall(perk_service.can_remove, gamble, player())
        if not ok_can or can ~= true then fatal[#fatal+1] = "gamble_remove="..tostring(why or can) end
    else
        fatal[#fatal+1] = "gamble_missing"
    end
    return #fatal == 0, fatal, warnings
end

local function abort_dirty(reason)
    if not state then return end
    state.dirty = true
    state.abort_reason = tostring(reason or "dirty")
    log("AUTOTEST DIRTY ABORT", "phase="..tostring(state.phase).." step="..tostring(state.current_step).." reason="..state.abort_reason)
    state.phase = "finalize"
end

local function gravity_rule()
    for _, rule in ipairs(world_rules.rules() or {}) do if rule.id == "physics_gravity" then return rule end end
    return nil
end

local function gravity_debug_ok(expected_factor)
    if type(world_rules.local_gravity_debug) ~= "function" then return false, "debug_api_missing" end
    local ok, info = pcall(world_rules.local_gravity_debug)
    if not ok or type(info) ~= "table" then return false, "debug_failed" end
    local rows = info.rows or {}
    if #rows == 0 then return false, "no_player_gravity_components" end
    local details = {}
    local all = true
    for _, row in ipairs(rows) do
        local current, expected = tonumber(row.current), tonumber(row.expected)
        local match = current ~= nil and expected ~= nil and math.abs(current-expected) < 0.001
        all = all and match
        details[#details+1] = tostring(row.field).."="..tostring(current).." expected="..tostring(expected).." native="..tostring(row.native)
    end
    if tonumber(info.factor) ~= tonumber(expected_factor) then all = false end
    return all, table.concat(details, ";")
end

local function take_perk(p, perk)
    local ok, reason, tracked, track_reason = perk_service.apply(p, perk, {source="qa", ignore_debounce=true})
    if not ok then return false, reason end
    if tracked ~= true then
        return false, "untracked:"..tostring(track_reason or reason or "unknown")
    end
    return true, "ok:tracked=true:"..tostring(track_reason)
end

local function retire_entity_safely(e)
    if not valid(e) then return end
    for _,c in ipairs(EntityGetAllComponents(e) or {}) do
        local ok,n=pcall(ComponentGetTypeName,c)
        if ok and n=="LuaComponent" then pcall(EntityRemoveComponent,e,c) else pcall(EntitySetComponentIsEnabled,e,c,false) end
    end
    pcall(EntitySetTransform,e,10000000,10000000)
    pcall(EntityKill,e)
end

local function qa_item_root(entity)
    if not valid(entity) then return false end
    local root = entity
    if type(EntityGetRootEntity)=="function" then
        local ok, value=pcall(EntityGetRootEntity,entity); if ok and value~=nil and value~=0 then root=value end
    end
    if root~=entity then return false end
    local filename=string.lower(tostring(EntityGetFilename(entity) or ""))
    if string.sub(filename,1,20)=="data/entities/items/" then return true end
    for _,tag in ipairs({"item","item_pickup","item_physics","wand"}) do
        local ok,has=pcall(EntityHasTag,entity,tag); if ok and has then return true end
    end
    return false
end

local function qa_item_snapshot(p, radius)
    local result={}
    local x,y=EntityGetTransform(p); if x==nil then return result end
    local ok,values=pcall(EntityGetInRadius,x,y,tonumber(radius) or 180)
    if ok and type(values)=="table" then
        for _,entity in ipairs(values) do if qa_item_root(entity) then result[entity]=true end end
    end
    return result
end

local function qa_new_item_roots(p, before, radius)
    local result={}
    for entity in pairs(qa_item_snapshot(p,radius)) do
        if not (before or {})[entity] then result[#result+1]=entity end
    end
    return result
end

local function perk_by_id(id)
    for _,perk in ipairs(state and state.perks or {}) do if perk.id==id then return perk end end
    return nil
end

local function perk_count_snapshot()
    local result={}
    for _,perk in ipairs(state and state.perks or {}) do
        local id=tostring(perk.id or "")
        if id~="" then result[id]=perk_service.count(id) end
    end
    return result
end

local function perk_count_residue(baseline)
    local issues={}
    for _,perk in ipairs(state and state.perks or {}) do
        local id=tostring(perk.id or "")
        if id~="" then
            local before=tonumber((baseline or {})[id]) or 0
            local after=perk_service.count(id)
            if after~=before then issues[#issues+1]=id..":"..tostring(before).."->"..tostring(after) end
        end
    end
    return issues
end

local function count_child_file(root, wanted)
    local n=0
    for _,child in ipairs(EntityGetAllChildren(root) or {}) do
        if tostring(EntityGetFilename(child) or "")==wanted then n=n+1 end
    end
    return n
end

local function visible_alpha_summary(root)
    local min_a,max_a,count=1,0,0
    for _,c in ipairs(EntityGetComponentIncludingDisabled(root,"SpriteComponent") or {}) do
        local ok,a=pcall(ComponentGetValue2,c,"alpha"); a=ok and tonumber(a) or nil
        if a~=nil then min_a=math.min(min_a,a); max_a=math.max(max_a,a); count=count+1 end
    end
    return min_a,max_a,count
end

local begin_spell_roundtrip = spell_roundtrip.begin
local cleanup_spell_roundtrip = spell_roundtrip.cleanup

local function start()
    if state then GamePrint("Metamorph: Creative Menu QA already running"); return false end
    local p=player(); if p==0 then GamePrint("Metamorph: Creative Menu QA: no player"); return false end
    run_counter=run_counter+1
    -- The independent diagnostic scan must start even when scenario preflight later fails.
    -- This guarantees that Z always produces actionable evidence instead of a silent abort.
    pcall(diagnostics.start_scan)
    local perks,effects,forms_all,items_all,ui_mob_count,warmup_ok,warmup_reason,ui_paths=build_catalogs()
    local peers = remote_peer_count()
    local networked = ModIsEnabled("quant.ew") and peers > 0
    local preflight_ok, preflight_fatal, preflight_warnings = catalog_preflight(perks, effects, forms_all, items_all, ui_mob_count, warmup_ok, warmup_reason, ui_paths)
    if #preflight_warnings > 0 then
        log("AUTOTEST PREFLIGHT WARN", "issues="..table.concat(preflight_warnings, ";"))
    end
    if not preflight_ok then
        log("AUTOTEST PREFLIGHT FAIL", "issues="..table.concat(preflight_fatal, ";"))
        GamePrintImportant("Metamorph: Creative Menu QA", "ABORTED: scenario preflight failed; diagnostic scan is still running")
        return false
    end
    local forms = networked and select_named_entries(forms_all, NETWORK_FORM_CASES, function(v) return tostring(v or "") end) or forms_all
    local items = networked and select_named_entries(items_all, NETWORK_ITEM_CASES, function(v) return tostring(type(v)=="table" and v.path or v or "") end) or items_all
    local item_runtime_cases = networked and {} or select_named_entries(items_all, SINGLEPLAYER_ITEM_RUNTIME_CASES, function(v) return tostring(type(v)=="table" and v.path or v or "") end)
    if not networked and #item_runtime_cases ~= #SINGLEPLAYER_ITEM_RUNTIME_CASES then
        log("AUTOTEST PREFLIGHT FAIL", "issues=runtime_item_cases="..tostring(#item_runtime_cases).."/"..tostring(#SINGLEPLAYER_ITEM_RUNTIME_CASES))
        GamePrintImportant("Metamorph: Creative Menu QA", "ABORTED: representative item set incomplete; diagnostic scan is still running")
        return false
    end
    state={id=tostring(os and os.time and os.time() or frame()).."-"..tostring(run_counter),phase="baseline",pass=0,warn=0,fail=0,dirty=false,
        baseline=snapshot_player(p),baseline_guard=perk_guard_snapshot(p),world_baseline=snapshot_world_controls(),perks=perks,effects=effects,forms=forms,items=items,item_runtime_cases=item_runtime_cases,ui_mob_count=ui_mob_count,perk_i=1,effect_i=1,form_i=1,item_i=1,item_runtime_i=1,
        forms_catalog=#forms_all,items_catalog=#items_all,networked=networked,peer_baseline=peers,peer_loss_since=nil,
        perk_done=0,effect_done=0,form_done=0,item_done=0,item_runtime_done=0,last_heartbeat=-100000,current_step="start",stack_case_i=1,stack_take_i=0,stack_remove_i=0,batch_i=1,batch_remove_i=1,combo_i=1,
        can_rules=select(1,world_rules.can_edit()),can_weather=select(1,weather.can_edit()),spell_result="pending"}
    METAMORPH_CREATIVE_MENU_QA_ACTIVE = true
    GlobalsSetValue("mcm_qa_active_v1", "1"); GlobalsSetValue("mcm_qa_run_v1", tostring(state.id)); GlobalsSetValue("mcm_qa_peer_baseline_v1", tostring(peers))
    log("=== EWCM AUTOTEST BEGIN",string.format("run=%s frame=%d perks=%d effects=%d forms_test=%d forms_catalog=%d mobs_total=%d items_test=%d items_catalog=%d ew=%s peers=%d network_safe=%s",state.id,frame(),#perks,#effects,#forms,#forms_all,ui_mob_count,#items,#items_all,tostring(ModIsEnabled("quant.ew")),peers,tostring(networked)))
    log("TEST CONFIG","destructive=true rollback=phase_checkpoint fail_fast_dirty=true item_mode="..(networked and "network_representative" or "singleplayer_static_catalog+visible_representative").." crash_resume_marker=true multiplayer_representative="..tostring(networked))
    GamePrintImportant("Metamorph: Creative Menu QA","STARTED. Z runs full scenario test; diagnostics are running in parallel.")
    return true
end

local WEATHER_PRESETS={"clear","cloudy","foggy","storm","clear"}
local TIME_PRESETS={"morning","day","evening","night"}

local function update_state()
    local f=frame()
    if state.phase=="wait" then if f>=state.wait_until then state.phase=state.next_phase end return end
    local p=player()
    if p==0 then mark("FAIL","player_alive","player missing/dead"); finish("player_lost"); return end
    if state.networked and (state.peer_baseline or 0) > 0 then
        local peers = remote_peer_count()
        if peers < state.peer_baseline then
            if state.peer_loss_since == nil then
                state.peer_loss_since = f
                log("NETWORK PEER DROP", "baseline="..tostring(state.peer_baseline).." current="..tostring(peers).." phase="..tostring(state.phase).." step="..tostring(state.current_step))
            elseif f - state.peer_loss_since >= NETWORK_PEER_LOSS_GRACE then
                mark("FAIL", "network.peer_loss", "baseline="..tostring(state.peer_baseline).." current="..tostring(peers).." persisted_frames="..tostring(f-state.peer_loss_since))
                finish("peer_lost")
                return
            end
        elseif state.peer_loss_since ~= nil then
            log("NETWORK PEER RECOVER", "current="..tostring(peers).." drop_frames="..tostring(f-state.peer_loss_since))
            state.peer_loss_since = nil
        end
    end

    if state.phase=="baseline" then
        step_begin("baseline")
        local r_ok,w_ok=true,true
        if state.can_rules then r_ok=reset_rules_checked("baseline") end
        if state.can_weather then local call,res=pcall(weather.release); w_ok=call and res==true end
        mark(r_ok and w_ok and "PASS" or "WARN","baseline","world_reset="..tostring(r_ok).." weather_release="..tostring(w_ok).." preexisting_effects_preserved=true can_rules="..tostring(state.can_rules).." can_weather="..tostring(state.can_weather))
        if not state.can_weather and not state.can_rules then log("STEP SKIP","phase=peer_controls reason=controls_unavailable"); state.phase="spell_start"; return end
        if state.can_weather then state.weather_i=1; state.phase="weather_apply" else state.rule_i=1; state.phase="rule_apply" end
        return
    end

    if state.phase=="weather_apply" then
        local name=WEATHER_PRESETS[state.weather_i]
        if not name then state.time_i=1; state.phase="time_apply"; return end
        step_begin("weather."..name)
        action("weather.apply_preset","name="..tostring(name)); local ok,reason=weather.apply_preset(name)
        state.pending_name=name; state.pending_ok=ok; state.pending_reason=reason; state.pending_weather_frame=f
        set_wait(WAIT_WEATHER,"weather_verify"); return
    end
    if state.phase=="weather_verify" then
        local locked=weather.is_locked()
        local weather_ok=state.pending_ok and locked
        local extra=""
        if state.pending_name=="clear" and type(weather.debug_state)=="function" then
            local ok_state,dbg=pcall(weather.debug_state)
            local rainfall=ok_state and type(dbg)=="table" and tonumber(dbg.rainfall) or nil
            local rain=ok_state and type(dbg)=="table" and tonumber(dbg.rain) or nil
            local target=ok_state and type(dbg)=="table" and tonumber(dbg.rain_target) or nil
            local last_emit=ok_state and type(dbg)=="table" and tonumber(dbg.last_rain_emit_frame) or nil
            local stopped=rainfall~=nil and rain~=nil and target~=nil and math.abs(rainfall)<0.0001 and math.abs(rain)<0.0001 and math.abs(target)<0.0001
                and (last_emit==nil or last_emit < (tonumber(state.pending_weather_frame) or f))
            weather_ok=weather_ok and stopped
            extra=" rainfall="..tostring(rainfall).." rain="..tostring(rain).." rain_target="..tostring(target).." last_emit="..tostring(last_emit).." stopped="..tostring(stopped)
        end
        mark(weather_ok and "PASS" or "FAIL","weather."..state.pending_name,"apply="..tostring(state.pending_ok).." reason="..tostring(state.pending_reason).." locked="..tostring(locked)..extra)
        state.weather_i=state.weather_i+1; state.phase="weather_apply"; return
    end
    if state.phase=="time_apply" then
        local name=TIME_PRESETS[state.time_i]
        if not name then pcall(weather.release); if state.can_rules then state.rule_i=1; state.phase="rule_apply" else state.phase="spell_start" end; return end
        step_begin("time."..name)
        action("weather.set_time_preset","name="..tostring(name)); local ok,reason=weather.set_time_preset(name)
        state.pending_name=name; state.pending_ok=ok; state.pending_reason=reason
        set_wait(WAIT_SHORT,"time_verify"); return
    end
    if state.phase=="time_verify" then
        mark(state.pending_ok and "PASS" or "FAIL","time."..state.pending_name,"reason="..tostring(state.pending_reason).." time="..tostring(weather.get_time()))
        state.time_i=state.time_i+1; state.phase="time_apply"; return
    end

    if state.phase=="rule_apply" then
        if not state.can_rules then state.phase="spell_start"; return end
        local rules=world_rules.rules() or {}; local rule=rules[state.rule_i]
        if not rule then state.combo_i=1; state.phase="rule_combo"; return end
        if not world_rules.supported(rule) then mark("WARN","rule."..tostring(rule.id),"unsupported"); state.rule_i=state.rule_i+1; return end
        step_begin("rule."..tostring(rule.id),"from="..tostring(world_rules.choice_label(rule)))
        action("world_rule.step","id="..tostring(rule.id).." direction=1"); local ok,reason=world_rules.step(rule,1); state.pending_rule=rule; state.pending_ok=ok; state.pending_reason=reason
        set_wait(WAIT_RULE,"rule_verify"); return
    end
    if state.phase=="rule_verify" then
        local r=state.pending_rule; local over=world_rules.is_overridden(r)
        mark(state.pending_ok and over and "PASS" or "FAIL","rule."..tostring(r.id),"reason="..tostring(state.pending_reason).." choice="..tostring(world_rules.choice_label(r)))
        local clean=reset_rules_checked("rule."..tostring(r.id)); state.rule_i=state.rule_i+1; state.phase=clean and "rule_apply" or "spell_start"; return
    end
    if state.phase=="rule_combo" then
        local combos={{"relations","infinite_spells","gold_forever"},{"physics_gravity","physics_damping","day_speed"},{"gore","blood_amount","damage_flash"}}
        local combo=combos[state.combo_i]
        if not combo then state.phase="cross_combo"; return end
        local rules=world_rules.rules() or {}; local chosen={}
        for _,id in ipairs(combo) do
            for _,r in ipairs(rules) do if r.id==id and world_rules.supported(r) then action("world_rule.combo_step","id="..tostring(id).." direction=1 combo="..tostring(state.combo_i)); local ok=world_rules.step(r,1); chosen[#chosen+1]=id..":"..tostring(ok); break end end
        end
        step_begin("rule.combo."..state.combo_i,table.concat(chosen,",")); set_wait(60,"rule_combo_verify"); return
    end
    if state.phase=="rule_combo_verify" then
        local over=world_rules.has_overrides(); mark(over and "PASS" or "FAIL","rule.combo."..state.combo_i,"overrides="..tostring(over)); local clean=reset_rules_checked("combo."..tostring(state.combo_i)); state.combo_i=state.combo_i+1; state.phase=clean and "rule_combo" or "spell_start"; return
    end
    if state.phase=="cross_combo" then
        step_begin("cross.weather_rules","storm + gravity + day_speed")
        action("cross.weather","preset=storm"); local wok=select(1,weather.apply_preset("storm")); local rules=world_rules.rules() or {}; local n=0
        for _,id in ipairs({"physics_gravity","day_speed"}) do for _,r in ipairs(rules) do if r.id==id and world_rules.supported(r) then action("cross.rule","id="..tostring(id).." direction=1"); if world_rules.step(r,1) then n=n+1 end; break end end end
        state.cross_ok=wok and n>0; set_wait(90,"cross_combo_verify"); return
    end
    if state.phase=="cross_combo_verify" then
        mark(state.cross_ok and weather.is_locked() and world_rules.has_overrides() and "PASS" or "FAIL","cross.weather_rules","weather="..tostring(weather.is_locked()).." rules="..tostring(world_rules.has_overrides()))
        pcall(weather.release); reset_rules_checked("cross.weather_rules"); state.phase="spell_start"; return
    end

    if state.phase=="spell_start" then
        step_begin("spell.roundtrip")
        action("spell.roundtrip_begin","safe_temp_capacity=true")
        local ctx,reason=begin_spell_roundtrip(p)
        if not ctx then state.spell_result="skipped:"..tostring(reason); mark("WARN","spell.roundtrip","skipped reason="..tostring(reason)); state.phase="perk_apply"; return end
        state.spell_ctx=ctx; state.spell_begin_reason=reason
        set_wait(3,"spell_verify"); return
    end
    if state.phase=="spell_verify" then
        local ctx=state.spell_ctx; local found=false; local found_id=""
        if ctx and valid(ctx.created) then
            for _,child in ipairs(EntityGetAllChildren(ctx.wand.entity) or {}) do
                if child==ctx.created then
                    local ac=EntityGetFirstComponentIncludingDisabled(child,"ItemActionComponent")
                    if ac and ac~=0 then found_id=tostring(ComponentGetValue2(ac,"action_id") or ""); found=found_id==ctx.action_id end
                    break
                end
            end
        end
        state.spell_insert_ok=found
        action("spell.roundtrip_restore","action="..tostring(ctx and ctx.action_id).." slot="..tostring(ctx and ctx.slot).." inserted="..tostring(found))
        local rok,rreason=cleanup_spell_roundtrip(p,ctx); state.spell_restore_call=rok; state.spell_restore_reason=rreason
        set_wait(3,"spell_restore_verify"); return
    end
    if state.phase=="spell_restore_verify" then
        local ctx=state.spell_ctx; local current=active_wand_state(p); local same=current and ctx and current.entity==ctx.wand.entity
        local cap_ok=same and current.cap==ctx.wand.cap
        local mana_ok=same and (ctx.wand.mana==nil or current.mana==ctx.wand.mana) and (ctx.wand.max==nil or current.max==ctx.wand.max) and (ctx.wand.charge==nil or current.charge==ctx.wand.charge)
        local gone=not (ctx and valid(ctx.created))
        local ok=state.spell_insert_ok and state.spell_restore_call and cap_ok and mana_ok and gone
        state.spell_result=ok and "pass" or "fail"
        mark(ok and "PASS" or "FAIL","spell.roundtrip","action="..tostring(ctx and ctx.action_id).." inserted="..tostring(state.spell_insert_ok).." cleanup="..tostring(state.spell_restore_call).." cleanup_reason="..tostring(state.spell_restore_reason).." cap_restored="..tostring(cap_ok).." mana_restored="..tostring(mana_ok).." test_entity_gone="..tostring(gone))
        if not ok then abort_dirty("spell_roundtrip_unrecovered"); return end
        state.phase="perk_apply"; return
    end

    if state.phase=="perk_apply" then
        local perk=state.perks[state.perk_i]
        if not perk then state.phase="perk_gamble_start"; return end
        local before=perk_service.count(perk.id)
        local skip_reason=QA_SKIP_PERKS[tostring(perk.id or "")]
        if skip_reason~=nil then
            log("STEP SKIP","phase=perk_apply step=perk."..tostring(perk.id).." reason="..tostring(skip_reason))
            state.perk_i=state.perk_i+1
            return
        end
        state.pending_perk=perk; state.pending_before=before; state.pending_guard=perk_guard_snapshot(p)
        step_begin("perk."..perk.id,"before="..before)
        action("perk.take","id="..tostring(perk.id).." before="..tostring(before)); local ok,reason=take_perk(p,perk); state.pending_ok=ok; state.pending_reason=reason
        set_wait(WAIT_SHORT,"perk_verify_add"); return
    end
    if state.phase=="perk_verify_add" then
        local perk=state.pending_perk; local after=perk_service.count(perk.id)
        if not state.pending_ok or after<=state.pending_before then
            local issues=perk_guard_diff(state.pending_guard,perk_guard_snapshot(p))
            mark("FAIL","perk."..perk.id,"add_failed before="..state.pending_before.." after="..after.." reason="..tostring(state.pending_reason)
                ..(#issues>0 and (" residue="..compact_issues(issues)) or ""))
            abort_dirty("perk_add_failed:"..tostring(perk.id)); return
        end
        local can,why=perk_service.can_remove(perk,p)
        if not can then mark("FAIL","perk."..perk.id,"added_but_not_removable count="..after.." reason="..tostring(why)); abort_dirty("perk_not_removable:"..tostring(perk.id)); return end
        local ok,reason
        action("perk.remove_one","id="..tostring(perk.id).." peer_local=true"); ok,reason=perk_service.remove_one(p,perk)
        state.pending_remove_ok=ok; state.pending_remove_reason=reason
        set_wait(WAIT_SHORT,"perk_verify_remove"); return
    end
    if state.phase=="perk_verify_remove" then
        local perk=state.pending_perk; local after=perk_service.count(perk.id); local count_ok=state.pending_remove_ok and after==state.pending_before
        local issues=perk_guard_diff(state.pending_guard,perk_guard_snapshot(p))
        local ok=count_ok and #issues==0
        local extra=""
        if perk.id=="FUNGAL_DISEASE" then extra=" fungal_children="..count_child_file(p,"data/entities/misc/perks/fungal_disease.xml") end
        if perk.id=="INVISIBILITY" then local mina,maxa,n=visible_alpha_summary(p); extra=extra.." sprite_alpha="..tostring(mina)..".."..tostring(maxa).." sprites="..n end
        if perk.id=="EXTRA_MANA" then local w=active_wand_state(p); extra=extra.." wand="..tostring(w and w.entity or 0).." mana_max="..tostring(w and w.max).." charge="..tostring(w and w.charge).." cap="..tostring(w and w.cap) end
        if #issues>0 then extra=extra.." residue="..compact_issues(issues) end
        mark(ok and "PASS" or "FAIL","perk."..perk.id,"removed="..tostring(state.pending_remove_ok).." reason="..tostring(state.pending_remove_reason).." final="..after.." baseline="..state.pending_before..extra)
        if not ok then abort_dirty("perk_unrecovered:"..tostring(perk.id)); return end
        state.perk_done=state.perk_done+1; state.perk_i=state.perk_i+1; state.phase="perk_apply"; return
    end

    if state.phase=="perk_gamble_start" then
        local perk=perk_by_id("GAMBLE")
        if not perk then mark("WARN","perk.gamble_roundtrip","missing"); state.phase="perk_stack_start"; return end
        state.gamble_perk=perk
        state.gamble_counts=perk_count_snapshot()
        state.gamble_guard=perk_guard_snapshot(p)
        local before=perk_service.count("GAMBLE")
        step_begin("perk.gamble_roundtrip","baseline="..tostring(before).." random_rewards=accepted")
        action("perk.gamble_take","same_user_path=true")
        local ok,reason=take_perk(p,perk)
        state.gamble_apply_ok=ok; state.gamble_apply_reason=reason; state.gamble_before=before
        set_wait(math.max(WAIT_SHORT,12),"perk_gamble_verify_add"); return
    end
    if state.phase=="perk_gamble_verify_add" then
        local after=perk_service.count("GAMBLE")
        if not state.gamble_apply_ok or after<=state.gamble_before then
            mark("FAIL","perk.gamble_roundtrip","add_failed before="..tostring(state.gamble_before).." after="..tostring(after).." reason="..tostring(state.gamble_apply_reason))
            abort_dirty("gamble_add_failed"); return
        end
        local changed=perk_count_residue(state.gamble_counts)
        state.gamble_added_counts=changed
        action("perk.gamble_remove","changed_counts="..compact_issues(changed))
        local ok,reason=perk_service.remove_one(p,state.gamble_perk)
        state.gamble_remove_ok=ok; state.gamble_remove_reason=reason
        set_wait(180,"perk_gamble_verify_remove"); return
    end
    if state.phase=="perk_gamble_verify_remove" then
        local count_issues=perk_count_residue(state.gamble_counts)
        local guard_issues=perk_guard_diff(state.gamble_guard,perk_guard_snapshot(p))
        local ok=state.gamble_remove_ok and #count_issues==0 and #guard_issues==0
        mark(ok and "PASS" or "FAIL","perk.gamble_roundtrip",
            "removed="..tostring(state.gamble_remove_ok).." reason="..tostring(state.gamble_remove_reason)..
            " rewards="..compact_issues(state.gamble_added_counts or {})..
            " count_residue="..compact_issues(count_issues).." state_residue="..compact_issues(guard_issues))
        if not ok then abort_dirty("gamble_unrecovered"); return end
        state.phase="perk_stack_start"; return
    end

    if state.phase=="perk_stack_start" then
        local cases={{id="ATTACK_FOOT",count=3},{id="FUNGAL_DISEASE",count=3}}
        local case=cases[state.stack_case_i]
        if not case then state.phase=state.networked and "effect_apply" or "perk_batch_start"; return end
        local perk=perk_by_id(case.id); if not perk then mark("WARN","perk.stack."..case.id,"missing"); state.stack_case_i=state.stack_case_i+1; return end
        state.stack_case=case; state.stack_perk=perk; state.stack_baseline=perk_service.count(perk.id); state.stack_take_i=0; state.stack_guard=perk_guard_snapshot(p)
        step_begin("perk.stack."..case.id,"baseline="..state.stack_baseline.." target_add="..case.count)
        state.phase="perk_stack_take"; return
    end
    if state.phase=="perk_stack_take" then
        local c=state.stack_case
        if state.stack_take_i>=c.count then set_wait(WAIT_SHORT,"perk_stack_verify_add"); return end
        action("perk.stack_take","id="..tostring(c.id).." index="..tostring(state.stack_take_i+1).."/"..tostring(c.count)); local ok,reason=take_perk(p,state.stack_perk); if not ok then mark("FAIL","perk.stack."..c.id,"take_failed i="..state.stack_take_i.." reason="..tostring(reason)); abort_dirty("perk_stack_take:"..tostring(c.id)); return end
        state.stack_take_i=state.stack_take_i+1; return
    end
    if state.phase=="perk_stack_verify_add" then
        local c=state.stack_case; local count=perk_service.count(c.id); local expected=state.stack_baseline+c.count
        if count<expected then mark("FAIL","perk.stack."..c.id,"count_after_add="..count.." expected="..expected); abort_dirty("perk_stack_add:"..tostring(c.id)); return end
        state.stack_remove_i=0; state.phase="perk_stack_remove"; return
    end
    if state.phase=="perk_stack_remove" then
        local c=state.stack_case
        if state.stack_remove_i>=c.count then set_wait(WAIT_SHORT,"perk_stack_verify_remove"); return end
        action("perk.stack_remove","id="..tostring(c.id).." index="..tostring(state.stack_remove_i+1).."/"..tostring(c.count)); local ok,reason=perk_service.remove_one(p,state.stack_perk); if not ok then mark("FAIL","perk.stack."..c.id,"remove_failed i="..state.stack_remove_i.." reason="..tostring(reason)); abort_dirty("perk_stack_remove:"..tostring(c.id)); return end
        state.stack_remove_i=state.stack_remove_i+1; return
    end
    if state.phase=="perk_stack_verify_remove" then
        local c=state.stack_case; local count=perk_service.count(c.id); local extra=""
        if c.id=="FUNGAL_DISEASE" then extra=" children="..count_child_file(p,"data/entities/misc/perks/fungal_disease.xml") end
        local issues=perk_guard_diff(state.stack_guard,perk_guard_snapshot(p))
        if #issues>0 then extra=extra.." residue="..compact_issues(issues) end
        local ok=count==state.stack_baseline and #issues==0
        mark(ok and "PASS" or "FAIL","perk.stack."..c.id,"final="..count.." baseline="..state.stack_baseline..extra)
        if not ok then abort_dirty("perk_stack_unrecovered:"..tostring(c.id)); return end
        state.stack_case_i=state.stack_case_i+1; state.phase="perk_stack_start"; return
    end

    if state.phase=="perk_batch_start" then
        state.batch_cycle=tonumber(state.batch_cycle) or 1
        state.batch_guard=perk_guard_snapshot(p)
        state.batch_candidates={}
        state.batch_active={}
        state.batch_failures={}
        for _,perk in ipairs(state.perks or {}) do
            local perk_id=tostring(perk.id or "")
            local skipped=QA_SKIP_PERKS[perk_id]~=nil and perk_id~="GAMBLE"
            if perk_service.count(perk.id)==0 and not skipped then
                state.batch_candidates[#state.batch_candidates+1]=perk
            end
        end
        state.batch_i=1
        step_begin("perk.batch_all.cycle"..tostring(state.batch_cycle),"candidates="..tostring(#state.batch_candidates))
        state.phase="perk_batch_take"
        return
    end
    if state.phase=="perk_batch_take" then
        local perk=state.batch_candidates[state.batch_i]
        if not perk then
            state.batch_remove_order={}
            -- GAMBLE owns its two random grants. Remove that parent transaction first so
            -- its nested contributions disappear before independently acquired copies of
            -- those same perk ids are removed. Other perks deliberately use opposite
            -- orders across the two cycles.
            for _,active_perk in ipairs(state.batch_active or {}) do
                if tostring(active_perk.id or "")=="GAMBLE" then state.batch_remove_order[#state.batch_remove_order+1]=active_perk end
            end
            if state.batch_cycle==2 then
                for i=#(state.batch_active or {}),1,-1 do
                    local active_perk=state.batch_active[i]
                    if tostring(active_perk.id or "")~="GAMBLE" then state.batch_remove_order[#state.batch_remove_order+1]=active_perk end
                end
            else
                for _,active_perk in ipairs(state.batch_active or {}) do
                    if tostring(active_perk.id or "")~="GAMBLE" then state.batch_remove_order[#state.batch_remove_order+1]=active_perk end
                end
            end
            state.batch_remove_i=1
            if state.can_rules then set_wait(30,"perk_batch_gravity_apply") else set_wait(30,"perk_batch_remove") end
            return
        end
        local before=perk_service.count(perk.id)
        action("perk.batch_take","id="..tostring(perk.id).." index="..tostring(state.batch_i).."/"..tostring(#state.batch_candidates))
        local ok,reason=take_perk(p,perk)
        local after=perk_service.count(perk.id)
        if ok and after>before then state.batch_active[#state.batch_active+1]=perk
        else state.batch_failures[#state.batch_failures+1]="take:"..tostring(perk.id)..":"..tostring(reason) end
        state.batch_i=state.batch_i+1
        return
    end
    if state.phase=="perk_batch_gravity_apply" then
        local rule = gravity_rule()
        if rule == nil or not world_rules.supported(rule) then
            mark("FAIL","interaction.all_perks_gravity","gravity_rule_missing")
            abort_dirty("all_perks_gravity_rule_missing")
            return
        end
        reset_rules_checked("perk_batch_gravity_pre")
        step_begin("interaction.all_perks_gravity","active_perks="..tostring(#(state.batch_active or {})).." target=-4x")
        local ok, reason = world_rules.step(rule, 1) -- Native -> -4x
        state.batch_gravity_apply_ok, state.batch_gravity_reason = ok, reason
        set_wait(3,"perk_batch_gravity_verify")
        return
    end
    if state.phase=="perk_batch_gravity_verify" then
        local ok, detail = gravity_debug_ok(-4)
        local explosive = {}
        for _, id in ipairs({"GLASS_CANNON","REVENGE_EXPLOSION","EXPLODING_CORPSES","EXPLODING_GOLD"}) do
            local count = perk_service.count(id)
            if count > 0 then explosive[#explosive+1] = id.."="..tostring(count) end
        end
        mark(state.batch_gravity_apply_ok and ok and "PASS" or "FAIL","interaction.all_perks_gravity",
            "apply="..tostring(state.batch_gravity_apply_ok).." reason="..tostring(state.batch_gravity_reason).." "..tostring(detail).." explosive_perks="..table.concat(explosive,","))
        local clean = reset_rules_checked("perk_batch_gravity_post")
        if not state.batch_gravity_apply_ok or not ok or not clean then
            if not clean then abort_dirty("all_perks_gravity_reset") end
        end
        state.phase="perk_batch_remove"
        return
    end

    if state.phase=="perk_batch_remove" then
        local perk=(state.batch_remove_order or {})[state.batch_remove_i]
        if not perk then set_wait(320,"perk_batch_verify"); return end
        action("perk.batch_remove","id="..tostring(perk.id).." cycle="..tostring(state.batch_cycle).." index="..tostring(state.batch_remove_i).."/"..tostring(#(state.batch_remove_order or {})))
        local removed,reason=perk_service.remove_all(p,perk)
        if removed<=0 or perk_service.count(perk.id)~=0 then
            state.batch_failures[#state.batch_failures+1]="remove:"..tostring(perk.id)..":"..tostring(reason)
        end
        state.batch_remove_i=state.batch_remove_i+1
        return
    end
    if state.phase=="perk_batch_verify" then
        local issues=perk_guard_diff(state.batch_guard,perk_guard_snapshot(p))
        local count_residue={}
        for _,perk in ipairs(state.batch_candidates or {}) do
            local count=perk_service.count(perk.id)
            if count~=0 then count_residue[#count_residue+1]=tostring(perk.id).."="..tostring(count) end
        end
        local ok=#(state.batch_failures or {})==0 and #issues==0 and #count_residue==0
        mark(ok and "PASS" or "FAIL","perk.batch_all.cycle"..tostring(state.batch_cycle),
            "taken="..tostring(#(state.batch_active or {}))..
            " failures="..compact_issues(state.batch_failures or {})..
            " counts="..compact_issues(count_residue)..
            " residue="..compact_issues(issues))
        if not ok then abort_dirty("perk_batch_unrecovered_cycle"..tostring(state.batch_cycle)); return end
        if state.batch_cycle < 2 then
            state.batch_cycle=state.batch_cycle+1
            state.phase="perk_batch_start"
        else
            state.phase="effect_apply"
        end
        return
    end

    if state.phase=="effect_apply" then
        local e=state.effects[state.effect_i]
        if not e then state.phase="item_spawn"; return end
        state.pending_effect=e; step_begin("effect."..tostring(e.id or e.path))
        local pre=effect_service.is_active(p,e,effect_service.active_snapshot(p))
        if pre then mark("WARN","effect."..tostring(e.id or e.path),"preexisting_active skipped_to_preserve_state"); state.effect_i=state.effect_i+1; return end
        action("effect.add","id="..tostring(e.id or e.path).." frames=60"); local ok,reason=effect_service.add(p,e,60); state.pending_ok=ok; state.pending_reason=reason
        set_wait(WAIT_SHORT,"effect_verify"); return
    end
    if state.phase=="effect_verify" then
        local e=state.pending_effect; local snap=effect_service.active_snapshot(p); local active=effect_service.is_active(p,e,snap)
        action("effect.remove","id="..tostring(e.id or e.path)); local removed=effect_service.remove(p,e)
        state.pending_effect_active=active; state.pending_effect_removed=removed
        set_wait(WAIT_SHORT,"effect_remove_verify"); return
    end
    if state.phase=="effect_remove_verify" then
        local e=state.pending_effect
        local active_after=effect_service.is_active(p,e,effect_service.active_snapshot(p))
        local residue=type(effect_service.residue_count)=="function" and effect_service.residue_count(p,e) or (active_after and 1 or 0)
        local applied=state.pending_ok and state.pending_effect_active
        local clean=(not active_after) and residue==0
        local status_material=e.kind=="status" and type(e.material)=="string" and e.material~=""
        local level=(applied and clean) and "PASS" or (status_material and "WARN" or "FAIL")
        mark(level,"effect."..tostring(e.id or e.path),
            "add="..tostring(state.pending_ok).." reason="..tostring(state.pending_reason)..
            " active_before="..tostring(state.pending_effect_active).." removed="..tostring(state.pending_effect_removed)..
            " active_after="..tostring(active_after).." residue="..tostring(residue))
        if level=="FAIL" then abort_dirty("effect_cleanup_failed:"..tostring(e.id or e.path)); return end
        state.effect_done=state.effect_done+1; state.effect_i=state.effect_i+1; state.phase="effect_apply"; return
    end

    if state.phase=="item_spawn" then
        local e=state.items[state.item_i]
        if not e then state.phase=state.networked and "companion_start" or "item_runtime_spawn"; return end
        state.pending_item=e; step_begin("item."..tostring(e.path))
        if not state.networked then
            -- Exhaustive catalogue coverage must not instantiate arbitrary item XML.
            -- EntityLoad can run one-shot scripts that create detached roots/materials
            -- before the probed root is killed. Validate availability without simulation.
            local exists=type(e.path)=="string" and e.path~="" and ModDoesFileExist(e.path)
            local readable=false
            if exists and type(ModTextFileGetContent)=="function" then
                local ok_text, text=pcall(ModTextFileGetContent,e.path)
                readable=ok_text and type(text)=="string" and text~="" and string.find(text,"<",1,true)~=nil
            end
            action("item.static","path="..tostring(e.path).." exists="..tostring(exists).." readable="..tostring(readable))
            local static_ok=exists and readable
            mark(static_ok and "PASS" or "FAIL","item."..tostring(e.path),"static_exists="..tostring(exists).." readable="..tostring(readable).." world_spawn=false")
            state.item_done=state.item_done+1; state.item_i=state.item_i+1
            return
        end
        action("item.spawn","path="..tostring(e.path).." offset=64,-16 mode=network_representative")
        local ent,reason=item_service.spawn_near(p,e.path,64,-16)
        state.pending_item_entity=ent; state.pending_reason=reason; state.pending_item_deadline=f+45
        set_wait(2,"item_verify"); return
    end
    if state.phase=="item_runtime_spawn" then
        local e=(state.item_runtime_cases or {})[state.item_runtime_i]
        if not e then state.phase="companion_start"; return end
        state.pending_item=e; step_begin("item.runtime."..tostring(e.path))
        state.pending_item_before=qa_item_snapshot(p,640)
        action("item.runtime_spawn","path="..tostring(e.path).." offset=48,-12 visible=true")
        local ent,reason=item_service.spawn_near(p,e.path,48,-12)
        state.pending_item_entity=ent; state.pending_reason=reason
        set_wait(2,"item_runtime_verify"); return
    end
    if state.phase=="item_runtime_verify" then
        local e=state.pending_item; local ent=tonumber(state.pending_item_entity) or 0
        local spawned=valid(ent)
        local owned=qa_new_item_roots(p,state.pending_item_before,640)
        -- Include the direct root even if a scripted transform moved it just outside the
        -- radius during the two-frame observation window.
        local seen={}; for _,id in ipairs(owned) do seen[id]=true end
        if spawned and not seen[ent] and qa_item_root(ent) then owned[#owned+1]=ent; seen[ent]=true end
        action("item.runtime_cleanup","path="..tostring(e.path).." roots="..tostring(#owned))
        for _,id in ipairs(owned) do retire_entity_safely(id) end
        state.pending_item_owned=owned; state.pending_item_spawned=spawned
        set_wait(3,"item_runtime_cleanup_verify"); return
    end
    if state.phase=="item_runtime_cleanup_verify" then
        local e=state.pending_item; local residue=0
        for _,id in ipairs(state.pending_item_owned or {}) do if valid(id) then residue=residue+1; retire_entity_safely(id) end end
        local ok=state.pending_item_spawned==true and residue==0
        mark(ok and "PASS" or "FAIL","item.runtime."..tostring(e.path),
            "spawn="..tostring(state.pending_item_spawned).." reason="..tostring(state.pending_reason).." roots="..tostring(#(state.pending_item_owned or {})).." residue="..tostring(residue))
        if residue>0 then abort_dirty("item_runtime_residue:"..tostring(e.path)); return end
        state.item_runtime_done=(state.item_runtime_done or 0)+1
        state.item_runtime_i=state.item_runtime_i+1; state.phase="item_runtime_spawn"; return
    end
    if state.phase=="item_verify" then
        local e=state.pending_item; local ent=tonumber(state.pending_item_entity) or 0; local ok=valid(ent)
        local sync_ok, sync_state, gid = item_service.world_sync_state(ent)
        if ok and not sync_ok and f < (state.pending_item_deadline or f) then set_wait(2,"item_verify"); return end
        mark(ok and sync_ok and "PASS" or "FAIL","item."..tostring(e.path),
            "entity="..tostring(ent).." spawn="..tostring(state.pending_reason).." ew_registered="..tostring(sync_ok).." sync_state="..tostring(sync_state).." gid="..tostring(gid or ""))
        if ok then action("item.cleanup","entity="..tostring(ent).." path="..tostring(e.path)); retire_entity_safely(ent) end
        state.item_done=state.item_done+1; state.item_i=state.item_i+1; state.phase="item_spawn"; return
    end

    if state.phase=="companion_start" then
        state.clone_before={}
        for _,e in ipairs(EntityGetWithTag("metamorph_creative_menu_player_clone") or {}) do state.clone_before[e]=true end
        step_begin("companion.spawn")
        action("companion.spawn","offset=64,-4")
        local ok,reason=player_avatar.request_spawn(p,64,-4); state.companion_ok=ok; state.companion_reason=reason
        set_wait(reason=="queued" and 90 or 12,"companion_verify"); return
    end
    if state.phase=="companion_verify" then
        local created={}
        for _,e in ipairs(EntityGetWithTag("metamorph_creative_menu_player_clone") or {}) do if not state.clone_before[e] then created[#created+1]=e end end
        local clone=created[1] or 0; local health_ok=nil; local detail="created="..tostring(#created).." request="..tostring(state.companion_ok).." reason="..tostring(state.companion_reason)
        if clone~=0 and valid(clone) then
            local od=EntityGetFirstComponentIncludingDisabled(p,"DamageModelComponent"); local cd=EntityGetFirstComponentIncludingDisabled(clone,"DamageModelComponent")
            if od and od~=0 and cd and cd~=0 then
                local om=tonumber(ComponentGetValue2(od,"max_hp")); local ch=tonumber(ComponentGetValue2(cd,"hp")); local cm=tonumber(ComponentGetValue2(cd,"max_hp")); local cc=tonumber(ComponentGetValue2(cd,"max_hp_cap"))
                health_ok=om and ch and cm and math.abs(ch-om)<0.0001 and math.abs(cm-om)<0.0001 and (cc==nil or cc<=0 or cc+0.0001>=om)
                detail=detail.." owner_max="..tostring(om).." clone="..tostring(ch).."/"..tostring(cm).." cap="..tostring(cc)
            end
        end
        local level=(state.companion_ok and #created>0 and health_ok~=false) and "PASS" or ((state.companion_reason=="queued" and #created==0) and "WARN" or "FAIL")
        mark(level,"companion.spawn",detail)
        -- Only retire clones that appeared locally. On an EW client a queued host-owned clone may arrive later; do not kill foreign authority.
        if state.companion_reason~="queued" then for _,e in ipairs(created) do action("companion.cleanup","entity="..tostring(e)); retire_entity_safely(e) end end
        state.phase="possession_start"; return
    end

    if state.phase=="possession_start" then
        if not ModDoesFileExist("data/entities/animals/sheep.xml") then mark("WARN","possession.roundtrip","sheep_missing"); state.phase="form_start"; return end
        step_begin("possession.roundtrip","target=sheep")
        action("possession.spawn_target","path=data/entities/animals/sheep.xml")
        local target=creature_service.spawn_near_player(p,"data/entities/animals/sheep.xml",64,0) or 0
        if not valid(target) then mark("FAIL","possession.roundtrip","spawn_failed"); state.phase="form_start"; return end
        state.possession_target=target
        action("possession.begin","target="..tostring(target))
        local ok,reason=possession.possess_entity(p,target); state.possession_ok=ok; state.possession_reason=reason; state.possession_started=f; state.phase="possession_wait_active"; return
    end
    if state.phase=="possession_wait_active" then
        p=player()
        if p~=0 and EntityHasTag(p,"polymorphed_player") and form_manager.has_active_form() then state.possession_active=f; state.phase="possession_dwell"; return end
        if f-(state.possession_started or f)>FORM_TIMEOUT then
            mark("FAIL","possession.roundtrip","commit_timeout reason="..tostring(state.possession_reason))
            if valid(state.possession_target) then retire_entity_safely(state.possession_target) end
            pcall(form_manager.return_to_human)
            state.possession_recover_started=f; state.phase="possession_recover"
        end
        return
    end
    if state.phase=="possession_recover" then
        p=player()
        if p~=0 and form_manager.is_human_ready(p) then restore_player_baseline(p,state.baseline,false); state.phase="form_start"; return end
        if f-(state.possession_recover_started or f)>RETURN_TIMEOUT then abort_dirty("possession_unrecovered") end
        return
    end
    if state.phase=="possession_dwell" then
        if f-(state.possession_active or f)<(state.networked and NETWORK_FORM_DWELL or FORM_DWELL) then return end
        action("possession.return","target="..tostring(state.possession_target)); local ok,reason=form_manager.return_to_human(); state.possession_return_ok=ok; state.possession_return_reason=reason; state.possession_return_started=f; state.phase="possession_wait_return"; return
    end
    if state.phase=="possession_wait_return" then
        p=player()
        if p~=0 and form_manager.is_human_ready(p) then restore_player_baseline(p,state.baseline,false); local retired=not valid(state.possession_target); mark(state.possession_ok and state.possession_return_ok and retired and "PASS" or "WARN","possession.roundtrip","returned=true original_retired="..tostring(retired).." begin="..tostring(state.possession_reason).." return="..tostring(state.possession_return_reason)); state.phase="form_start"; return end
        if f-(state.possession_return_started or f)>RETURN_TIMEOUT then mark("FAIL","possession.roundtrip","return_timeout"); abort_dirty("possession_return_timeout") end
        return
    end

    if state.phase=="form_start" then
        local path=state.forms[state.form_i]
        if not path then state.phase="finalize"; return end
        if EntityHasTag(p,"polymorphed_player") then pcall(form_manager.return_to_human); state.return_started=f; state.phase="form_wait_human"; return end
        state.pending_form=path; step_begin("form."..tostring(path),"index="..state.form_i.."/"..#state.forms)
        action("form.transform","path="..tostring(path).." index="..tostring(state.form_i).."/"..tostring(#state.forms)); local ok,reason=form_manager.transform_creature(p,path,nil,true,{requested_target=path,compatibility_mode="qa_autotest",role="creature",form_strategy="qa"})
        state.form_started=f; state.pending_ok=ok; state.pending_reason=reason
        if not ok then
            mark("FAIL","form."..tostring(path),"transform_start_failed reason="..tostring(reason).." timeout_waited=false")
            state.form_i=state.form_i+1; state.phase="form_start"; return
        end
        state.phase="form_wait_active"; return
    end
    if state.phase=="form_wait_active" then
        p=player(); local active_form=p~=0 and EntityHasTag(p,"polymorphed_player") and form_manager.has_active_form()
        if active_form then state.form_active_frame=f; state.phase="form_dwell"; return end
        if f-(state.form_started or f)>FORM_TIMEOUT then
            mark("FAIL","form."..tostring(state.pending_form),"transform_timeout reason="..tostring(state.pending_reason))
            pcall(form_manager.return_to_human); state.return_started=f; state.phase="form_wait_human_recover"
        end
        return
    end
    if state.phase=="form_dwell" then
        if f-(state.form_active_frame or f)<(state.networked and NETWORK_FORM_DWELL or FORM_DWELL) then return end
        p=player(); local file=p~=0 and tostring(EntityGetFilename(p) or "") or ""; local family=tostring(form_manager.active_control_family() or "")
        local c=#(p~=0 and (EntityGetAllComponents(p) or {}) or {}); local ch=#(p~=0 and (EntityGetAllChildren(p) or {}) or {})
        state.form_observation="observed="..file.." family="..family.." components="..c.." children="..ch
        action("form.return","path="..tostring(state.pending_form)); local ok,reason=form_manager.return_to_human(); state.return_started=f; state.pending_return_ok=ok; state.pending_return_reason=reason; state.phase="form_wait_return"; return
    end
    if state.phase=="form_wait_return" then
        p=player(); if p~=0 and form_manager.is_human_ready(p) then
            restore_player_baseline(p,state.baseline,false)
            mark("PASS","form."..tostring(state.pending_form),"returned=true actual="..tostring(EntityGetFilename(p) or "").." baseline_position_restored=true "..tostring(state.form_observation or ""))
            state.form_done=state.form_done+1; state.form_i=state.form_i+1
            if state.networked then set_wait(NETWORK_FORM_SETTLE,"form_start") else state.phase="form_start" end
            return
        end
        if f-(state.return_started or f)>RETURN_TIMEOUT then mark("FAIL","form."..tostring(state.pending_form),"return_timeout reason="..tostring(state.pending_return_reason)); abort_dirty("form_return_timeout:"..tostring(state.pending_form)) end
        return
    end
    if state.phase=="form_wait_human_recover" then
        p=player()
        if p~=0 and form_manager.is_human_ready(p) then
            restore_player_baseline(p,state.baseline,false)
            state.form_i=state.form_i+1; state.phase="form_start"
            return
        end
        if f-(state.return_started or f)>RETURN_TIMEOUT then abort_dirty("form_transform_timeout_unrecovered:"..tostring(state.pending_form)) end
        return
    end

    if state.phase=="form_wait_human" then
        p=player(); if p~=0 and form_manager.is_human_ready(p) then state.phase="form_start"; return end
        if f-(state.return_started or f)>RETURN_TIMEOUT then abort_dirty("unexpected_form_human_recovery_timeout") end
        return
    end

    if state.phase=="finalize" then
        local world_ok=restore_world_controls(state.world_baseline)
        if p~=0 and form_manager.is_human_ready(p) then
            restore_player_baseline(p,state.baseline,true)
            -- Final cleanup is ownership-based, not a blanket remove_all: direct effects
            -- carry metamorph_creative_menu_effect and surface statuses are tracked only when QA/menu
            -- added them from an inactive baseline. Pre-existing effects stay untouched.
            if type(effect_service.flush_owned)=="function" then effect_service.flush_owned(p) end
        end
        state.final_world_ok=world_ok; set_wait(10,"finalize_verify"); return
    end
    if state.phase=="finalize_verify" then
        p=player(); local guard_issues=p~=0 and perk_guard_diff(state.baseline_guard,perk_guard_snapshot(p)) or {"player_missing"}
        local guard_repaired=true; if #guard_issues>0 and p~=0 then guard_repaired=repair_perk_guard(p,state.baseline_guard) end
        local world_match,world_reason=world_controls_match(state.world_baseline)
        local world_clean=state.final_world_ok and world_match
        if #guard_issues>0 then
            mark("FAIL","final.player_residue","issues="..compact_issues(guard_issues).." emergency_repaired="..tostring(guard_repaired))
            state.dirty=true
        end
        if not world_clean then mark("FAIL","final.world_restore","reason="..tostring(world_reason).." overrides="..tostring(world_rules.has_overrides())); state.dirty=true end
        finish(state.abort_reason and ("aborted_dirty:"..tostring(state.abort_reason)) or "complete"); return
    end
end

function qa_runner.running() return state~=nil end
function qa_runner.status()
    if state == nil then return {active=false} end
    return {active=true,id=state.id,phase=state.phase,step=state.current_step,networked=state.networked,
        peers_start=state.peer_baseline,peers_now=remote_peer_count and remote_peer_count() or 0,
        pass=state.pass,warn=state.warn,fail=state.fail}
end
function qa_runner.start() return start() end
function qa_runner.stop()
    if not state then return false end
    log("AUTOTEST ABORT","run="..tostring(state.id).." phase="..tostring(state.phase).." step="..tostring(state.current_step))
    finish("aborted_by_user")
    return true
end

function qa_runner.update()
    if not state then return end
    heartbeat()
    local ok,err=xpcall(update_state,function(e) return type(debug)=="table" and type(debug.traceback)=="function" and debug.traceback(tostring(e),2) or tostring(e) end)
    if not ok then
        diagnostics.capture_error("qa_runner",err)
        state.fail=state.fail+1
        log("STEP FAIL","phase="..tostring(state.phase).." unhandled="..tostring(err))
        finish("runner_exception")
    end
end

METAMORPH_CREATIVE_MENU_QA_RUNNER=qa_runner
return qa_runner
