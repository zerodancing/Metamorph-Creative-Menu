local root=assert(arg[1],"root required")
local natural=50
local reference=51
local created=77
local alive={[natural]=true,[reference]=true,[created]=true}
local tags={
 [natural]={boss_centipede=true},
 [reference]={reference=true},
 [created]={},
}
local pos={[natural]={100,200},[reference]={100,200},[created]={100,200}}
local comps={}
local by_entity={[natural]={},[reference]={},[created]={}}
local next_comp=100
local killed={}
local notified={}
local globals={mcm31_kolmi_lifecycle_ready_v1="1"}

local function add_comp(e,t,v)
 next_comp=next_comp+1
 comps[next_comp]={type=t,values=v or {},tags={}}
 by_entity[e]=by_entity[e] or {}; table.insert(by_entity[e],next_comp)
 return next_comp
end
add_comp(natural,"VariableStorageComponent",{name="ew_gid_lid",value_string="123456",value_bool=true})
add_comp(natural,"DamageModelComponent",{wait_for_kill_flag_on_death=true,kill_now=false})
add_comp(natural,"LuaComponent",{script_death="death.lua",script_damage_received="damage.lua",script_damage_about_to_be_received="about.lua"})

-- Real menu VM: ewext exists only in EW's VM. TEST 30 silently killed the global
-- arena boss here without ever queuing DeleteEntity. Keep this regression realistic.
ewext=nil
function GlobalsGetValue(k,d) return globals[k] or d end
function GlobalsSetValue(k,v) globals[k]=v end
function EntityGetIsAlive(e) return alive[e]==true end
function EntityGetTransform(e) local p=pos[e] or {0,0}; return p[1],p[2] end
function EntityHasTag(e,t) return tags[e] and tags[e][t]==true or false end
function EntityAddTag(e,t) tags[e]=tags[e] or {}; tags[e][t]=true end
function EntityGetWithTag(tag)
 local out={}
 for e,tt in pairs(tags) do if alive[e] and tt[tag] then out[#out+1]=e end end
 table.sort(out); return out
end
function EntityGetComponentIncludingDisabled(e,t)
 local out={}; for _,id in ipairs(by_entity[e] or {}) do if comps[id] and comps[id].type==t then out[#out+1]=id end end; return out
end
function EntityGetFirstComponentIncludingDisabled(e,t) local v=EntityGetComponentIncludingDisabled(e,t); return v[1] end
function ComponentGetValue2(id,n) return comps[id] and comps[id].values[n] end
function ComponentSetValue2(id,n,v) comps[id].values[n]=v end
function ComponentAddTag(id,t) comps[id].tags[t]=true end
function EntitySetComponentIsEnabled() end
function EntityRemoveComponent(e,id) comps[id]=nil end
function EntityKill(e) alive[e]=false; killed[#killed+1]=e end
function EntityAddComponent2(e,t,v) return add_comp(e,t,v) end
function EntityLoad(path,x,y) error("reference should be reused, not loaded: "..tostring(path)) end

local m=assert(loadfile(root.."/files/features/creatures/spawn_compat.lua"))()
local ctx=m.before_spawn(m.KOLMI_PATH,100,200)
assert(type(ctx)=="table" and ctx.kind=="kolmi","Kolmi preflight did not return Kolmi context")
assert(ctx.reference_id==reference,"existing authored arena reference was not reused")
assert(ctx.replaced_entity==natural,"existing authored Kolmi was not identified for replacement")
assert(alive[natural]==true,"tracked arena body was killed before EW acknowledged removal of its GID")
assert(globals["mcm31_kolmi_retire_request_v1_50"]=="123456",
 "menu did not hand the exact GID to the EW VM")
assert(#killed==0,"a retirement request must not kill the local body")
local ok,reason=m.after_spawn(m.KOLMI_PATH,created,100,200,ctx)
assert(ok and reason=="creative_kolmi_prepared","creative replacement preparation failed")
assert(EntityHasTag(created,m.CREATIVE_MARKER),"creative replacement marker missing")
local ref_id=nil
for _,id in ipairs(EntityGetComponentIncludingDisabled(created,"VariableStorageComponent")) do
 if ComponentGetValue2(id,"name")==m.CREATIVE_REF_ID_VAR then ref_id=ComponentGetValue2(id,"value_int") end
end
assert(tonumber(ref_id)==reference,"creative replacement did not retain authored arena reference")
-- If EW's lifecycle bridge is unavailable, reuse the retained root. Never return a
-- new-spawn context after failure to retire it.
globals.mcm31_kolmi_lifecycle_ready_v1=""
local fallback=m.before_spawn(m.KOLMI_PATH,100,200)
assert(fallback.kind=="reuse" and fallback.entity==natural,"failed retirement created another arena boss")
assert(alive[natural],"unavailable EW bridge killed a tracked root")
print("creature_kolmi_arena_dedupe=PASS separate_vm=true waits_for_des=true reference_reused=true failure_reuses=true")
