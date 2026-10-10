local root=assert(arg[1],"root required")
local native_dofile=dofile
local controls,animal=10,20
local values={
 [controls]={mButtonDownFire=true,mButtonDownFire2=false},
 [animal]={attack_ranged_entity_file="data/entities/projectiles/coward_bullet.xml",attack_ranged_enabled=false,attack_ranged_use_message=false},
}
local component_ops={valid=function(v)return v~=nil and v~=0 end,first=function(_,k)if k=="ControlsComponent" then return controls elseif k=="AnimalAIComponent" then return animal end end,get=function(c,f,d)local v=values[c] and values[c][f];if v==nil then return d end return v end,boolean=function(v)return v==true or v==1 end,ensure_controls=function()return controls end,set_type_enabled=function()end,set_type_enabled_tree=function()end}
local tree={components=function(_,k)if k=="AnimalAIComponent" then return {animal} end return {} end,reset=function()end}
local entity_tree={walk=function(e,fn)fn(e)end}
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/features/forms/component_ops.lua" then return component_ops end
 if path=="mods/metamorph_creative_menu/files/features/forms/entity_tree_cache.lua" then return tree end
 if path=="mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua" then return entity_tree end
 local prefix="mods/metamorph_creative_menu/";if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
function ComponentGetEntity()return 1 end
function ComponentSetValue2(c,f,v)values[c][f]=v end
function EntitySetComponentIsEnabled()end
function EntityGetComponentIncludingDisabled(_,k)if k=="AnimalAIComponent" then return {animal} end return {} end
function EntityGetRootEntity()return 1 end
function EntityGetTransform()return 0,0,0,1,1 end
function EntityGetIsAlive()return true end
function DEBUG_GetMouseWorld()return 100,0 end
function GameGetFrameNum()return 10 end
local loads=0
function EntityLoad()loads=loads+1;return 99 end
function GameShootProjectile()end
function EntityKill()end
function EntityCreateNew()return 0 end
function EntityAddTag()end
function EntityAddComponent2()return 0 end
local combat=assert(native_dofile(root.."/files/features/forms/combat.lua"))
assert(combat.configure_ranged_player(1)==true,"dormant direct descriptor was not retained for future authored enable")
assert(values[animal].attack_ranged_entity_file=="data/entities/projectiles/coward_bullet.xml","manual ownership mutated the authored projectile descriptor")
assert(combat.update_ranged_attacks(1)==false and loads==0,"dormant attack fired")
assert(values[controls].polymorph_hax==false,"manual ownership did not disable native polymorph attack replay")
assert(values[animal].attack_ranged_enabled==false,"manual ownership changed authored enabled state")
print("form_dormant_attack=PASS authored_disabled_preserved=true dynamic_capability=true")
