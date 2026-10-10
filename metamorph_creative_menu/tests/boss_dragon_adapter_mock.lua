local root = assert(arg[1], "root required")
local native_dofile = dofile

local components = {
    ControlsComponent = 10,
    BossDragonComponent = 20,
}
local component_values = {
    [10] = { mButtonDownFire=false, mButtonDownFire2=false, polymorph_hax=true },
    [20] = {
        projectile_1="data/entities/projectiles/test.xml", projectile_2="", projectile_1_count=1, projectile_2_count=0,
        speed=7, acceleration=3, part_distance=10, ground_check_offset=0,
        hitbox_radius=2, bite_damage=4, target_kill_radius=2,
        target_kill_ragdoll_force=1, eat_anim_wait_mult=0.05, jump_cam_shake=20,
        ragdoll_filename="",
    },
}
local enabled = {}
local next_component = 30
local configured_non_ai = 0
local setup_barrels = 0

local component_ops = {}
function component_ops.valid(value) return value ~= nil and value ~= 0 end
function component_ops.first(_, component_type) return components[component_type] end
function component_ops.get(component, field, fallback)
    local values = component_values[component]
    if values == nil or values[field] == nil then return fallback end
    return values[field]
end
function component_ops.set_typed_scalar(component, field, value)
    component_values[component] = component_values[component] or {}
    component_values[component][field] = value
    return true
end
function component_ops.ensure_controls(_) return components.ControlsComponent end

local stubs = {
    ["mods/metamorph_creative_menu/files/features/forms/component_ops.lua"] = component_ops,
    ["mods/metamorph_creative_menu/files/features/forms/controls.lua"] = {
        direction=function(component)
            assert(component == components.ControlsComponent, "wrong ControlsComponent passed to direction helper")
            return 1, 0, true
        end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/combat.lua"] = {
        configure_non_ai_player=function() configured_non_ai=configured_non_ai+1 end,
        setup_manual_barrels=function() setup_barrels=setup_barrels+1 end,
        play_attack_animation=function() end,
    },
}

dofile = function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path, 1, #prefix) == prefix then return native_dofile(root .. "/" .. string.sub(path, #prefix + 1)) end
    return native_dofile(path)
end

function ComponentSetValue2(component, field, value)
    component_values[component] = component_values[component] or {}
    component_values[component][field] = value
end
function EntityAddComponent2(_, component_type, values)
    local id = next_component
    next_component = next_component + 1
    components[component_type] = id
    component_values[id] = values or {}
    return id
end
function EntitySetComponentIsEnabled(_, component, value) enabled[component] = value == true end
function EntityGetTransform(_) return 100, 200 end
function GameGetFrameNum() return 100 end
function ModDoesFileExist(path) return path=="data/entities/projectiles/test.xml" end
function DEBUG_GetMouseWorld() return 120, 200 end
local projectile_loads=0
local killed_projectiles={}
function EntityLoad() projectile_loads=projectile_loads+1; return 100+projectile_loads end
function EntityKill(entity) killed_projectiles[entity]=true end
function GameShootProjectile() error("native shoot rejected projectile") end

local adapter = assert(native_dofile(root .. "/files/features/forms/adapters/boss_dragon.lua"))
adapter.configure(1)

local worm = assert(components.WormComponent, "boss form did not receive WormComponent driver")
local driver = assert(components.WormPlayerComponent, "boss form did not receive WormPlayerComponent")
assert(configured_non_ai == 1, "boss form did not disable/configure ordinary AI path")
assert(setup_barrels == 1, "boss attack setup was skipped")
assert(enabled[components.BossDragonComponent] == false, "BossDragonComponent AI motor must be disabled")
assert(enabled[worm] == true and enabled[driver] == true, "player worm driver must be enabled")
assert(component_values[10].polymorph_hax == false, "boss form must not double-fire through polymorph_hax")

adapter.update(1)
assert(enabled[components.BossDragonComponent] == false, "boss AI motor was re-enabled during update")
assert(component_values[worm].mTargetSpeed == 7, "player movement did not drive authored boss worm speed")
assert(component_values[worm].speed == 7 and component_values[worm].acceleration == 3, "boss locomotion envelope changed")

-- Failed native projectile launch must retire the loaded entity and must not start
-- the boss cooldown; a second update in the same frame should attempt again.
component_values[10].mButtonDownFire=true
adapter.update(1)
adapter.update(1)
assert(projectile_loads==2,"failed boss shot incorrectly started cooldown")
assert(killed_projectiles[101] and killed_projectiles[102],"failed boss projectile survived at muzzle")
print("boss_dragon_adapter=PASS ai_disabled=true player_driver=true movement=true projectile_failure_cleanup=true")
