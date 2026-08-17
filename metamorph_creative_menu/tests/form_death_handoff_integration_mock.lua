local root = assert(arg[1], "root required")
local native_dofile = dofile
local current_player = 1
local frame = 100
local runtime_updates = 0
local runtime_resets = 0
local corpse_detaches = 0
local restored_position = nil
local protected_entity = nil
local switched_from, switched_to = nil, nil

METAMORPH_CREATIVE_MENU_FORM_MANAGER = nil

local bridge = {
    SerializeEntity=function(entity)
        assert(entity == 1, "human backup serialized from wrong entity")
        return "serialized-human"
    end,
    DeserializeEntity=function() end,
    SetPlayerEntity=function() end,
    CrossCallAdd=function() return true end,
}

local stubs = {
    ["mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua"] = {get=function() return bridge end},
    ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"] = {get=function() return current_player end},
    ["mods/metamorph_creative_menu/files/platform/noita/keycodes.lua"] = {resolve=function() return 43 end},
    ["mods/metamorph_creative_menu/files/features/forms/profile.lua"] = {get=function() return {id="profile"} end},
    ["mods/metamorph_creative_menu/files/features/forms/runtime.lua"] = {
        reset=function() runtime_resets=runtime_resets+1 end,
        update=function(entity, session)
            assert(entity == 2 and session.phase == "active", "runtime did not activate on transformed body")
            runtime_updates=runtime_updates+1
        end,
        family=function() return "character" end,
        draw_health=function() end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/exact_effects.lua"] = {
        effect_path=function() return "mods/metamorph_creative_menu/files/generated/test_effect.xml" end,
        invalidate_failed_target=function() end,
        prepare=function() return 1 end,
        prepare_from_catalog=function() return 1 end,
        runtime_target=function(path) return path end,
        prepared_count=function() return 1 end,
        default_duration_frames=function() return 2147480000 end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/player_authority.lua"] = {
        switch=function(_, old_entity, new_entity)
            switched_from, switched_to = old_entity, new_entity
            current_player = new_entity
            return true, "committed"
        end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/transform_flash.lua"] = {suppress=function() end, restore=function() end},
    ["mods/metamorph_creative_menu/files/features/forms/corpse_service.lua"] = {
        detach=function(entity, source, reason)
            assert(entity == 2, "wrong transformed body detached as corpse")
            assert(source == "data/entities/animals/test.xml", "corpse lost source creature path")
            assert(reason == "death", "death reason changed")
            corpse_detaches=corpse_detaches+1
            return true
        end,
        update=function() end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/human_restore.lua"] = {
        protect_player=function(entity, frames)
            protected_entity=entity
            assert(frames == 12, "death handoff invincibility changed")
        end,
        polymorph_effect_components=function(entity)
            if entity == 2 then return {88} end
            return {}
        end,
        serialized_backup_from_effects=function() return nil end,
        deserialize_backup=function(_, serialized, x, y, name)
            assert(serialized == "serialized-human", "wrong human backup restored")
            assert(name == "metamorph_creative_menu_death_handoff", "death handoff entity name changed")
            restored_position={x,y}
            return 3
        end,
    },
    ["mods/metamorph_creative_menu/files/integrations/ew/form_death_channel.lua"] = {register=function() return true end},
}

dofile = function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path, 1, #prefix) == prefix then return native_dofile(root .. "/" .. string.sub(path, #prefix + 1)) end
    return native_dofile(path)
end

function EntityGetIsAlive(entity) return entity == 1 or entity == 2 or entity == 3 or entity == 99 end
function EntityHasTag(entity, tag)
    if tag == "polymorphed_player" then return entity == 2 end
    if tag == "player_unit" then return entity == 1 or entity == 3 end
    return false
end
function ModDoesFileExist(path) return path == "data/entities/animals/test.xml" end
function EntityGetTransform(entity)
    if entity == 1 then return 10,20 end
    if entity == 2 then return 70,80 end
    if entity == 3 then return 70,80 end
    return 0,0
end
function LoadGameEffectEntityTo() return 99 end
function EntityGetFirstComponentIncludingDisabled(entity, component_type)
    if entity == 99 and component_type == "GameEffectComponent" then return 77 end
    if (entity == 1 or entity == 3) and component_type == "Inventory2Component" then return 66 end
    if entity == 2 and component_type == "VariableStorageComponent" then return 0 end
    return 0
end
function EntityAddTag() end
function EntityAddComponent2(_, component_type, _)
    if component_type == "VariableStorageComponent" then return 55 end
    return 56
end
function ComponentSetValue2() end
function GameGetFrameNum() return frame end
function GameGetRealWorldTimeSinceStarted() return frame / 60 end
function print() end

local manager = assert(native_dofile(root .. "/files/features/forms/manager.lua"))
local transformed, reason = manager.transform_creature(1, "data/entities/animals/test.xml", nil, false, {})
assert(transformed == true, "transform setup failed: " .. tostring(reason))

current_player = 2
frame = frame + 1
manager.update()
assert(manager.session_phase() == "active", "form session did not become active")
assert(runtime_updates == 1, "form runtime was not activated before death")

local handed_off = manager.handle_form_death(2, "death", 9, 100, 0)
assert(handed_off == true, "native form death did not restore human")
assert(current_player == 3, "restored human did not become authoritative player")
assert(switched_from == 2 and switched_to == 3, "player authority transaction changed")
assert(restored_position[1] == 70 and restored_position[2] == 80, "human was not restored at dead mob position")
assert(protected_entity == 3, "restored human was not protected during handoff")
assert(corpse_detaches == 1, "dead mob body was not detached exactly once")
assert(manager.session_phase() == "human", "form session survived death handoff")
assert(runtime_resets >= 2, "form runtime was not reset after death handoff")

print("form_death_handoff_integration=PASS human_restored=true corpse_preserved=true position_preserved=true")
