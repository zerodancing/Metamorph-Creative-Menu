local root=assert(arg[1])
local player=1
local comps={
 [101]={type="CharacterDataComponent",owner=player,gravity=100},
 [102]={type="CharacterPlatformingComponent",owner=player,pixel_gravity=350},
}
local frame=1
GlobalsGetValue=function(_,d) return d end
GlobalsSetValue=function() end
ModIsEnabled=function() return false end
GameHasFlagRun=function() return false end
GameGetFrameNum=function() return frame end
GameGetWorldStateEntity=function() return 0 end
EntityGetIsAlive=function(e) return e==player end
EntityGetComponentIncludingDisabled=function(e,kind)
 if e~=player then return {} end
 if kind=="CharacterDataComponent" then return {101} end
 if kind=="CharacterPlatformingComponent" then return {102} end
 return {}
end
EntityGetFirstComponentIncludingDisabled=function(e,kind) local t=EntityGetComponentIncludingDisabled(e,kind); return t[1] end
ComponentGetValue2=function(c,f) return comps[c] and comps[c][f] end
ComponentSetValue2=function(c,f,v) assert(comps[c]); comps[c][f]=v end
ComponentGetTypeName=function(c) return comps[c] and comps[c].type end
ComponentGetEntity=function(c) return comps[c] and comps[c].owner end
EntityGetTransform=function() return 0,0 end
EntityGetInRadius=function() return {} end
PhysicsBodyIDQueryBodies=function() return {} end
PhysicsBodyIDSetGravityScale=function() end
PhysicsBodyIDSetDamping=function() end
PhysicsBodyIDGetGravityScale=function() return 1 end
PhysicsBodyIDGetDamping=function() return 0,0 end
ModDoesFileExist=function() return false end
local native_dofile=dofile
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/platform/noita/player_locator.lua" then return {get=function() return player end} end
 if path=="mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua" then return {get=function() return nil end} end
 if path=="mods/metamorph_creative_menu/files/core/rule_math.lua" then return {same=function(a,b) return math.abs((tonumber(a)or 0)-(tonumber(b)or 0))<1e-6 end,scaled=function(a,b) return tonumber(a)*tonumber(b) end} end
 if path=="mods/metamorph_creative_menu/files/platform/noita/input_guard.lua" then return {heavy_updates_allowed=function() return true end} end
 local prefix="mods/metamorph_creative_menu/"; if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
local api=assert(native_dofile(root.."/files/features/world_rules/service.lua"))
-- Clean baseline is captured before perks alter the player.
api.update()
assert(comps[102].pixel_gravity==350)
-- Simulate an active perk that zeroes player platform gravity before creative rule is enabled.
comps[102].pixel_gravity=0
frame=2
local rule
for _,r in ipairs(api.rules()) do if r.id=="physics_gravity" then rule=r end end
assert(rule)
local ok,reason=api.step(rule,1); assert(ok,reason)
assert(math.abs(comps[102].pixel_gravity - (-1400))<1e-6,"player pixel gravity="..tostring(comps[102].pixel_gravity))
assert(math.abs(comps[101].gravity - (-400))<1e-6,"player gravity="..tostring(comps[101].gravity))
-- Simulate a perk script running after pre-update and overwriting the platform value.
comps[102].pixel_gravity=-700
api.post_update()
assert(math.abs(comps[102].pixel_gravity - (-1400))<1e-6,"post-update reassert="..tostring(comps[102].pixel_gravity))
local dbg=api.local_gravity_debug(); assert(dbg.factor==-4)
local found=false; for _,r in ipairs(dbg.rows) do if r.field=="pixel_gravity" then found=true; assert(r.native==350); assert(r.expected==-1400); assert(r.current==-1400) end end; assert(found)
-- RESET returns ownership snapshot (perk-modified 0), not the clean scale used for creative multiplication.
frame=3
local reset_ok=api.reset(); assert(reset_ok)
assert(comps[102].pixel_gravity==0,"reset must restore active perk state")
assert(comps[101].gravity==100,"reset data gravity")
print("local_gravity_dual_baseline=PASS native=350 active=-1400 reset=0")
