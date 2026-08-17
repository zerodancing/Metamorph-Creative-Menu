local root = assert(arg[1], "root required")
local native_dofile = dofile
local frame = 10
local transformed = false
local target_alive = true
local retirement_calls = 0
local player_x, player_y = 0, 0
local requested_path = "data/entities/animals/crypt/acidshooter.xml"
local actual_path = "data/entities/animals/acidshooter.xml"

METAMORPH_CREATIVE_MENU_POSSESSION = nil

local form_manager = {
    current_player=function() return transformed and 3 or 1 end,
    is_human_ready=function(entity) return not transformed and entity == 1 end,
    return_to_human=function() transformed=false return true, "expire" end,
    prepare_exact_effect_paths=function(paths)
        assert(paths[1] == actual_path, "possession prewarm used requested crash-prone wrapper")
        return 1
    end,
    transform_creature=function(player, path, _, _, options)
        assert(player == 1 and path == actual_path, "G did not use safe same-species player target")
        assert(options.requested_target == requested_path, "G lost original authored target identity")
        assert(options.profile_target == actual_path, "fallback form must use base profile instead of wrapper-only NPC overrides")
        transformed = true
        return true, "ok"
    end,
    session_target=function() return transformed and requested_path or nil end,
    session_actual_target=function() return transformed and actual_path or nil end,
}
local targeting = {
    target_under_cursor=function() return 2 end,
    is_creature=function(entity, player) return entity == 2 and player == 1 end,
    transform_plan=function(path)
        assert(path == requested_path, "wrong G source path")
        return actual_path, "placement_wrapper_fallback"
    end,
}
local retirement = {
    retire_without_death_side_effects=function(entity)
        assert(entity == 2, "wrong original entity retired")
        retirement_calls = retirement_calls + 1
        target_alive = false
        return true
    end,
}
local ew_retirement = {is_owned_locally=function() return true end, queue_remote=function() error("remote retirement should not be used") end}
local ew_runtime = {mode=function() return "singleplayer" end}

local stubs = {
    ["mods/metamorph_creative_menu/files/features/forms/manager.lua"] = form_manager,
    ["mods/metamorph_creative_menu/files/integrations/ew/runtime.lua"] = ew_runtime,
    ["mods/metamorph_creative_menu/files/features/possession/targeting.lua"] = targeting,
    ["mods/metamorph_creative_menu/files/features/possession/retirement.lua"] = retirement,
    ["mods/metamorph_creative_menu/files/integrations/ew/possession_retire.lua"] = ew_retirement,
}
dofile = function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

function EntityGetIsAlive(entity)
    if entity == 1 or entity == 3 then return true end
    if entity == 2 then return target_alive end
    return false
end
function EntityGetFilename(entity) return entity == 2 and requested_path or "" end
function ModDoesFileExist(path) return path == requested_path or path == actual_path end
function EntityGetName(entity) return entity == 2 and "crypt_acidshooter" or "" end
function EntityGetTransform(entity)
    if entity == 2 then return 100, 200 end
    if entity == 1 or entity == 3 then return player_x, player_y end
end
function EntitySetTransform(entity, x, y) if entity == 1 then player_x, player_y = x, y end end
function EntityGetFirstComponentIncludingDisabled() return 0 end
function ComponentGetValue2() return nil end
function ComponentSetValue2() end
function GameGetFrameNum() return frame end
function EntityHasTag(entity, tag) return transformed and entity == 3 and tag == "polymorphed_player" end

local possession = assert(native_dofile(root .. "/files/features/possession/service.lua"))
local ok, reason = possession.possess_entity(1, 2)
assert(ok and reason == "pending", "possession did not enter replacement pipeline")
assert(player_x == 100 and player_y == 200, "human was not moved to original mob position")
frame = frame + 1
possession.update()
frame = frame + 1
possession.update()
assert(retirement_calls == 1 and target_alive == false, "original crypt mob was not removed after confirmed fallback form")
print("possession_crypt_replacement=PASS fallback_actual_target=true original_retired=true requested_identity_preserved=true")
