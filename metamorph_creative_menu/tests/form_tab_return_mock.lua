local root = assert(arg[1], "root required")
local native_dofile = dofile
local player_entity_id = 1
local polymorph_component_id = 77
local component_frames = 120
local tab_pressed = false
local current_frame = 42

function ModTextFileGetContent(path)
    if path == "data/scripts/debug/keycodes.lua" then return "Key_TAB = 9\n" end
    return ""
end
function InputIsKeyJustDown(key_code) return key_code == 9 and tab_pressed end
function GameGetFrameNum() return current_frame end
function GameGetGameEffect(entity, effect_name)
    if entity == player_entity_id and effect_name == "POLYMORPH" then return polymorph_component_id end
    return 0
end
function ComponentSetValue2(component_id, field_name, value)
    if component_id == polymorph_component_id and field_name == "frames" then component_frames = value end
end
function EntityGetFirstComponentIncludingDisabled() return 0 end
function EntityGetIsAlive(entity) return entity == player_entity_id end
function EntityHasTag() return false end
function ModDoesFileExist() return false end
function print(_) end

local dependency_stubs = {
    ["mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua"] = {get=function() return nil end},
    ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"] = {get=function() return player_entity_id end},
    ["mods/metamorph_creative_menu/files/core/hash.lua"] = {hex64=function(value) return tostring(value) end},
    ["mods/metamorph_creative_menu/files/core/xml_utils.lua"] = native_dofile(root .. "/files/core/xml_utils.lua"),
    ["mods/metamorph_creative_menu/files/features/forms/profile.lua"] = {},
    ["mods/metamorph_creative_menu/files/features/forms/runtime.lua"] = {reset=function() end},
}
dofile = function(path)
    if dependency_stubs[path] ~= nil then return dependency_stubs[path] end
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path, 1, #prefix) == prefix then return native_dofile(root .. "/" .. string.sub(path, #prefix + 1)) end
    return native_dofile(path)
end

local form_manager = native_dofile(root .. "/files/features/forms/manager.lua")
tab_pressed = true
assert(form_manager.handle_tab_return(true) == false, "Alt-Tab/input quarantine triggered form return")
assert(component_frames == 120, "blocked TAB modified polymorph effect")
assert(form_manager.handle_tab_return(false) == true, "TAB did not return active polymorph form")
assert(component_frames == 1, "TAB did not expire polymorph effect")
print("form_tab_return=PASS blocked_alt_tab=true active_tab_return=true")
