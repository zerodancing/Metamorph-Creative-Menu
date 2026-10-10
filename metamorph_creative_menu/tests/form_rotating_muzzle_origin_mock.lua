local root=assert(arg[1],"root required")
local native_dofile=dofile
local controls,attack=10,30
local frame=100
local loaded,shots={},{}
local values={
 [controls]={mButtonDownFire=true,mButtonDownFire2=false},
 [attack]={
  attack_ranged_entity_file="data/entities/projectiles/rocket_tank.xml",
  frames_between=50,frames_between_global=50,
  attack_ranged_entity_count_min=1,attack_ranged_entity_count_max=1,
  attack_ranged_action_frame=0,animation_name="",
  min_distance=0,max_distance=300,use_probability=100,state_duration_frames=45,
  attack_ranged_root_offset_x=0,attack_ranged_root_offset_y=-5,
  attack_ranged_offset_x=10,attack_ranged_offset_y=-3,
  attack_ranged_use_message=false,attack_landing_ranged_enabled=false,
  attack_ranged_aim_rotation_enabled=true,attack_ranged_aim_rotation_speed=10,
  attack_ranged_aim_rotation_shooting_ok_angle_deg=5,
  attack_ranged_use_laser_sight=true,
  mRangedAttackCurrentAimAngle=0,mNextFrameUsable=0,
 },
}
local component_ops={
 valid=function(v)return v~=nil and v~=0 end,
 first=function(_,kind)if kind=="ControlsComponent" then return controls end end,
 get=function(c,f,d)local v=values[c] and values[c][f];if v==nil then return d end return v end,
 boolean=function(v)return v==true or v==1 end,
 ensure_controls=function()return controls end,
 set_type_enabled=function()end,set_type_enabled_tree=function()end,
}
local tree={components=function(_,kind)if kind=="AIAttackComponent" then return {attack} end return {} end,reset=function()end}
local entity_tree={walk=function(e,fn)fn(e)end}
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/features/forms/component_ops.lua" then return component_ops end
 if path=="mods/metamorph_creative_menu/files/features/forms/entity_tree_cache.lua" then return tree end
 if path=="mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua" then return entity_tree end
 local prefix="mods/metamorph_creative_menu/";if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
function ComponentGetEntity()return 1 end
function ComponentSetValue2(c,f,v)values[c]=values[c] or {};values[c][f]=v end
function EntitySetComponentIsEnabled()end
function ComponentGetIsEnabled() return true end
function EntityGetComponentIncludingDisabled(_,kind)if kind=="AIAttackComponent" then return {attack} end return {} end
function EntityGetRootEntity()return 1 end
function EntityGetTransform()return 100,200,0,1,1 end
function EntitySetTransform()end
function EntityGetIsAlive()return true end
function DEBUG_GetMouseWorld()return 100,300 end
function GameGetFrameNum()return frame end
function Random(a,b)return a end
function EntityLoad(path,x,y)loaded[#loaded+1]={path=path,x=x,y=y};return 100+#loaded end
function GameShootProjectile(_,sx,sy,tx,ty)shots[#shots+1]={sx=sx,sy=sy,tx=tx,ty=ty} return true end
function EntityKill()end
function EntityCreateNew()return 0 end
function EntityAddTag()end
function GamePlayAnimation()end
local combat=assert(native_dofile(root.."/files/features/forms/combat.lua"))
assert(combat.configure_ranged_player(1)==true,"tank-like AIAttack did not acquire manual ownership")
combat.update_manual_aim(1)
assert(math.abs((values[attack].mRangedAttackCurrentAimAngle or 0)-math.pi*0.5)<0.0001,"aim did not rotate around authored pivot toward cursor")
assert(combat.update_ranged_attacks(1)==true,"tank-like attack did not fire")
assert(#loaded==1 and #shots==1,"tank-like attack did not create exactly one projectile")
-- tank.xml proves the geometry relationship: gun Sprite transform_offset.y=-5 exactly
-- matches attack_ranged_root_offset_y=-5. The muzzle vector (10,-3) is therefore
-- relative to that pivot and rotates with the physical aim. At +90deg it becomes (3,10).
assert(math.abs(loaded[1].x-103)<0.001 and math.abs(loaded[1].y-205)<0.001,
 "rotating AIAttack muzzle was treated as a fixed world-space offset")
assert(math.abs(shots[1].sx-loaded[1].x)<0.001 and math.abs(shots[1].sy-loaded[1].y)<0.001,"shoot origin disagreed with loaded projectile origin")
assert(math.abs(shots[1].tx-103)<0.01 and shots[1].ty>1200,"projectile direction did not follow physical barrel angle")
print("form_rotating_muzzle_origin=PASS pivot=true rotated_muzzle=true barrel_direction=true")
