local root=assert(arg[1],"root required")
local script=root.."/files/features/creatures/kolmi_combat_verify.lua"
local controller=500
local boss=77
local alive={[controller]=true,[boss]=true}
local frame=100
local next_id=1000
local components={
 [1]={owner=controller,type="VariableStorageComponent",values={name="mcm_kolmi_boss_id_v3",value_int=boss}},
 [2]={owner=controller,type="VariableStorageComponent",values={name="mcm_kolmi_verify_start_frame_v1",value_int=100}},
 [3]={owner=boss,type="VariableStorageComponent",values={name="initialized",value_bool=false}},
 [4]={owner=boss,type="LuaComponent",enabled=true,values={script_source_file="data/entities/animals/boss_centipede/boss_centipede_update.lua"}},
}
local entity_components={[controller]={1,2},[boss]={3,4}}
local globals={}
local removed={}
local added={}
local enabled={}

local function list(e,ctype)
 local out={}
 for _,id in ipairs(entity_components[e] or {}) do
  local c=components[id]
  if c and c.type==ctype then out[#out+1]=id end
 end
 return out
end
function GetUpdatedEntityID() return controller end
function GameGetFrameNum() return frame end
function EntityGetIsAlive(e) return alive[e]==true end
function EntityGetComponentIncludingDisabled(e,ctype) return list(e,ctype) end
function ComponentGetValue2(id,name) return components[id] and components[id].values[name] end
function ComponentSetValue2(id,name,value) components[id].values[name]=value end
function EntityRemoveComponent(e,id)
 removed[id]=true
 components[id]=nil
end
function EntityAddComponent2(e,ctype,values)
 next_id=next_id+1
 components[next_id]={owner=e,type=ctype,enabled=true,values=values or {}}
 entity_components[e]=entity_components[e] or {};table.insert(entity_components[e],next_id)
 added[#added+1]={id=next_id,entity=e,ctype=ctype,values=values or {}}
 return next_id
end
function EntitySetComponentIsEnabled(e,id,value) enabled[id]=value; if components[id] then components[id].enabled=value end end
function GlobalsSetValue(k,v) globals[k]=v end
function EntityKill(e) alive[e]=false end

-- During grace: no mutation.
assert(loadfile(script))()
assert(components[4]~=nil and #added==0,"verifier restarted authored VM before grace")

-- After grace, still uninitialized: stale authored VM is replaced once with exact stock path.
frame=109
assert(loadfile(script))()
assert(removed[4]==true,"stale combat LuaComponent was not removed")
local fresh=nil
for _,r in ipairs(added) do if r.ctype=="LuaComponent" then fresh=r end end
assert(fresh~=nil,"fresh combat LuaComponent not created")
assert(fresh.values.script_source_file=="data/entities/animals/boss_centipede/boss_centipede_update.lua","verifier substituted non-stock combat script")
assert(fresh.values.enable_coroutines==true and fresh.values.execute_on_added==true,"fresh combat VM lacks authored coroutine startup semantics")
assert(fresh.values.execute_every_n_frame==-1 and fresh.values.execute_times==1,"fresh combat VM execution contract changed")
assert(fresh.values.vm_type=="ONE_PER_COMPONENT_INSTANCE","fresh combat VM type changed")
assert(enabled[fresh.id]==true,"fresh combat VM was not explicitly enabled")
assert(globals.mcm25_kolmi_combat_status_v1=="restarted_component","restart status not published")

-- Simulate init_boss() running in the fresh VM; verifier must retire without touching combat.
components[3].values.value_bool=true
frame=110
assert(loadfile(script))()
assert(alive[controller]==false,"verifier survived after stock combat initialized")
assert(globals.mcm25_kolmi_combat_status_v1=="initialized_stock" or globals.mcm25_kolmi_combat_status_v1=="initialized_after_restart","initialized status missing")
print("creature_kolmi_combat_verify=PASS startup_grace=true stock_vm_restart_once=true no_phase_emulation=true")
