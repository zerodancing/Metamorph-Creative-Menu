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
local util_min={do_i_own=function() return true end}

dofile=function(path)
    if path=='mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua' then return entity_tree end
    if path=='mods/metamorph_creative_menu/files/features/creatures/service.lua' then return creature_service end
    if path=='mods/metamorph_creative_menu/files/integrations/ew/runtime.lua' then return ew_runtime end
    if path=='mods/quant.ew/files/resource/util_min.lua' then return util_min end
    local prefix='mods/metamorph_creative_menu/'
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

local alive={[1]=true,[10]=true,[11]=true,[12]=true,[20]=true}
local tags={
    [10]={ew_replicated=true,enemy=true},
    [11]={enemy=true},
    [12]={ew_replicated=true},
}
EntityGetIsAlive=function(entity) return alive[entity]==true end
EntityHasTag=function(entity,tag) return tags[entity]~=nil and tags[entity][tag]==true end
EntityGetFilename=function(entity)
    if entity==10 or entity==11 or entity==20 then return 'mods/example/entities/network_mob.xml' end
    if entity==12 then return 'data/entities/props/physics_box.xml' end
    return ''
end
EntityGetFirstComponentIncludingDisabled=function(entity,component)
    if (entity==10 or entity==11 or entity==12) and component=='DamageModelComponent' then return 100+entity end
    return nil
end
EntityGetParent=function() return 0 end
EntityGetFirstHitboxCenter=function(entity) return entity==10 and 105 or 500,200 end
EntityGetTransform=function(entity)
    if entity==1 then return 100,200 end
    if entity==10 or entity==20 then return 105,200 end
    return 500,200
end
local radius_entities={10,12}
EntityGetInRadius=function() return radius_entities end
DEBUG_GetMouseWorld=function() return 100,200 end
EntityGetComponentIncludingDisabled=function() return {} end
ComponentGetValue2=function() return nil end
ModDoesFileExist=function(path) return path=='mods/quant.ew/files/resource/util_min.lua' end
GlobalsGetValue=function(_,fallback) return fallback end
GlobalsSetValue=function() end

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
assert(retire.is_owned_locally(10)==false,
    'EW replica without gid storage was incorrectly treated as locally authoritative')
assert(retire.is_owned_locally(11)==true,
    'genuinely local entity ownership fallback regressed')

local rpc={opts_reliable=function() end,opts_everywhere=function() end}
local common={
    finite_number=function(value) return type(value)=='number' and value==value end,
    report_error=function() end,
}
ctx={rpc_player_data={entity=1}}
EntityGetAllChildren=function() return {} end
EntityGetAllComponents=function() return {} end
EntitySetTransform=function() end
EntityKill=function(entity) alive[entity]=false end
local bridge=assert(native_dofile(root..'/files/integrations/ew/bridge/possession.lua'))
bridge.register(rpc,common)
radius_entities={20}
rpc.retire_possession_target('mods/example/entities/network_mob.xml',105,200)
assert(alive[20]==false,'authoritative modded target was not retired after remote possession')

print('possession_remote_replica=PASS stripped_ai_target=true modded_tag_target=true prop_rejected=true host_retirement=true modded_rpc=true')
