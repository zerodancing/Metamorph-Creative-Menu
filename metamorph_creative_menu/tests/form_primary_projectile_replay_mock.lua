local root=assert(arg[1],"root required")
local native_dofile=dofile
local controls,animal,sprite_animator,sprite=10,20,30,40
local frame=100
local loads,shots=0,0
local animations={}
local refreshed=0
local dynamic_next=false
local loaded_paths={}
local enabled={}
local values={
 [controls]={mButtonDownFire=true,mButtonDownFire2=false,polymorph_hax=true},
 [animal]={attack_ranged_entity_file="data/entities/projectiles/buckshot.xml",attack_ranged_enabled=true,attack_ranged_use_message=false,attack_ranged_frames_between=100,attack_ranged_entity_count_min=3,attack_ranged_entity_count_max=4,attack_ranged_action_frame=4,attack_ranged_offset_x=2,attack_ranged_offset_y=-7,attack_ranged_min_distance=0,attack_ranged_max_distance=180,attack_ranged_aim_rotation_enabled=false,mRangedAttackNextFrame=0},
 [sprite]={image_file="data/enemies_gfx/shotgunner.xml"},
}
local component_ops={
 valid=function(v) return v~=nil and v~=0 end,
 first=function(_,kind)
  if kind=="ControlsComponent" then return controls end
  if kind=="SpriteAnimatorComponent" then return sprite_animator end
 end,
 get=function(c,f,d) local v=values[c] and values[c][f]; if v==nil then return d end return v end,
 boolean=function(v) return v==true or v==1 end,
 ensure_controls=function() return controls end,
 set_type_enabled=function() end,set_type_enabled_tree=function() end,
}
local tree={components=function(_,kind)
 if kind=="AnimalAIComponent" then return {animal} end
 if kind=="AIAttackComponent" then return {} end
 return {}
end, reset=function() end}
local entity_tree={walk=function(e,fn) fn(e) end}
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/features/forms/component_ops.lua" then return component_ops end
 if path=="mods/metamorph_creative_menu/files/features/forms/entity_tree_cache.lua" then return tree end
 if path=="mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua" then return entity_tree end
 local prefix="mods/metamorph_creative_menu/"; if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
function ComponentGetEntity(c) return c==animal and 1 or 1 end
function ComponentSetValue2(c,f,v) values[c]=values[c] or {}; values[c][f]=v end
function EntitySetComponentIsEnabled(_,c,v) enabled[c]=v==true end
function ComponentGetIsEnabled(c) if enabled[c]==nil then return true end return enabled[c] end
function EntityRefreshSprite() refreshed=refreshed+1 end
function EntityGetComponentIncludingDisabled(_,kind)
 if kind=="AnimalAIComponent" then return {animal} end
 if kind=="AIAttackComponent" then return {} end
 if kind=="SpriteComponent" then return {sprite} end
 if kind=="SpriteAnimatorComponent" then return {sprite_animator} end
 return {}
end
function EntityGetRootEntity() return 1 end
function EntityGetTransform() return 10,20,0,1,1 end
function EntityGetIsAlive() return true end
function DEBUG_GetMouseWorld() return 110,20 end
function GameGetFrameNum() return frame end
function ModTextFileGetContent(path)
 assert(path=="data/enemies_gfx/shotgunner.xml","unexpected sprite path")
 return [[<Sprite filename="shotgunner.png"><RectAnimation name="attack_ranged" frame_count="7" frame_width="17" frame_height="17" frame_wait="0.15" frames_per_row="8" /></Sprite>]]
end
function Random(a,b) if dynamic_next then return a end; assert(a==3 and b==4); return 4 end
function EntityLoad(path,x,y) loads=loads+1; loaded_paths[#loaded_paths+1]=path; return 100+loads end
function EntityKill() end
function GameShootProjectile(shooter,sx,sy,tx,ty,projectile,send_message)
 shots=shots+1
 assert(shooter==1 and sx==12 and sy==13,"authored muzzle offset not used")
 assert(tx==110 and ty==20,"cursor target changed")
 assert(send_message==true,"projectile message semantics changed")
 if dynamic_next then
  -- Simulate a synchronous vanilla LuaComponent.script_shot callback (Boss Wizard):
  -- Message_Shot authors the next projectile and its interval on AnimalAIComponent.
  values[animal].attack_ranged_entity_file="data/entities/animals/boss_wizard/meteor.xml"
  values[animal].attack_ranged_frames_between=220
 end
end
function GamePlayAnimation(_,name,priority) animations[#animations+1]={name=name,priority=priority} end
function EntityAddComponent2() return 0 end
function EntityAddTag() end
function EntityCreateNew() return 0 end
local combat=assert(native_dofile(root.."/files/features/forms/combat.lua"))
assert(combat.configure_ranged_player(1)==true,"direct ranged ownership was not acquired")
assert(values[animal].attack_ranged_enabled==true,"manual replay destroyed the authored logical attack-enabled state")
assert(values[animal].attack_ranged_entity_file=="data/entities/projectiles/buckshot.xml","manual ownership mutated native projectile descriptor")

assert(combat.update_ranged_attacks(1)==true,"primary attack was not reserved")
assert(values[animal].mRangedAttackNextFrame==200,"AnimalAI native ranged cooldown was not mirrored")
assert(values[controls].polymorph_hax==false,"manual replay did not disable polymorph_hax")
assert(loads==0,"shot fired before authored animation action frame")
frame=135; combat.update_ranged_attacks(1); assert(loads==0,"shot fired one frame too early")
frame=136; combat.update_ranged_attacks(1)
assert(loads==4 and shots==4,"shotgun did not fire exact authored projectile count")
for _,p in ipairs(loaded_paths) do assert(p=="data/entities/projectiles/buckshot.xml","fake/wrong projectile entity used") end
assert(values[sprite].rect_animation=="attack_ranged","ranged replay did not drive the authored attack sprite")
assert(enabled[sprite_animator]==false,"locomotion animator was not suspended during the attack window")
assert(refreshed>0,"attack sprite was not refreshed")
local animation_count=#animations
assert(animation_count==0,"supported sprite unexpectedly used sticky GamePlayAnimation fallback")
frame=150; combat.update_ranged_attacks(1); assert(loads==4,"local authored cooldown ignored")
assert(values[sprite].rect_animation=="","attack override did not restore previous locomotion sprite state")
assert(enabled[sprite_animator]==true,"locomotion animator was not restored after attack")
assert(#animations==animation_count,"ranged state exit injected a synthetic locomotion animation")

-- A manual action adapter can reserve either mouse button. The common ranged layer must
-- not observe that same press, otherwise dash/melee/wand actions double-fire a projectile.
combat.reset(); loads=0; shots=0; loaded_paths={}; dynamic_next=false; frame=250
values[animal].mRangedAttackNextFrame=0
values[controls].mButtonDownFire=false; values[controls].mButtonDownFire2=true
assert(combat.configure_ranged_player(1)==true,"ownership missing for input reservation test")
combat.update_ranged_attacks(1,false,true)
assert(loads==0 and shots==0,"reserved secondary input leaked into ranged replay")
combat.reset(); frame=251; values[animal].mRangedAttackNextFrame=0
values[controls].mButtonDownFire=true; values[controls].mButtonDownFire2=false
assert(combat.configure_ranged_player(1)==true,"ownership missing for primary reservation test")
combat.update_ranged_attacks(1,true,false)
assert(loads==0 and shots==0,"reserved primary input leaked into ranged replay")

-- Message_Shot-driven attack mutation must survive manual ownership on the live descriptor.
-- polymorph_hax remains disabled, so the next shot uses the callback-authored projectile once.
combat.reset(); loads=0; shots=0; loaded_paths={}; dynamic_next=true; frame=300
values[animal].attack_ranged_entity_file="data/entities/animals/boss_wizard/debuff_init.xml"
values[animal].attack_ranged_enabled=true; values[animal].attack_ranged_frames_between=240
values[animal].attack_ranged_entity_count_min=1; values[animal].attack_ranged_entity_count_max=1
values[animal].attack_ranged_action_frame=0; values[animal].mRangedAttackNextFrame=0
assert(combat.configure_ranged_player(1)==true,"dynamic attack did not acquire ownership")
combat.update_ranged_attacks(1)
assert(loads==1 and loaded_paths[1]=="data/entities/animals/boss_wizard/debuff_init.xml","dynamic attack initial projectile changed")
assert(values[animal].attack_ranged_entity_file=="data/entities/animals/boss_wizard/meteor.xml","script_shot-authored live descriptor was overwritten")
assert(values[animal].mRangedAttackNextFrame==520,"script_shot-authored cooldown did not replace stale interval")
frame=519; combat.update_ranged_attacks(1); assert(loads==1,"dynamic cooldown fired early")
frame=520; combat.update_ranged_attacks(1)
assert(loads==2 and loaded_paths[2]=="data/entities/animals/boss_wizard/meteor.xml","next script_shot-authored projectile was not replayed")
print("form_primary_projectile_replay=PASS attack_sprite_override=true locomotion_restored=true no_forced_stand=true polymorph_hax_suppressed=true descriptor_preserved=true projectile_exact=true count=4 action_delay=36 cooldown=true dynamic_shot=true")
