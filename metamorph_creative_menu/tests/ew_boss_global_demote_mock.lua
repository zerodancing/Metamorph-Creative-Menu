local root=assert(arg[1],"root required")

local frame=100
local next_component=500
local entities={
 [101]={alive=true,tags={},components={},filename="data/entities/animals/maggot_tiny/maggot_tiny.xml"},
 [102]={alive=true,tags={},components={},filename="data/entities/animals/sheep.xml"},
 [103]={alive=true,tags={ew_des=true},components={},filename="data/entities/animals/boss_dragon.xml"},
 [107]={alive=true,tags={boss=true,boss_centipede=true,mcm_creative_kolmi_v3=true},components={},filename="data/entities/animals/boss_centipede/boss_centipede.xml"},
 [108]={alive=true,tags={boss=true,miniboss=true},components={},filename="data/entities/animals/boss_limbs/boss_limbs.xml"},
 [109]={alive=true,tags={boss=true,boss_centipede=true},components={},filename="data/entities/animals/boss_centipede/boss_centipede.xml"},
 [110]={alive=true,tags={enemy=true},components={},filename="data/entities/animals/example_keepalive_mob.xml"},
}
local comps={}
local globals={}

local function ensure_entity(id,tags,filename)
 entities[id]=entities[id] or {alive=true,tags={},components={},filename=filename or ""}
 if filename then entities[id].filename=filename end
 for k,v in pairs(tags or {}) do entities[id].tags[k]=v end
 return entities[id]
end

local function add_component(entity,ctype,members,enabled,tags,id)
 ensure_entity(entity)
 id=id or next_component; next_component=math.max(next_component+1,id+1)
 comps[id]={entity=entity,type=ctype,members=members or {},enabled=enabled~=false,tags=tags or ""}
 table.insert(entities[entity].components,id)
 return id
end

-- Normal demoted creative boss. Keep IDs for BossDragon + StreamingKeepAlive.
add_component(101,"StreamingKeepAliveComponent",{},true,"",201)
add_component(101,"BossDragonComponent",{speed="8",part_distance="56",projectile_1=""},true,"dragon_tag",202)
add_component(101,"BossHealthBarComponent",{gui="0",in_world="1",gui_max_distance_visible="600"},true,"",203)
add_component(101,"DamageModelComponent",{hp="10",wait_for_kill_flag_on_death=false},true,"",211)
add_component(102,"DamageModelComponent",{hp="10",wait_for_kill_flag_on_death=false},true,"",204)
-- Existing remote boss must be untouched.
add_component(103,"StreamingKeepAliveComponent",{},true,"",205)
add_component(103,"BossDragonComponent",{speed="9"},true,"",206)
add_component(103,"BossHealthBarComponent",{},true,"",207)
add_component(103,"DamageModelComponent",{hp="5",wait_for_kill_flag_on_death=false},true,"",212)
add_component(103,"VariableStorageComponent",{name="ew_gid_lid",value_string="remote-gid",value_bool=false},true,"",208)
-- Creative Kolmisilma: disabled-at-start boss components + wait-for-kill handshake.
add_component(107,"StreamingKeepAliveComponent",{},false,"disabled_at_start",301)
add_component(107,"BossHealthBarComponent",{gui_special_final_boss="1"},false,"disabled_at_start",302)
add_component(107,"DamageModelComponent",{hp="56.5",wait_for_kill_flag_on_death=true},true,"",303)
-- Boss limbs uses the same delayed-kill contract and should also bypass demotion.
add_component(108,"BossHealthBarComponent",{},true,"",304)
add_component(108,"DamageModelComponent",{hp="20",wait_for_kill_flag_on_death=true},true,"",305)
-- Natural Kolmisilma keeps stock global lifecycle.
add_component(109,"StreamingKeepAliveComponent",{},false,"disabled_at_start",308)
add_component(109,"BossHealthBarComponent",{gui_special_final_boss="1"},false,"disabled_at_start",309)
add_component(109,"DamageModelComponent",{hp="56.5",wait_for_kill_flag_on_death=true},true,"",310)
add_component(110,"StreamingKeepAliveComponent",{},true,"",306)
add_component(110,"DamageModelComponent",{hp="3",wait_for_kill_flag_on_death=false},true,"",307)

function GameGetFrameNum() return frame end
function GlobalsGetValue(k,d) local v=globals[k]; if v==nil then return d end return v end
function GlobalsSetValue(k,v) globals[k]=tostring(v) end
function EntityGetIsAlive(e) return entities[e] and entities[e].alive or false end
function EntityHasTag(e,t) return entities[e] and entities[e].tags[t] == true or false end
function EntityAddTag(e,t) ensure_entity(e).tags[t]=true end
function EntityGetFilename(e) return entities[e] and entities[e].filename or "" end
function EntitiesGetMaxID()
 local m=0
 for id in pairs(entities) do if id>m then m=id end end
 return m
end
function EntityGetComponentIncludingDisabled(e,ctype)
 local out={}
 for _,id in ipairs((entities[e] and entities[e].components) or {}) do
  local c=comps[id]
  if c and c.type==ctype then out[#out+1]=id end
 end
 return out
end
function EntityGetFirstComponentIncludingDisabled(e,ctype)
 return (EntityGetComponentIncludingDisabled(e,ctype) or {})[1]
end
function EntityGetFirstComponent(e,ctype)
 for _,id in ipairs(EntityGetComponentIncludingDisabled(e,ctype) or {}) do
  if comps[id] and comps[id].enabled then return id end
 end
 return nil
end
function ComponentGetMembers(id)
 local out={}
 for k,v in pairs(assert(comps[id]).members) do out[k]=v end
 return out
end
function ComponentGetValue(id,name) return assert(comps[id]).members[name] end
function ComponentSetValue(id,name,value) assert(comps[id]).members[name]=tostring(value) end
function ComponentGetValue2(id,name)
 local v=assert(comps[id]).members[name]
 if name=="value_bool" or name=="wait_for_kill_flag_on_death" then
  return v==true or v=="1" or v==1
 end
 return v
end
function ComponentGetIsEnabled(id) return assert(comps[id]).enabled end
function ComponentGetTags(id) return assert(comps[id]).tags end
function ComponentAddTag(id,tag)
 local c=assert(comps[id])
 if c.tags=="" then c.tags=tag else c.tags=c.tags..","..tag end
end
function EntityRemoveComponent(e,id)
 local list=assert(entities[e]).components
 for i,v in ipairs(list) do if v==id then table.remove(list,i); comps[id]=nil; return end end
 error("component not found")
end
function EntityAddComponent2(e,ctype,_)
 return add_component(e,ctype,{},true,"")
end
function EntityAddComponent(e,ctype,_)
 return add_component(e,ctype,{},true,"")
end
function EntitySetComponentIsEnabled(e,id,value)
 assert(comps[id],"component missing: "..tostring(id)).enabled=value==true
end

local function native_consume_camera_bound(entity)
 for _,id in ipairs(EntityGetComponentIncludingDisabled(entity,"CameraBoundComponent") or {}) do
  EntityRemoveComponent(entity,id)
 end
end

-- Native reconstruction entry points.
local raw_entity_load_calls=0
function EntityLoad(file,x,y)
 raw_entity_load_calls=raw_entity_load_calls+1
 assert(file=="data/entities/animals/boss_alchemist/boss_alchemist.xml")
 ensure_entity(105,{boss=true,miniboss=true},file)
 if not EntityGetFirstComponentIncludingDisabled(105,"BossHealthBarComponent") then
  add_component(105,"BossHealthBarComponent",{},true,"")
  add_component(105,"DamageModelComponent",{hp="2",wait_for_kill_flag_on_death=false},true,"")
 end
 return 105
end
local raw_deserialize_calls=0
function EwextDeserialize(_blob)
 raw_deserialize_calls=raw_deserialize_calls+1
 ensure_entity(106,{boss=true},"data/entities/animals/boss_wizard/boss_wizard.xml")
 if not EntityGetFirstComponentIncludingDisabled(106,"BossHealthBarComponent") then
  add_component(106,"BossHealthBarComponent",{},true,"")
  add_component(106,"DamageModelComponent",{hp="12",wait_for_kill_flag_on_death=false},true,"")
 end
 return 106
end

local track_creative_now=false
local original_new_calls=0
local original_update_calls=0
local loaded_authority_once=false
ewext={}
ewext.module_on_new_entity=function(arr,len)
 original_new_calls=original_new_calls+1
 assert(len==#arr,"length changed")
 assert(EntityGetFirstComponentIncludingDisabled(101,"BossHealthBarComponent")==nil,"healthbar visible during native new-entity enqueue")
 assert(EntityGetFirstComponentIncludingDisabled(101,"StreamingKeepAliveComponent")==201,"keepalive component ID was destroyed")
 assert(EntityGetFirstComponent(101,"StreamingKeepAliveComponent")==nil,"keepalive still enabled during native enqueue")
 assert(EntityGetFirstComponentIncludingDisabled(101,"BossDragonComponent")==202,"BossDragon component ID was destroyed")
 assert(EntityGetFirstComponent(101,"BossDragonComponent")==nil,"BossDragon still enabled; EW could recreate keepalive")
 assert(#EntityGetComponentIncludingDisabled(101,"CameraBoundComponent")>=1,"filename spawn-info marker missing")
 assert(EntityGetFirstComponentIncludingDisabled(103,"BossDragonComponent")~=nil,"existing remote DES boss was modified")
 -- Creative Kolmi is deliberately hidden until native tracking, while natural
 -- wait-for-kill bosses keep their stock component state.
 assert(EntityGetFirstComponentIncludingDisabled(107,"BossHealthBarComponent")==nil,"creative Kolmisilma healthbar remained visible")
 assert(EntityGetFirstComponentIncludingDisabled(107,"StreamingKeepAliveComponent")==301,"creative Kolmi keepalive ID was destroyed")
 assert(EntityGetFirstComponent(107,"StreamingKeepAliveComponent")==nil,"creative Kolmi keepalive remained enabled")
 assert(EntityGetFirstComponentIncludingDisabled(108,"BossHealthBarComponent")==304,"boss_limbs wait-kill healthbar was removed")
 assert(EntityGetFirstComponentIncludingDisabled(109,"BossHealthBarComponent")==309,"natural Kolmisilma healthbar was removed")
 assert(EntityGetFirstComponentIncludingDisabled(109,"StreamingKeepAliveComponent")==308,"natural Kolmisilma keepalive was removed")
end

ewext.module_on_world_update=function()
 original_update_calls=original_update_calls+1
 assert(EntityGetFirstComponentIncludingDisabled(101,"BossDragonComponent")==202,"creative BossDragon ID changed before tracking")
 assert(EntityGetFirstComponent(101,"BossDragonComponent")==nil,"creative boss restored before native track_entity")
 assert(#EntityGetComponentIncludingDisabled(101,"CameraBoundComponent")>=1,"creative boss did not force Filename spawn-info")
 if entities[111] and not entities[111].tags.ew_des then
  assert(EntityGetFirstComponentIncludingDisabled(111,"BossHealthBarComponent")==nil,"gap natural alchemist visible to native fallback tracking")
  assert(#EntityGetComponentIncludingDisabled(111,"CameraBoundComponent")>=1,"gap boss did not force Filename spawn-info")
  native_consume_camera_bound(111)
  entities[111].tags.ew_des=true
  add_component(111,"VariableStorageComponent",{name="ew_gid_lid",value_string="natural-gid",value_bool=true},true,"")
 end
 if not loaded_authority_once then
  loaded_authority_once=true
  local loaded=EntityLoad("data/entities/animals/boss_alchemist/boss_alchemist.xml",0,0)
  assert(loaded==105 and EntityGetFirstComponentIncludingDisabled(105,"BossHealthBarComponent")==nil,
   "EntityLoad authority reconstruction was not hidden before native track_entity")
  assert(#EntityGetComponentIncludingDisabled(105,"CameraBoundComponent")>=1,"EntityLoad boss did not force Filename spawn-info")
  native_consume_camera_bound(105)
  entities[105].tags.ew_des=true
  add_component(105,"VariableStorageComponent",{name="ew_gid_lid",value_string="authority-file-gid",value_bool=true},true,"")

  local deser=EwextDeserialize("serialized-boss")
  assert(deser==106 and EntityGetFirstComponentIncludingDisabled(106,"BossHealthBarComponent")==nil,
   "EwextDeserialize authority reconstruction was not hidden before native track_entity")
  assert(#EntityGetComponentIncludingDisabled(106,"CameraBoundComponent")>=1,"deserialized boss did not force Filename spawn-info")
  native_consume_camera_bound(106)
  entities[106].tags.ew_des=true
  add_component(106,"VariableStorageComponent",{name="ew_gid_lid",value_string="authority-ser-gid",value_bool=true},true,"")
 end
 if track_creative_now then
  native_consume_camera_bound(101)
  entities[101].tags.ew_des=true
  add_component(101,"VariableStorageComponent",{name="ew_gid_lid",value_string="creative-gid",value_bool=true},true,"")
  native_consume_camera_bound(107)
  entities[107].tags.ew_des=true
  add_component(107,"VariableStorageComponent",{name="ew_gid_lid",value_string="creative-kolmi-gid",value_bool=true},true,"")
 end
end

local module=assert(loadfile(root.."/files/integrations/ew/boss_global_demote.lua"))()
local ok,reason=module.install()
assert(ok and reason=="installed","install failed: "..tostring(reason))

-- Normal top-level EW discovery. Kolmisilma and boss_limbs bypass demotion.
ewext.module_on_new_entity({101,102,103,107,108,109,110},7)
assert(original_new_calls==1,"native new entity wrapper did not delegate")
assert(module.pending_count_for_test()==2,"normal boss + creative Kolmi should be pending")
assert(EntityGetFirstComponentIncludingDisabled(101,"BossDragonComponent")==202,"BossDragon ID changed after enqueue")
assert(EntityGetFirstComponent(101,"BossDragonComponent")==nil,"BossDragon restored immediately after on_new_entity")
assert(EntityGetFirstComponentIncludingDisabled(102,"DamageModelComponent")~=nil,"ordinary entity mutated")
assert(EntityGetFirstComponentIncludingDisabled(103,"BossHealthBarComponent")~=nil,"remote boss mutated")
assert(EntityGetFirstComponentIncludingDisabled(107,"BossHealthBarComponent")==nil,"creative Kolmi restored before native tracking")
assert(EntityGetFirstComponentIncludingDisabled(108,"BossHealthBarComponent")==304,"boss_limbs mutated outside native call")
assert(EntityGetFirstComponentIncludingDisabled(109,"BossHealthBarComponent")==309,"natural Kolmi mutated outside native call")
assert(EntityGetFirstComponentIncludingDisabled(110,"StreamingKeepAliveComponent")==306 and ComponentGetIsEnabled(306)==true,"ordinary keepalive-only mob was demoted")
assert(tonumber(globals["mcm21_boss_wait_kill_bypass_v1"] or "0")>=2,"natural wait-for-kill bosses were not bypassed")
assert(globals["mcm27_creative_kolmi_non_global_v1"]=="1","creative Kolmi was not opted into non-global classification")

-- Natural Alchemist appears after Lua discovery but before native update.
ensure_entity(104,{boss=true,miniboss=true},"data/entities/animals/boss_alchemist/boss_alchemist.xml")
add_component(104,"BossHealthBarComponent",{},true,"",209)
add_component(104,"DamageModelComponent",{hp="40",wait_for_kill_flag_on_death=false},true,"",210)
assert(module.last_seen_entity_id_for_test()==110,"Lua discovery high-water mark incorrect")
-- Use a newer id because 104 is below current high-water in this deterministic mock.
entities[111]=entities[104]; entities[104]=nil
for _,cid in ipairs(entities[111].components) do comps[cid].entity=111 end

ewext.module_on_world_update()
assert(original_update_calls==1,"native update did not run")
assert(module.pending_count_for_test()==2,"budget-delayed normal boss + creative Kolmi should remain pending")
assert(EntityGetFirstComponentIncludingDisabled(111,"BossHealthBarComponent")~=nil,"gap natural boss components not restored after native GID")
assert(EntityGetFirstComponentIncludingDisabled(105,"BossHealthBarComponent")~=nil,"EntityLoad authority boss not restored")
assert(EntityGetFirstComponentIncludingDisabled(106,"BossHealthBarComponent")~=nil,"deserialize authority boss not restored")
assert(globals["mcm21_boss_global_gap_hidden_v1"]=="1","one-frame native gap was not caught")
assert(globals["mcm21_boss_global_load_hidden_v1"]=="1","EntityLoad authority path was not caught")
assert(globals["mcm21_boss_global_deserialize_hidden_v1"]=="1","deserialize authority path was not caught")
assert(raw_entity_load_calls==1 and raw_deserialize_calls==1,"wrapped native spawn functions did not delegate exactly once")

frame=101
track_creative_now=true
ewext.module_on_world_update()
assert(original_update_calls==2,"second native update did not run")
assert(module.pending_count_for_test()==0,"tracked creative boss was not restored")
assert(EntityGetFirstComponentIncludingDisabled(101,"BossDragonComponent")==202,"BossDragon original component ID was not preserved")
assert(EntityGetFirstComponentIncludingDisabled(101,"StreamingKeepAliveComponent")==201,"KeepAlive original component ID was not preserved")
assert(ComponentGetIsEnabled(202)==true and ComponentGetIsEnabled(201)==true,"preserved boss components were not re-enabled")
local health=assert(EntityGetFirstComponentIncludingDisabled(101,"BossHealthBarComponent"),"healthbar was not recreated")
assert(health~=203,"test expected healthbar recreation only")
assert(ComponentGetValue(health,"gui")=="0" and ComponentGetValue(health,"in_world")=="1",
    "restoration changed authored worm-style in-world bar into a GUI bar")
assert(ComponentGetValue(health,"gui_max_distance_visible")=="600","healthbar range changed")
assert(ComponentGetValue(202,"speed")=="8","BossDragon authored speed changed")
assert(ComponentGetValue(202,"part_distance")=="56","BossDragon authored part_distance changed")
assert(EntityGetFirstComponentIncludingDisabled(107,"StreamingKeepAliveComponent")==301,"creative Kolmi KeepAlive component ID changed")
assert(ComponentGetIsEnabled(301)==false,"creative Kolmi pre-fight KeepAlive state was not restored")
local kolmi_health=assert(EntityGetFirstComponentIncludingDisabled(107,"BossHealthBarComponent"),"creative Kolmi healthbar was not recreated")
assert(kolmi_health~=302,"creative Kolmi test expected healthbar recreation")
assert(ComponentGetIsEnabled(kolmi_health)==false,"creative Kolmi healthbar pre-fight enabled state changed")
assert(EntityGetFirstComponentIncludingDisabled(109,"BossHealthBarComponent")==309,"natural Kolmi component changed")
assert(ComponentGetTags(202):find("dragon_tag",1,true),"BossDragon component tags changed")
assert(tonumber(globals["mcm21_boss_global_hidden_v1"] or "0")==5,"hide counter mismatch")
assert(tonumber(globals["mcm21_boss_global_restored_v1"] or "0")==5,"restore counter mismatch")
assert(tonumber(globals["mcm21_boss_filename_spawninfo_v1"] or "0")==5,"Filename spawn-info was not forced for all demoted bosses")

io.write("ew_boss_global_demote=PASS keepalive_only_mob_untouched=true wait_kill_bypass=true creative_kolmi_non_global=true natural_kolmi_preserved=true boss_limbs_preserved=true dragon_id_preserved=true keepalive_id_preserved=true healthbar_only_recreated=true filename_spawninfo=true native_gap=true authority_paths=true remote_untouched=true ordinary_untouched=true\n")
