local root=assert(arg[1],"root required")
local native_dofile=dofile
local controls,animal,dynamic_attack=10,20,30
local values={
 [controls]={mButtonDownFire=true,mButtonDownFire2=false},
 [animal]={
  attack_ranged_entity_file="data/entities/projectiles/coward_bullet.xml",
  attack_ranged_enabled=false,
  attack_ranged_use_message=false,
  attack_ranged_frames_between=60,
  attack_ranged_entity_count_min=1,attack_ranged_entity_count_max=1,
  attack_ranged_action_frame=0,
  attack_ranged_min_distance=0,attack_ranged_max_distance=300,
  attack_ranged_offset_x=0,attack_ranged_offset_y=0,
  attack_ranged_state_duration_frames=45,
  mRangedAttackNextFrame=0,
 },
}
local component_ops={
 valid=function(v)return v~=nil and v~=0 end,
 first=function(_,k)if k=="ControlsComponent" then return controls elseif k=="AnimalAIComponent" then return animal end end,
 get=function(c,f,d)local v=values[c] and values[c][f];if v==nil then return d end return v end,
 boolean=function(v)return v==true or v==1 end,
 ensure_controls=function()return controls end,
 set_type_enabled=function()end,
 set_type_enabled_tree=function()end,
}
local dynamic_attacks={}
local tree={components=function(_,k)
 if k=="AnimalAIComponent" then return {animal} end
 if k=="AIAttackComponent" then return dynamic_attacks end
 return {}
end,reset=function()end}
local entity_tree={walk=function(e,fn)fn(e)end}
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/features/forms/component_ops.lua" then return component_ops end
 if path=="mods/metamorph_creative_menu/files/features/forms/entity_tree_cache.lua" then return tree end
 if path=="mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua" then return entity_tree end
 local prefix="mods/metamorph_creative_menu/";if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
local frame=10
local dynamic_enabled=false
local loaded={}
function ComponentGetEntity()return 1 end
function ComponentSetValue2(c,f,v) values[c][f]=v end
function EntitySetComponentIsEnabled()end
function ComponentGetIsEnabled(c) if c==dynamic_attack then return dynamic_enabled end return true end
function EntityGetComponentIncludingDisabled(_,k)
 if k=="AnimalAIComponent" then return {animal} end
 if k=="AIAttackComponent" then return dynamic_attacks end
 return {}
end
function EntityGetRootEntity()return 1 end
function EntityGetTransform()return 0,0,0,1,1 end
function EntityGetIsAlive()return true end
function DEBUG_GetMouseWorld()return 100,0 end
function GameGetFrameNum()return frame end
function EntityLoad(path) loaded[#loaded+1]=path; return 100+#loaded end
function GameShootProjectile() return true end
function EntityKill()end
function EntityCreateNew()return 0 end
function EntityAddTag()end
function EntityAddComponent2()return 0 end
function Random(a,b)return b or a end
function ModTextFileGetContent() return '<Sprite><RectAnimation name="attack_ranged" frame_wait="0" frame_count="1" /></Sprite>' end
function GamePlayAnimation()end

local combat=assert(native_dofile(root.."/files/features/forms/combat.lua"))
assert(combat.configure_ranged_player(1)==true,"dormant direct descriptor was not claimed for dynamic authored state")
assert(values[animal].attack_ranged_entity_file=="data/entities/projectiles/coward_bullet.xml","manual ownership mutated initial descriptor")
assert(combat.update_ranged_attacks(1)==false and #loaded==0,"disabled coward attack fired")

-- Simulate coward_check.lua enabling its already-authored ranged descriptor.
values[animal].attack_ranged_enabled=true
frame=11
assert(combat.update_ranged_attacks(1)==true,"dynamically enabled AnimalAI attack did not fire")
assert(loaded[1]=="data/entities/projectiles/coward_bullet.xml","dynamic enable lost the original projectile")
assert(values[animal].attack_ranged_entity_file=="data/entities/projectiles/coward_bullet.xml","dynamic enable mutated live descriptor")
assert(values[controls].polymorph_hax==false,"manual replay left polymorph_hax enabled")

-- Simulate basebot_sentry_check.lua rewriting projectile + cadence between updates.
values[animal].attack_ranged_entity_file="data/entities/projectiles/machinegun_bullet_roboguard_big.xml"
values[animal].attack_ranged_frames_between=20
values[animal].mRangedAttackNextFrame=0
frame=100
assert(combat.update_ranged_attacks(1)==true,"dynamic sentry projectile rewrite was not replayed")
assert(loaded[2]=="data/entities/projectiles/machinegun_bullet_roboguard_big.xml","dynamic projectile rewrite was ignored")
assert(values[animal].attack_ranged_entity_file=="data/entities/projectiles/machinegun_bullet_roboguard_big.xml","dynamic rewrite was not preserved on live descriptor")
assert(values[animal].mRangedAttackNextFrame==120,"dynamic cadence was not mirrored into cooldown")

-- Simulate wizard_returner_memory.lua installing an arbitrary remembered projectile.
values[animal].attack_ranged_entity_file="mods/example/projectiles/remembered.xml"
values[animal].attack_ranged_frames_between=30
values[animal].mRangedAttackNextFrame=0
frame=200
assert(combat.update_ranged_attacks(1)==true,"dynamic remembered projectile was not replayed")
assert(loaded[3]=="mods/example/projectiles/remembered.xml","dynamic mod projectile path was not preserved exactly")
assert(values[animal].attack_ranged_entity_file=="mods/example/projectiles/remembered.xml","remembered projectile was not preserved on live descriptor")

-- Dynamic disable must immediately stop subsequent shots without destroying descriptor state.
values[animal].attack_ranged_enabled=false
values[animal].mRangedAttackNextFrame=0
frame=300
assert(combat.update_ranged_attacks(1)==false and #loaded==3,"dynamic disable did not suppress firing")


-- A vanilla/mod LuaComponent may add a new AIAttackComponent after the form was configured.
-- Exact replay must discover and claim it instead of keeping the one-time snapshot forever.
values[dynamic_attack]={
 attack_ranged_entity_file="data/entities/projectiles/grenade_scavenger.xml",
 frames_between=45,frames_between_global=0,
 attack_ranged_entity_count_min=2,attack_ranged_entity_count_max=2,
 attack_ranged_action_frame=0,animation_name="attack_ranged",
 min_distance=0,max_distance=300,use_probability=100,state_duration_frames=45,
 attack_ranged_offset_x=4,attack_ranged_offset_y=-2,
 attack_ranged_root_offset_x=0,attack_ranged_root_offset_y=0,
 attack_ranged_use_message=false,attack_landing_ranged_enabled=false,
 attack_ranged_predict=false,attack_ranged_aim_rotation_enabled=false,
 attack_ranged_use_laser_sight=false,mNextFrameUsable=0,
}
dynamic_attacks[1]=dynamic_attack
values[animal].attack_ranged_enabled=false
frame=400
assert(combat.update_ranged_attacks(1)==false and #loaded==3,"disabled late-added AIAttackComponent became player-usable")

-- Phase/mod enabling the real component makes it available without MCM forcing state.
dynamic_enabled=true
frame=401
assert(combat.update_ranged_attacks(1)==true,"enabled late-added AIAttackComponent was not discovered")
assert(loaded[4]=="data/entities/projectiles/grenade_scavenger.xml" and loaded[5]=="data/entities/projectiles/grenade_scavenger.xml","late-added attack lost exact projectile/count")
assert(values[dynamic_attack].attack_ranged_entity_file=="data/entities/projectiles/grenade_scavenger.xml","late-added descriptor was mutated by ownership")

-- An intentional empty projectile path from another mod/phase must immediately retire the
-- remembered shadow projectile instead of firing the stale saved path.
values[dynamic_attack].attack_ranged_entity_file=""
values[dynamic_attack].mNextFrameUsable=0
frame=500
assert(combat.update_ranged_attacks(1)==false and #loaded==5,"intentional empty AIAttack path fired stale projectile")
values[dynamic_attack].attack_ranged_entity_file="mods/example/projectiles/re_enabled.xml"
values[dynamic_attack].mNextFrameUsable=0
frame=501
assert(combat.update_ranged_attacks(1)==true and loaded[6]=="mods/example/projectiles/re_enabled.xml","re-enabled live descriptor did not replace empty state")

print("form_dynamic_attack_state=PASS dormant_claim=true enable=true projectile_rewrite=true cadence=true remembered=true disable=true late_component=true component_enabled=true empty_path_authoritative=true")
