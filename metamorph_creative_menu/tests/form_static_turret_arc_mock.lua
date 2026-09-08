local root=assert(arg[1],"root required")
local native_dofile=dofile
local controls,animal=10,20
local mouse_angle=math.rad(80)
local values={
 [controls]={mButtonDownFire=false,mButtonDownFire2=false},
 [animal]={
  attack_ranged_entity_file="data/entities/projectiles/laser_turret.xml",
  attack_ranged_enabled=true,attack_ranged_use_message=false,
  attack_ranged_frames_between=100,attack_ranged_entity_count_min=1,attack_ranged_entity_count_max=1,
  attack_ranged_action_frame=0,attack_ranged_offset_x=10,attack_ranged_offset_y=-6,
  attack_ranged_min_distance=10,attack_ranged_max_distance=740,
  attack_ranged_aim_rotation_enabled=true,attack_ranged_aim_rotation_speed=0.1,
  attack_ranged_aim_rotation_shooting_ok_angle_deg=2,
  creature_detection_angular_range_deg=90,is_static_turret=true,
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
function DEBUG_GetMouseWorld() return math.cos(mouse_angle)*100,math.sin(mouse_angle)*100 end
function GameGetFrameNum() return 100 end
function EntityCreateNew() return 999 end
function EntityAddTag() end
function GamePlayAnimation() end
local combat=assert(native_dofile(root.."/files/features/forms/combat.lua"))
assert(combat.configure_ranged_player(1)==true,"static turret did not acquire ranged ownership")
for _=1,20 do combat.update_manual_aim(1) end
local actual=values[animal].mRangedAttackCurrentAimAngle
assert(math.abs(actual-mouse_angle)<0.0001,
 "creature_detection_angular_range_deg=90 was incorrectly treated as a +/-45 degree sector: "..tostring(actual))
print("form_static_turret_arc=PASS authored_half_arc=true full_sector_180=true")
