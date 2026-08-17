local root = assert(arg[1], "root required")
local native_dofile = dofile
local frame=100
local scan_calls=0
local local_reassert_calls=0
local dirty_calls=0
local rules={
    {id="physics_gravity",kind="physics_gravity",choices={{native=true,label="NATIVE"},{value=2,label="2x"}}},
}
local physics={
    supported=function() return true end,
    capture_local_native=function() end,
    reassert_local=function() local_reassert_calls=local_reassert_calls+1; return true end,
    scan=function() scan_calls=scan_calls+1 end,
    restore_rule=function() return true,"ok" end,
    reset_all=function() return true end,
    has_overrides=function() return false end,
    debug_local_gravity=function() return {} end,
    has_persisted_local_recovery=function() return false end,
    recover_persisted_local=function() return true end,
}
local sync={
    can_edit=function() return true,"singleplayer" end,
    mark_dirty=function() dirty_calls=dirty_calls+1 end,
    update=function(_,callbacks) callbacks.set_remote_authoritative(false) end,
}
local empty_adapter={
    supported=function() return true end,
    has_overrides=function() return false end,
    reset_all=function() return true end,
    has_persisted_recovery=function() return false end,
    recover_persisted=function() return true end,
}
local stain={supported=function() return true end,apply=function() end,cleanup_stale=function() end,restore_all=function() return true end,has_overrides=function() return false end}
local stubs={
    ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"]={get=function() return 1 end},
    ["mods/metamorph_creative_menu/files/platform/noita/input_guard.lua"]={heavy_updates_allowed=function() return true end},
    ["mods/metamorph_creative_menu/files/features/world_rules/gold_lifetime.lua"]={restore_missing_lifetimes=function() return 0 end},
    ["mods/metamorph_creative_menu/files/features/world_rules/definitions.lua"]=rules,
    ["mods/metamorph_creative_menu/files/integrations/ew/world_rules_sync.lua"]=sync,
    ["mods/metamorph_creative_menu/files/features/world_rules/physics.lua"]=physics,
    ["mods/metamorph_creative_menu/files/features/world_rules/world_state.lua"]=empty_adapter,
    ["mods/metamorph_creative_menu/files/features/world_rules/stains.lua"]=stain,
    ["mods/metamorph_creative_menu/files/features/world_rules/magic_numbers.lua"]=empty_adapter,
}
dofile=function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix="mods/metamorph_creative_menu/"; if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end
function GameGetFrameNum() return frame end
function EntityGetIsAlive() return true end
function print() end
METAMORPH_CREATIVE_MENU_WORLD_RULE_SERVICE=nil; METAMORPH_CREATIVE_MENU_WORLD_RULES_EDITOR=nil
local service=assert(native_dofile(root.."/files/features/world_rules/service.lua"))
local rule=service.rules()[1]

local ok=service.step(rule,1)
assert(ok==true,"gravity click failed")
assert(scan_calls==0,"Rules click ran broad physics scan inside UI action")
assert(local_reassert_calls==1,"latency-sensitive local gravity was not updated immediately")
assert(dirty_calls==1,"Rules click did not mark state dirty")

-- Heavy work is allowed only through the normal world-update path.
service.update()
assert(scan_calls==1,"normal world update did not perform deferred physics scan")
assert(local_reassert_calls>=2,"world update stopped local gravity reassertion")

io.write("world_rules_click_deferred_scan=PASS click_scan=0 update_scan=1\n")
