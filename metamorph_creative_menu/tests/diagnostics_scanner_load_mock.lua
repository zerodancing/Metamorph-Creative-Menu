local root = assert(arg[1], "root required")
local native_dofile = dofile
local events = {}
local logger = {
    runtime_errors = function() return {} end,
    now_frame = function() return 0 end,
    now_seconds = function() return 0 end,
    timestamp = function() return "now" end,
    one_line = function(value) return tostring(value or "") end,
    append = function() return true end,
    ensure_ready = function() return true end,
    event = function(kind, details) events[#events + 1] = {kind=kind, details=details}; return true end,
    user_action = function(action, details) events[#events + 1] = {kind=action, details=details}; return true end,
    capture_error = function() return true end,
}

ModGetActiveModIDs = function() return {} end
StatsGetValue = function() return "1" end
GlobalsGetValue = function(_key, default) return default or "" end
EntityGetIsAlive = function(entity) return entity == 1 end
EntityGetFilename = function() return "data/entities/player.xml" end
EntityGetTransform = function() return 10, 20 end
EntityGetAllChildren = function() return {} end
EntityGetAllComponents = function() return {} end
EntityHasTag = function() return false end
EntityGetComponentIncludingDisabled = function() return {} end
EntityGetFirstComponentIncludingDisabled = function() return nil end
EntityGetWithTag = function() return {} end
GameGetAllInventoryItems = function() return {} end
GamePrintImportant = function() end
ModDoesFileExist = function() return true end
dofile_once = function(path)
    if path == "data/scripts/gun/gun_actions.lua" then actions = {} end
    if path == "data/scripts/perks/perk_list.lua" then perk_list = {} end
    return true
end

local module_stubs = {
    ["mods/metamorph_creative_menu/files/integrations/ew/runtime.lua"] = {
        enabled=function() return true end,
        mode=function() return "client" end,
    },
    ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"] = {get=function() return 1 end},
    ["mods/metamorph_creative_menu/files/features/forms/manager.lua"] = {
        session_phase=function() return "human" end,
        session_target=function() return nil end,
        session_actual_target=function() return nil end,
        active_control_family=function() return "human" end,
        prepared_exact_effect_count=function() return 0 end,
    },
    ["mods/metamorph_creative_menu/files/features/creatures/service.lua"] = {
        collect=function() return {} end,
        collect_transform_target_paths=function() return {} end,
    },
    ["mods/metamorph_creative_menu/files/features/creatures/ui_catalog.lua"] = {},
    ["mods/metamorph_creative_menu/files/features/items/catalog.lua"] = {},
    ["mods/metamorph_creative_menu/files/features/effects/service.lua"] = {catalog=function() return {} end},
    ["mods/metamorph_creative_menu/files/features/perks/service.lua"] = {count=function() return 0 end},
    ["mods/metamorph_creative_menu/files/features/world_rules/service.lua"] = {},
    ["mods/metamorph_creative_menu/files/features/weather/service.lua"] = {
        can_edit=function() return true, "ok" end,
        is_locked=function() return false end,
        fields=function() return {} end,
        debug_state=function() return {} end,
    },
    ["mods/metamorph_creative_menu/files/ui/menu_controller.lua"] = {active_tab=function() return "SPELLS" end, is_hovered=function() return false end},
    ["mods/metamorph_creative_menu/files/features/possession/keybinds.lua"] = {possess_key_name=function() return "Key_g" end},
}

dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/diagnostics/logger.lua" then return logger end
    if path == "mods/metamorph_creative_menu/files/diagnostics/entity_inspection.lua" then
        return native_dofile(root .. "/files/diagnostics/entity_inspection.lua")
    end
    if path == "mods/metamorph_creative_menu/files/diagnostics/runtime_context.lua" then
        return native_dofile(root .. "/files/diagnostics/runtime_context.lua")
    end
    if path == "mods/metamorph_creative_menu/files/diagnostics/scan_support.lua" then
        return native_dofile(root .. "/files/diagnostics/scan_support.lua")
    end
    if path == "mods/metamorph_creative_menu/files/diagnostics/catalog_scanner.lua" then
        return native_dofile(root .. "/files/diagnostics/catalog_scanner.lua")
    end
    if path == "mods/metamorph_creative_menu/files/diagnostics/runtime_scanner.lua" then
        return native_dofile(root .. "/files/diagnostics/runtime_scanner.lua")
    end
    if module_stubs[path] ~= nil then return module_stubs[path] end
    return native_dofile(path)
end

METAMORPH_CREATIVE_MENU_DIAGNOSTIC_SCANNER = nil
METAMORPH_CREATIVE_MENU_DIAGNOSTIC_ENTITY_INSPECTION = nil
METAMORPH_CREATIVE_MENU_DIAGNOSTIC_RUNTIME_CONTEXT = nil
METAMORPH_CREATIVE_MENU_DIAGNOSTIC_SCAN_SUPPORT = nil
METAMORPH_CREATIVE_MENU_DIAGNOSTIC_CATALOG_SCANNER = nil
METAMORPH_CREATIVE_MENU_DIAGNOSTIC_RUNTIME_SCANNER = nil
local scanner = assert(native_dofile(root .. "/files/diagnostics/scanner.lua"))
assert(type(scanner.event) == "function", "scanner event API missing")
assert(type(scanner.user_action) == "function", "scanner user-action API missing")
assert(type(scanner.capture_error) == "function", "scanner error API missing")
scanner.event("TEST", "load")
assert(#events == 1 and events[1].kind == "TEST", "scanner logger delegation failed")

local report = {
    pass=0, warn=0, fail=0, info=0, rows={}, modules={},
    runtime_error_count_at_start=0, frame_ms={}, started_frame=0, started_time=0, started_stamp="now", run_id=1,
}
scanner.initialize(report)
assert(report.player == 1, "scanner initialize did not inspect the player")
local found_player_summary = false
for _, row in ipairs(report.rows) do
    if string.find(row, "player.local", 1, true) and string.find(row, "entity=1", 1, true) then
        found_player_summary = true
        break
    end
end
assert(found_player_summary, "scanner initialize did not execute shared entity inspection")
report.scan_stage = "runtime"
scanner.step(report)
assert(report.runtime_done == true and report.scan_stage == "sampling", "scanner runtime stage did not complete")
local found_world_sync = false
for _, row in ipairs(report.rows) do
    if string.find(row, "ew.world_sync", 1, true) and string.find(row, "world_sent=", 1, true) then
        found_world_sync = true
        break
    end
end
assert(found_world_sync, "scanner runtime stage did not execute shared EW runtime context")
print("diagnostics_scanner_load=PASS module_table_consistent=true initialize=true runtime=true")
