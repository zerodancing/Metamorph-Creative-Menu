local root = assert(arg[1], "project root required")
local original_dofile = dofile

-- The QA baseline module owns the perk introspection modules it reads; it must not
-- borrow a service table from runner.lua globals.
perk_service = nil

local world_rules_stub = {
    rules = function() return {} end,
    can_edit = function() return false end,
}
local weather_stub = {
    is_locked = function() return false end,
    fields = function() return {} end,
    get_time = function() return 0 end,
    can_edit = function() return false end,
}
local root_companions_stub = {
    owned_counts = function() return {} end,
}
local transaction_calls = 0
local transactions_stub = {
    active_count = function() transaction_calls = transaction_calls + 1; return 0 end,
    active_mutation_count = function() return 0 end,
    active_global_owner_counts = function() return 0, 0 end,
    cleanup_state = function() return {pending=0, failed=0} end,
}
local nested_stub = {state_snapshot=function() return {scopes=0, children=0} end}
local locomotion_stub = {baseline_count=function() return 0 end}


dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/features/world_rules/service.lua" then return world_rules_stub end
    if path == "mods/metamorph_creative_menu/files/features/weather/service.lua" then return weather_stub end
    if path == "mods/metamorph_creative_menu/files/features/perks/root_companions.lua" then return root_companions_stub end
    if path == "mods/metamorph_creative_menu/files/features/perks/transactions.lua" then return transactions_stub end
    if path == "mods/metamorph_creative_menu/files/features/perks/nested_pickups.lua" then return nested_stub end
    if path == "mods/metamorph_creative_menu/files/features/perks/locomotion_guard.lua" then return locomotion_stub end
    return original_dofile(path)
end

EntityGetIsAlive = function(e) return e == 1 end
EntityGetWithTag = function() return {} end
EntityGetAllChildren = function() return {} end
EntityGetComponentIncludingDisabled = function() return {} end
EntityGetFirstComponentIncludingDisabled = function() return nil end
EntityGetFilename = function() return "data/entities/player.xml" end
EntityGetName = function() return "" end
EntityHasTag = function() return false end
GlobalsGetValue = function(_, default) return default or "" end
GameGetWorldStateEntity = function() return 0 end
ComponentGetValue2 = function() return nil end
ComponentGetValue = function() return nil end

local baselines = original_dofile(root .. "/files/qa/baselines.lua")
assert(type(baselines) == "table", "baseline module did not load")
local ok, snapshot = pcall(baselines.perk_guard_snapshot, 1)
assert(ok, "perk_guard_snapshot must not depend on a global perk_service: " .. tostring(snapshot))
assert(type(snapshot) == "table", "snapshot missing")
assert(transaction_calls == 1, "owned transaction state was not queried")
assert(type(snapshot.ownership) == "table" and snapshot.ownership.transactions == 0, "ownership snapshot missing")
print("qa_baselines_scope=PASS explicit_perk_ownership_dependencies=true")
