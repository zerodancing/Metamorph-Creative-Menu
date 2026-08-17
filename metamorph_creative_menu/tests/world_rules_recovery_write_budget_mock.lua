local root=assert(arg[1],"root required")
local native_dofile=dofile
local globals={}
local global_writes=0
local player=1
local comps={
 [101]={type="CharacterDataComponent",owner=player,gravity=100},
 [102]={type="CharacterPlatformingComponent",owner=player,pixel_gravity=350},
}
function GlobalsGetValue(key,fallback) local v=globals[key]; if v==nil then return fallback end; return v end
function GlobalsSetValue(key,value) global_writes=global_writes+1; globals[key]=tostring(value) end
function EntityGetIsAlive(e) return e==player end
function EntityGetFilename() return "data/entities/player.xml" end
function EntityGetComponentIncludingDisabled(e,kind)
 if e~=player then return {} end
 if kind=="CharacterDataComponent" then return {101} end
 if kind=="CharacterPlatformingComponent" then return {102} end
 return {}
end
function ComponentGetValue2(c,f) return comps[c] and comps[c][f] end
function ComponentSetValue2(c,f,v) comps[c][f]=v end
function ComponentGetTypeName(c) return comps[c] and comps[c].type end
function ComponentGetEntity(c) return comps[c] and comps[c].owner end
function EntityGetTransform() return 0,0 end
function EntityGetInRadius() return {} end
function PhysicsBodyIDQueryBodies() return {} end
function PhysicsBodyIDSetGravityScale() end
function PhysicsBodyIDGetGravityScale() return 1 end
function PhysicsBodyIDSetDamping() end
function PhysicsBodyIDGetDamping() return 0,0 end
local stubs={
 ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"]={get=function() return player end},
 ["mods/metamorph_creative_menu/files/core/rule_math.lua"]={same=function(a,b) return math.abs((tonumber(a)or 0)-(tonumber(b)or 0))<1e-9 end,scaled=function(a,b) return tonumber(a)*tonumber(b) end},
}
dofile=function(path)
 if stubs[path]~=nil then return stubs[path] end
 local prefix="mods/metamorph_creative_menu/"; if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
METAMORPH_CREATIVE_MENU_WORLD_RULE_RECOVERY=nil; METAMORPH_CREATIVE_MENU_WORLD_RULE_PHYSICS=nil
local physics=assert(native_dofile(root.."/files/features/world_rules/physics.lua"))
physics.capture_local_native(player)
assert(physics.reassert_local(player,2,1)==true)
local writes_after_first=global_writes
assert(writes_after_first>0,"first gravity ownership did not persist recovery")
for frame=2,120 do assert(physics.reassert_local(player,2,frame)==true) end
assert(global_writes==writes_after_first,"steady-state gravity reassert kept rewriting persistent recovery")
-- Changing factor changes the owned last value once per field, not every later frame.
assert(physics.reassert_local(player,0.5,121)==true)
local writes_after_change=global_writes
assert(writes_after_change>writes_after_first,"factor change did not update recovery last value")
for frame=122,240 do assert(physics.reassert_local(player,0.5,frame)==true) end
assert(global_writes==writes_after_change,"steady-state after factor change rewrote recovery repeatedly")
io.write("world_rules_recovery_write_budget=PASS steady_state_writes=0\n")
