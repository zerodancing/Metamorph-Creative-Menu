if type(METAMORPH_CREATIVE_MENU_DIAGNOSTIC_CATALOG_SCANNER) == "table" then return METAMORPH_CREATIVE_MENU_DIAGNOSTIC_CATALOG_SCANNER end

local catalog_scanner = {}
local support = dofile("mods/metamorph_creative_menu/files/diagnostics/scan_support.lua")
local add = support.add
local sample_list = support.sample_list
local safe_module = support.safe_module

local function prepare_catalogs(report)
    report.creature_service = safe_module(report, "creature_service", "mods/metamorph_creative_menu/files/features/creatures/service.lua")
    report.entity_catalog = safe_module(report, "entity_catalog", "mods/metamorph_creative_menu/files/features/creatures/ui_catalog.lua")
    report.item_catalog = safe_module(report, "item_catalog", "mods/metamorph_creative_menu/files/features/items/catalog.lua")
    report.effect_service = safe_module(report, "effect_service", "mods/metamorph_creative_menu/files/features/effects/service.lua")
    report.perk_service = safe_module(report, "perk_service", "mods/metamorph_creative_menu/files/features/perks/service.lua")
    report.world_rules = safe_module(report, "world_rules", "mods/metamorph_creative_menu/files/features/world_rules/service.lua")
    report.weather = safe_module(report, "weather", "mods/metamorph_creative_menu/files/features/weather/service.lua")
    report.menu = safe_module(report, "menu", "mods/metamorph_creative_menu/files/ui/menu_controller.lua")
    report.keybinds = safe_module(report, "keybinds", "mods/metamorph_creative_menu/files/features/possession/keybinds.lua")

    if report.creature_service ~= nil then
        local ok, values = pcall(report.creature_service.collect)
        report.creatures = ok and type(values) == "table" and values or {}
        local ok_targets, targets = pcall(report.creature_service.collect_transform_target_paths)
        report.creature_targets = ok_targets and type(targets) == "table" and targets or {}
    else report.creatures, report.creature_targets = {}, {} end

    if report.item_catalog ~= nil then
        report.items = type(report.item_catalog) == "table" and report.item_catalog or {}
    else report.items = {} end

    if report.effect_service ~= nil then
        local ok, values = pcall(report.effect_service.catalog)
        report.effects = ok and type(values) == "table" and values or {}
        if report.player ~= 0 and type(report.effect_service.active_snapshot) == "function" then
            local ok_snapshot, snapshot = pcall(report.effect_service.active_snapshot, report.player)
            if ok_snapshot and type(snapshot) == "table" then report.effect_snapshot = snapshot end
        end
    else report.effects = {} end

    local ok_enums = pcall(dofile_once, "data/scripts/gun/gun_enums.lua")
    local ok_actions = pcall(dofile_once, "data/scripts/gun/gun_actions.lua")
    report.actions = ok_enums and ok_actions and type(actions) == "table" and actions or {}
    if #report.actions == 0 then add(report, "FAIL", "catalog.spells_load", "actions table unavailable") end

    pcall(dofile_once, "data/scripts/perks/perk.lua")
    pcall(dofile_once, "data/scripts/perks/perk_list.lua")
    report.perks = type(perk_list) == "table" and perk_list or {}
    if #report.perks == 0 then add(report, "FAIL", "catalog.perks_load", "perk_list unavailable") end

    add(report, #report.creatures >= 200 and "PASS" or "WARN", "catalog.creatures_count", "count=" .. tostring(#report.creatures) .. " targets=" .. tostring(#report.creature_targets))
    add(report, #report.items > 0 and "PASS" or "FAIL", "catalog.items_count", "count=" .. tostring(#report.items))
    add(report, #report.actions > 0 and "PASS" or "FAIL", "catalog.spells_count", "count=" .. tostring(#report.actions))
    add(report, #report.perks > 0 and "PASS" or "FAIL", "catalog.perks_count", "count=" .. tostring(#report.perks))
    add(report, #report.effects > 0 and "PASS" or "FAIL", "catalog.effects_count", "count=" .. tostring(#report.effects))

    report.scan_stage = "spells"
    report.scan_index = 1
    report.scan = {
        spell_ids={}, spell_duplicates={}, spell_missing_sprite={}, spell_missing_name={},
        item_paths={}, item_duplicates={}, item_missing_path={}, item_missing_icon={}, chest_leggy=false,
        perk_ids={}, perk_duplicates={}, active_perks={}, active_unremovable={}, perk_missing_icon={},
        effect_missing_path={}, effect_missing_icon={}, active_effects={},
        creature_paths={}, creature_duplicates={}, creature_missing_path={}, creature_missing_icon={},
        creature_internal={}, creature_not_transformable={}, creature_missing_wrapper={}, creature_targets={},
        creature_compatibility={ verified=0, candidate=0, unsupported=0, unsafe=0, unknown=0 },
    }
end

local function scan_spells(report, budget)
    local scan = report.scan
    local last = math.min(#report.actions, report.scan_index + budget - 1)
    for index = report.scan_index, last do
        local action = report.actions[index]
        if type(action) == "table" then
            local id = tostring(action.id or "")
            if id == "" then scan.spell_missing_name[#scan.spell_missing_name + 1] = "index:" .. tostring(index) .. ":missing_id"
            else
                if scan.spell_ids[id] then scan.spell_duplicates[#scan.spell_duplicates + 1] = id else scan.spell_ids[id] = true end
            end
            if tostring(action.name or "") == "" then scan.spell_missing_name[#scan.spell_missing_name + 1] = id .. ":name" end
            local sprite = tostring(action.sprite or "")
            if sprite ~= "" and not ModDoesFileExist(sprite) then scan.spell_missing_sprite[#scan.spell_missing_sprite + 1] = id .. "=" .. sprite end
        end
    end
    report.scan_index = last + 1
    if report.scan_index > #report.actions then
        add(report, #scan.spell_duplicates == 0 and "PASS" or "WARN", "catalog.spells_duplicates", "count=" .. tostring(#scan.spell_duplicates) .. " examples=" .. sample_list(scan.spell_duplicates, 8))
        add(report, #scan.spell_missing_sprite == 0 and "PASS" or "WARN", "catalog.spells_sprites", "missing=" .. tostring(#scan.spell_missing_sprite) .. " examples=" .. sample_list(scan.spell_missing_sprite, 6))
        add(report, #scan.spell_missing_name == 0 and "PASS" or "WARN", "catalog.spells_metadata", "issues=" .. tostring(#scan.spell_missing_name) .. " examples=" .. sample_list(scan.spell_missing_name, 6))
        report.scan_stage, report.scan_index = "items", 1
    end
end

local function scan_items(report, budget)
    local scan = report.scan
    local last = math.min(#report.items, report.scan_index + budget - 1)
    for index = report.scan_index, last do
        local entry = report.items[index]
        if type(entry) == "table" then
            local path = tostring(entry.path or "")
            if scan.item_paths[path] then scan.item_duplicates[#scan.item_duplicates + 1] = path else scan.item_paths[path] = true end
            if path == "data/entities/items/pickup/chest_leggy.xml" then scan.chest_leggy = true end
            if path == "" or not ModDoesFileExist(path) then scan.item_missing_path[#scan.item_missing_path + 1] = path == "" and ("index:" .. index) or path end
            local icon = tostring(entry.icon or "")
            if icon ~= "" and not ModDoesFileExist(icon) then scan.item_missing_icon[#scan.item_missing_icon + 1] = path .. "=" .. icon end
        end
    end
    report.scan_index = last + 1
    if report.scan_index > #report.items then
        add(report, #scan.item_duplicates == 0 and "PASS" or "WARN", "catalog.items_duplicates", "count=" .. tostring(#scan.item_duplicates) .. " examples=" .. sample_list(scan.item_duplicates, 8))
        add(report, #scan.item_missing_path == 0 and "PASS" or "FAIL", "catalog.items_paths", "missing=" .. tostring(#scan.item_missing_path) .. " examples=" .. sample_list(scan.item_missing_path, 8))
        add(report, #scan.item_missing_icon == 0 and "PASS" or "WARN", "catalog.items_icons", "missing=" .. tostring(#scan.item_missing_icon) .. " examples=" .. sample_list(scan.item_missing_icon, 6))
        add(report, not scan.chest_leggy and "PASS" or "FAIL", "catalog.items_no_leggy_mimic", "present=" .. tostring(scan.chest_leggy))
        report.scan_stage, report.scan_index = "perks", 1
    end
end

local function scan_perks(report, budget)
    local scan = report.scan
    local last = math.min(#report.perks, report.scan_index + budget - 1)
    for index = report.scan_index, last do
        local perk = report.perks[index]
        if type(perk) == "table" then
            local id = tostring(perk.id or "")
            if scan.perk_ids[id] then scan.perk_duplicates[#scan.perk_duplicates + 1] = id else scan.perk_ids[id] = true end
            local icon = tostring(perk.ui_icon or "")
            if icon ~= "" and not ModDoesFileExist(icon) then scan.perk_missing_icon[#scan.perk_missing_icon + 1] = id .. "=" .. icon end
            if report.perk_service ~= nil and id ~= "" then
                local count = tonumber(report.perk_service.count(id)) or 0
                if count > 0 then
                    scan.active_perks[#scan.active_perks + 1] = id .. "x" .. tostring(count)
                    if report.player ~= 0 and type(report.perk_service.can_remove) == "function" then
                        local ok, can, reason = pcall(report.perk_service.can_remove, perk, report.player)
                        if not ok or can ~= true then scan.active_unremovable[#scan.active_unremovable + 1] = id .. ":" .. tostring(reason or can) end
                    end
                end
            end
        end
    end
    report.scan_index = last + 1
    if report.scan_index > #report.perks then
        add(report, #scan.perk_duplicates == 0 and "PASS" or "WARN", "catalog.perks_duplicates", "count=" .. tostring(#scan.perk_duplicates) .. " examples=" .. sample_list(scan.perk_duplicates, 8))
        add(report, #scan.perk_missing_icon == 0 and "PASS" or "WARN", "catalog.perks_icons", "missing=" .. tostring(#scan.perk_missing_icon) .. " examples=" .. sample_list(scan.perk_missing_icon, 6))
        add(report, "INFO", "perk.active", "count=" .. tostring(#scan.active_perks) .. " values=" .. sample_list(scan.active_perks, 24))
        add(report, #scan.active_unremovable == 0 and "PASS" or "WARN", "perk.active_removability", "blocked=" .. tostring(#scan.active_unremovable) .. " values=" .. sample_list(scan.active_unremovable, 16))
        report.scan_stage, report.scan_index = "effects", 1
    end
end

local function scan_effects(report, budget)
    local scan = report.scan
    local last = math.min(#report.effects, report.scan_index + budget - 1)
    for index = report.scan_index, last do
        local entry = report.effects[index]
        if type(entry) == "table" then
            local path = tostring(entry.path or entry.entity_path or "")
            if path ~= "" and not ModDoesFileExist(path) then scan.effect_missing_path[#scan.effect_missing_path + 1] = path end
            local icon = tostring(entry.icon or entry.ui_icon or "")
            if icon ~= "" and not ModDoesFileExist(icon) then scan.effect_missing_icon[#scan.effect_missing_icon + 1] = tostring(entry.id or index) .. "=" .. icon end
            if report.player ~= 0 and report.effect_snapshot ~= nil and report.effect_service ~= nil
                and type(report.effect_service.is_active) == "function" then
                local ok_active, is_active = pcall(report.effect_service.is_active, report.player, entry, report.effect_snapshot)
                if ok_active and is_active == true then scan.active_effects[#scan.active_effects + 1] = tostring(entry.id or entry.display_name or path or index) end
            end
        end
    end
    report.scan_index = last + 1
    if report.scan_index > #report.effects then
        add(report, #scan.effect_missing_path == 0 and "PASS" or "WARN", "catalog.effects_paths", "missing=" .. tostring(#scan.effect_missing_path) .. " examples=" .. sample_list(scan.effect_missing_path, 8))
        add(report, #scan.effect_missing_icon == 0 and "PASS" or "WARN", "catalog.effects_icons", "missing=" .. tostring(#scan.effect_missing_icon) .. " examples=" .. sample_list(scan.effect_missing_icon, 6))
        add(report, "INFO", "effect.active", "count=" .. tostring(#scan.active_effects) .. " values=" .. sample_list(scan.active_effects, 24))
        report.scan_stage, report.scan_index = "creature_warmup", 1
    end
end

local function warmup_creatures(report, budget)
    local creature_service = report.creature_service
    if creature_service == nil or type(creature_service.warmup_step) ~= "function" then
        report.scan_stage, report.scan_index = "creatures", 1
        return
    end
    local ok, done = pcall(creature_service.warmup_step, math.max(1, tonumber(budget) or 8))
    if not ok then
        add(report, "WARN", "catalog.creatures_warmup", "error=" .. tostring(done))
        report.scan_stage, report.scan_index = "creatures", 1
        return
    end
    if done == true then
        local ok_values, values = pcall(creature_service.collect)
        if ok_values and type(values) == "table" then report.creatures = values end
        local ok_targets, targets = pcall(creature_service.collect_transform_target_paths)
        if ok_targets and type(targets) == "table" then report.creature_targets = targets end
        add(report, #report.creatures >= 200 and "PASS" or "WARN", "catalog.creatures_count_final",
            "count=" .. tostring(#report.creatures) .. " targets=" .. tostring(#report.creature_targets) .. " warmup_complete=true")
        report.scan_stage, report.scan_index = "creatures", 1
    end
end

local function scan_creatures(report, budget)
    local scan = report.scan
    local creature_service = report.creature_service
    local manager = report.modules.form_manager
    local last = math.min(#report.creatures, report.scan_index + budget - 1)
    for index = report.scan_index, last do
        local entry = report.creatures[index]
        if type(entry) == "table" then
            local path = tostring(entry.path or "")
            if scan.creature_paths[path] then scan.creature_duplicates[#scan.creature_duplicates + 1] = path else scan.creature_paths[path] = true end
            if path == "" or not ModDoesFileExist(path) then
                scan.creature_missing_path[#scan.creature_missing_path + 1] = path == "" and ("index:" .. tostring(index)) or path
            else
                if creature_service ~= nil and type(creature_service.is_internal_helper_path) == "function" then
                    local ok, internal = pcall(creature_service.is_internal_helper_path, path)
                    if ok and internal == true then scan.creature_internal[#scan.creature_internal + 1] = path end
                end
                if creature_service ~= nil and type(creature_service.is_transformable_creature_path) == "function" and path ~= "data/entities/player.xml" then
                    local ok, transformable = pcall(creature_service.is_transformable_creature_path, path)
                    if not ok or transformable ~= true then scan.creature_not_transformable[#scan.creature_not_transformable + 1] = path end
                end
                if creature_service ~= nil and type(creature_service.compatibility_status) == "function" and path ~= "data/entities/player.xml" then
                    local ok_status, status = pcall(creature_service.compatibility_status, path)
                    status = ok_status and tostring(status or "unknown") or "unknown"
                    if scan.creature_compatibility[status] == nil then status = "unknown" end
                    scan.creature_compatibility[status] = scan.creature_compatibility[status] + 1
                end
                if manager ~= nil and type(manager.exact_effect_path_for_target) == "function" and path ~= "data/entities/player.xml" then
                    local canonical = path
                    if creature_service ~= nil and type(creature_service.canonical_transform_path) == "function" then
                        local ok, value = pcall(creature_service.canonical_transform_path, path)
                        if ok and type(value) == "string" and value ~= "" then canonical = value end
                    end
                    local ok, wrapper = pcall(manager.exact_effect_path_for_target, path)
                    if (not ok or type(wrapper) ~= "string" or wrapper == "") and canonical ~= path then
                        ok, wrapper = pcall(manager.exact_effect_path_for_target, canonical)
                    end
                    if not ok or type(wrapper) ~= "string" or wrapper == "" or not ModDoesFileExist(wrapper) then
                        scan.creature_missing_wrapper[#scan.creature_missing_wrapper + 1] = path .. "=>" .. tostring(wrapper or "")
                    end
                end
            end
            local icon = tostring(entry.icon or "")
            if icon ~= "" and not ModDoesFileExist(icon) then scan.creature_missing_icon[#scan.creature_missing_icon + 1] = tostring(entry.id or path) .. "=" .. icon end
        end
    end
    report.scan_index = last + 1
    if report.scan_index > #report.creatures then
        for _, target in ipairs(report.creature_targets or {}) do scan.creature_targets[tostring(target)] = true end
        local required = {
            "data/entities/animals/illusions/worm_big.xml",
            "data/entities/animals/drone_physics.xml",
            "data/entities/animals/boss_dragon.xml",
            "data/entities/animals/maggot.xml",
            "data/entities/animals/maggot_tiny/maggot_tiny.xml",
            "data/entities/animals/worm_end.xml",
            -- Confirmed playable projectile-like forms. Keep these exact regressions so
            -- a future cleanup cannot replace the evidence-based denylist with a broad
            -- `rocket/projectile/orb` filename filter.
            "data/entities/animals/boss_wizard/meteor.xml",
            "data/entities/animals/boss_centipede/orb_mat_radioactive.xml",
        }
        local required_missing = {}
        for _, path in ipairs(required) do
            if not scan.creature_paths[path] then required_missing[#required_missing + 1] = path end
        end
        add(report, #scan.creature_duplicates == 0 and "PASS" or "WARN", "catalog.creatures_duplicates", "count=" .. tostring(#scan.creature_duplicates) .. " examples=" .. sample_list(scan.creature_duplicates, 8))
        add(report, #scan.creature_missing_path == 0 and "PASS" or "FAIL", "catalog.creatures_paths", "missing=" .. tostring(#scan.creature_missing_path) .. " examples=" .. sample_list(scan.creature_missing_path, 8))
        add(report, #scan.creature_internal == 0 and "PASS" or "FAIL", "catalog.creatures_helpers", "leaked=" .. tostring(#scan.creature_internal) .. " examples=" .. sample_list(scan.creature_internal, 8))
        add(report, #scan.creature_not_transformable == 0 and "PASS" or "FAIL", "catalog.creatures_transformable", "blocked=" .. tostring(#scan.creature_not_transformable) .. " examples=" .. sample_list(scan.creature_not_transformable, 10))
        add(report, #scan.creature_missing_wrapper == 0 and "PASS" or "FAIL", "catalog.creatures_wrappers", "missing=" .. tostring(#scan.creature_missing_wrapper) .. " examples=" .. sample_list(scan.creature_missing_wrapper, 10))
        add(report, #scan.creature_missing_icon == 0 and "PASS" or "WARN", "catalog.creatures_icons", "missing=" .. tostring(#scan.creature_missing_icon) .. " examples=" .. sample_list(scan.creature_missing_icon, 10))
        local compatibility_counts = scan.creature_compatibility or {}
        add(report, "INFO", "catalog.creatures_compatibility",
            "verified=" .. tostring(compatibility_counts.verified or 0)
            .. " candidate=" .. tostring(compatibility_counts.candidate or 0)
            .. " unsupported=" .. tostring(compatibility_counts.unsupported or 0)
            .. " unsafe=" .. tostring(compatibility_counts.unsafe or 0)
            .. " unknown=" .. tostring(compatibility_counts.unknown or 0))
        -- creature diagnostics alone cannot catch a presentation-contract regression:
        -- v14's entity_catalog consumed path-only prewarm rows, so this check reported
        -- missing=0 while MOBS rendered fallback icons/names. Validate the actual UI feed.
        local ui_meta_missing, ui_progress_icon_missing = {}, {}
        local entity_catalog = report.entity_catalog
        if type(entity_catalog) == "table" and type(entity_catalog.collect) == "function" then
            local ok_ui, ui_entries = pcall(entity_catalog.collect)
            if ok_ui and type(ui_entries) == "table" then
                for _, ui_entry in ipairs(ui_entries) do
                    if type(ui_entry) == "table" and ui_entry.role == "creature" then
                        local path = tostring(ui_entry.path or "")
                        local id = tostring(ui_entry.id or "")
                        local name = tostring(ui_entry.display_name or "")
                        local category = tostring(ui_entry.category or "")
                        local source = tostring(ui_entry.source or "")
                        if id == "" or name == "" or category == "" or source == "" then
                            ui_meta_missing[#ui_meta_missing + 1] = path
                        end
                        if source == "vanilla_progress" then
                            local icon = tostring(ui_entry.icon or "")
                            if icon == "" or not ModDoesFileExist(icon) then
                                ui_progress_icon_missing[#ui_progress_icon_missing + 1] = id ~= "" and id or path
                            end
                        end
                    end
                end
            else
                ui_meta_missing[#ui_meta_missing + 1] = "entity_catalog.collect_failed"
            end
        else
            ui_meta_missing[#ui_meta_missing + 1] = "entity_catalog.unavailable"
        end
        add(report, #ui_meta_missing == 0 and "PASS" or "FAIL", "catalog.mobs_ui_metadata",
            "missing=" .. tostring(#ui_meta_missing) .. " examples=" .. sample_list(ui_meta_missing, 10))
        add(report, #ui_progress_icon_missing == 0 and "PASS" or "FAIL", "catalog.mobs_ui_progress_icons",
            "missing=" .. tostring(#ui_progress_icon_missing) .. " examples=" .. sample_list(ui_progress_icon_missing, 10))
        add(report, #required_missing == 0 and "PASS" or "FAIL", "catalog.creatures_regression_set", "missing=" .. sample_list(required_missing, 8))
        local unsafe_leaks = {}
        if creature_service ~= nil and type(creature_service.known_unsafe_forms) == "function" then
            local ok, unsafe = pcall(creature_service.known_unsafe_forms)
            if ok and type(unsafe) == "table" then
                for path, reason in pairs(unsafe) do
                    if scan.creature_paths[path] then unsafe_leaks[#unsafe_leaks + 1] = path .. "(" .. tostring(reason) .. ")" end
                end
            end
        end
        add(report, #unsafe_leaks == 0 and "PASS" or "FAIL", "catalog.creatures_known_unsafe_hidden",
            "leaked=" .. sample_list(unsafe_leaks, 8))
        report.scan_stage = "runtime"
    end
end


function catalog_scanner.prepare(report)
    return prepare_catalogs(report)
end

function catalog_scanner.step(report)
    if report.scan_stage == "spells" then scan_spells(report, 32)
    elseif report.scan_stage == "items" then scan_items(report, 32)
    elseif report.scan_stage == "perks" then scan_perks(report, 24)
    elseif report.scan_stage == "effects" then scan_effects(report, 24)
    elseif report.scan_stage == "creature_warmup" then warmup_creatures(report, 12)
    elseif report.scan_stage == "creatures" then scan_creatures(report, 12)
    else return false end
    return true
end

METAMORPH_CREATIVE_MENU_DIAGNOSTIC_CATALOG_SCANNER = catalog_scanner
return catalog_scanner
