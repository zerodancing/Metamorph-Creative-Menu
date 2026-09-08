local root=assert(arg[1],"root required")
local native_dofile=dofile
local children={[1]={2},[2]={3},[3]={}}
local alive={[1]=true,[2]=true,[3]=true}
local enabled={[11]=true,[21]=true,[22]=true,[23]=true,[31]=true}
local values={
 [11]={},
 [21]={script_source_file="data/entities/animals/boss_robot/state.lua",script_death=""},
 [22]={script_source_file="",script_death="data/entities/animals/test/death.lua"},
 [23]={is_emitting=true,emit_until_frame=999},
 [31]={attack_ranged_entity_file="danger.xml"},
 [40]={hp=0,max_hp=10,wait_for_kill_flag_on_death=false,kill_now=false},
 [50]={mVelocity={5,6}},
}
local entity_tree={walk=function(e,fn)
 local function rec(x) if fn(x)==false then return false end; for _,c in ipairs(children[x] or {}) do if rec(c)==false then return false end end end
 rec(e)
end}
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua" then return entity_tree end
 if path=="mods/metamorph_creative_menu/files/integrations/ew/runtime.lua" then return {enabled=function() return false end} end
 local prefix="mods/metamorph_creative_menu/"
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
function EntityGetIsAlive(e)return alive[e]==true end
function EntityGetAllChildren(e)return children[e] or {} end
function EntityGetComponentIncludingDisabled(e,k,tag)
 if tag~=nil then return {} end
 if e==1 and k=="AnimalAIComponent" then return {11} end
 if e==1 and k=="LuaComponent" then return {22} end
 if e==2 and k=="LuaComponent" then return {21} end
 if e==2 and k=="LaserEmitterComponent" then return {23} end
 if e==2 and k=="VelocityComponent" then return {50} end
 if e==3 and k=="AIAttackComponent" then return {31} end
 if e==1 and k=="DamageModelComponent" then return {40} end
 return {}
end
function EntityGetFirstComponentIncludingDisabled(e,k)local t=EntityGetComponentIncludingDisabled(e,k);return t[1] or 0 end
function EntitySetComponentIsEnabled(_,c,v) enabled[c]=v==true end
function ComponentGetValue2(c,f)local v=values[c] and values[c][f];if type(v)=="table" then return v[1],v[2] end;return v end
function ComponentSetValue2(c,f,...)values[c]=values[c] or {};local a={...};if #a==1 then values[c][f]=a[1] else values[c][f]=a end end
function EntityRemoveTag()end
function EntityAddTag()end
function EntityRemoveComponent()end
function EntityGetTransform()return 10,20 end
function EntityGetFilename()return "data/entities/animals/test.xml" end
function EntityHasTag()return false end
function EntityKill(e)alive[e]=false end
function GameGetFrameNum()return 100 end
function ModDoesFileExist()return false end
local corpse=assert(native_dofile(root.."/files/features/forms/corpse_service.lua"))
assert(corpse.detach(1,"data/entities/animals/test.xml","death",0)==true,"corpse detach failed")
assert(enabled[11]==false,"root AI remained active on pending corpse")
assert(enabled[31]==false,"child-tree AIAttack remained active on pending corpse")
assert(enabled[21]==false,"child attack Lua remained active on pending corpse")
assert(enabled[23]==false and values[23].is_emitting==false and values[23].emit_until_frame==100,"laser was not hard-stopped before corpse handoff")
assert(enabled[22]==true,"pure native script_death hook was unnecessarily frozen")
assert(values[50].mVelocity[1]==0 and values[50].mVelocity[2]==0,"child velocity was not frozen")
assert(values[40].wait_for_kill_flag_on_death==true and values[40].kill_now==false,"corpse one-frame death hold changed")
print("form_corpse_tree_freeze=PASS recursive=true lua=true laser=true pure_death_preserved=true")
