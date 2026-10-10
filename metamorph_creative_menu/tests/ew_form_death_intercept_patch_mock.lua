local root=assert(arg[1], 'root required')
local patches=assert(dofile(root..'/files/integrations/ew/resilience_patches.lua'))
local source=[[
local rpc={change_entity=function() end}
local module = {}
local gameover_requested=false
ctx={my_player={entity=7,currently_polymorphed=true},cap={health={on_poly_death=function() HEALTH_DEATHS=HEALTH_DEATHS+1 end}}}
util={serialize_entity=function() return 'x' end,deserialize_entity=function() return 8 end,get_ent_health=function() return 0,1,true end}
function module.on_world_update()
    if ctx.my_player.currently_polymorphed then
        local hp, _, has_hp_component = util.get_ent_health(ctx.my_player.entity)
        if has_hp_component and hp <= 0 and not gameover_requested then
            ctx.cap.health.on_poly_death()
            gameover_requested = true
        end
    else
        gameover_requested = false
    end
end
local function send_poly()
        rpc.change_entity({ data = util.serialize_entity(ctx.my_player.entity) })
end
local function apply_seri_ent(player_data, seri_ent)
    if seri_ent ~= nil then
        local ent = util.deserialize_entity(seri_ent.data)
    end
end
return module
]]
local death_patched,death_count=patches.patch_polymorph_death_source(source)
assert(death_count==1 and death_patched:find('mcm_poly_death_intercept_v1',1,true),
    'EW polymorph death intercept was not independently patched')
local patched,count=patches.patch_polymorph_profile_source(death_patched)
assert(count==1 and patched:find('mcm_poly_profile_v1',1,true),
    'optional polymorph profiler did not compose with the critical death patch')
HEALTH_DEATHS=0
local globals={}
GlobalsSetValue=function(k,v) globals[k]=tostring(v) end
GlobalsGetValue=function(k,d) return globals[k] or d end
EntityHasTag=function(entity,tag) return entity==7 and tag=='metamorph_creative_menu_network_form' end
EntityGetComponentIncludingDisabled=function() return {} end
EntityGetFilename=function() return '' end
EntityGetFirstComponentIncludingDisabled=function() return nil end
GameGetFrameNum=function() return 5 end
GameGetRealWorldTimeSinceStarted=function() return 1 end
CrossCall=function() error('EW-local CrossCall table must not handle an MCM callback') end
np={CrossCall=function(name,entity)
    assert(name=='metamorph_creative_menu_form_died' and entity==7,'wrong MCM death interception call')
    GlobalsSetValue('mcm_form_death_intercept_ack_v1','7:5')
end}
local chunk,err=load(patched,'patched_poly_death','t',_G); assert(chunk,err)
local module=assert(chunk())
module.on_world_update()
assert(HEALTH_DEATHS==0,'EW player-death path ran after MCM committed human restore')

-- If the entity death() callback committed the restore earlier in the same frame, the
-- form tag may already be removed from the corpse. The recent entity+frame ack must still
-- suppress EW's notplayer/game-over path.
HEALTH_DEATHS=0; globals={mcm_form_death_intercept_ack_v1='7:5'}
EntityHasTag=function() return false end
np.CrossCall=function() error('pre-ack path should not need a second CrossCall') end
local chunk_pre=assert(load(patched,'patched_poly_death_pre','t',_G)); local module_pre=assert(chunk_pre())
module_pre.on_world_update()
assert(HEALTH_DEATHS==0,'same-frame pre-ack was ignored after corpse tag removal')

-- Without an acknowledgement, stock EW death semantics must remain untouched.
HEALTH_DEATHS=0; globals={}
np.CrossCall=function() end
local chunk2=assert(load(patched,'patched_poly_death2','t',_G)); local module2=assert(chunk2())
module2.on_world_update()
assert(HEALTH_DEATHS==1,'ordinary/unhandled polymorph death was swallowed')

-- Source patches can lose an OnModPreInit ordering race after EW has already loaded the
-- original polymorph module. The extra-module health wrapper installs after all EW
-- systems and must therefore enforce the same transaction without relying on rewritten
-- source being the code that actually runs.
HEALTH_DEATHS=0; globals={}; local active_player=7
ctx={my_player={entity=7,currently_polymorphed=true},cap={health={
    on_poly_death=function(message)
        assert(message=='fatal','stock health arguments were not preserved')
        HEALTH_DEATHS=HEALTH_DEATHS+1
    end,
}}}
EntityGetIsAlive=function(entity) return entity==7 or entity==8 or entity==9 end
EntityHasTag=function(entity,tag)
    if entity==7 then return tag=='metamorph_creative_menu_network_form' end
    if entity==8 then return tag=='player_unit' end
    return false
end
np={
    GetPlayerEntity=function() return active_player end,
    CrossCall=function(name,entity)
        assert(name=='metamorph_creative_menu_form_died' and entity==7,'runtime intercept used wrong native channel')
        active_player=8
        GlobalsSetValue('mcm_form_death_intercept_ack_v1','7:5')
    end,
}
local runtime_intercept=assert(dofile(root..'/files/integrations/ew/form_death_intercept.lua'))
local installed,install_reason=runtime_intercept.install()
assert(installed and install_reason=='installed','EW health capability intercept was not installed')
ctx.cap.health.on_poly_death('fatal')
assert(HEALTH_DEATHS==0,'runtime health intercept allowed notplayer after committed restore')
assert(globals.mcm_form_death_runtime_rescues_v2=='1'
    and globals.mcm_form_death_runtime_intercept_v2:find('rescued:7:',1,true)==1,
    'runtime rescue was not positively recorded')

-- Untagged/ordinary polymorph deaths keep the exact EW handler and arguments.
ctx.my_player.entity=9; active_player=9
ctx.cap.health.on_poly_death('fatal')
assert(HEALTH_DEATHS==1,'runtime wrapper swallowed an ordinary EW polymorph death')

-- Two mods can bundle separate NoitaPatcher instances. If their native CrossCall
-- registries do not meet, the interceptor must still restore the human from the exact
-- serialized backup which EW itself stores on the polymorph effect.
local alive={[10]=true,[11]=true,[12]=true}; local killed={}; local damage_values={invincibility_frames=2}
ctx.my_player.entity=10; active_player=10; globals.mcm_form_death_intercept_ack_v1=''
EntityGetIsAlive=function(entity) return alive[entity]==true end
EntityHasTag=function(entity,tag)
    if entity==10 then return tag=='metamorph_creative_menu_network_form' end
    if entity==12 then return tag=='player_unit' end
    return false
end
EntityGetAllChildren=function(entity) return entity==10 and {11} or {} end
EntityGetFirstComponentIncludingDisabled=function(entity,kind)
    if entity==11 and kind=='GameEffectComponent' then return 501 end
    if entity==12 and kind=='DamageModelComponent' then return 601 end
    return nil
end
ComponentGetValue2=function(component,key)
    if component==501 and key=='effect' then return 'POLYMORPH' end
    if component==501 and key=='mSerializedData' then return 'encoded-human' end
    if component==601 then return damage_values[key] end
end
ComponentSetValue2=function(component,key,value)
    assert(component==601,'native fallback mutated an unexpected component')
    damage_values[key]=value
end
EntityGetTransform=function(entity) assert(entity==10); return 30,40 end
EntityKill=function(entity) killed[entity]=true; alive[entity]=false end
dofile_once=function(path)
    assert(path=='mods/quant.ew/files/resource/base64.lua','native fallback loaded the wrong EW codec')
    return {decode=function(value) assert(value=='encoded-human'); return 'serialized-human' end}
end
util={deserialize_entity=function(value,x,y)
    assert(value=='serialized-human' and x==30 and y==40,'native human restore lost its payload or position')
    return 12
end}
np={
    GetPlayerEntity=function() return active_player end,
    CrossCall=function() end, -- deliberately no callback and therefore no acknowledgement
    SetPlayerEntity=function(entity) active_player=entity end,
}
ctx.cap.health.on_poly_death('fatal')
assert(HEALTH_DEATHS==1,'stock notplayer path ran after EW-native human restoration')
assert(active_player==12 and killed[10]==true,'EW-native fallback did not commit human before retiring the form')
assert(damage_values.invincibility_frames==12 and damage_values.kill_now==false,
    'EW-native restored human did not receive the handoff protection window')
assert(globals.mcm_form_death_runtime_rescues_v2=='2'
    and globals.mcm_form_death_runtime_intercept_v2:find('rescued_native:10:',1,true)==1,
    'EW-native fallback was not positively recorded')
print('ew_form_death_intercept_patch=PASS source_patch=true runtime_capability=true cross_vm_fallback=true stock_fallback=true')
