local root=assert(arg[1],"root required")
local native_dofile=dofile
local controls=10
local attack_close,attack_far=31,32
local frame=200
local mouse_x=20
local loads={}
local random_roll=nil
local values={
 [controls]={mButtonDownFire=true,mButtonDownFire2=false},
 [attack_close]={attack_ranged_entity_file="same.xml",attack_ranged_use_message=false,frames_between=80,frames_between_global=0,attack_ranged_entity_count_min=1,attack_ranged_entity_count_max=1,attack_ranged_action_frame=0,animation_name="",min_distance=0,max_distance=40,use_probability=100,state_duration_frames=45,angular_range_deg=90,mNextFrameUsable=0,attack_ranged_offset_x=0,attack_ranged_offset_y=0,attack_ranged_root_offset_x=0,attack_ranged_root_offset_y=0},
 [attack_far]={attack_ranged_entity_file="same.xml",attack_ranged_use_message=false,frames_between=50,frames_between_global=50,attack_ranged_entity_count_min=2,attack_ranged_entity_count_max=2,attack_ranged_action_frame=0,animation_name="",min_distance=100,max_distance=300,use_probability=100,state_duration_frames=45,angular_range_deg=90,mNextFrameUsable=0,attack_ranged_offset_x=5,attack_ranged_offset_y=0,attack_ranged_root_offset_x=7,attack_ranged_root_offset_y=0},
}
local component_ops={valid=function(v)return v~=nil and v~=0 end,first=function(_,k)if k=="ControlsComponent" then return controls end end,get=function(c,f,d)local v=values[c] and values[c][f]; if v==nil then return d end return v end,boolean=function(v)return v==true or v==1 end,ensure_controls=function()return controls end,set_type_enabled=function()end,set_type_enabled_tree=function()end}
local tree={components=function(_,kind) if kind=="AIAttackComponent" then return {attack_close,attack_far} elseif kind=="AnimalAIComponent" then return {} else return {} end end, reset=function() end}
local entity_tree={walk=function(e,fn)fn(e)end}
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/features/forms/component_ops.lua" then return component_ops end
 if path=="mods/metamorph_creative_menu/files/features/forms/entity_tree_cache.lua" then return tree end
 if path=="mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua" then return entity_tree end
 local prefix="mods/metamorph_creative_menu/"; if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
function ComponentGetEntity(c) return 1 end
function ComponentSetValue2(c,f,v) values[c][f]=v end
function EntitySetComponentIsEnabled() end
function ComponentGetIsEnabled() return true end
function EntityGetComponentIncludingDisabled(_,kind) if kind=="AIAttackComponent" then return {attack_close,attack_far} else return {} end end
function EntityGetRootEntity() return 1 end
function EntityGetTransform() return 0,0,0,1,1 end
function EntityGetIsAlive() return true end
function DEBUG_GetMouseWorld() return mouse_x,0 end
function GameGetFrameNum() return frame end
function Random(a,b) if random_roll~=nil then return math.max(a,math.min(b,random_roll)) end return a end
function EntityLoad(path,x,y) loads[#loads+1]={path=path,x=x,y=y}; return 100+#loads end
function GameShootProjectile() end
function EntityKill() end
function GamePlayAnimation() end
function EntityAddTag() end
function EntityCreateNew() return 0 end
local combat=assert(native_dofile(root.."/files/features/forms/combat.lua"))
assert(combat.configure_ranged_player(1)==true,"AIAttack-only creature did not acquire manual ranged ownership")
assert(values[attack_close].attack_ranged_entity_file=="same.xml" and values[attack_far].attack_ranged_entity_file=="same.xml","manual ownership mutated multi-attack descriptors")
combat.update_ranged_attacks(1)
assert(#loads==1 and loads[1].x==0,"close attack was not selected at close range")
-- Reset state and use the far authored profile. Both components deliberately use same.xml.
combat.reset(); frame=300; mouse_x=180; loads={}
combat.configure_ranged_player(1)
combat.update_ranged_attacks(1)
assert(#loads==2,"same-path far profile was deduplicated or lost its count")
assert(loads[1].x==12 and loads[1].y==0,"root+muzzle offset was not preserved")
assert(values[attack_far].mNextFrameUsable==350,"authored local cooldown was not mirrored")

-- A cursor beyond every AI acquisition radius must still use the nearest (far) authored
-- profile under player authority. Only attack selection uses the ranges; the click itself
-- must never be rejected.
combat.reset(); frame=360; mouse_x=1000; loads={}
values[attack_close].mNextFrameUsable=0; values[attack_far].mNextFrameUsable=0
combat.configure_ranged_player(1)
combat.update_ranged_attacks(1)
assert(#loads==2 and loads[1].x==12,"far cursor was rejected instead of selecting the far authored profile")

-- Overlapping attack ranges must preserve the authored AIAttack state. A tank-like
-- machinegun state may fire repeatedly during its 45f state instead of rerolling into
-- a grenade state on every 3f shot.
combat.reset(); loads={}; frame=400; mouse_x=35; random_roll=1
values[attack_close].frames_between=3; values[attack_close].frames_between_global=0; values[attack_close].min_distance=0; values[attack_close].max_distance=200; values[attack_close].mNextFrameUsable=0
values[attack_far].frames_between=40; values[attack_far].frames_between_global=0; values[attack_far].min_distance=0; values[attack_far].max_distance=200; values[attack_far].mNextFrameUsable=0
combat.configure_ranged_player(1); combat.update_ranged_attacks(1)
assert(#loads==1 and loads[1].x==0,"overlap state did not start with selected profile")
random_roll=200; mouse_x=1000; frame=403; combat.update_ranged_attacks(1)
assert(#loads==2 and loads[2].x==0,"locked player attack state was cancelled when cursor left the AI radius")
frame=446; combat.update_ranged_attacks(1)
assert(#loads==4 and loads[3].x==12 and loads[4].x==12,"attack state did not become selectable again after authored duration")
print("form_multiattack_replay=PASS same_path_distinct=true distance_select=true root_offset=true count=true state_lock=true")
