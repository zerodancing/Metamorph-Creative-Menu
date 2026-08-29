local root = assert(arg[1], "root required")
local native_dofile = dofile

local current_player = 1
local frame = 50
local alive = {[1]=true,[2]=true,[3]=true,[99]=true}
local control_fields = {[303]={enabled=false,polymorph_hax=true}}
local component_enabled = {[303]=false}
local effect_frames = 2147480000

METAMORPH_CREATIVE_MENU_FORM_MANAGER = nil

local bridge = {
    SerializeEntity=function(entity)
        assert(entity==1,"wrong human serialized before polymorph")
        return "disabled-controls-human"
    end,
    CrossCallAdd=function() return true end,
}

local stubs = {
    ["mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua"]={get=function() return bridge end},
    ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"]={get=function() return current_player end},
    ["mods/metamorph_creative_menu/files/platform/noita/keycodes.lua"]={resolve=function() return 15 end},
    ["mods/metamorph_creative_menu/files/features/forms/profile.lua"]={get=function() return {} end},
    ["mods/metamorph_creative_menu/files/features/forms/runtime.lua"]={
        update=function() end, reset=function() end, family=function() return "character" end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/exact_effects.lua"]={
        effect_path=function() return "mods/metamorph_creative_menu/files/generated/test_effect.xml" end,
        invalidate_failed_target=function() end, prepare=function() return 1 end,
        prepare_from_catalog=function() return 1 end, runtime_target=function(path) return path end,
        default_duration_frames=function() return 2147480000 end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/player_authority.lua"]={switch=function() return true,"committed" end},
    ["mods/metamorph_creative_menu/files/features/forms/transform_flash.lua"]={restore=function() end,suppress=function() end},
    ["mods/metamorph_creative_menu/files/features/forms/corpse_service.lua"]={detach=function() return true end,update=function() end},
    ["mods/metamorph_creative_menu/files/integrations/ew/form_death_channel.lua"]={register=function() return true end},
}

dofile=function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

function GameGetFrameNum() return frame end
function GameGetGameEffect(entity,effect)
    if entity==2 and effect=="POLYMORPH" then return 202 end
    return 0
end
function EntityGetIsAlive(entity) return alive[entity]==true end
function EntityHasTag(entity,tag) return entity==2 and tag=="polymorphed_player" end
function EntityGetTransform() return 12,34 end
function EntityGetAllChildren() return {} end
function EntityGetComponentIncludingDisabled(entity,kind)
    if entity==3 and kind=="ControlsComponent" then return {303} end
    return {}
end
function EntityGetFirstComponentIncludingDisabled(entity,kind)
    if entity==99 and kind=="GameEffectComponent" then return 77 end
    if entity==3 and kind=="ControlsComponent" then return 303 end
    return 0
end
function EntityGetComponentIsEnabled(entity,component) return component_enabled[component]==true end
function EntitySetComponentIsEnabled(entity,component,enabled)
    assert(entity==3 and component==303,"wrong restored control component")
    component_enabled[component]=enabled==true
end
function EntityAddTag() end
function EntityAddComponent2() return 250 end
function ComponentGetValue2(component,field)
    local fields=control_fields[component]
    return fields and fields[field] or nil
end
function ComponentSetValue2(component,field,value)
    if component==202 and field=="frames" then effect_frames=value end
    local fields=control_fields[component]
    if fields then fields[field]=value end
end
function ModDoesFileExist() return true end
function LoadGameEffectEntityTo() return 99 end
function print() end

local manager=assert(native_dofile(root.."/files/features/forms/manager.lua"))
local transformed,reason=manager.transform_creature(1,"data/entities/animals/test.xml")
assert(transformed==true,"transform setup failed: "..tostring(reason))

current_player=2
frame=51
manager.update()
assert(manager.session_phase()=="active","creature form did not become active")
local returning,return_reason=manager.return_to_human()
assert(returning==true and return_reason=="expire" and effect_frames==1,"native return was not requested")

-- Native polymorph restores the serialized human on its own. Reproduce the real failure:
-- that snapshot was taken while a menu click had ControlsComponent.enabled=false.
alive[2]=false
current_player=3
frame=52
manager.update()

assert(control_fields[303].enabled==true,"restored human ControlsComponent.enabled stayed false")
assert(control_fields[303].polymorph_hax==false,"restored human kept the form-only polymorph_hax flag")
assert(component_enabled[303]==true,"restored human ControlsComponent stayed engine-disabled")
assert(manager.session_phase()=="human","form session survived native human restoration")

io.write("form_return_controls=PASS native_return=true controls_reactivated=true polymorph_flag_cleared=true\n")
