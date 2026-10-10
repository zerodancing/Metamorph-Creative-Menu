local root=assert(arg[1],"root required")
local native_dofile=dofile
local controls,attack,gun=10,30,40
local frame=100
local values={
 [controls]={mButtonDownFire=true,mButtonDownFire2=false},
 [attack]={
  attack_ranged_entity_file="data/entities/projectiles/machinegun_bullet_tank.xml",
  frames_between=10,frames_between_global=0,
  attack_ranged_entity_count_min=1,attack_ranged_entity_count_max=1,
  attack_ranged_action_frame=0,animation_name="",
  min_distance=0,max_distance=500,use_probability=100,state_duration_frames=10,
  attack_ranged_root_offset_x=0,attack_ranged_root_offset_y=-5,
  attack_ranged_offset_x=10,attack_ranged_offset_y=-3,
  attack_ranged_use_message=false,attack_landing_ranged_enabled=false,
  attack_ranged_aim_rotation_enabled=true,attack_ranged_aim_rotation_speed=0.05,
  attack_ranged_aim_rotation_shooting_ok_angle_deg=10,
  mRangedAttackCurrentAimAngle=-1.2,mNextFrameUsable=0,
 },
 [gun]={image_file="data/enemies_gfx/tank_gun.xml",update_transform_rotation=false,alpha=1},
}
local enabled={[controls]=true,[attack]=true,[gun]=true}
local loaded,shots={},{}
local created=0
local component_ops={
 valid=function(v)return v~=nil and v~=0 end,
 first=function(_,kind)if kind=="ControlsComponent" then return controls end end,
 get=function(c,f,d)local v=values[c] and values[c][f];if v==nil then return d end return v end,
 boolean=function(v)if type(v)=="string" then return v=="1" or v=="true" end return v==true or v==1 end,
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
function ComponentGetEntity(c) if c==attack or c==gun then return 1 end return 1 end
function ComponentGetIsEnabled(c)return enabled[c]~=false end
function ComponentSetValue2(c,f,v)values[c]=values[c] or {};values[c][f]=v end
function EntitySetComponentIsEnabled(_,c,v)enabled[c]=v==true end
function EntityGetComponentIncludingDisabled(_,kind)
 if kind=="AIAttackComponent" then return {attack} end
 if kind=="SpriteComponent" then return {gun} end
 return {}
end
function EntityGetRootEntity()return 1 end
function EntityGetTransform()return 100,200,0,1,1 end
function EntitySetTransform()end
function EntityGetIsAlive()return true end
function DEBUG_GetMouseWorld()return 100,300 end
function GameGetFrameNum()return frame end
function Random(a,b)return a end
function EntityLoad(path,x,y)loaded[#loaded+1]={path=path,x=x,y=y};return 100+#loaded end
function GameShootProjectile(_,sx,sy,tx,ty)shots[#shots+1]={sx=sx,sy=sy,tx=tx,ty=ty};return true end
function EntityKill()end
function EntityCreateNew()created=created+1;return 900+created end
function EntityAddTag()end
function EntityAddComponent2()return 0 end
function GamePlayAnimation()end

local combat=assert(native_dofile(root.."/files/features/forms/combat.lua"))
assert(combat.configure_ranged_player(1)==true,"tank attack was not manually owned")
combat.setup_manual_barrels(1)
assert(created==0 and enabled[gun]==true,"static tank gun sprite was replaced by a fake rotating pivot")
local stale=values[attack].mRangedAttackCurrentAimAngle
combat.update_manual_aim(1)
assert(values[attack].mRangedAttackCurrentAimAngle==stale,"static tank gun still tried to rotate an unsupported visual layer")
assert(combat.update_ranged_attacks(1)==true,"static tank attack did not fire")
assert(#loaded==1 and #shots==1,"static tank attack did not emit exactly one projectile")
-- No rotation of the authored muzzle vector: pivot=(100,195), muzzle=(110,192).
assert(math.abs(loaded[1].x-110)<0.001 and math.abs(loaded[1].y-192)<0.001,"static tank muzzle was rotated away from its authored sprite position")
assert(math.abs(shots[1].tx-100)<0.001 and math.abs(shots[1].ty-300)<0.001,"static tank projectile did not target the real cursor")
print("form_static_tank_aim=PASS no_fake_turret_rotation=true authored_muzzle=true direct_cursor=true")
