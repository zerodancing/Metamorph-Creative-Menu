local root = assert(arg[1], "root required")
local native_dofile = dofile
local current_player = 1
local frame = 50
local effect_frames = nil
local runtime_reset_calls = 0
local suppress_calls = 0

METAMORPH_CREATIVE_MENU_FORM_MANAGER = nil

local bridge = {
    SerializeEntity = function(entity)
        assert(entity == 1, "wrong entity serialized")
        return "serialized-human"
    end,
    CrossCallAdd = function() return true end,
}

local stubs = {
    ["mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua"] = {get=function() return bridge end},
    ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"] = {get=function() return current_player end},
    ["mods/metamorph_creative_menu/files/platform/noita/keycodes.lua"] = {resolve=function() return 43 end},
    ["mods/metamorph_creative_menu/files/features/forms/profile.lua"] = {get=function() return {id="profile"} end},
    ["mods/metamorph_creative_menu/files/features/forms/runtime.lua"] = {reset=function() runtime_reset_calls=runtime_reset_calls+1 end, family=function() return "" end, draw_health=function() end},
    ["mods/metamorph_creative_menu/files/features/forms/exact_effects.lua"] = {
        effect_path=function(path) return "mods/metamorph_creative_menu/files/generated/test_effect.xml" end,
        invalidate_failed_target=function() return true end,
        prepare=function() return 1 end,
        prepare_from_catalog=function() return 1 end,
        runtime_target=function(path) return path end,
        prepared_count=function() return 1 end,
        default_duration_frames=function() return 2147480000 end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/player_authority.lua"] = {switch=function() return true, "committed" end},
    ["mods/metamorph_creative_menu/files/features/forms/transform_flash.lua"] = {
        suppress=function(frames) suppress_calls=suppress_calls+1 assert(frames==18) end,
        restore=function() end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/corpse_service.lua"] = {detach=function() return true end, update=function() end},
    ["mods/metamorph_creative_menu/files/features/forms/human_restore.lua"] = {
        protect_player=function() end,
        polymorph_effect_components=function() return {} end,
        serialized_backup_from_effects=function() return nil end,
        deserialize_backup=function() return 0 end,
    },
    ["mods/metamorph_creative_menu/files/integrations/ew/form_death_channel.lua"] = {register=function() return true end},
}

dofile = function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path, 1, #prefix) == prefix then return native_dofile(root .. "/" .. string.sub(path, #prefix + 1)) end
    return native_dofile(path)
end

function EntityGetIsAlive(entity) return entity == 1 or entity == 99 end
function EntityHasTag(entity, tag) return false end
function ModDoesFileExist(path) return path == "data/entities/animals/test.xml" end
function EntityGetTransform(entity) return 12, 34 end
function LoadGameEffectEntityTo(player, path)
    assert(player == 1, "effect attached to wrong player")
    return 99
end
function EntityGetFirstComponentIncludingDisabled(entity, component_type)
    if entity == 99 and component_type == "GameEffectComponent" then return 77 end
    return 0
end
function ComponentSetValue2(component, field, value)
    if component == 77 and field == "frames" then effect_frames = value end
end
function GameGetFrameNum() return frame end
function print() end

local manager = assert(native_dofile(root .. "/files/features/forms/manager.lua"))
local ok, reason = manager.transform_creature(1, "data/entities/animals/test.xml", nil, false, {})
assert(ok == true, "default-duration transform failed: " .. tostring(reason))
assert(effect_frames == 2147480000, "default polymorph duration was not preserved")
assert(manager.session_phase() == "transforming", "form session was not committed after effect creation")
assert(manager.session_target() == "data/entities/animals/test.xml", "session target changed")
assert(runtime_reset_calls == 1 and suppress_calls == 1, "transform lifecycle setup changed")
print("form_transform_session=PASS default_duration=true session_committed=true")
