local root=assert(arg[1],"root required")
local native_dofile=dofile
local controls=10
local lua_dragon=20
local genome=30
local frame=0
local next_entity=100
local children={[1]={2},[2]={}}
local alive={[1]=true,[2]=true}
local enabled={[lua_dragon]=true}
local owner_of={[lua_dragon]=2,[genome]=1,[controls]=1}
local values={
 [controls]={mButtonDownFire=true,mButtonDownFire2=false},
 [lua_dragon]={script_source_file="data/scripts/projectiles/orb_green_dragon.lua",_enabled=true},
 [genome]={herd_id=7},
}
local transforms={[1]={10,20,0,1,1},[2]={12,18,0,1,1}}
local projectile_components={}
local velocity_components={}
local shots={}
local component_ops={
 valid=function(v)return v~=nil and v~=0 end,
 get=function(c,f,d)local v=values[c] and values[c][f];if v==nil then return d end;return v end,
 boolean=function(v)return v==true or v==1 end,
 ensure_controls=function()return controls end,
}
local entity_tree={walk=function(e,fn)
 local function rec(id) if fn(id)==false then return false end; for _,c in ipairs(children[id] or {}) do if rec(c)==false then return false end end end
 rec(e)
end}
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua" then return entity_tree end
 if path=="mods/metamorph_creative_menu/files/features/forms/component_ops.lua" then return component_ops end
 local prefix="mods/metamorph_creative_menu/";if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
function EntityGetComponentIncludingDisabled(e,kind)
 if kind=="LuaComponent" and e==2 then return {lua_dragon} end
 if kind=="GenomeDataComponent" and e==1 then return {genome} end
 if kind=="ProjectileComponent" then return projectile_components[e] and {projectile_components[e]} or {} end
 if kind=="VelocityComponent" then return velocity_components[e] and {velocity_components[e]} or {} end
 return {}
end
function EntityGetFirstComponentIncludingDisabled(e,kind)
 local t=EntityGetComponentIncludingDisabled(e,kind);return t[1]
end
function ComponentGetIsEnabled(c)return enabled[c]==true end
function EntitySetComponentIsEnabled(_,c,v) enabled[c]=v==true end
function ComponentGetValue2(c,f)local v=values[c] and values[c][f];return v end
function ComponentSetValue2(c,f,...)
 values[c]=values[c] or {};local args={...};values[c][f]=#args==1 and args[1] or args
end
function ComponentGetEntity(c)return owner_of[c] or 0 end
function EntityGetAllChildren(e)return children[e] or {} end
function EntityGetIsAlive(e)return alive[e]==true end
function EntityGetTransform(e)local t=transforms[e];if not t then return nil end;return t[1],t[2],t[3],t[4],t[5] end
function EntitySetTransform(e,x,y) transforms[e]={x,y,0,1,1} end
function EntityCreateNew() next_entity=next_entity+1;alive[next_entity]=true;transforms[next_entity]={0,0,0,1,1};return next_entity end
function EntityAddTag() end
function EntityKill(e) alive[e]=false end
function EntityLoad(path,x,y)
 next_entity=next_entity+1;alive[next_entity]=true;transforms[next_entity]={x,y,0,1,1}
 local pc=next_entity+1000;local vc=next_entity+2000
 projectile_components[next_entity]=pc;velocity_components[next_entity]=vc;owner_of[pc]=next_entity;owner_of[vc]=next_entity
 values[pc]={};values[vc]={};shots[#shots+1]={path=path,entity=next_entity,x=x,y=y};return next_entity
end
function GameShootProjectile(who,sx,sy,tx,ty,p,send) local s=shots[#shots];s.who=who;s.tx=tx;s.ty=ty;s.send=send end
function GameGetFrameNum()return frame end
function DEBUG_GetMouseWorld()return 110,20 end
function GameEntityPlaySound() end
function GamePlaySound() end
function Random(...) return 0 end
local scripted=assert(native_dofile(root.."/files/features/forms/scripted_attacks.lua"))
assert(scripted.configure(1,"data/entities/animals/boss_dragon.xml")==true,"boss dragon scripted attack not discovered")
assert(enabled[lua_dragon]==false,"native scripted attack left autonomous")
frame=80
scripted.update(1)
assert(#shots==10,"boss dragon did not replay exact ten-projectile ring")
for _,s in ipairs(shots) do assert(s.path=="data/entities/projectiles/orb_green_boss_dragon.xml","wrong boss dragon projectile") end
assert(math.abs((values[velocity_components[shots[1].entity]].mVelocity or {})[1]-100)<0.001,"script velocity was not stamped like utilities.shoot_projectile")
scripted.reset()
assert(enabled[lua_dragon]==true,"script component enabled state was not restored")
print("form_scripted_attack_replay=PASS script_disabled=true dragon_ring=10 exact_entity=true velocity_stamp=true restore=true")
