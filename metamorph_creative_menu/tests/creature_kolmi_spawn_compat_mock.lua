local root=assert(arg[1],"root required")
local kolmi=77
local ordinary=88
local components={}
local entity_components={[kolmi]={},[ordinary]={}}
local tags={[kolmi]={},[ordinary]={}}
local alive={[kolmi]=true,[ordinary]=true}
local next_component=100
local next_entity=200
local loads={}

function EntityGetIsAlive(e) return alive[e]==true end
function EntityGetComponentIncludingDisabled(e,ctype)
 local out={}
 for _,id in ipairs(entity_components[e] or {}) do
  if components[id] and components[id].type==ctype then out[#out+1]=id end
 end
 return out
end
function ComponentGetValue2(id,name) return components[id] and components[id].values[name] end
function ComponentSetValue2(id,name,value) components[id].values[name]=value end
function ComponentAddTag(id,tag) components[id].tags[tag]=true end
function EntityAddComponent2(e,ctype,values)
 next_component=next_component+1
 components[next_component]={type=ctype,values=values or {},tags={}}
 if type(values)=="table" and type(values._tags)=="string" then
  for tag in string.gmatch(values._tags,"[^,]+") do components[next_component].tags[tag]=true end
 end
 entity_components[e]=entity_components[e] or {}
 table.insert(entity_components[e],next_component)
 return next_component
end
function EntityAddTag(e,tag) tags[e]=tags[e] or {}; tags[e][tag]=true end
function EntityHasTag(e,tag) return tags[e] and tags[e][tag]==true or false end
function EntityLoad(path,x,y)
 next_entity=next_entity+1
 alive[next_entity]=true; tags[next_entity]={}; entity_components[next_entity]={}
 loads[#loads+1]={id=next_entity,path=path,x=x,y=y}
 return next_entity
end

local module=assert(loadfile(root.."/files/features/creatures/spawn_compat.lua"))()
local ok,reason=module.after_spawn(module.KOLMI_PATH,kolmi,123.5,-44.25)
assert(ok and reason=="creative_kolmi_prepared","creative Kolmi preparation failed")
assert(EntityHasTag(kolmi,module.CREATIVE_MARKER),"creative Kolmi marker missing")
assert(not EntityHasTag(kolmi,"boss_centipede_active"),"Kolmi was activated before stock Sampo entrypoint")
assert(#loads==1 and loads[1].path==module.REF_PATH,"authored Kolmi reference_point was not spawned")
assert(EntityHasTag(loads[1].id,module.CREATIVE_REF_TAG),"creative reference marker missing")
assert(EntityHasTag(loads[1].id,"ew_synced"),"creative reference is not published for peer authority transfer")

local ref_var=nil
local ref_id_var=nil
local bootstrap=nil
for _,id in ipairs(EntityGetComponentIncludingDisabled(kolmi,"VariableStorageComponent")) do
 local c=components[id]
 if c.values.name==module.CREATIVE_REF_VAR then ref_var=c end
 if c.values.name==module.CREATIVE_REF_ID_VAR then ref_id_var=c end
end
for _,id in ipairs(EntityGetComponentIncludingDisabled(kolmi,"LuaComponent")) do
 local c=components[id]
 if c.values.script_source_file==module.BOOTSTRAP then bootstrap=c end
end
assert(ref_var~=nil and ref_var.tags.ew_synced_var==true,"creative Kolmi coordinates are not authority-transfer synced")
local x,y=tostring(ref_var.values.value_string):match("^([^,]+),([^,]+)$")
assert(math.abs(tonumber(x)-123.5)<0.001 and math.abs(tonumber(y)+44.25)<0.001,"creative arena reference coordinates changed")
assert(ref_id_var~=nil and tonumber(ref_id_var.values.value_int)==loads[1].id,"local authored reference id was not retained")
assert(ref_id_var.tags.ew_remove_on_send==true,"peer-local reference id leaked into DES serialization")
assert(bootstrap~=nil,"deferred stock-Sampo bootstrap component missing")

local before_components=#(entity_components[ordinary] or {})
local before_loads=#loads
ok,reason=module.after_spawn("data/entities/animals/sheep.xml",ordinary,0,0)
assert(ok and reason=="ordinary","ordinary creature compatibility result changed")
assert(#(entity_components[ordinary] or {})==before_components and #loads==before_loads,"ordinary creature was mutated by Kolmi compatibility")

print("creature_kolmi_spawn_compat=PASS pre_fight_untouched=true authored_reference=true synced_reference=true stock_pickup_deferred=true ordinary_untouched=true")
