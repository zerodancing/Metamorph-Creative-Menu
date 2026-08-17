local root = assert(arg[1], "root required")
local native_dofile = dofile
local dirty_calls = 0
local world_value = 0
local physics_value = nil
local reset_calls = {world=0, physics=0, stain=0, magic=0}

local rules = {
    {id="test_field", kind="field", field="test_field", choices={{native=true,label="NATIVE"},{value=1,label="ON"}}},
    {id="physics_gravity", kind="physics_gravity", choices={{native=true,label="NATIVE"},{value=2,label="2x"}}},
}
local world_state = {
    supported=function() return true end,
    component=function() return 10 end,
    apply=function(rule, choice) world_value=choice.value; return true,"ok" end,
    reset_all=function() reset_calls.world=reset_calls.world+1; world_value=0; return true end,
    owns_rule=function() return world_value ~= 0 end,
    has_overrides=function() return world_value ~= 0 end,
}
local physics = {
    supported=function() return true end,
    capture_local_native=function() end,
    reassert_local=function() end,
    scan=function() end,
    restore_rule=function() physics_value=nil; return true,"ok" end,
    reset_all=function() reset_calls.physics=reset_calls.physics+1; physics_value=nil; return true end,
    has_overrides=function() return physics_value ~= nil end,
    debug_local_gravity=function() return {} end,
}
local stain = {
    supported=function() return true end, apply=function() end, cleanup_stale=function() end,
    restore_all=function() reset_calls.stain=reset_calls.stain+1; return true end,
    has_overrides=function() return false end,
}
local magic = {
    supported=function() return true end, apply=function() return true end, restore=function() return true end,
    reset_all=function() reset_calls.magic=reset_calls.magic+1; return true end,
    owns=function() return false end, has_overrides=function() return false end,
}
local sync = {
    can_edit=function() return true,"ew_peer" end,
    mark_dirty=function() dirty_calls=dirty_calls+1 end,
    update=function(_, callbacks) callbacks.set_remote_authoritative(false) end,
}
local stubs = {
    ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"]={get=function() return 1 end},
    ["mods/metamorph_creative_menu/files/platform/noita/input_guard.lua"]={heavy_updates_allowed=function() return true end},
    ["mods/metamorph_creative_menu/files/features/world_rules/gold_lifetime.lua"]={restore_missing_lifetimes=function() return 0 end},
    ["mods/metamorph_creative_menu/files/features/world_rules/definitions.lua"]=rules,
    ["mods/metamorph_creative_menu/files/integrations/ew/world_rules_sync.lua"]=sync,
    ["mods/metamorph_creative_menu/files/features/world_rules/physics.lua"]=physics,
    ["mods/metamorph_creative_menu/files/features/world_rules/world_state.lua"]=world_state,
    ["mods/metamorph_creative_menu/files/features/world_rules/stains.lua"]=stain,
    ["mods/metamorph_creative_menu/files/features/world_rules/magic_numbers.lua"]=magic,
}

dofile = function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end
function GameGetFrameNum() return 100 end
function EntityGetIsAlive() return true end
function ComponentGetValue2(_, field) if field=="perk_gold_is_forever" then return false end return 0 end
function print() end

METAMORPH_CREATIVE_MENU_WORLD_RULE_SERVICE=nil
METAMORPH_CREATIVE_MENU_WORLD_RULES_EDITOR=nil
local service = assert(native_dofile(root.."/files/features/world_rules/service.lua"))
local listed = service.rules()
local field_rule, gravity_rule = listed[1], listed[2]

local ok, reason = service.step(field_rule, 1)
assert(ok == true and reason == "ok", "field rule step failed")
assert(world_value == 1 and service.choice_index(field_rule) == 2 and service.is_overridden(field_rule), "field rule override state was not committed")
assert(dirty_calls == 1, "field rule change did not mark network state dirty")

ok, reason = service.step(gravity_rule, 1)
assert(ok == true and reason == "ok", "gravity rule step failed")
-- The service owns the selected factor; the adapter receives it during update/scan.
assert(service.gravity_factor() == 2 and service.choice_index(gravity_rule) == 2, "gravity selection was not committed")
assert(dirty_calls == 2, "gravity rule change did not mark network state dirty")

local reset_ok, reset_reason = service.reset()
assert(reset_ok == true and reset_reason == "ok", "world-rule reset did not complete")
assert(service.choice_index(field_rule) == 1 and service.choice_index(gravity_rule) == 1, "reset did not return rules to native choices")
assert(service.has_overrides() == false, "reset left owned world-rule state behind")
assert(reset_calls.world == 1 and reset_calls.physics == 1 and reset_calls.stain == 1 and reset_calls.magic == 1, "reset did not delegate to every owned adapter")
assert(dirty_calls == 3, "reset did not publish a new network state")

print("world_rules_lifecycle=PASS apply=true network_dirty=true reset=true")
