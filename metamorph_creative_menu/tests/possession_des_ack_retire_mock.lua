local root=assert(arg[1],'root required')
local native_dofile=dofile
local frame=10
local transformed=false
local target_alive=true
local ack=false
local queued=0
local retired=0
local seq=7

METAMORPH_CREATIVE_MENU_POSSESSION=nil

local form_manager={
    current_player=function() return transformed and 3 or 1 end,
    is_human_ready=function(entity) return not transformed and entity==1 end,
    return_to_human=function() transformed=false return true,'expire' end,
    prepare_exact_effect_paths=function() return 1 end,
    transform_creature=function() transformed=true return true,'ok' end,
    session_target=function() return transformed and 'data/entities/animals/maggot_tiny/maggot_tiny.xml' or nil end,
    session_actual_target=function() return transformed and 'data/entities/animals/maggot_tiny/maggot_tiny.xml' or nil end,
}
local targeting={
    target_under_cursor=function() return 2 end,
    is_creature=function(entity,player) return entity==2 and player==1 end,
    transform_plan=function(path) return path,nil end,
}
local retirement={
    retire_without_death_side_effects=function(entity)
        assert(entity==2,'wrong local multipart root retired')
        retired=retired+1
        target_alive=false
        return true
    end,
}
local ew_retirement={
    network_entity=function(entity) return entity end,
    network_kind=function(entity) return entity==2 and 'des' or 'local',entity end,
    queue_remote=function(entity,path,x,y,responsible)
        assert(entity==2 and target_alive==true,'DES retirement was queued after local entity destruction')
        queued=queued+1
        return true,'queued',entity,seq
    end,
    acknowledged=function(request) return request==seq and ack end,
}
local stubs={
    ['mods/metamorph_creative_menu/files/features/forms/manager.lua']=form_manager,
    ['mods/metamorph_creative_menu/files/features/possession/targeting.lua']=targeting,
    ['mods/metamorph_creative_menu/files/features/possession/retirement.lua']=retirement,
    ['mods/metamorph_creative_menu/files/integrations/ew/possession_retire.lua']=ew_retirement,
}
dofile=function(path)
    if stubs[path] then return stubs[path] end
    local prefix='mods/metamorph_creative_menu/'
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

EntityGetIsAlive=function(entity)
    if entity==1 or entity==3 then return true end
    if entity==2 then return target_alive end
    return false
end
EntityGetFilename=function(entity) return entity==2 and 'data/entities/animals/maggot_tiny/maggot_tiny.xml' or '' end
ModDoesFileExist=function() return true end
EntityGetName=function(entity) return entity==2 and '$animal_maggot_tiny' or '' end
EntityGetTransform=function(entity) if entity==2 then return 100,200 else return 0,0 end end
EntitySetTransform=function() end
EntityGetFirstComponentIncludingDisabled=function() return 0 end
ComponentGetValue2=function() return nil end
ComponentSetValue2=function() end
GameGetFrameNum=function() return frame end
EntityHasTag=function(entity,tag) return transformed and entity==3 and tag=='polymorphed_player' end

local possession=assert(native_dofile(root..'/files/features/possession/service.lua'))
local ok=possession.possess_entity(1,2)
assert(ok==true,'possession did not start')
frame=11; possession.update() -- human frame -> transform
frame=12; possession.update() -- confirmed form -> queue DES retirement
assert(queued==1 and retired==0 and target_alive==true,
    'DES target was destroyed in the same update as its death request')
frame=13; possession.update() -- bridge not ACKed yet
assert(retired==0 and target_alive==true,'DES target was destroyed before EW ACK')
ack=true
frame=14; possession.update()
assert(retired==1 and target_alive==false,'DES target was not removed after EW ACK')

print('possession_des_ack_retire=PASS maggot_tiny=true live_gid_until_ack=true retire_after_ack=true')
