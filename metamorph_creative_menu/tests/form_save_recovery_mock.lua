local root = assert(arg[1], "root required")
local native_dofile = dofile

local active_player = 10
local alive = {[10]=true,[20]=true}
local frame = 100
local effect_frames = 2147478898
local runtime_updates = 0
local runtime_resets = 0
local switched_to = 0

function GameGetFrameNum() return frame end
function EntityGetIsAlive(entity) return alive[entity] == true end
function EntityHasTag(entity, tag)
    return entity == 10 and (tag == "polymorphed_player" or tag == "metamorph_creative_menu_network_form")
end
function EntityGetTransform(entity) return 40, 80 end
function EntityGetComponentIncludingDisabled(entity, kind)
    if entity == 10 and kind == "VariableStorageComponent" then return {101} end
    return {}
end
function EntityGetFirstComponentIncludingDisabled() return nil end
function ComponentGetValue2(component, field)
    if component == 101 and field == "name" then return "metamorph_creative_menu_network_source" end
    if component == 101 and field == "value_string" then return "data/entities/animals/coward.xml" end
    if component == 201 and field == "polymorph_target" then return "data/entities/animals/coward.xml" end
    if component == 201 and field == "frames" then return effect_frames end
end
function ComponentSetValue2(component, field, value)
    if component == 201 and field == "frames" then effect_frames = value end
end
function EntityKill(entity) alive[entity] = false end

local bridge = {
    DeserializeEntity=function() end,
    SetPlayerEntity=function(entity) active_player=entity end,
    GetPlayerEntity=function() return active_player end,
    CrossCallAdd=function() return true end,
}
local stubs = {
    ["mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua"]={get=function() return bridge end},
    ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"]={get=function() return active_player end},
    ["mods/metamorph_creative_menu/files/platform/noita/keycodes.lua"]={resolve=function() return 15 end},
    ["mods/metamorph_creative_menu/files/features/forms/profile.lua"]={get=function(target) return {target=target} end},
    ["mods/metamorph_creative_menu/files/features/forms/runtime.lua"]={
        update=function() runtime_updates=runtime_updates+1 end,
        reset=function() runtime_resets=runtime_resets+1 end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/exact_effects.lua"]={},
    ["mods/metamorph_creative_menu/files/features/forms/player_authority.lua"]={
        switch=function(_, previous, replacement)
            assert(previous==10 and replacement==20, "wrong recovery authority handoff")
            active_player=replacement; switched_to=replacement; return true,"confirmed"
        end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/transform_flash.lua"]={restore=function() end,suppress=function() end},
    ["mods/metamorph_creative_menu/files/features/forms/corpse_service.lua"]={detach=function() end,update=function() end},
    ["mods/metamorph_creative_menu/files/features/forms/human_restore.lua"]={
        protect_player=function() end,
        polymorph_effect_components=function(entity) return entity==10 and {201} or {} end,
        serialized_backup_from_effects=function() return "serialized-human-from-save" end,
        deserialize_backup=function(_, backup, x, y)
            assert(backup=="serialized-human-from-save" and x==40 and y==80,"saved human backup was not used")
            return 20
        end,
    },
    ["mods/metamorph_creative_menu/files/integrations/ew/form_death_channel.lua"]={register=function(_, callback) return type(callback)=="function" end},
}
dofile=function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

METAMORPH_CREATIVE_MENU_FORM_MANAGER=nil
local manager=assert(native_dofile(root.."/files/features/forms/manager.lua"))

assert(manager.has_active_form()==true,"saved marked form was invisible before session recovery")
assert(manager.update()==false,"ordinary recovery update should not complete a return")
assert(manager.has_active_form()==true and manager.session_phase()=="active","saved form session was not rehydrated")
assert(manager.session_target()=="data/entities/animals/coward.xml","saved form target was not recovered")
assert(runtime_updates==1,"recovered form runtime did not resume")

local started, reason=manager.return_to_human()
assert(started==true and reason=="expire" and effect_frames==1,"return did not expire saved polymorph")
frame=113
assert(manager.update()==true,"saved-form fallback restore did not complete")
assert(switched_to==20 and active_player==20 and alive[10]==false,"human authority was not restored transactionally")
assert(manager.has_active_form()==false and runtime_resets>=1,"recovered session was not cleared")

io.write("form_save_recovery=PASS detected_before_update=true session_rehydrated=true serialized_human_restored=true\n")
