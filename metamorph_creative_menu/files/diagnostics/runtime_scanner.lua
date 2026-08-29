if type(METAMORPH_CREATIVE_MENU_DIAGNOSTIC_RUNTIME_SCANNER) == "table" then return METAMORPH_CREATIVE_MENU_DIAGNOSTIC_RUNTIME_SCANNER end

local runtime_scanner = {}
local logger = dofile("mods/metamorph_creative_menu/files/diagnostics/logger.lua")
local support = dofile("mods/metamorph_creative_menu/files/diagnostics/scan_support.lua")
local entity_inspection = dofile("mods/metamorph_creative_menu/files/diagnostics/entity_inspection.lua")
local runtime_context = dofile("mods/metamorph_creative_menu/files/diagnostics/runtime_context.lua")
local add = support.add
local sample_list = support.sample_list
local component_count = support.component_count
local component_enabled_count = support.component_enabled_count
local entity_summary = entity_inspection.summary
local variable_value = entity_inspection.variable_string
local world_sync_context = runtime_context.world_sync
local one_line = logger.one_line
local perk_root_companions = dofile("mods/metamorph_creative_menu/files/features/perks/root_companions.lua")
local runtime_errors = logger.runtime_errors()
local QA_TRIGGER_KEY_NAME = "Key_z"

local function collect_world_and_runtime(report)
    local rules = report.world_rules
    if rules ~= nil and type(rules.rules) == "function" then
        local values = rules.rules() or {}
        local supported, overridden, unsupported = 0, {}, {}
        for _, rule in ipairs(values) do
            local ok, yes = pcall(rules.supported, rule)
            if ok and yes == true then supported = supported + 1 else unsupported[#unsupported + 1] = tostring(rule.id) end
            if type(rules.is_overridden) == "function" and rules.is_overridden(rule) then
                overridden[#overridden + 1] = tostring(rule.id) .. "=" .. tostring(rules.choice_label(rule))
            end
        end
        add(report, #unsupported == 0 and "PASS" or "WARN", "world_rules.support", "total=" .. tostring(#values) .. " supported=" .. tostring(supported) .. " unsupported=" .. sample_list(unsupported, 12))
        if type(rules.can_edit) == "function" then
            local ok_edit, can, reason = pcall(rules.can_edit)
            add(report, ok_edit and can == true and "PASS" or "WARN", "world_rules.editability",
                "can_edit=" .. tostring(ok_edit and can == true) .. " reason=" .. tostring(reason))
        end
        if type(rules.gravity_factor) == "function" then
            local ok_g, factor = pcall(rules.gravity_factor)
            add(report, "INFO", "world_rules.gravity_factor", "ok=" .. tostring(ok_g) .. " factor=" .. tostring(factor))
        end
        if type(rules.local_gravity_debug) == "function" then
            local ok_lg, dbg = pcall(rules.local_gravity_debug)
            if ok_lg and type(dbg) == "table" then
                local rows = {}
                for _, row in ipairs(dbg.rows or {}) do
                    rows[#rows + 1] = tostring(row.field)..":"..tostring(row.current).."/native="..tostring(row.native).."/expected="..tostring(row.expected)
                end
                add(report, "INFO", "world_rules.local_gravity", "player="..tostring(dbg.player).." factor="..tostring(dbg.factor).." rows="..sample_list(rows, 8))
            else
                add(report, "WARN", "world_rules.local_gravity", "debug_error="..tostring(dbg))
            end
        end
        if type(rules.recovery_status) == "function" then
            local ok_recovery, recovery_state = pcall(rules.recovery_status)
            if ok_recovery and type(recovery_state) == "table" then
                add(report, recovery_state.pending == true and "WARN" or "INFO", "world_rules.recovery",
                    "done="..tostring(recovery_state.done).." had_stale_state="..tostring(recovery_state.had_stale_state).." pending="..tostring(recovery_state.pending))
            else
                add(report, "WARN", "world_rules.recovery", "debug_error="..tostring(recovery_state))
            end
        end
        add(report, "INFO", "world_rules.overrides", "count=" .. tostring(#overridden) .. " values=" .. sample_list(overridden, 20))
    end

    if report.ew_enabled then
        local world_sync_patch = GlobalsGetValue("mcm_compat_world_sync_patch_v1", "unknown")
        local peer_perk_patch = GlobalsGetValue("mcm_compat_peer_perk_patch_v1", "unknown")
        local perk_helper_patch = GlobalsGetValue("mcm_compat_perk_helper_patch_v1", "unknown")
        local perk_helper_loaded = GlobalsGetValue("mcm_perk_helper_sync_loaded_v1", "unknown")
        local perk_mutation_patch = GlobalsGetValue("mcm_compat_perk_mutation_patch_v1", "unknown")
        local perk_mutation_loaded = GlobalsGetValue("mcm_perk_mutation_sync_loaded_v1", "unknown")
        local perk_runtime_guard = GlobalsGetValue("mcm_peer_perk_runtime_guard_v1", "unknown")
        local function patch_level(status)
            return (status == "applied" or status == "already_present") and "PASS" or "WARN"
        end
        add(report, patch_level(world_sync_patch), "ew.compat.world_sync_patch", "status=" .. tostring(world_sync_patch))
        add(report, patch_level(peer_perk_patch), "ew.compat.peer_perk_patch", "status=" .. tostring(peer_perk_patch))
        add(report, patch_level(perk_helper_patch), "ew.compat.perk_helper_patch", "status=" .. tostring(perk_helper_patch))
        add(report, perk_helper_loaded == "1" and "PASS" or "WARN", "ew.compat.perk_helper_runtime",
            "loaded=" .. tostring(perk_helper_loaded))
        add(report, patch_level(perk_mutation_patch), "ew.compat.perk_mutation_patch", "status=" .. tostring(perk_mutation_patch))
        add(report, perk_mutation_loaded == "1" and "PASS" or "WARN", "ew.compat.perk_mutation_runtime",
            "loaded=" .. tostring(perk_mutation_loaded))
        add(report, perk_runtime_guard == "installed" and "PASS" or "WARN", "ew.compat.peer_perk_runtime_guard",
            "status=" .. tostring(perk_runtime_guard))
        add(report, "INFO", "ew.world_sync", world_sync_context() .. " last_poly_chunk=" .. tostring(GlobalsGetValue("mcm_world_sync_last_poly_chunk_v1", "")))
        add(report, "INFO", "ew.world_item_outbox", "seq=" .. tostring(GlobalsGetValue("mcm_world_item_outbox_seq_v1", "0")) ..
            " ack=" .. tostring(GlobalsGetValue("mcm_world_item_outbox_ack_v1", "0")) .. " result=" .. tostring(GlobalsGetValue("mcm_world_item_outbox_result_v1", "")))
        add(report, "INFO", "ew.world_rules_mailbox", "remote_seq=" .. tostring(GlobalsGetValue("mcm_world_rules_remote_seq_v1", "0")) ..
            " origin=" .. tostring(GlobalsGetValue("mcm_world_rules_remote_origin_v1", "")) .. " outbox_seq=" .. tostring(GlobalsGetValue("mcm_world_rules_outbox_seq_v1", "0")))
        add(report, "INFO", "ew.form_sync", "mode=" .. tostring(GlobalsGetValue("mcm_form_sync_mode_v1", "unknown")) ..
            " pose_sent=" .. tostring(GlobalsGetValue("mcm_form_pose_sent_v1", "0")) ..
            " pose_recv=" .. tostring(GlobalsGetValue("mcm_form_pose_received_v1", "0")))
        add(report, "INFO", "ew.remote_qa", "seq=" .. tostring(GlobalsGetValue("mcm_remote_qa_seq_v1", "0")) ..
            " last=" .. one_line(GlobalsGetValue("mcm_remote_qa_last_v1", "")))
    end

    if type(perk_root_companions.ownership_summary) == "function" then
        local ok_owned, value = pcall(perk_root_companions.ownership_summary)
        if ok_owned then add(report, "INFO", "perk.root_companion_ownership", tostring(value or "")) end
    end
    if report.perk_service ~= nil and type(report.perk_service.count) == "function" then
        local explosive = {}
        for _, id in ipairs({"GLASS_CANNON", "REVENGE_EXPLOSION", "EXPLODING_CORPSES", "EXPLODING_GOLD"}) do
            local ok_count, count = pcall(report.perk_service.count, id)
            explosive[#explosive + 1] = id.."="..tostring(ok_count and count or "?")
        end
        add(report, "INFO", "perk.explosive_context", table.concat(explosive, ","))
    end

    if report.weather ~= nil then
        local can, reason = report.weather.can_edit()
        add(report, can and "PASS" or "INFO", "weather.editability", "can_edit=" .. tostring(can) .. " reason=" .. tostring(reason))
        add(report, "INFO", "weather.lock", "active=" .. tostring(report.weather.is_locked()))
        local weather_values = {}
        for _, field in ipairs(report.weather.fields() or {}) do
            local ok, value = pcall(report.weather.get, field)
            if ok then weather_values[#weather_values + 1] = tostring(field.id) .. "=" .. tostring(value) end
        end
        add(report, "INFO", "weather.values", sample_list(weather_values, 20))
        if type(report.weather.debug_state) == "function" then
            local ok_state, state = pcall(report.weather.debug_state)
            if ok_state and type(state) == "table" then
                add(report, "INFO", "weather.runtime",
                    "rainfall="..tostring(state.rainfall).." rain="..tostring(state.rain).." rain_target="..tostring(state.rain_target)..
                    " emitted="..tostring(state.rain_emitted_total).." last_emit="..tostring(state.last_rain_emit_frame)..
                    " stop_guard_until="..tostring(state.rain_stop_guard_until))
            end
        end
    end

    if report.menu ~= nil then
        add(report, "INFO", "ui.state", "tab=" .. tostring(report.menu.active_tab()) .. " hovered=" .. tostring(report.menu.is_hovered()))
    end
    if report.keybinds ~= nil then
        add(report, "INFO", "input.bindings", "possession=" .. tostring(report.keybinds.possess_key_name()) .. " qa=" .. QA_TRIGGER_KEY_NAME)
    end

    local corpses = EntityGetWithTag("metamorph_creative_menu_form_corpse") or {}
    add(report, "INFO", "form.corpses", "count=" .. tostring(#corpses))
    for index, entity in ipairs(corpses) do
        if index > 5 then break end
        local damage = EntityGetFirstComponentIncludingDisabled(entity, "DamageModelComponent")
        local wait_flag, kill_now = nil, nil
        if damage ~= nil and damage ~= 0 then
            pcall(function() wait_flag=ComponentGetValue2(damage,"wait_for_kill_flag_on_death"); kill_now=ComponentGetValue2(damage,"kill_now") end)
        end
        add(report, "INFO", "form.corpse." .. tostring(index), entity_summary(entity) ..
            " pending=" .. tostring(EntityHasTag(entity, "metamorph_creative_menu_form_corpse_pending")) ..
            " ew_synced=" .. tostring(EntityHasTag(entity, "ew_synced")) ..
            " ew_no_enemy_sync=" .. tostring(EntityHasTag(entity, "ew_no_enemy_sync")) ..
            " wait=" .. tostring(wait_flag) .. " kill_now=" .. tostring(kill_now) ..
            " des=" .. tostring(EntityHasTag(entity, "ew_des")) ..
            " gid=" .. one_line(variable_value(entity, "ew_gid_lid")))
    end

    local remote = EntityGetWithTag("ew_client") or {}
    add(report, "INFO", "ew.remote_players", "count=" .. tostring(#remote))
    for index, entity in ipairs(remote) do
        if index > 8 then break end
        local ai_enabled, ai_total = component_enabled_count(entity, "AnimalAIComponent")
        local worm_ai_enabled, worm_ai_total = component_enabled_count(entity, "WormAIComponent")
        local path_enabled, path_total = component_enabled_count(entity, "PathFindingComponent")
        local lua_enabled, lua_total = component_enabled_count(entity, "LuaComponent")
        local heavy = component_count(entity, "BossDragonComponent") > 0 or component_count(entity, "WormComponent") > 0
        local level = heavy and (ai_enabled + worm_ai_enabled + path_enabled > 0) and "WARN" or "INFO"
        local d=EntityGetFirstComponentIncludingDisabled(entity,"DamageModelComponent")
        local hp,max_hp=nil,nil; if d~=nil and d~=0 then pcall(function() hp=ComponentGetValue2(d,"hp"); max_hp=ComponentGetValue2(d,"max_hp") end) end
        add(report, level, "ew.remote." .. tostring(index), entity_summary(entity) ..
            string.format(" source=%s hp=%s/%s corpse=%s heavy=%s ai=%d/%d worm_ai=%d/%d path=%d/%d lua=%d/%d native_full=%s",
                one_line(variable_value(entity,"metamorph_creative_menu_network_source")),tostring(hp),tostring(max_hp),tostring(EntityHasTag(entity,"metamorph_creative_menu_form_corpse")),
                tostring(heavy), ai_enabled, ai_total, worm_ai_enabled, worm_ai_total,
                path_enabled, path_total, lua_enabled, lua_total, tostring(not EntityHasTag(entity, "metamorph_creative_menu_light_remote"))))
    end

    local errors_since_start = math.max(0, #runtime_errors - report.runtime_error_count_at_start)
    add(report, errors_since_start == 0 and "PASS" or "WARN", "runtime.captured_errors_since_start", "count=" .. tostring(errors_since_start))
    add(report, #runtime_errors == 0 and "PASS" or "WARN", "runtime.error_history", "session_count=" .. tostring(#runtime_errors))
    local history_first = math.max(1, #runtime_errors - 15)
    for index = history_first, #runtime_errors do
        local err = runtime_errors[index]
        add(report, "WARN", "runtime.error", "frame=" .. tostring(err.frame) .. " source=" .. err.source .. " message=" .. err.message)
    end

    report.runtime_done = true
end


function runtime_scanner.collect(report)
    return collect_world_and_runtime(report)
end

METAMORPH_CREATIVE_MENU_DIAGNOSTIC_RUNTIME_SCANNER = runtime_scanner
return runtime_scanner
