local root=assert(arg[1],"root required")
local entity=77
local reference=90
local bootstrap_component=700
local frame=100
local alive={[entity]=true,[reference]=true}
local tags={[entity]={},[reference]={}}
local components={
 [501]={type="VariableStorageComponent",values={name="mcm_creative_kolmi_reference_id_v3",value_int=reference}},
 [bootstrap_component]={type="LuaComponent",values={}},
}
local entity_components={[entity]={501,bootstrap_component},[reference]={}}
local removed={}
local created={}
local next_entity=900
local ew_on=true

local real_dofile=dofile
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/integrations/ew/runtime.lua" then
  return {enabled=function() return ew_on end}
 end
 return real_dofile(path)
end

function GetUpdatedEntityID() return entity end
function GetUpdatedComponentID() return bootstrap_component end
function EntityGetIsAlive(e) return alive[e]==true end
function GameGetFrameNum() return frame end
function EntityGetComponentIncludingDisabled(e,ctype)
 local out={}
 for _,id in ipairs(entity_components[e] or {}) do if components[id] and components[id].type==ctype then out[#out+1]=id end end
 return out
end
function ComponentGetValue2(id,name) return components[id] and components[id].values[name] end
function EntityAddComponent2(e,ctype,values)
 local id=1000+#(entity_components[e] or {})
 while components[id] do id=id+1 end
 components[id]={type=ctype,values=values or {}}
 entity_components[e]=entity_components[e] or {};table.insert(entity_components[e],id)
 return id
end
function EntityGetTransform(e) return 10,20 end
function EntityCreateNew(name)
 next_entity=next_entity+1;alive[next_entity]=true;tags[next_entity]={};entity_components[next_entity]={};created[next_entity]={name=name};return next_entity
end
function EntitySetTransform(e,x,y) created[e]=created[e] or {};created[e].x=x;created[e].y=y end
function EntityAddTag(e,tag) tags[e]=tags[e] or {};tags[e][tag]=true end
function EntityRemoveComponent(e,c) removed[c]=true;components[c]=nil end

local script=root.."/files/features/creatures/kolmi_creative_bootstrap.lua"
assert(loadfile(script))()
assert(next_entity==900 and not removed[bootstrap_component],"Kolmi controller started before owner GID existed")

components[502]={type="VariableStorageComponent",values={name="ew_gid_lid",value_string="123",value_bool=false}}
table.insert(entity_components[entity],502)
frame=101
assert(loadfile(script))()
assert(next_entity==900 and not removed[bootstrap_component],"remote Kolmi replica started the encounter")

components[502].values.value_bool=true
frame=102
assert(loadfile(script))()
assert(next_entity==901,"external Kolmi encounter controller was not created")
local controller=901
assert(tags[controller].ew_no_enemy_sync==true,"controller can enter DES enemy sync")
assert(tags[entity].mcm_creative_kolmi_activation_queued_v3==true,"boss activation queue marker missing")
assert(created[controller].x==10 and created[controller].y==100,"controller does not sit at authored Sampo +80 offset")
local boss_id,ref_id,controller_lua=nil,nil,nil
for _,id in ipairs(entity_components[controller] or {}) do
 local c=components[id]
 if c.type=="VariableStorageComponent" and c.values.name=="mcm_kolmi_boss_id_v3" then boss_id=c.values.value_int end
 if c.type=="VariableStorageComponent" and c.values.name=="mcm_kolmi_reference_id_v3" then ref_id=c.values.value_int end
 if c.type=="LuaComponent" then controller_lua=c end
end
assert(boss_id==entity and ref_id==reference,"controller did not receive exact boss/reference ids")
assert(controller_lua and controller_lua.values.script_source_file=="mods/metamorph_creative_menu/files/features/creatures/kolmi_encounter_start.lua","controller does not execute stock-pickup bridge")
assert(controller_lua.values.execute_on_added==false and controller_lua.values.execute_every_n_frame==1,"controller did not yield to an independent next-frame VM update")
assert(removed[bootstrap_component]==true,"bootstrap stayed on boss after controller handoff")

-- Singleplayer branch: no GID is required, but it must yield one frame after EntityLoad.
local entity2=177
local reference2=190
alive[entity2]=true;alive[reference2]=true;tags[entity2]={};entity_components[entity2]={}
components[601]={type="VariableStorageComponent",values={name="mcm_creative_kolmi_reference_id_v3",value_int=reference2}}
components[701]={type="LuaComponent",values={}}
entity_components[entity2]={601,701}
ew_on=false
function GetUpdatedEntityID() return entity2 end
function GetUpdatedComponentID() return 701 end
frame=200
assert(loadfile(script))()
local before=next_entity
frame=201
assert(loadfile(script))()
assert(next_entity==before+1,"singleplayer Kolmi did not start after authored init frame")

dofile=real_dofile
print("creature_kolmi_bootstrap=PASS requires_owner_gid=true remote_replica_blocked=true external_vm_controller=true singleplayer_deferred=true")
