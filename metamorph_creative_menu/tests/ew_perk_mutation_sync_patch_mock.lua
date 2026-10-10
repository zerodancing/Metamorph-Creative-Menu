local root=assert(arg[1])
local patches=assert(dofile(root..'/files/integrations/ew/resilience_patches.lua'))

local source=[[
local rpc = net.new_rpc_namespace()
TEST_RPC = rpc
local module = {}
local function become_rat(entity_who_picked)
    local c=EntityGetFirstComponentIncludingDisabled(entity_who_picked,"CharacterPlatformingComponent")
    ComponentSetMetaCustom(c,"run_velocity",ComponentGetMetaCustom(c,"run_velocity")*1.15)
    ComponentSetMetaCustom(c,"velocity_min_x",ComponentGetMetaCustom(c,"velocity_min_x")*1.15)
    ComponentSetMetaCustom(c,"velocity_max_x",ComponentGetMetaCustom(c,"velocity_max_x")*1.15)
    local child=EntityLoad("data/entities/verlet_chains/tail/verlet_tail.xml",0,0); EntityAddChild(entity_who_picked,child)
end
local function become_fungus(entity_who_picked)
    EntitySetComponentsWithTagEnabled(entity_who_picked,"player_hat",true)
    EntitySetComponentsWithTagEnabled(entity_who_picked,"player_hat2_shadow",false)
    local c=EntityGetFirstComponentIncludingDisabled(entity_who_picked,"DamageModelComponent")
    ComponentObjectSetValue(c,"damage_multipliers","explosion",tostring(tonumber(ComponentObjectGetValue(c,"damage_multipliers","explosion"))*0.9))
end
local function become_luuki(entity_who_picked)
    EntitySetComponentsWithTagEnabled(entity_who_picked,"lukki_enable",true)
    local sprite=EntityGetFirstComponentIncludingDisabled(entity_who_picked,"SpriteComponent","lukki_disable")
    ComponentSetValue2(sprite,"alpha",0)
    local c=EntityGetFirstComponentIncludingDisabled(entity_who_picked,"CharacterPlatformingComponent")
    ComponentSetMetaCustom(c,"run_velocity",ComponentGetMetaCustom(c,"run_velocity")*1.1)
    ComponentSetMetaCustom(c,"velocity_min_x",ComponentGetMetaCustom(c,"velocity_min_x")*1.1)
    ComponentSetMetaCustom(c,"velocity_max_x",ComponentGetMetaCustom(c,"velocity_max_x")*1.1)
end
local function become_ghost(entity_who_picked)
    local a=EntityLoad("data/entities/misc/perks/ghostly_ghost.xml",0,0); EntityAddChild(entity_who_picked,a)
    local b=EntityLoad("data/entities/misc/perks/tiny_ghost_extra.xml",0,0); EntityAddChild(entity_who_picked,b)
    local c=EntityGetFirstComponentIncludingDisabled(entity_who_picked,"CharacterDataComponent")
    ComponentSetValue2(c,"fly_recharge_spd",ComponentGetValue2(c,"fly_recharge_spd")*1.15)
end
local function lose_halo() end
local function gain_halo() end
function rpc.send_mutations(ghost, luuki, rat, fungus, halo)
    local last = ctx.players[ctx.rpc_peer_id].mutations
    ctx.players[ctx.rpc_peer_id].mutations = { ghost = ghost, luuki = luuki, rat = rat, fungus = fungus, halo = halo }
    local ent = ctx.rpc_player_data.entity
    if ghost and not last.ghost then
        become_ghost(ent)
    end
    if luuki and not last.luuki then
        become_luuki(ent)
    end
    if rat and not last.rat then
        become_rat(ent)
    end
    if fungus and not last.fungus then
        become_fungus(ent)
    end
    if math.abs(halo) < 3 and math.abs(last.halo) >= 3 then
        lose_halo(ent)
    elseif math.abs(halo) >= 3 and math.abs(last.halo) < 3 then
        gain_halo(ent, halo >= 3)
    end
end
return module
]]
local patched,count=patches.patch_perk_mutation_sync_source(source)
assert(count==1 and string.find(patched,'mcm_perk_mutation_sync_v1',1,true),'mutation patch did not apply')

local component_type={[10]='CharacterPlatformingComponent',[11]='SpriteComponent',[12]='HatComponent',[13]='HatComponent',[14]='DamageModelComponent',[15]='CharacterDataComponent'}
local component_tags={[10]={lukki_enable=true},[11]={lukki_disable=true},[12]={player_hat=true},[13]={player_hat2_shadow=true}}
local enabled={[10]=false,[11]=true,[12]=false,[13]=true,[14]=true,[15]=true}
local meta={[10]={run_velocity=100,velocity_min_x=-100,velocity_max_x=100}}
local value={[11]={alpha=1},[15]={fly_recharge_spd=10}}
local object={[14]={explosion='1'}}
local alive={[1]=true}
local children={[1]={}}
local filenames={}
local next_entity=100
local globals={}

net={new_rpc_namespace=function() return {} end}
ctx={rpc_peer_id='peer',rpc_player_data={entity=1},players={peer={mutations={ghost=false,luuki=false,rat=false,fungus=false,halo=0}}}}
function GlobalsSetValue(k,v) globals[k]=tostring(v) end
function ComponentGetTypeName(c) return component_type[c] or '' end
function EntityGetAllComponents() return {10,11,12,13,14,15} end
function ComponentHasTag(c,t) return component_tags[c] and component_tags[c][t]==true or false end
function ComponentGetIsEnabled(c) return enabled[c]==true end
function EntitySetComponentIsEnabled(_,c,v) enabled[c]=v==true end
function EntitySetComponentsWithTagEnabled(_,tag,v) for c,tags in pairs(component_tags) do if tags[tag] then enabled[c]=v==true end end end
function EntityGetComponentIncludingDisabled(_,kind)
    local out={}; for c,t in pairs(component_type) do if t==kind then out[#out+1]=c end end; table.sort(out); return out
end
function EntityGetFirstComponentIncludingDisabled(e,kind,tag)
    for _,c in ipairs(EntityGetComponentIncludingDisabled(e,kind)) do if tag==nil or ComponentHasTag(c,tag) then return c end end
end
function ComponentGetMetaCustom(c,f) return meta[c] and meta[c][f] end
function ComponentSetMetaCustom(c,f,v) meta[c][f]=v end
function ComponentGetValue2(c,f) return value[c] and value[c][f] end
function ComponentSetValue2(c,f,v) value[c]=value[c] or {}; value[c][f]=v end
function ComponentObjectGetValue(c,_,f) return object[c] and object[c][f] end
function ComponentObjectSetValue(c,_,f,v) object[c][f]=v end
function EntityLoad(path) next_entity=next_entity+1; alive[next_entity]=true; filenames[next_entity]=path; return next_entity end
function EntityAddChild(parent,child) children[parent]=children[parent] or {}; children[parent][#children[parent]+1]=child end
function EntityGetAllChildren(parent) local out={}; for _,c in ipairs(children[parent] or {}) do if alive[c] then out[#out+1]=c end end; return out end
function EntityGetFilename(e) return filenames[e] or '' end
function EntityKill(e) alive[e]=false end

local loader=loadstring or load
local chunk,err=loader(patched,'patched_perk_mutations')
assert(chunk,err); chunk()
assert(globals.mcm_perk_mutation_sync_loaded_v1=='1','loaded marker missing')
TEST_RPC.send_mutations(true,true,true,true,0)
assert(math.abs(meta[10].run_velocity-126.5)<0.0001,'combined rat/lukki mutation not applied')
assert(enabled[10]==true and enabled[12]==true and enabled[13]==false and value[11].alpha==0,'mutation presentation not applied')
assert(math.abs(tonumber(object[14].explosion)-0.9)<0.0001 and math.abs(value[15].fly_recharge_spd-11.5)<0.0001,'mutation stats not applied')
assert(#EntityGetAllChildren(1)==3,'mutation children not applied')
-- Removing Lukki while Rat remains must keep Rat's 1.15 contribution instead of
-- restoring an old snapshot over the still-active mutation.
TEST_RPC.send_mutations(true,false,true,true,0)
assert(math.abs(meta[10].run_velocity-115)<0.0001,'partial mutation removal clobbered remaining Rat movement')
assert(enabled[10]==false and value[11].alpha==1,'Lukki presentation did not reverse independently')
TEST_RPC.send_mutations(true,true,true,true,0)
assert(math.abs(meta[10].run_velocity-126.5)<0.0001,'Lukki reapply did not compose with Rat')
TEST_RPC.send_mutations(false,false,false,false,0)
assert(math.abs(meta[10].run_velocity-100)<0.0001 and meta[10].velocity_min_x==-100 and meta[10].velocity_max_x==100,'movement baseline not restored')
assert(enabled[10]==false and enabled[12]==false and enabled[13]==true and value[11].alpha==1,'component baseline not restored')
assert(math.abs(tonumber(object[14].explosion)-1)<0.0001 and value[15].fly_recharge_spd==10,'stat baseline not restored')
assert(#EntityGetAllChildren(1)==0,'remote mutation children survived removal')
print('ew_perk_mutation_sync_patch=PASS reverse_transitions=true exact_baselines=true existing_rpc=true')
