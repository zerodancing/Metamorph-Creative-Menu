local root=assert(arg[1])
local native_dofile=dofile
local player,frame=1,1
local active,shell=true,true
local body={gravity=1,linear=0.2,angular=0.3}
local getter_calls=0
local globals={}
function GlobalsGetValue(k,f) return globals[k] or f end
function GlobalsSetValue(k,v) globals[k]=tostring(v) end
function GameGetFrameNum() return frame end
function EntityGetIsAlive(e) return e==player end
function EntityGetTransform() return 0,0 end
function EntityGetInRadius() return {} end
function EntityGetComponentIncludingDisabled() return {} end
function EntityGetFilename() return 'data/entities/player.xml' end
function ComponentGetTypeName() return nil end
function ComponentGetEntity() return nil end
function PhysicsBodyIDQueryBodies(minx,_,maxx) local hw=(maxx-minx)/2; if hw<=1024 then return active and {77} or {} end; return shell and {77} or {} end
function PhysicsBodyIDGetGravityScale(id) assert(id==77); getter_calls=getter_calls+1; return body.gravity end
function PhysicsBodyIDSetGravityScale(id,v) assert(id==77); body.gravity=v end
function PhysicsBodyIDGetDamping(id) assert(id==77); getter_calls=getter_calls+1; return body.linear,body.angular end
function PhysicsBodyIDSetDamping(id,l,a) assert(id==77); body.linear,body.angular=l,a end
function PhysicsBodyIDApplyForce() end
local stubs={
 ['mods/metamorph_creative_menu/files/platform/noita/player_locator.lua']={get=function() return player end},
 ['mods/metamorph_creative_menu/files/core/rule_math.lua']={same=function(a,b) return math.abs(a-b)<1e-9 end,scaled=function(a,b) return a*b end},
}
dofile=function(p) if stubs[p] then return stubs[p] end local prefix='mods/metamorph_creative_menu/' if string.sub(p,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(p,#prefix+1)) end return native_dofile(p) end
METAMORPH_CREATIVE_MENU_WORLD_RULE_RECOVERY=nil; METAMORPH_CREATIVE_MENU_WORLD_RULE_PHYSICS=nil
local physics=assert(native_dofile(root..'/files/features/world_rules/physics.lua'))
physics.scan(player,2,2,frame)
assert(body.gravity==2 and math.abs(body.linear-0.4)<1e-9)
frame=2; active=false; shell=false; local before=getter_calls
physics.scan(player,2,2,frame)
assert(getter_calls==before,'body outside restore shell was queried by stale ID')
assert(body.gravity==2 and math.abs(body.linear-0.4)<1e-9,'out-of-area body was unexpectedly touched')
frame=3; active=true; shell=true
physics.scan(player,2,2,frame)
assert(body.gravity==2,'returning body compounded gravity to '..tostring(body.gravity))
assert(math.abs(body.linear-0.4)<1e-9 and math.abs(body.angular-0.6)<1e-9,'returning body compounded damping')
assert(physics.restore_rule('physics_gravity')==true and body.gravity==1,'original gravity was not retained across far excursion')
assert(physics.restore_rule('physics_damping')==true and math.abs(body.linear-0.2)<1e-9 and math.abs(body.angular-0.3)<1e-9,'original damping was not retained across far excursion')
print('physics_reentry=PASS far_exit_safe=true original_retained=true no_compound=true')
