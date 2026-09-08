local root=assert(arg[1],"root required")
local native_dofile=dofile
local controls,animal=10,20
local frame=100
local mouse_x,mouse_y=0,100
local loads,shots=0,{}
local values={
 [controls]={mButtonDownFire=true,mButtonDownFire2=false},
 [animal]={
  attack_ranged_entity_file="data/entities/projectiles/rocket_tiny_roll.xml",
  attack_ranged_enabled=true,attack_ranged_use_message=false,
  attack_ranged_frames_between=90,attack_ranged_entity_count_min=1,attack_ranged_entity_count_max=1,
  attack_ranged_action_frame=0,attack_ranged_offset_x=0,attack_ranged_offset_y=0,
  attack_ranged_min_distance=0,attack_ranged_max_distance=400,
  attack_ranged_aim_rotation_enabled=true,attack_ranged_aim_rotation_speed=0.1,
  attack_ranged_aim_rotation_shooting_ok_angle_deg=5,
  mRangedAttackCurrentAimAngle=0,
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
function EntitySetTransform() end
function EntityGetIsAlive() return true end
function DEBUG_GetMouseWorld() return mouse_x,mouse_y end
function GameGetFrameNum() return frame end
function Random(a,b) return a end
function EntityLoad(path,x,y) loads=loads+1; return 100+loads end
function GameShootProjectile(_,sx,sy,tx,ty) shots[#shots+1]={sx=sx,sy=sy,tx=tx,ty=ty,angle=values[animal].mRangedAttackCurrentAimAngle} end
function EntityKill() end
function EntityCreateNew() return 0 end
function EntityAddTag() end
function GamePlayAnimation() end
local combat=assert(native_dofile(root.."/files/features/forms/combat.lua"))
assert(combat.configure_ranged_player(1)==true,"aimed creature did not acquire manual ranged ownership")
-- Cursor starts at +90 degrees while the authored barrel starts at 0 and can only turn 0.1 rad/frame.
for i=1,14 do
 frame=99+i
 combat.update_manual_aim(1)
 combat.update_ranged_attacks(1)
 assert(loads==0,"aimed creature fired before authored barrel entered shooting tolerance")
end
frame=114
combat.update_manual_aim(1)
combat.update_ranged_attacks(1)
assert(loads==1 and #shots==1,"aimed creature did not fire once barrel reached authored tolerance")
local a=shots[1].angle
assert(math.abs(a-1.5)<0.0001,"authored aim rotation speed was not preserved")
assert(math.abs(shots[1].tx - math.cos(a)*1000)<0.001 and math.abs(shots[1].ty - math.sin(a)*1000)<0.001,
 "projectile target snapped to cursor instead of using physical barrel direction")
assert(not (math.abs(shots[1].tx-mouse_x)<0.001 and math.abs(shots[1].ty-mouse_y)<0.001),"aimed shot ignored barrel direction")
print("form_ranged_aim_replay=PASS authored_turn_rate=true shooting_tolerance=true barrel_direction=true")
