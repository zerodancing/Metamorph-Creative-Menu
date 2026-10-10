local root = assert(arg[1], "root required")
local native_dofile = dofile

local current_player = 10
local alive = {[10]=true,[20]=true}
local frame = 300
local network_tagged = false
local effect_frames = 600
local runtime_updates = 0
local runtime_resets = 0
local runtime_session = nil
local profile_target = nil
local switched_from, switched_to = nil, nil
local restored_position = nil
local protected_entity = nil

METAMORPH_CREATIVE_MENU_FORM_MANAGER = nil

local bridge = {
    DeserializeEntity=function() end,
    SetPlayerEntity=function(entity) current_player=entity end,
    GetPlayerEntity=function() return current_player end,
    CrossCallAdd=function() return true end,
}

local human_restore = {
    restore_controls=function() return true end,
    protect_player=function(entity, frames)
        protected_entity = entity
        assert(frames == 12, "external death restore protection changed")
    end,
    polymorph_effect_components=function(entity)
        return entity == 10 and {201} or {}
    end,
    serialized_backup_from_effects=function(components)
        assert(components[1] == 201, "external polymorph backup read from wrong effect")
        return "external-serialized-human"
    end,
    deserialize_backup=function(_, backup, x, y, name)
        assert(backup == "external-serialized-human", "external human backup was not preserved")
        assert(name == "metamorph_creative_menu_death_handoff", "external death used wrong restore transaction")
        restored_position = {x,y}
        return 20
    end,
}

local stubs = {
    ["mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua"]={get=function() return bridge end},
    ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"]={get=function() return current_player end},
    ["mods/metamorph_creative_menu/files/platform/noita/keycodes.lua"]={resolve=function() return 15 end},
    ["mods/metamorph_creative_menu/files/features/forms/profile.lua"]={get=function(target)
        profile_target=target
        return {target=target}
    end},
    ["mods/metamorph_creative_menu/files/features/forms/runtime.lua"]={
        update=function(entity, session)
            assert(entity==10, "external runtime applied to wrong entity")
            assert(session.phase=="active", "external form was not adopted as active")
            assert(session.compatibility_mode=="external_polymorph", "external form lost adoption mode")
            assert(session.form_strategy=="external_native_polymorph", "external form lost native strategy")
            assert(session.allow_death_handoff==true, "external serialized human was not death-rescuable")
            runtime_session=session
            runtime_updates=runtime_updates+1
        end,
        reset=function() runtime_resets=runtime_resets+1 end,
        family=function() return "character" end,
        draw_health=function() end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/exact_effects.lua"]={},
    ["mods/metamorph_creative_menu/files/features/forms/player_authority.lua"]={switch=function(_, old_entity, new_entity)
        switched_from, switched_to=old_entity,new_entity
        current_player=new_entity
        return true,"confirmed"
    end},
    ["mods/metamorph_creative_menu/files/features/forms/transform_flash.lua"]={restore=function() end,suppress=function() end},
    ["mods/metamorph_creative_menu/files/features/forms/corpse_service.lua"]={detach=function(entity, source, reason)
        assert(entity==10,"wrong external form detached")
        assert(source=="data/entities/animals/shotgunner.xml","external corpse lost exact body path")
        assert(reason=="death","external corpse reason changed")
        alive[entity]=false
        return true
    end,update=function() end},
    ["mods/metamorph_creative_menu/files/features/forms/human_restore.lua"]=human_restore,
    ["mods/metamorph_creative_menu/files/integrations/ew/form_death_channel.lua"]={register=function(_, callback)
        return type(callback)=="function"
    end},
}

dofile=function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

function GameGetFrameNum() return frame end
function GameGetRealWorldTimeSinceStarted() return frame/60 end
function EntityGetIsAlive(entity) return alive[entity]==true end
function EntityHasTag(entity, tag)
    if entity~=10 then return tag=="player_unit" and entity==20 end
    if tag=="polymorphed_player" then return true end
    if tag=="metamorph_creative_menu_network_form" then return network_tagged end
    return false
end
function EntityGetFilename(entity)
    return entity==10 and "data/entities/animals/shotgunner.xml" or "data/entities/player.xml"
end
function EntityGetTransform(entity)
    if entity==10 then return 123,456 end
    if entity==20 then return 123,456 end
    return 0,0
end
function EntityGetComponentIncludingDisabled(entity, kind)
    if entity==10 and kind=="VariableStorageComponent" then return {} end
    return {}
end
function EntityGetFirstComponentIncludingDisabled(entity, kind)
    if entity==20 and kind=="Inventory2Component" then return 66 end
    return 0
end
function EntityAddTag(entity, tag)
    assert(entity==10 and tag=="metamorph_creative_menu_network_form","external form marked with wrong network tag")
    network_tagged=true
end
function EntityAddComponent2(entity, kind, values)
    assert(entity==10 and kind=="VariableStorageComponent","external source marker used wrong component")
    assert(values.name=="metamorph_creative_menu_network_source","external source marker name changed")
    assert(values.value_string=="data/entities/animals/shotgunner.xml","external source marker lost exact path")
    return 301
end
function ComponentGetValue2(component, field)
    if component==201 and field=="polymorph_target" then return "[RANDOM]" end
    if component==201 and field=="frames" then return effect_frames end
    return nil
end
function ComponentSetValue2(component, field, value)
    if component==201 and field=="frames" then effect_frames=value end
end
function EntityKill(entity) alive[entity]=false end
function print() end

local manager=assert(native_dofile(root.."/files/features/forms/manager.lua"))

-- No MCM marker exists yet: the live local polymorph must still be visible to return-HUMAN
-- input before the adoption update runs.
assert(manager.has_active_form()==true,"unowned local polymorph was invisible to MCM")
assert(network_tagged==false,"has_active_form must not mutate the external form")

manager.update()
assert(manager.session_phase()=="active","external local polymorph was not adopted")
assert(manager.session_target()=="data/entities/animals/shotgunner.xml","random polymorph did not use exact live creature path")
assert(profile_target=="data/entities/animals/shotgunner.xml","external form profile did not use exact live creature path")
assert(runtime_updates==1 and runtime_session~=nil,"external form did not enter normal MCM runtime")
assert(network_tagged==true,"adopted external form was not published to the existing network/death path")
assert(manager.original_player_backup()=="external-serialized-human","external form did not expose native human backup")

local returning=manager.handle_tab_return(false,true)
assert(returning==true and effect_frames==1,"return-human binding did not expire adopted external polymorph")

-- A lethal hit can land on the same frame as the requested return. Death handoff must
-- still win synchronously instead of letting Noita/EW enter the game-over path.
local handed_off=manager.handle_form_death(10,"death",9,50,0)
assert(handed_off==true,"external polymorph death did not restore human")
assert(current_player==20 and switched_from==10 and switched_to==20,"external death did not transfer player authority")
assert(restored_position[1]==123 and restored_position[2]==456,"external death restore changed position")
assert(protected_entity==20,"external death restore did not protect human")
assert(manager.session_phase()=="human","external form session survived death handoff")
assert(runtime_resets>=1,"external form runtime was not reset after death")

io.write("form_external_polymorph_adoption=PASS exact_body_profile=true runtime_adopted=true network_published=true death_restored=true\n")
