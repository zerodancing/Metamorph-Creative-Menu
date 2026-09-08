local root=assert(arg[1],"root required")

local initf=assert(io.open(root.."/init.lua","rb"))
local init_source=initf:read("*a");initf:close()
assert(not string.find(init_source,"kolmi_update_append",1,true),"MCM still appends into boss_centipede_update.lua")
assert(not string.find(init_source,"kolmi_creative_update.append",1,true),"legacy Kolmi update patch is still wired")
local controller=500
local boss=77
local reference=90
local player=10
local other_boss=78
local other_ref=91
local alive={[controller]=true,[boss]=true,[reference]=true,[player]=true,[other_boss]=true,[other_ref]=true}
local positions={[controller]={100,280},[boss]={100,200},[reference]={100,200},[player]={120,210},[other_boss]={999,999},[other_ref]={999,999}}
local tags={[boss]={sampo_or_boss=true},[other_boss]={sampo_or_boss=true},[reference]={reference=true},[other_ref]={reference=true},[player]={player_unit=true}}
local components={
 [1]={name="mcm_kolmi_boss_id_v3",value_int=boss},
 [2]={name="mcm_kolmi_reference_id_v3",value_int=reference},
}
local globals={}
local added_components={}
local next_component=100
local call_snapshot=nil
local original_get=nil
local killed={}
local dofile_path=nil
local important={}

function GetUpdatedEntityID() return controller end
function EntityGetComponentIncludingDisabled(e,ctype) if e==controller and ctype=="VariableStorageComponent" then return {1,2} end return {} end
function ComponentGetValue2(id,name) return components[id] and components[id][name] end
function EntityGetIsAlive(e) return alive[e]==true end
function EntityGetTransform(e) local p=positions[e];return p[1],p[2] end
function EntityGetWithTag(tag)
 local out={}
 for e,t in pairs(tags) do if alive[e] and t[tag] then out[#out+1]=e end end
 table.sort(out)
 return out
end
original_get=EntityGetWithTag
function EntityAddTag(e,tag) tags[e]=tags[e] or {};tags[e][tag]=true end
function GlobalsSetValue(k,v) globals[k]=v end
function GameGetFrameNum() return 123 end
function EntityAddComponent2(e,ctype,values)
 next_component=next_component+1
 added_components[#added_components+1]={entity=e,ctype=ctype,values=values,id=next_component}
 return next_component
end
function EntityKill(e) alive[e]=false;killed[e]=true end
function GamePrintImportant(a,b) important={a,b} end

local real_dofile=dofile
dofile=function(path)
 dofile_path=path
 assert(path=="data/entities/animals/boss_centipede/sampo_pickup.lua","controller loaded a replacement instead of stock Sampo pickup")
 function item_pickup(entity_item,entity_who_picked,name)
  call_snapshot={
   entity_item=entity_item,player=entity_who_picked,name=name,
   bosses=EntityGetWithTag("sampo_or_boss"),refs=EntityGetWithTag("reference"),players=EntityGetWithTag("player_unit")
  }
 end
end

assert(loadfile(root.."/files/features/creatures/kolmi_encounter_start.lua"))()
dofile=real_dofile
assert(dofile_path=="data/entities/animals/boss_centipede/sampo_pickup.lua","stock Sampo entrypoint was not loaded")
assert(call_snapshot~=nil,"stock Sampo item_pickup was not called")
assert(call_snapshot.entity_item==controller and call_snapshot.player==player,"stock pickup call did not use external controller/local player")
assert(#call_snapshot.bosses==1 and call_snapshot.bosses[1]==boss,"stock pickup could activate an unrelated Kolmi/Sampo")
assert(#call_snapshot.refs==1 and call_snapshot.refs[1]==reference,"stock pickup did not receive the authored creative reference")
assert(#call_snapshot.players==1 and call_snapshot.players[1]==player,"stock pickup did not receive the selected combat player")
assert(EntityGetWithTag==original_get,"controller leaked its temporary EntityGetWithTag isolation into the VM")
assert(tags[boss].mcm_creative_kolmi_encounter_started_v3==true,"successful stock pickup did not mark encounter started")
assert(globals.mcm25_kolmi_encounter_status_v1=="started_via_stock_sampo_pickup","encounter status is not stock-pickup success")
assert(killed[controller]~=true,"controller died before combat startup verification")
local saw_verify=false
local saw_start=false
for _,record in ipairs(added_components) do
 if record.entity==controller and record.ctype=="LuaComponent" and record.values.script_source_file=="mods/metamorph_creative_menu/files/features/creatures/kolmi_combat_verify.lua" then
  saw_verify=true
 end
 if record.entity==controller and record.ctype=="VariableStorageComponent" and record.values.name=="mcm_kolmi_verify_start_frame_v1" and record.values.value_int==123 then
  saw_start=true
 end
end
assert(saw_verify,"successful stock pickup did not schedule combat verifier")
assert(saw_start,"combat verifier start frame was not recorded")
assert(#important==0,"successful controller printed an error")
print("creature_kolmi_encounter_controller=PASS stock_sampo_pickup=true external_vm=true isolated_roots=true globals_restored=true stock_update_unpatched=true verifier_scheduled=true")
