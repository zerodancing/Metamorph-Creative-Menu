local root = assert(arg[1], "root")
local native_dofile = dofile
dofile = function(path)
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end
local component = 10
local entity = 1
local values = {[component]={pixel_gravity=350}}
local meta = {[component]={run_velocity=100,velocity_min_x=-100,velocity_max_x=100}}
local objects = {[component]={damage_multipliers={explosion=1.0}}}
local enabled = {[component]=true}
local alive = {[entity]=true}
local next_entity = 100
local next_component = 200
local parents={[300]=9}
local entity_tags={[entity]={baseline=true}}
local component_tags={[component]={baseline_component=true}}
local block_gravity_restore=false
alive[9]=true; alive[300]=true

function ComponentGetTypeName(id)
    if id == component and values[id] then return "CharacterPlatformingComponent" end
    if id >= 200 and values[id] then return "LuaComponent" end
    return ""
end
function ComponentGetValue2(id, field) return values[id] and values[id][field] end
function ComponentSetValue2(id, field, value)
 if block_gravity_restore and id==component and field=="pixel_gravity" and tonumber(value)==350 then return end
 values[id][field]=value
end
function ComponentGetValue(id, field) local v=values[id] and values[id][field]; return v==nil and "" or tostring(v) end
function ComponentSetValue(id, field, value) values[id][field]=value end
function ComponentGetMetaCustom(id, field) return meta[id] and meta[id][field] end
function ComponentSetMetaCustom(id, field, value) meta[id][field]=value end
function ComponentObjectGetValue2(id, object, field) return objects[id] and objects[id][object] and objects[id][object][field] end
function ComponentObjectSetValue2(id, object, field, value) objects[id][object][field]=value end
function ComponentObjectGetValue(id, object, field) return tostring(ComponentObjectGetValue2(id,object,field) or "") end
function ComponentObjectSetValue(id, object, field, value) objects[id][object][field]=tonumber(value) or value end
function ComponentGetIsEnabled(id) return enabled[id] == true end
function EntitySetComponentIsEnabled(_, id, state) enabled[id]=state==true end
function EntityGetAllComponents(_) return {component} end
function ComponentHasTag(id,tag) return component_tags[id] and component_tags[id][tag]==true or false end
function ComponentAddTag(id,tag) component_tags[id]=component_tags[id] or {}; component_tags[id][tag]=true end
function ComponentRemoveTag(id,tag) if component_tags[id] then component_tags[id][tag]=nil end end
function EntityHasTag(id,tag) return entity_tags[id] and entity_tags[id][tag]==true or false end
function EntityAddTag(id,tag) entity_tags[id]=entity_tags[id] or {}; entity_tags[id][tag]=true end
function EntityRemoveTag(id,tag) if entity_tags[id] then entity_tags[id][tag]=nil end end
function EntitySetComponentsWithTagEnabled() end
function EntityLoad() next_entity=next_entity+1; alive[next_entity]=true; return next_entity end
function EntityCreateNew() next_entity=next_entity+1; alive[next_entity]=true; return next_entity end
function EntityAddComponent2(e) next_component=next_component+1; values[next_component]={}; enabled[next_component]=true; return next_component end
function EntityAddComponent(e) return EntityAddComponent2(e) end
function EntityRemoveComponent(e,c) values[c]=nil; enabled[c]=nil end
function EntityGetParent(e) return parents[e] or 0 end
function EntityAddChild(parent,child) parents[child]=parent end
function EntityRemoveFromParent(child) parents[child]=0 end
function EntityGetIsAlive(id) return alive[id] == true end
function EntityGetComponentIncludingDisabled() return {} end
function EntityKill(id) alive[id]=false end

local journal = assert(dofile(root .. "/files/features/perks/transactions/mutation_journal.lua"))
local first={}
assert(journal.prepare(first))
assert(journal.start_capture(first,_G))
ComponentSetMetaCustom(component,"run_velocity",110)
ComponentSetValue2(component,"pixel_gravity",0)
ComponentObjectSetValue2(component,"damage_multipliers","explosion",0.9)
local first_created=EntityLoad("perk_child.xml",0,0)
local first_component=EntityAddComponent2(entity,"LuaComponent",{})
EntityAddChild(entity,300)
EntityAddTag(entity,"perk_added")
EntityRemoveTag(entity,"baseline")
ComponentAddTag(component,"perk_component")
ComponentRemoveTag(component,"baseline_component")
journal.stop_capture(first)
local d1={transaction_id=first.transaction_id}; journal.attach_delta(d1,first)
assert(#d1.mutations==8,"expected meta/value/object/parent/entity-tag/component-tag mutations")
assert(#d1.created_entities==1 and d1.created_entities[1]==first_created,"created entity not owned")
assert(#d1.created_components==1 and d1.created_components[1].component==first_component,"created component not owned")
assert(parents[300]==entity,"existing entity was not reparented during pickup")

local second={}
assert(journal.prepare(second))
assert(journal.start_capture(second,_G))
ComponentSetMetaCustom(component,"run_velocity",121)
ComponentObjectSetValue2(component,"damage_multipliers","explosion",0.81)
journal.stop_capture(second)
local d2={transaction_id=second.transaction_id}; journal.attach_delta(d2,second)

-- Removing an older overlapping owner must not overwrite the newer perk.
journal.revert_delta(d1)
assert(meta[component].run_velocity==121,"older layer clobbered newer speed")
assert(math.abs(objects[component].damage_multipliers.explosion-0.81)<1e-9,"older layer clobbered newer multiplier")
assert(values[component].pixel_gravity==350,"non-overlapped gravity was not restored")
assert(alive[first_created]==false,"exact perk-created root entity survived removal")
assert(values[first_component]==nil,"component created on an existing entity survived removal")
assert(parents[300]==9,"pre-existing entity parent was not restored")
assert(EntityHasTag(entity,"baseline") and not EntityHasTag(entity,"perk_added"),"entity tags were not restored")
assert(ComponentHasTag(component,"baseline_component") and not ComponentHasTag(component,"perk_component"),"component tags were not restored")

-- Removing the final owner restores the original baseline even after stacking.
journal.revert_delta(d2)
assert(meta[component].run_velocity==100,"stacked speed baseline not restored")
assert(math.abs(objects[component].damage_multipliers.explosion-1.0)<1e-9,"stacked object baseline not restored")
assert(journal.active_property_count()==0,"property ownership leaked")

-- Scalar rollback must keep ownership when the setter silently fails readback, then
-- succeed on retry instead of forgetting a mutation that still exists in the player.
local third={}
assert(journal.prepare(third))
assert(journal.start_capture(third,_G))
ComponentSetValue2(component,"pixel_gravity",50)
journal.stop_capture(third)
local d3={transaction_id=third.transaction_id}; journal.attach_delta(d3,third)
block_gravity_restore=true
local failed,failed_reason=journal.revert_delta(d3)
assert(failed==false and string.find(tostring(failed_reason),"property_restore",1,true),"silent scalar restore failure reported success")
assert(values[component].pixel_gravity==50,"fixture unexpectedly restored blocked scalar")
assert(journal.active_property_count()==1,"failed scalar restore discarded ownership")
block_gravity_restore=false
local retried,retry_reason=journal.revert_delta(d3)
assert(retried==true,retry_reason)
assert(values[component].pixel_gravity==350 and journal.active_property_count()==0,"scalar retry did not restore baseline and release ownership")
print("perk_mutation_journal=PASS meta=true object=true overlap=true created_root=true component=true reparent=true tags=true scalar_retry=true")
