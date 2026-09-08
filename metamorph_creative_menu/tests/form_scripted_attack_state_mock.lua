local root=assert(arg[1],"root required")
local native_dofile=dofile
local controls=10
local frame=0
local next_entity=1000
local scenario={}
local values={}
local owners={}
local enabled={}
local alive={}
local transforms={}
local children={}
local shots={}
local projectile_components={}
local velocity_components={}
local object_values={}
local random_queue={}
local mouse_x,mouse_y=110,20
local ray_blocked=false
local function pop_random(a,b)
 local v=table.remove(random_queue,1)
 if v~=nil then return v end
 if a==nil then return 0 end
 if b==nil then return a end
 return a
end
local component_ops={
 valid=function(v)return v~=nil and v~=0 end,
 get=function(c,f,d)local v=values[c] and values[c][f];if v==nil then return d end;return v end,
 boolean=function(v)return v==true or v==1 end,
 ensure_controls=function()return controls end,
}
local entity_tree={walk=function(e,fn)
 local function rec(id) if fn(id)==false then return false end; for _,c in ipairs(children[id] or {}) do if rec(c)==false then return false end end end
 rec(e)
end}
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua" then return entity_tree end
 if path=="mods/metamorph_creative_menu/files/features/forms/component_ops.lua" then return component_ops end
 local prefix="mods/metamorph_creative_menu/"; if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
local function reset_world(script_specs, vars, extra_children)
 values={[controls]={mButtonDownFire=true,mButtonDownFire2=false}}
 owners={[controls]=1}
 enabled={};alive={[1]=true};transforms={[1]={10,20,0,1,1}};children={[1]={}}
 shots={};projectile_components={};velocity_components={};object_values={};random_queue={};frame=0;next_entity=1000;mouse_x=110;mouse_y=20;ray_blocked=false
 local id=20
 for _,spec in ipairs(script_specs or {}) do
  id=id+1; local is_enabled=spec.enabled~=false; values[id]={script_source_file=spec.path,execute_every_n_frame=spec.interval or -1,mLastExecutionFrame=spec.last or -1,_enabled=spec.serialized_enabled~=nil and spec.serialized_enabled or is_enabled};owners[id]=spec.owner or 1;enabled[id]=is_enabled
  local owner=spec.owner or 1;alive[owner]=true;transforms[owner]=transforms[owner] or {12,18,0,1,1};scenario.lua_by_owner=scenario.lua_by_owner or {};scenario.lua_by_owner[owner]=scenario.lua_by_owner[owner] or {};table.insert(scenario.lua_by_owner[owner],id)
  if owner~=1 then local found=false;for _,c in ipairs(children[1])do if c==owner then found=true end end;if not found then table.insert(children[1],owner) end end
 end
 for _,v in ipairs(vars or {}) do
  id=id+1;values[id]={name=v.name,value_int=v.value_int,value_string=v.value_string or "",value_bool=v.value_bool or false};owners[id]=v.owner or 1
  scenario.vars=scenario.vars or {};scenario.vars[v.name]=id
 end
 for _,c in ipairs(extra_children or {}) do
  alive[c.id]=true;transforms[c.id]={c.x or 0,c.y or 0,0,1,1};table.insert(children[1],c.id);children[c.id]={};scenario.names=scenario.names or {};scenario.names[c.id]=c.name or ""
  if c.genome then id=id+1; values[id]={herd_id=c.herd_id or 5};owners[id]=c.id;scenario.genomes=scenario.genomes or {};scenario.genomes[c.id]=id end
  if c.sprite then id=id+1;values[id]={rect_animation=c.sprite,image_file="sprite.xml"};owners[id]=c.id;scenario.sprites=scenario.sprites or {};scenario.sprites[c.id]=id end
 end
 id=id+1;values[id]={herd_id=7};owners[id]=1;scenario.root_genome=id
 scenario.root=1
end
scenario={lua_by_owner={},vars={},genomes={},sprites={}}
function EntityGetComponentIncludingDisabled(e,kind)
 if kind=="LuaComponent" then return (scenario.lua_by_owner and scenario.lua_by_owner[e]) or {} end
 if kind=="VariableStorageComponent" then local out={};for name,c in pairs(scenario.vars or {}) do if owners[c]==e then out[#out+1]=c end end;return out end
 if kind=="GenomeDataComponent" then local out={};if e==1 and scenario.root_genome then out[#out+1]=scenario.root_genome end;if scenario.genomes and scenario.genomes[e] then out[#out+1]=scenario.genomes[e] end;return out end
 if kind=="SpriteComponent" then
  if scenario.sprite_lists and scenario.sprite_lists[e] then return scenario.sprite_lists[e] end
  local c=scenario.sprites and scenario.sprites[e];return c and {c} or {}
 end
 if kind=="ProjectileComponent" then local c=projectile_components[e];return c and {c} or {} end
 if kind=="VelocityComponent" then local c=velocity_components[e];return c and {c} or {} end
 if kind=="LaserEmitterComponent" then return scenario.lasers or {} end
 if kind=="HitboxComponent" then return (scenario.hitbox_owner==e and scenario.hitbox) and {scenario.hitbox} or {} end
 if kind=="DamageModelComponent" then return (scenario.damage_owner==e and scenario.damage_component) and {scenario.damage_component} or {} end
 return {}
end
function EntityGetFirstComponentIncludingDisabled(e,kind)local t=EntityGetComponentIncludingDisabled(e,kind);return t[1] end
function EntitySetComponentsWithTagEnabled(e,tag,v) scenario.tag_enabled=scenario.tag_enabled or {};scenario.tag_enabled[tag]=v==true;scenario.tag_enabled_by_owner=scenario.tag_enabled_by_owner or {};scenario.tag_enabled_by_owner[e]=scenario.tag_enabled_by_owner[e] or {};scenario.tag_enabled_by_owner[e][tag]=v==true end
function EntityGetName(e)return scenario.names and scenario.names[e] or "" end
function ComponentGetIsEnabled(c)return enabled[c]==true end
function EntitySetComponentIsEnabled(_,c,v)enabled[c]=v==true end
function ComponentGetValue2(c,f)local v=values[c] and values[c][f];if type(v)=="table" then return v[1],v[2] end;return v end
function ComponentSetValue2(c,f,...)values[c]=values[c] or {};local a={...};values[c][f]=#a==1 and a[1] or a end
function ComponentObjectSetValue2(c,obj,f,v)object_values[c]=object_values[c] or {};object_values[c][obj.."."..f]=v end
function ComponentGetEntity(c)return owners[c] or 0 end
function EntityGetAllChildren(e)return children[e] or {} end
function EntityGetRootEntity(e)return e==2 and 1 or e end
function EntityGetIsAlive(e)return alive[e]==true end
function EntityGetTransform(e)local t=transforms[e];if not t then return nil end;return t[1],t[2],t[3],t[4],t[5] end
function EntitySetTransform(e,x,y)transforms[e]={x,y,0,1,1} end
function EntityCreateNew()next_entity=next_entity+1;alive[next_entity]=true;transforms[next_entity]={0,0,0,1,1};children[next_entity]={};return next_entity end
function EntityAddTag(e,tag) scenario.tags=scenario.tags or {};scenario.tags[e]=scenario.tags[e] or {};scenario.tags[e][tag]=true end
function EntityKill(e)alive[e]=false end
function EntityAddChild(parent, child) children[parent]=children[parent] or {};table.insert(children[parent],child);scenario.names=scenario.names or {};if scenario.loaded_paths and scenario.loaded_paths[child] and string.find(scenario.loaded_paths[child],"boss_centipede_shield",1,true) then scenario.names[child]="shield_entity" end end
function EntitySetDamageFromMaterial(e,mat,v) scenario.material_damage=scenario.material_damage or {};scenario.material_damage[mat]=v end
function EntityAddComponent2(e,kind,fields)next_entity=next_entity+1;values[next_entity]=fields or {};owners[next_entity]=e;return next_entity end
function EntityLoad(path,x,y)
 next_entity=next_entity+1;local e=next_entity;alive[e]=true;transforms[e]={x,y,0,1,1};children[e]={};scenario.loaded_paths=scenario.loaded_paths or {};scenario.loaded_paths[e]=path
 local pc=e+10000;local vc=e+20000;values[pc]={};values[vc]={};owners[pc]=e;owners[vc]=e;projectile_components[e]=pc;velocity_components[e]=vc
 shots[#shots+1]={path=path,e=e,x=x,y=y};return e
end
function GameShootProjectile(who,sx,sy,tx,ty,p,send)local s=shots[#shots];s.who=who;s.tx=tx;s.ty=ty;s.send=send end
function GameGetFrameNum()return frame end
function DEBUG_GetMouseWorld()return mouse_x,mouse_y end
function RaytraceSurfacesAndLiquiform()return ray_blocked end
function EntityGetWithTag(tag) if tag=="healer" then return scenario.healers or {} end return {} end
function EntityGetFirstHitboxCenter(e)local t=transforms[e];return t[1],t[2] end
function Random(a,b)return pop_random(a,b) end
function SetRandomSeed()end
function ProceduralRandomf(a,b,c,d)if d~=nil then return c end;return 0.25 end
function GamePlayAnimation(e,name)scenario.animations=scenario.animations or {};scenario.animations[#scenario.animations+1]={e,name} end
function GameEntityPlaySound()end
function GamePlaySound()end
function GameCreateParticle()end
function GameGetOrbCountThisRun()return scenario.orbs or 0 end
function SessionNumbersGetValue(key) assert(key=="NEW_GAME_PLUS_COUNT"); return tostring(scenario.ngplus or 0) end
local scripted=assert(native_dofile(root.."/files/features/forms/scripted_attacks.lua"))
local function fresh(specs,vars,extra)
 scripted.reset();scenario={lua_by_owner={},vars={},genomes={},sprites={}};reset_world(specs,vars,extra)
end
local function count_path(path)local n=0;for _,s in ipairs(shots)do if s.path==path then n=n+1 end end;return n end
-- Scripted replay treats explicit player fire as target acquisition. Vanilla search
-- radii must not reject a distant cursor, while attack-internal conditions such as the
-- monk's line-of-sight check remain authored behavior.
fresh({{path="data/scripts/animals/fungus_giga_pollen.lua",interval=10}},nil,nil)
assert(scripted.configure(1,"fungus_giga"));frame=10;mouse_x=1000;scripted.update(1);assert(count_path("data/entities/projectiles/pollen.xml")==1,"fungus giga player fire was blocked by the vanilla 64px acquisition radius")

fresh({{path="data/scripts/animals/monk_hand_shoot.lua",interval=60,owner=2}},nil,{{id=2,x=10,y=20,sprite="stand"}})
assert(scripted.configure(1,"monk"));frame=60;mouse_x=1000;scripted.update(1);assert(count_path("data/entities/projectiles/orb_green_accelerating.xml")==1,"monk player fire was blocked by the vanilla 200px acquisition radius")
-- A separate far-cursor attempt still respects the authored line-of-sight condition.
fresh({{path="data/scripts/animals/monk_hand_shoot.lua",interval=60,owner=2}},nil,{{id=2,x=10,y=20,sprite="stand"}})
assert(scripted.configure(1,"monk"));frame=60;mouse_x=1000;ray_blocked=true;scripted.update(1);assert(count_path("data/entities/projectiles/orb_green_accelerating.xml")==0,"monk ignored vanilla line-of-sight check")

-- boss meat: 20f acid + 80f status-driven orb
fresh({{path="data/entities/animals/boss_meat/shot.lua",interval=20},{path="data/entities/animals/boss_meat/eye.lua",interval=80}},{{name="status",value_int=3}})
assert(scripted.configure(1,"boss_meat"));frame=20;scripted.update(1);assert(count_path("data/entities/animals/boss_meat/acidshot_slow.xml")==1,"boss meat acid cadence changed")
frame=80;scripted.update(1);assert(count_path("data/entities/animals/boss_meat/orb_big.xml")==1,"boss meat eye orb state was lost")
assert(scenario.tag_enabled==nil or scenario.tag_enabled.vacuum_NOT~=true,"boss meat replay re-enabled native shot.lua through vacuum_NOT")
-- fish giga: opened eye + timer 360 fires exact eight orb ring and mirrors the
-- vanilla vulnerable-hitbox lifecycle while the eye opens/closes.
fresh({{path="data/entities/animals/boss_fish/eye.lua",interval=1,owner=2}},{{name="phase_timer",value_int=360,owner=2}},{{id=2,x=30,y=40,sprite="opened"}})
scenario.hitbox=90;scenario.hitbox_owner=1;values[90]={};owners[90]=1;enabled[90]=true
assert(scripted.configure(1,"fish_giga"));frame=1;scripted.update(1);assert(count_path("data/entities/animals/boss_fish/orb_big.xml")==8,"fish giga did not fire eight authored orbs")
-- Losing the target from an opened eye must begin close and immediately disable the
-- same root hitbox, exactly as boss_fish/eye.lua.
values[controls].mButtonDownFire=false;frame=2;scripted.update(1);assert(enabled[90]==false,"fish giga close did not disable vulnerable hitbox")
-- Re-open through the same authored `closed -> open -> opened` 36-frame sequence.
values[controls].mButtonDownFire=true;values[scenario.sprites[2]].rect_animation="closed";frame=3;scripted.update(1)
assert(values[scenario.sprites[2]].rect_animation=="open","fish giga did not enter authored open animation")
for f=4,40 do frame=f;scripted.update(1) end
assert(enabled[90]==true and values[scenario.sprites[2]].rect_animation=="opened","fish giga open did not enable vulnerable hitbox")
fresh({{path="data/entities/animals/boss_fish/eye.lua",interval=1,owner=2}},{{name="phase_timer",value_int=360,owner=2}},{{id=2,x=30,y=40,sprite="opened"}})
assert(scripted.configure(1,"fish_giga"));mouse_x=1000
for f=1,361 do frame=f;scripted.update(1) end
assert(count_path("data/entities/animals/boss_fish/orb_big.xml")==8,"fish giga player fire was blocked by the vanilla 160px acquisition radius")
-- maggot: shooter_part points at genome-bearing segment and advances state
fresh({{path="data/entities/animals/maggot_tiny/shot.lua",interval=20}},{{name="shooter_part",value_int=1}},{{id=2,x=50,y=60,genome=true}})
assert(scripted.configure(1,"maggot_tiny"));frame=20;scripted.update(1);assert(count_path("data/entities/animals/maggot_tiny/orb.xml")==1,"maggot segment shot missing");assert(values[scenario.vars.shooter_part].value_int==2,"maggot shooter_part did not advance")
-- wizard supplemental volley: two tentacles per 16f
fresh({{path="data/entities/animals/boss_wizard/bloodtentacle.lua",interval=16}},nil,nil)
assert(scripted.configure(1,"boss_wizard"));frame=16;scripted.update(1);assert(count_path("data/entities/animals/boss_wizard/bloodtentacle.xml")==2,"boss wizard tentacle volley count changed")
fresh({{path="data/entities/animals/boss_wizard/bloodtentacle.lua",interval=16,enabled=false,serialized_enabled=true}},nil,nil)
assert(scripted.configure(1,"boss_wizard"));frame=16;scripted.update(1);assert(count_path("data/entities/animals/boss_wizard/bloodtentacle.xml")==0,"runtime-disabled boss wizard phase was invented from stale _enabled data")
-- boss ghost laser cross is already a safe native self-contained state machine; leave it enabled and prevent generic cursor-laser ownership.
fresh({{path="data/entities/animals/boss_ghost/lasers.lua",interval=1,enabled=true}},nil,nil)
scripted.configure(1,"boss_ghost");assert(scripted.manages_lasers()==true,"boss ghost native laser state machine was not protected");local ghost_lua=scenario.lua_by_owner[1][1];assert(enabled[ghost_lua]==true,"boss ghost native laser script was disabled")
-- robot preserves the entire 40f state cycle, including spell-eater gates and healer spawn.
fresh({{path="data/entities/animals/boss_robot/state.lua",interval=40}},{{name="state",value_int=1},{name="spell_eater",value_int=1}},nil)
assert(scripted.configure(1,"boss_robot"));mouse_x=1000;frame=40;scripted.update(1);assert(count_path("data/entities/animals/boss_robot/rocket_roll.xml")==10,"boss robot rocket phase was blocked by the vanilla 300px acquisition radius");assert(values[scenario.vars.spell_eater].value_int==0,"boss robot state2 did not disable spell eater")
frame=80;scripted.update(1);frame=120;scripted.update(1);assert(values[scenario.vars.spell_eater].value_int==1,"boss robot state4 did not enable spell eater")
for f=160,480,40 do frame=f;scripted.update(1) end
assert(count_path("data/entities/animals/robobase/healerdrone_physics.xml")==1,"boss robot state13 healer spawn was lost")
assert(values[scenario.vars.state].value_int==0,"boss robot state13 did not reset authored state cycle")
-- Once the robot reaches laser state 6, releasing fire must not freeze an emitting
-- laser. The replay finishes only the in-progress laser phase through authored state10.
fresh({{path="data/entities/animals/boss_robot/state.lua",interval=40}},{{name="state",value_int=5},{name="spell_eater",value_int=1}},nil)
scenario.lasers={91,92};values[91]={is_emitting=false};values[92]={is_emitting=false};owners[91]=1;owners[92]=1;enabled[91]=true;enabled[92]=true
assert(scripted.configure(1,"boss_robot"));frame=40;scripted.update(1)
assert(values[91].is_emitting==true and values[92].is_emitting==true,"boss robot state6 did not start lasers")
values[controls].mButtonDownFire=false
for _,f in ipairs({80,120,160,200}) do frame=f;scripted.update(1) end
assert(ComponentGetValue2(91,"is_emitting")==false and ComponentGetValue2(92,"is_emitting")==false,"boss robot laser stayed active after primary fire release")
assert(values[scenario.vars.state].value_int==10,"boss robot did not finish the in-progress laser phase through state10")
-- reset is also a hard safety boundary for manually-owned emitters.
fresh({{path="data/entities/animals/boss_robot/state.lua",interval=40}},{{name="state",value_int=5},{name="spell_eater",value_int=1}},nil)
scenario.lasers={93};values[93]={is_emitting=false};owners[93]=1;enabled[93]=true
assert(scripted.configure(1,"boss_robot"));frame=40;scripted.update(1);assert(values[93].is_emitting==true,"boss robot reset fixture did not start laser")
scripted.reset();assert(ComponentGetValue2(93,"is_emitting")==false,"boss robot reset left a managed laser emitting")
-- pit state0 -> state1 = exact wand carrier
fresh({{path="data/entities/animals/boss_pit/boss_pit_logic.lua",interval=40}},{{name="state",value_int=0},{name="memory",value_string="memory.xml"},{name="pathfinding_frames_stuck",value_int=0}},nil)
random_queue={1,1};assert(scripted.configure(1,"boss_pit"));frame=40;scripted.update(1);assert(count_path("data/entities/animals/boss_pit/wand.xml")==1,"boss pit wand carrier missing")
-- Passive boss-pit recovery belongs to the disabled vanilla logic too. It must run
-- every authored 40f even when the player is not firing, without advancing attack state.
fresh({{path="data/entities/animals/boss_pit/boss_pit_logic.lua",interval=40}},{{name="state",value_int=0},{name="memory",value_string="memory.xml"},{name="pathfinding_frames_stuck",value_int=0}},nil)
scenario.hitbox=94;scenario.hitbox_owner=1;values[94]={damage_multiplier=0};owners[94]=1;enabled[94]=true;values[controls].mButtonDownFire=false
assert(scripted.configure(1,"boss_pit"))
frame=40;scripted.update(1);assert(math.abs(values[94].damage_multiplier-0.35)<0.000001,"boss pit damage multiplier did not recover by vanilla +0.35")
assert(scenario.tag_enabled and scenario.tag_enabled.invincible==false,"boss pit invincible tag was not disabled during passive recovery")
assert(values[scenario.vars.state].value_int==0 and count_path("data/entities/animals/boss_pit/wand.xml")==0,"boss pit passive recovery advanced the manual firing state")
frame=80;scripted.update(1);assert(math.abs(values[94].damage_multiplier-0.70)<0.000001,"boss pit second recovery tick changed")
frame=120;scripted.update(1);assert(values[94].damage_multiplier==1,"boss pit recovery did not clamp at 1.0")
-- limbs primary mirrors expose/weak-hitbox/details lifecycle as well as the exact rings.
fresh({{path="data/entities/animals/boss_limbs/boss_limbs_update.lua",interval=-1}},nil,nil)
scenario.sprite_lists={[1]={91,92,93,94}}
for _,c in ipairs(scenario.sprite_lists[1]) do values[c]={rect_animation="stand"};owners[c]=1 end
assert(scripted.configure(1,"boss_limbs"));frame=0;scripted.update(1)
assert(values[91].rect_animation=="stand" and values[92].rect_animation=="invisible" and values[94].rect_animation=="invisible","boss limbs expose did not hide only detail sprites")
frame=9;scripted.update(1);assert(scenario.tag_enabled==nil or scenario.tag_enabled.hitbox_weak_spot~=true,"boss limbs weak spot exposed before authored 10f delay")
frame=10;scripted.update(1);assert(scenario.tag_enabled.hitbox_weak_spot==true and scenario.tag_enabled.hitbox_default==false,"boss limbs weak hitbox timing changed")
frame=45;scripted.update(1);assert(count_path("data/entities/animals/boss_limbs/orb_boss_limbs.xml")==8,"boss limbs first ring changed")
frame=110;scripted.update(1);frame=175;scripted.update(1);assert(count_path("data/entities/animals/boss_limbs/orb_boss_limbs.xml")==24,"boss limbs three-ring phase changed")
frame=414;scripted.update(1);assert(scenario.tag_enabled.hitbox_weak_spot==true,"boss limbs weak spot closed before authored 240f exposure")
frame=415;scripted.update(1);assert(scenario.tag_enabled.hitbox_weak_spot==true,"boss limbs close animation disabled weak spot too early")
frame=425;scripted.update(1);assert(scenario.tag_enabled.hitbox_weak_spot==false and scenario.tag_enabled.hitbox_default==true,"boss limbs default hitbox restore timing changed")
assert(values[92].rect_animation=="invisible","boss limbs details returned before close finished")
frame=455;scripted.update(1);assert(values[92].rect_animation=="stand" and values[94].rect_animation=="stand","boss limbs details restore timing changed")
frame=464;scripted.update(1);assert(count_path("data/entities/animals/boss_limbs/orb_boss_limbs.xml")==24,"boss limbs phase cooldown was skipped")
-- Boss Centipede player form must suppress the pre-battle limb coroutine and replay
-- vanilla init_boss() state before the manual attack controller reads orbcount/shield.
fresh({
 {path="data/entities/animals/boss_centipede/boss_centipede_before_fight.lua",interval=-1,enabled=true},
 {path="data/entities/animals/boss_centipede/boss_centipede_update.lua",interval=-1,enabled=false},
},{{name="initialized",value_bool=false},{name="orbcount",value_int=0}},{{id=2,x=10,y=20,name="limb"}})
scenario.orbs=5;scenario.ngplus=2
scenario.damage_component=90;scenario.damage_owner=1;values[90]={hp=1,max_hp=1};owners[90]=1
assert(scripted.configure(1,"boss_centipede"),"centipede configure failed")
local before_comp,update_comp=nil,nil
for _,c in ipairs(scenario.lua_by_owner[1] or {}) do
 local src=values[c].script_source_file
 if src=="data/entities/animals/boss_centipede/boss_centipede_before_fight.lua" then before_comp=c end
 if src=="data/entities/animals/boss_centipede/boss_centipede_update.lua" then update_comp=c end
end
assert(before_comp and enabled[before_comp]==false,"centipede pre-battle coroutine remained enabled")
assert(update_comp and enabled[update_comp]==false,"centipede vanilla combat coroutine escaped manual ownership")
assert(values[scenario.vars.initialized].value_bool==true,"centipede init flag was not committed")
assert(values[scenario.vars.orbcount].value_int==7,"centipede real run+NG orbcount was not stored")
local expected_hp=46.0+(2.0^(7+1.3))+(7*15.5)
assert(math.abs(values[90].hp-expected_hp)<0.001 and math.abs(values[90].max_hp-expected_hp)<0.001,"centipede orb-scaled HP init changed")
assert(object_values[90]["damage_multipliers.projectile"]==0.2 and object_values[90]["damage_multipliers.drill"]==0.01,"centipede orb resistance init missing")
assert(scenario.material_damage.acid==0.0,"centipede material resistance init missing")
local shield_found=false
for child,path in pairs(scenario.loaded_paths or {}) do if path=="data/entities/animals/boss_centipede/boss_centipede_shield_strong.xml" and scenario.names[child]=="shield_entity" then shield_found=true end end
assert(shield_found,"centipede strong shield entity was not initialized")
assert(scenario.tag_enabled_by_owner[2] and scenario.tag_enabled_by_owner[2].disabled_at_start==true,"centipede initial child components were not enabled")

-- centipede circle phase reproduces its authored prep, repeat and branch growth.
-- orbcount0: repeat_left=1 means first phase has 5 branches, repeated phase has 6.
fresh({{path="data/entities/animals/boss_centipede/boss_centipede_update.lua",interval=-1,enabled=false}},{{name="orbcount",value_int=0}},{{id=2,x=10,y=20,name="shield_entity"}})
random_queue={1};assert(scripted.configure(1,"boss_centipede"));mouse_x=1000;frame=0;scripted.update(1)
assert(scenario.animations==nil or #scenario.animations==0,"centipede opened eye before vanilla 50+10f shield prep")
frame=49;scripted.update(1);assert(scenario.tag_enabled_by_owner==nil or scenario.tag_enabled_by_owner[2]==nil,"centipede shield enabled before 50f")
frame=50;scripted.update(1);assert(scenario.tag_enabled_by_owner[2].shield==true,"centipede shield_on timing changed")
frame=59;scripted.update(1);assert(scenario.animations==nil or #scenario.animations==0,"centipede eye opened before shield wait completed")
frame=60;scripted.update(1);assert(scenario.animations[#scenario.animations][2]=="open","centipede eye-open timing changed")
frame=114;scripted.update(1);assert(count_path("data/entities/animals/boss_centipede/orb_circleshot.xml")==0,"centipede ignored 115f authored prep")
frame=115;scripted.update(1);assert(count_path("data/entities/animals/boss_centipede/orb_circleshot.xml")==5,"centipede first repeated circle branch count changed");assert(count_path("data/entities/particles/muzzle_flashes/muzzle_flash_circular_pink.xml")==1,"centipede circle muzzle flash missing")
for i=1,9 do frame=115+i*12;scripted.update(1) end
assert(count_path("data/entities/animals/boss_centipede/orb_circleshot.xml")==50,"centipede first ten-ring spiral changed")
frame=235;scripted.update(1);assert(scenario.tag_enabled_by_owner[2].shield==false,"centipede repeated circle did not disable shield after loop wait")
frame=345;scripted.update(1);assert(scenario.tag_enabled_by_owner[2].shield==true,"centipede repeated circle did not re-enable shield after move wait")
frame=355;scripted.update(1);assert(count_path("data/entities/animals/boss_centipede/orb_circleshot.xml")==56,"centipede repeated phase did not grow to six branches")
-- firepillar exact repeat amounts 2/1/0 => 6,8,10 projectiles at orbcount0.
fresh({{path="data/entities/animals/boss_centipede/boss_centipede_update.lua",interval=-1,enabled=false}},{{name="orbcount",value_int=0}},nil)
random_queue={2};assert(scripted.configure(1,"boss_centipede"));frame=0;scripted.update(1)
frame=115;scripted.update(1);assert(count_path("data/entities/animals/boss_centipede/firepillar.xml")==6,"centipede first firepillar repeat amount changed")
frame=215;scripted.update(1);assert(count_path("data/entities/animals/boss_centipede/firepillar.xml")==14,"centipede second firepillar repeat amount changed")
frame=315;scripted.update(1);assert(count_path("data/entities/animals/boss_centipede/firepillar.xml")==24,"centipede final firepillar repeat amount changed")
-- orbcount2 unlocks homing: 4 + floor(2*0.5) = five shots, 20f apart after open-eye prep.
fresh({{path="data/entities/animals/boss_centipede/boss_centipede_update.lua",interval=-1,enabled=false}},{{name="orbcount",value_int=2}},nil)
random_queue={3};assert(scripted.configure(1,"boss_centipede"));frame=0;scripted.update(1)
for _,f in ipairs({55,75,95,115,135}) do frame=f;scripted.update(1) end
assert(count_path("data/entities/animals/boss_centipede/orb_homing.xml")==5,"centipede authored homing count/cadence changed")
-- orbcount11 unlocks the exact three-projectile polymorph triangle.
fresh({{path="data/entities/animals/boss_centipede/boss_centipede_update.lua",interval=-1,enabled=false}},{{name="orbcount",value_int=11}},nil)
random_queue={4};assert(scripted.configure(1,"boss_centipede"));frame=0;scripted.update(1);frame=85;scripted.update(1)
assert(count_path("data/entities/animals/boss_centipede/orb_polymorph.xml")==3,"centipede polymorph volley count changed")
local poly={};for _,shot in ipairs(shots)do if shot.path=="data/entities/animals/boss_centipede/orb_polymorph.xml" then poly[#poly+1]=shot end end
assert(poly[1].x==10 and poly[1].y==10 and values[velocity_components[poly[1].e]].mVelocity[1]==0 and values[velocity_components[poly[1].e]].mVelocity[2]==-50,"centipede first polymorph vector changed")
assert(poly[2].x==5 and poly[2].y==20 and poly[3].x==5 and poly[3].y==20,"centipede authored duplicate side vectors changed")
print("form_scripted_attack_state=PASS meat=true fish=true maggot=true wizard=true robot=true pit=true limbs=true centipede=true")
