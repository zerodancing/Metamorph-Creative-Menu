local root = assert(arg[1], "project root required")
local original_dofile = dofile

-- This test intentionally does NOT define a global perk_service.  The QA baseline
-- module must own its dependency instead of accidentally borrowing runner.lua locals.
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
local service_calls = 0
local perk_service_stub = {
    debug_ownership_state = function()
        service_calls = service_calls + 1
        return { transactions = 0, mutations = 0, global_owners = 0, run_flag_owners = 0, cleanup = {pending=0, failed=0} }
    end,
}

dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/features/world_rules/service.lua" then return world_rules_stub end
    if path == "mods/metamorph_creative_menu/files/features/weather/service.lua" then return weather_stub end
    if path == "mods/metamorph_creative_menu/files/features/perks/root_companions.lua" then return root_companions_stub end
    if path == "mods/metamorph_creative_menu/files/features/perks/service.lua" then return perk_service_stub end
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
assert(service_calls == 1, "owned perk service was not queried")
assert(type(snapshot.ownership) == "table" and snapshot.ownership.transactions == 0, "ownership snapshot missing")
print("qa_baselines_scope=PASS explicit_perk_service_dependency=true")
