local root=assert(arg[1],"root required")
local native_dofile=dofile
local controls,animal=10,20
local frame=100
local loads=0
local values={
 [controls]={mButtonDownFire=true,mButtonDownFire2=false},
 [animal]={
  attack_ranged_entity_file="",attack_ranged_enabled=false,attack_ranged_use_message=false,
  attack_ranged_frames_between=30,attack_ranged_entity_count_min=1,attack_ranged_entity_count_max=1,
  attack_ranged_action_frame=0,attack_ranged_offset_x=4,attack_ranged_offset_y=0,
  attack_ranged_min_distance=0,attack_ranged_max_distance=400,
  attack_ranged_aim_rotation_enabled=false,mRangedAttackNextFrame=0,
 },
}
local component_ops={
 valid=function(v)return v~=nil and v~=0 end,
 first=function(_,k)if k=="ControlsComponent" then return controls end end,
 get=function(c,f,d)local v=values[c] and values[c][f]; if v==nil then return d end return v end,
 boolean=function(v)return v==true or v==1 end,
 ensure_controls=function()return controls end,
 set_type_enabled=function()end,set_type_enabled_tree=function()end,
}
local tree={components=function(_,kind) if kind=="AnimalAIComponent" then return {animal} end return {} end,reset=function()end}
local entity_tree={walk=function(e,fn)fn(e)end}
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/features/forms/component_ops.lua" then return component_ops end
 if path=="mods/metamorph_creative_menu/files/features/forms/entity_tree_cache.lua" then return tree end
 if path=="mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua" then return entity_tree end
 local prefix="mods/metamorph_creative_menu/"; if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
function ComponentGetEntity() return 1 end
function ComponentSetValue2(c,f,v) values[c]=values[c] or {}; values[c][f]=v end
function EntitySetComponentIsEnabled() end
function EntityGetComponentIncludingDisabled(_,kind) if kind=="AnimalAIComponent" then return {animal} end return {} end
function EntityGetRootEntity() return 1 end
function EntityGetTransform() return 0,0,0,1,1 end
function EntityGetIsAlive() return true end
function DEBUG_GetMouseWorld() return 100,0 end
function GameGetFrameNum() return frame end
function Random(a,b) return a end
function EntityLoad(path,x,y) loads=loads+1; assert(path=="mods/example/files/late_bolt.xml"); return 100+loads end
function GameShootProjectile() end
function EntityKill() end
function GamePlayAnimation() end
local combat=assert(native_dofile(root.."/files/features/forms/combat.lua"))
assert(combat.configure_ranged_player(1)==false,"empty initial descriptor unexpectedly acquired ownership")
assert(combat.manual_ranged_owned()==false,"empty initial descriptor marked manual ownership")
-- Simulate a later Lua/mod callback authoring the first real direct attack.
values[animal].attack_ranged_entity_file="mods/example/files/late_bolt.xml"
values[animal].attack_ranged_enabled=true
frame=101
combat.update_ranged_attacks(1)
assert(combat.manual_ranged_owned()==true,"late first direct attack was never acquired")
assert(values[animal].attack_ranged_entity_file=="mods/example/files/late_bolt.xml","late first descriptor was mutated by ownership")
assert(values[controls].polymorph_hax==false,"late ownership did not disable polymorph_hax")
assert(loads==1,"late first direct attack was not replayed exactly")
print("form_late_first_attack=PASS retry_acquisition=true polymorph_hax_suppressed=true descriptor_preserved=true exact_replay=true")
