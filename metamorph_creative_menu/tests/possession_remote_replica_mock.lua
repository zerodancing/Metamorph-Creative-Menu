local root=assert(arg[1],'root required')
local native_dofile=dofile

local entity_tree={
    root=function(entity) return entity end,
    walk=function(entity,callback) callback(entity) end,
}
local creature_service={
    is_internal_helper_path=function() return false end,
    unsafe_reason=function() return nil end,
}
local ew_runtime={enabled=function() return true end}
local util_min={do_i_own=function(entity) return entity~=20 end}

dofile=function(path)
    if path=='mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua' then return entity_tree end
    if path=='mods/metamorph_creative_menu/files/features/creatures/service.lua' then return creature_service end
    if path=='mods/metamorph_creative_menu/files/integrations/ew/runtime.lua' then return ew_runtime end
    if path=='mods/quant.ew/files/resource/util_min.lua' then return util_min end
    local prefix='mods/metamorph_creative_menu/'
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

local alive={[1]=true,[10]=true,[11]=true,[12]=true,[13]=true,[20]=true}
local tags={
    [10]={ew_replicated=true,enemy=true},
    [11]={enemy=true},
    [12]={ew_replicated=true},
    [13]={ew_replicated=true,enemy=true},
    [20]={ew_des=true,enemy=true},
}
EntityGetIsAlive=function(entity) return alive[entity]==true end
EntityHasTag=function(entity,tag) return tags[entity]~=nil and tags[entity][tag]==true end
EntityGetFilename=function(entity)
    if entity==10 or entity==11 or entity==13 or entity==20 then return 'mods/example/entities/network_mob.xml' end
    if entity==12 then return 'data/entities/props/physics_box.xml' end
    return ''
end
EntityGetFirstComponentIncludingDisabled=function(entity,component)
    if (entity==10 or entity==11 or entity==12 or entity==13 or entity==20) and component=='DamageModelComponent' then return 100+entity end
    return nil
end
EntityGetParent=function(entity) return entity==10 and 20 or 0 end
EntityGetRootEntity=function(entity) return entity==10 and 20 or entity end
EntityGetAllChildren=function(entity) return entity==20 and {10} or {} end
EntityGetFirstHitboxCenter=function(entity) return entity==10 and 105 or 500,200 end
EntityGetTransform=function(entity)
    if entity==1 then return 100,200 end
    if entity==10 or entity==20 then return 105,200 end
    return 500,200
end
local radius_entities={10,12}
EntityGetInRadius=function() return radius_entities end
DEBUG_GetMouseWorld=function() return 100,200 end
local gid_components={[20]={220}}
EntityGetComponentIncludingDisabled=function(entity,kind)
    if kind=='VariableStorageComponent' then return gid_components[entity] or {} end
    return {}
end
ComponentGetValue2=function(component,key)
    if component==220 and key=='name' then return 'ew_gid_lid' end
    if component==220 and key=='value_bool' then return false end
    return nil
end
ModDoesFileExist=function(path) return path=='mods/quant.ew/files/resource/util_min.lua' end
local globals={}
GlobalsGetValue=function(key,fallback) return globals[key] or fallback end
GlobalsSetValue=function(key,value) globals[key]=tostring(value) end

local targeting=assert(native_dofile(root..'/files/features/possession/targeting.lua'))
assert(targeting.is_creature(10,1)==true,
    'EW replica stripped of AI components was rejected despite its creature tag and damage model')
assert(targeting.is_creature(11,1)==false,
    'ordinary non-replica bypassed structural creature validation')
assert(targeting.is_creature(12,1)==false,
    'replicated physics prop was misclassified as a creature')
assert(targeting.target_under_cursor(1,48)==10,
    'cursor targeting did not return another peer/host replica')

local retire=assert(native_dofile(root..'/files/integrations/ew/possession_retire.lua'))
assert(retire.network_entity(10)==20,
    'possession retirement did not resolve clicked child to the EW-tracked root entity')
assert(retire.is_owned_locally(10)==false,
    'EW-tracked root ownership was not used for a clicked child')
assert(retire.is_owned_locally(11)==true,
    'genuinely local entity ownership fallback regressed')
assert(select(1,retire.network_kind(10))=='des','DES child/root classification regressed')
assert(select(1,retire.network_kind(13))=='enemy_replica','pure enemy_sync replica was misclassified as DES')
local wrong_ok,wrong_reason=retire.queue_remote(13,'mods/example/entities/network_mob.xml',105,200,1)
assert(wrong_ok==false and wrong_reason=='enemy_sync_replica',
    'pure enemy_sync replica was incorrectly sent through the DES death channel')

-- Force the main-MCM -> EW-extra-module mailbox path. It must preserve the canonical
-- EW root, not the clicked child, and the EW side must emit the stock death CrossCall.
CrossCall=nil
local queued,reason,target=retire.queue_remote(10,'mods/example/entities/network_mob.xml',105,200,1)
assert(queued==true and reason=='queued' and target==20
    and globals.mcm_possession_retire_outbox_entity_v1=='20',
    'remote possession did not queue the canonical EW network root')

local rpc={opts_reliable=function() end,opts_everywhere=function() end}
local common={
    finite_number=function(value) return type(value)=='number' and value==value end,
    report_error=function(scope,detail) error('unexpected bridge error: '..tostring(scope)..':'..tostring(detail)) end,
}
ctx={my_player={entity=1}}
local des_calls={}
ewext={des_death_notify=function(entity,wait,x,y,path,responsible)
    des_calls[#des_calls+1]={entity=entity,wait=wait,x=x,y=y,path=path,responsible=responsible}
end}
CrossCall=function() error('live DES possession should not defer through CrossCall') end
local bridge=assert(native_dofile(root..'/files/integrations/ew/bridge/possession.lua'))
bridge.register(rpc,common)
-- Protocol slot 9 remains registered for old MCM peers, but is deliberately inert.
rpc.retire_possession_target('mods/example/entities/network_mob.xml',105,200)
assert(alive[20]==true,'reserved MCM RPC still mutated the target')
bridge.update()
assert(#des_calls==1 and des_calls[1].entity==20 and des_calls[1].wait==false
    and des_calls[1].path=='mods/example/entities/network_mob.xml',
    'EW bridge did not resolve DES retirement while the tracked entity/GID was alive')
assert(alive[20]==true,'EW bridge directly killed the entity instead of delegating death to DES')
assert(globals.mcm_possession_retire_outbox_ack_v1=='1','EW retirement mailbox was not acknowledged')

print('possession_remote_replica=PASS canonical_root=true des_live_gid=true ack=true enemy_sync_channel_separate=true')
