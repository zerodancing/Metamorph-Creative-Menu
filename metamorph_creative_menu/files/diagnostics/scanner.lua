if type(METAMORPH_CREATIVE_MENU_DIAGNOSTIC_SCANNER) == "table" then return METAMORPH_CREATIVE_MENU_DIAGNOSTIC_SCANNER end

local scanner = {}
local logger = dofile("mods/metamorph_creative_menu/files/diagnostics/logger.lua")
local entity_inspection = dofile("mods/metamorph_creative_menu/files/diagnostics/entity_inspection.lua")

local MOD_LABEL = "Metamorph: Creative Menu syncfix v14.1 + MOBS icon contract hotfix"
local runtime_errors = logger.runtime_errors()
local now_frame = logger.now_frame
local now_seconds = logger.now_seconds
local timestamp = logger.timestamp
local one_line = logger.one_line
local append_file = logger.append
local entity_summary = entity_inspection.summary

local support = dofile("mods/metamorph_creative_menu/files/diagnostics/scan_support.lua")
local catalog_scanner = dofile("mods/metamorph_creative_menu/files/diagnostics/catalog_scanner.lua")
local runtime_scanner = dofile("mods/metamorph_creative_menu/files/diagnostics/runtime_scanner.lua")
local add = support.add
local sample_list = support.sample_list
local finite = support.finite
local safe_module = support.safe_module
local component_enabled_count = support.component_enabled_count

function scanner.event(kind, details)
    return logger.event(kind, details)
end

function scanner.user_action(action, details)
    return logger.user_action(action, details)
end

function scanner.test_action(_action, _details)
    return true
end

METAMORPH_CREATIVE_MENU_DIAGNOSTICS_USER_ACTION = function(action, details) pcall(scanner.user_action, action, details) end
METAMORPH_CREATIVE_MENU_DIAGNOSTICS_EVENT = function(kind, details) pcall(scanner.event, kind, details) end

scanner.capture_error = logger.capture_error
METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE = logger.capture_error

local function collect_environment(report)
    local mod_ids = {}
    local ok_mods, ids = pcall(ModGetActiveModIDs)
    if ok_mods and type(ids) == "table" then
        for _, id in ipairs(ids) do mod_ids[#mod_ids + 1] = tostring(id) end
        table.sort(mod_ids)
    end
    add(report, "INFO", "env.version", MOD_LABEL)
    add(report, "INFO", "env.time", "timestamp=" .. timestamp() .. " frame=" .. tostring(now_frame()))
    local seed = "?"
    if type(StatsGetValue) == "function" then local ok_seed, value = pcall(StatsGetValue, "world_seed"); if ok_seed then seed = tostring(value or "?") end end
    add(report, "INFO", "env.world", "seed=" .. seed)
    add(report, "INFO", "env.mods", "count=" .. tostring(#mod_ids) .. " ids=" .. sample_list(mod_ids, 20))

    local ok_mem, mem = pcall(collectgarbage, "count")
    report.memory_start = ok_mem and tonumber(mem) or nil
    if report.memory_start ~= nil then add(report, "INFO", "perf.lua_memory_start", string.format("kb=%.1f", report.memory_start)) end

    local ew_runtime = safe_module(report, "ew_runtime", "mods/metamorph_creative_menu/files/integrations/ew/runtime.lua")
    if ew_runtime ~= nil then
        local enabled = false
        local mode = "unknown"
        pcall(function() enabled = ew_runtime.enabled() == true; mode = tostring(ew_runtime.mode()) end)
        add(report, enabled and "PASS" or "INFO", "ew.runtime", "enabled=" .. tostring(enabled) .. " mode=" .. mode)
        report.ew_enabled = enabled
    end

    local bridge_ready = GlobalsGetValue("mcm_world_rules_rpc_ready_v1", "0")
    local bridge_error_seq = GlobalsGetValue("mcm_world_rules_rpc_error_seq_v1", "0")
    local bridge_error = GlobalsGetValue("mcm_world_rules_rpc_error_v1", "")
    if report.ew_enabled then
        add(report, bridge_ready == "1" and "PASS" or "WARN", "ew.bridge",
            "ready=" .. tostring(bridge_ready) .. " my_id=" .. GlobalsGetValue("mcm_world_rules_rpc_my_id_v1", "") ..
            " host_id=" .. GlobalsGetValue("mcm_world_rules_rpc_host_id_v1", ""))
        local seq = tonumber(bridge_error_seq) or 0
        add(report, seq == 0 and "PASS" or "WARN", "ew.bridge_errors",
            "seq=" .. tostring(seq) .. (bridge_error ~= "" and (" last=" .. bridge_error) or ""))
    end
end

local function collect_player(report)
    local locator = safe_module(report, "player_locator", "mods/metamorph_creative_menu/files/platform/noita/player_locator.lua")
    local manager = safe_module(report, "form_manager", "mods/metamorph_creative_menu/files/features/forms/manager.lua")
    local player = 0
    if locator ~= nil and type(locator.get) == "function" then
        local ok, value = pcall(locator.get)
        if ok then player = tonumber(value) or 0 end
    end
    report.player = player
    if player == 0 or not EntityGetIsAlive(player) then
        add(report, "FAIL", "player.local", "missing_or_dead")
        return
    end
    add(report, "PASS", "player.local", entity_summary(player))

    local damage = EntityGetFirstComponentIncludingDisabled(player, "DamageModelComponent")
    if damage ~= nil and damage ~= 0 then
        local hp = tonumber(ComponentGetValue2(damage, "hp"))
        local max_hp = tonumber(ComponentGetValue2(damage, "max_hp"))
        add(report, hp ~= nil and max_hp ~= nil and hp <= max_hp + 0.0001 and "PASS" or "WARN", "player.health",
            "hp=" .. tostring(hp) .. " max_hp=" .. tostring(max_hp) .. " cap=" .. tostring(ComponentGetValue2(damage, "max_hp_cap")))
    else
        add(report, "WARN", "player.health", "DamageModelComponent missing")
    end

    local is_poly = EntityHasTag(player, "polymorphed_player")
    if not is_poly then
        local controls = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
        local inventory = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
        add(report, controls ~= nil and controls ~= 0 and "PASS" or "FAIL", "player.controls", "component=" .. tostring(controls or 0))
        add(report, inventory ~= nil and inventory ~= 0 and "PASS" or "FAIL", "player.inventory_component", "component=" .. tostring(inventory or 0))
        if inventory ~= nil and inventory ~= 0 then
            local active_item = tonumber(ComponentGetValue2(inventory, "mActiveItem")) or 0
            local actual = tonumber(ComponentGetValue2(inventory, "mActualActiveItem")) or 0
            local items = GameGetAllInventoryItems(player) or {}
            local active_ok = active_item == 0 or EntityGetIsAlive(active_item)
            local actual_ok = actual == 0 or EntityGetIsAlive(actual)
            add(report, active_ok and actual_ok and "PASS" or "WARN", "player.inventory_state",
                "items=" .. tostring(#items) .. " active=" .. tostring(active_item) .. " actual=" .. tostring(actual))
            local wand = actual ~= 0 and actual or active_item
            if wand ~= 0 and EntityGetIsAlive(wand) then
                local ability = EntityGetFirstComponentIncludingDisabled(wand, "AbilityComponent")
                if ability ~= nil and ability ~= 0 then
                    local mana = ComponentGetValue2(ability, "mana")
                    local mana_max = ComponentGetValue2(ability, "mana_max")
                    local charge = ComponentGetValue2(ability, "mana_charge_speed")
                    local deck, shuffle = nil, nil
                    if type(ComponentObjectGetValue2) == "function" then
                        pcall(function() deck = ComponentObjectGetValue2(ability, "gun_config", "deck_capacity") end)
                        pcall(function() shuffle = ComponentObjectGetValue2(ability, "gun_config", "shuffle_deck_when_empty") end)
                    end
                    add(report, "INFO", "wand.active", "entity=" .. tostring(wand) .. " mana=" .. tostring(mana) ..
                        "/" .. tostring(mana_max) .. " charge=" .. tostring(charge) .. " capacity=" .. tostring(deck) .. " shuffle=" .. tostring(shuffle))
                end
            end
        end
    else
        local driver = EntityGetFirstComponentIncludingDisabled(player, "WormPlayerComponent")
        local worm = EntityGetFirstComponentIncludingDisabled(player, "WormComponent")
        local dragon = EntityGetFirstComponentIncludingDisabled(player, "BossDragonComponent")
        local kind = dragon ~= nil and dragon ~= 0 and "dragon" or (driver ~= nil and driver ~= 0 and "worm_player" or (worm ~= nil and worm ~= 0 and "worm" or "other"))
        local dx, dy, speed = nil, nil, nil
        if driver ~= nil and driver ~= 0 then pcall(function() dx, dy = ComponentGetValue2(driver, "mDirection") end) end
        if worm ~= nil and worm ~= 0 then pcall(function() speed = ComponentGetValue2(worm, "mTargetSpeed") end) end
        local ai_enabled, ai_total = component_enabled_count(player, "AnimalAIComponent")
        local wai_enabled, wai_total = component_enabled_count(player, "WormAIComponent")
        add(report, "INFO", "form.motor", "kind=" .. kind .. " direction=" .. tostring(dx) .. "," .. tostring(dy) ..
            " target_speed=" .. tostring(speed) .. " animal_ai=" .. tostring(ai_enabled) .. "/" .. tostring(ai_total) ..
            " worm_ai=" .. tostring(wai_enabled) .. "/" .. tostring(wai_total))
    end

    if manager ~= nil then
        local phase, target, actual, family, prepared = "?", nil, nil, "?", nil
        pcall(function()
            phase = manager.session_phase()
            target = manager.session_target()
            actual = manager.session_actual_target()
            family = manager.active_control_family()
            prepared = manager.prepared_exact_effect_count()
        end)
        add(report, "INFO", "form.session", "phase=" .. tostring(phase) .. " family=" .. tostring(family) ..
            " requested=" .. tostring(target or "") .. " actual=" .. tostring(actual or "") .. " wrappers=" .. tostring(prepared or "?"))
        if is_poly then
            add(report, tostring(phase) ~= "human" and "PASS" or "WARN", "form.session_consistency",
                "polymorphed_tag=true phase=" .. tostring(phase))
        end
    end

    local clones = EntityGetWithTag("metamorph_creative_menu_player_clone") or {}
    if #clones > 0 then
        for index, clone in ipairs(clones) do
            if index > 4 then break end
            local dmg = EntityGetFirstComponentIncludingDisabled(clone, "DamageModelComponent")
            local hp, max_hp = nil, nil
            if dmg ~= nil and dmg ~= 0 then hp, max_hp = ComponentGetValue2(dmg, "hp"), ComponentGetValue2(dmg, "max_hp") end
            add(report, "INFO", "companion." .. tostring(index), entity_summary(clone) .. " hp=" .. tostring(hp) .. "/" .. tostring(max_hp))
        end
    else
        add(report, "INFO", "companion.count", "0")
    end
end

local function percentile(sorted, fraction)
    if #sorted == 0 then return 0 end
    local index = math.max(1, math.min(#sorted, math.floor((#sorted - 1) * fraction + 1.5)))
    return sorted[index]
end

local function finalize_perf(report)
    local values = {}
    local sum, slow33, slow50 = 0, 0, 0
    for _, value in ipairs(report.frame_ms) do
        if finite(value) and value >= 0 and value < 5000 then
            values[#values + 1] = value
            sum = sum + value
            if value > 33.34 then slow33 = slow33 + 1 end
            if value > 50 then slow50 = slow50 + 1 end
        end
    end
    table.sort(values)
    local avg = #values > 0 and sum / #values or 0
    local p50, p95, p99, maxv = percentile(values, 0.50), percentile(values, 0.95), percentile(values, 0.99), values[#values] or 0
    local level = p95 <= 33.34 and "PASS" or p95 <= 50 and "WARN" or "WARN"
    add(report, level, "perf.frame_time",
        string.format("samples=%d avg=%.2fms p50=%.2fms p95=%.2fms p99=%.2fms max=%.2fms slow33=%d slow50=%d",
            #values, avg, p50, p95, p99, maxv, slow33, slow50))

    local ok_mem, mem = pcall(collectgarbage, "count")
    if ok_mem and tonumber(mem) ~= nil then
        local finish = tonumber(mem)
        add(report, "INFO", "perf.lua_memory_end",
            string.format("kb=%.1f delta=%.1f", finish, report.memory_start and (finish - report.memory_start) or 0))
    end

    if report.player ~= 0 and EntityGetIsAlive(report.player) then
        local player_x, player_y = EntityGetTransform(report.player)
        if report.start_x ~= nil then
            local displacement_x = (tonumber(player_x) or 0) - report.start_x
            local displacement_y = (tonumber(player_y) or 0) - report.start_y
            add(report, "INFO", "perf.player_motion", string.format("displacement=%.1f,%.1f distance=%.1f", displacement_x, displacement_y, math.sqrt(displacement_x*displacement_x+displacement_y*displacement_y)))
        end
    end
end

local function finish(report)
    finalize_perf(report)
    local duration = nil
    local end_time = now_seconds()
    if end_time ~= nil and report.started_time ~= nil then duration = end_time - report.started_time end
    add(report, "INFO", "test.coverage", "non_destructive=true destructive_spawn_pickup_transform_rule_write=false")

    local summary = string.format("SUMMARY pass=%d warn=%d fail=%d info=%d frames=%d duration_s=%s runtime_errors_new=%d",
        report.pass, report.warn, report.fail, report.info,
        now_frame() - report.started_frame,
        duration ~= nil and string.format("%.2f", duration) or "?", math.max(0, #runtime_errors - (report.runtime_error_count_at_start or 0)))
    local text = table.concat({
        "\n=== EWCM DIAGNOSTIC REPORT run=" .. tostring(report.run_id) .. " time=" .. report.started_stamp .. " ===\n",
        table.concat(report.rows, "\n"), "\n",
        summary, "\n",
        "=== END EWCM DIAGNOSTIC REPORT run=" .. tostring(report.run_id) .. " ===\n",
    })
    local ok, err = append_file(text)
    if not ok then
        print("[Metamorph: Creative Menu] diagnostics could not write report: " .. tostring(err))
        GamePrintImportant("Metamorph: Creative Menu diagnostics", "WRITE FAILED: " .. tostring(err))
    else
        print("[Metamorph: Creative Menu] diagnostics finished: " .. summary .. " -> " .. logger.path())
        GamePrintImportant("Metamorph: Creative Menu diagnostics", "DONE: " .. summary)
    end
end


function scanner.initialize(report)
    collect_environment(report)
    collect_player(report)
    if report.player ~= 0 and EntityGetIsAlive(report.player) then
        report.start_x, report.start_y = EntityGetTransform(report.player)
    end
    catalog_scanner.prepare(report)
end

function scanner.step(report)
    if catalog_scanner.step(report) then return end
    if report.scan_stage == "runtime" then
        runtime_scanner.collect(report)
        report.scan_stage = "sampling"
    end
end

function scanner.finish(report)
    finish(report)
end

function scanner.runtime_error_count()
    return #runtime_errors
end

METAMORPH_CREATIVE_MENU_DIAGNOSTIC_SCANNER = scanner
return scanner
