local root = assert(arg[1], "root required")
local native_dofile = dofile
local reset_calls = {worm=0, physics=0, combat=0, boss=0}

METAMORPH_CREATIVE_MENU_FORM_COMPAT = nil

local stubs = {
    ["mods/metamorph_creative_menu/files/features/forms/profile.lua"] = {get=function() return {} end},
    ["mods/metamorph_creative_menu/files/features/forms/component_ops.lua"] = {ensure_controls=function() return 1 end, add_death_guard=function() end},
    ["mods/metamorph_creative_menu/files/features/forms/entity_tree_cache.lua"] = {reset=function() end},
    ["mods/metamorph_creative_menu/files/features/forms/presentation.lua"] = {
        ensure_vision=function() end, apply_native_herd=function() end, sync_damage_ui=function() end,
        prime_transform_damage_ui=function() end, apply_damage_overlay=function() return true end,
        apply_character_profile=function() end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/family.lua"] = {
        claim_root_lifecycle=function() return false end, detect=function() return "unknown" end,
        is_native_tank_path=function() return false end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/adapters/ghost.lua"] = {stabilize_lifecycle=function() end, configure=function() end, update=function() end},
    ["mods/metamorph_creative_menu/files/features/forms/adapters/fish.lua"] = {configure=function() end, update=function() end},
    ["mods/metamorph_creative_menu/files/features/forms/adapters/worm.lua"] = {configure=function() end, update=function() end, reset=function() reset_calls.worm=reset_calls.worm+1 end},
    ["mods/metamorph_creative_menu/files/features/forms/adapters/physics.lua"] = {configure=function() end, update=function() end, reset=function() reset_calls.physics=reset_calls.physics+1 end},
    ["mods/metamorph_creative_menu/files/features/forms/combat.lua"] = {
        configure_non_ai_player=function() end, setup_manual_barrels=function() end, update_secondary_attacks=function() end,
        update_manual_aim=function() end, update_manual_lasers=function() end, tree_has_laser=function() return false end,
        reset=function() reset_calls.combat=reset_calls.combat+1 end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/adapters/boss_dragon.lua"] = {
        configure=function() end, update=function() end, reset=function() reset_calls.boss=reset_calls.boss+1 end,
    },
}

dofile = function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path, 1, #prefix) == prefix then return native_dofile(root .. "/" .. string.sub(path, #prefix + 1)) end
    return native_dofile(path)
end

local runtime = native_dofile(root .. "/files/features/forms/runtime.lua")
runtime.reset()
assert(reset_calls.worm == 1, "worm adapter reset not delegated")
assert(reset_calls.physics == 1, "physics adapter reset not delegated")
assert(reset_calls.combat == 1, "combat reset not delegated")
assert(reset_calls.boss == 1, "boss adapter reset not delegated")
assert(runtime.family() == "", "runtime family was not cleared")
print("form_runtime_reset=PASS dispatcher_state_cleared=true")
