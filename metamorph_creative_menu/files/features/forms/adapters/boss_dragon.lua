local boss_dragon_adapter = {}

local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local form_controls = dofile("mods/metamorph_creative_menu/files/features/forms/controls.lua")
local combat = dofile("mods/metamorph_creative_menu/files/features/forms/combat.lua")

local valid = component_ops.valid
local component = component_ops.first
local get_value = component_ops.get
local set_typed_scalar = component_ops.set_typed_scalar
local ensure_controls = component_ops.ensure_controls

local next_primary_attack_frame = 0
local next_secondary_attack_frame = 0
local primary_projectile_path = ""
local secondary_projectile_path = ""
local primary_projectile_count = 1
local secondary_projectile_count = 1
local movement_speed = 0
local movement_acceleration = 0

local function configure(entity)
    combat.configure_non_ai_player(entity)
    combat.setup_manual_barrels(entity)
    local controls_component = component(entity, "ControlsComponent")
    -- Boss dragon keeps a dedicated projectile adapter below, so unlike ordinary forms
    -- it must not also let polymorph_hax fire the same authored attack a second time.
    if valid(controls_component) then pcall(ComponentSetValue2, controls_component, "polymorph_hax", false) end
    local dragon = component(entity, "BossDragonComponent")
    if not valid(dragon) then return end
    primary_projectile_path = tostring(get_value(dragon, "projectile_1", "") or "")
    secondary_projectile_path = tostring(get_value(dragon, "projectile_2", "") or "")
    primary_projectile_count = math.max(0, tonumber(get_value(dragon, "projectile_1_count", 0)) or 0)
    secondary_projectile_count = math.max(0, tonumber(get_value(dragon, "projectile_2_count", 0)) or 0)
    movement_speed = math.max(0, tonumber(get_value(dragon, "speed", 1)) or 1)
    movement_acceleration = math.max(0, tonumber(get_value(dragon, "acceleration", 3)) or 3)
    -- BossDragon is an AI-only worm motor. Driving its private target fields made
    -- player input compete with hunt phases and produced long, inconsistent turns.
    -- Adapt it once to Noita's real playable-worm interface instead: a WormComponent
    -- owns the same body and WormPlayerComponent consumes the normal polymorph input.
    local worm = component(entity, "WormComponent")
    if not valid(worm) then
        local ok_worm, created_worm = pcall(EntityAddComponent2, entity, "WormComponent", {
            _tags = "metamorph_creative_menu_boss_worm_driver",
            speed = movement_speed,
            max_speed = math.max(25, movement_speed * 4),
            acceleration = movement_acceleration,
            gravity = 0,
            tail_gravity = 0,
            part_distance = tonumber(get_value(dragon, "part_distance", 10)) or 10,
            ground_check_offset = tonumber(get_value(dragon, "ground_check_offset", 0)) or 0,
            hitbox_radius = tonumber(get_value(dragon, "hitbox_radius", 1)) or 1,
            bite_damage = tonumber(get_value(dragon, "bite_damage", 2)) or 2,
            target_kill_radius = tonumber(get_value(dragon, "target_kill_radius", 1)) or 1,
            target_kill_ragdoll_force = tonumber(get_value(dragon, "target_kill_ragdoll_force", 1)) or 1,
            eat_anim_wait_mult = tonumber(get_value(dragon, "eat_anim_wait_mult", 0.05)) or 0.05,
            jump_cam_shake = tonumber(get_value(dragon, "jump_cam_shake", 20)) or 20,
            ragdoll_filename = tostring(get_value(dragon, "ragdoll_filename", "") or ""),
        })
        if ok_worm and valid(created_worm) then worm = created_worm end
    end
    local player_driver = component(entity, "WormPlayerComponent")
    if valid(worm) and not valid(player_driver) then
        local ok_player, created_player = pcall(EntityAddComponent2, entity, "WormPlayerComponent", {
            _tags = "metamorph_creative_menu_boss_worm_driver",
        })
        if ok_player and valid(created_player) then player_driver = created_player end
    end
    if valid(worm) and valid(player_driver) then
        pcall(EntitySetComponentIsEnabled, entity, worm, true)
        pcall(EntitySetComponentIsEnabled, entity, player_driver, true)
        pcall(EntitySetComponentIsEnabled, entity, dragon, false)
    end
end

local function shoot_boss_projectile(entity, path, count, x, y)
    if type(path) ~= "string" or path == "" or not ModDoesFileExist(path) then return false end
    local tx, ty = x, y - 40
    local ok_mouse, mx, my = pcall(DEBUG_GetMouseWorld)
    if ok_mouse and mx ~= nil and my ~= nil then tx, ty = mx, my end
    local fired = false
    for _ = 1, math.max(1, math.min(10, tonumber(count) or 1)) do
        local projectile = EntityLoad(path, x, y)
        if projectile ~= nil and projectile ~= 0 then
            local shot_ok = pcall(GameShootProjectile, entity, x, y, tx, ty, projectile, true)
            if shot_ok then
                fired = true
            else
                pcall(EntityKill, projectile)
            end
        end
    end
    return fired
end

local function update(entity)
    local controls_component = ensure_controls(entity)
    local _, _, moving = form_controls.direction(controls_component)
    local dragon = component(entity, "BossDragonComponent")
    if not valid(dragon) then return end
    local x, y = EntityGetTransform(entity)
    if x == nil then return end
    -- Never let a late engine state transition reactivate the competing AI motor.
    pcall(EntitySetComponentIsEnabled, entity, dragon, false)
    local worm = component(entity, "WormComponent")
    if valid(worm) then
        -- WormPlayer otherwise assigns its generic player speed (~3.5) to every worm.
        -- Translate the boss's authored locomotion envelope to the native worm motor;
        -- WormComponent still performs the acceleration/deceleration itself.
        set_typed_scalar(worm, "speed", movement_speed)
        set_typed_scalar(worm, "acceleration", movement_acceleration)
        pcall(ComponentSetValue2, worm, "mTargetSpeed", moving and movement_speed or 0)
    end

    if valid(controls_component) then
        local frame = GameGetFrameNum()
        local fire1 = get_value(controls_component, "mButtonDownFire", false) == true
        local fire2 = get_value(controls_component, "mButtonDownFire2", false) == true
        if fire1 and frame >= next_primary_attack_frame then
            if shoot_boss_projectile(entity, primary_projectile_path, primary_projectile_count, x, y) then
                combat.play_attack_animation(entity, "eat", 40)
                next_primary_attack_frame = frame + 24
            end
        end
        if fire2 and frame >= next_secondary_attack_frame then
            if shoot_boss_projectile(entity, secondary_projectile_path, secondary_projectile_count, x, y) then
                combat.play_attack_animation(entity, "eat", 40)
                next_secondary_attack_frame = frame + 45
            end
        end
    end
end


function boss_dragon_adapter.reset()
    next_primary_attack_frame = 0
    next_secondary_attack_frame = 0
    primary_projectile_path = ""
    secondary_projectile_path = ""
    primary_projectile_count = 1
    secondary_projectile_count = 1
    movement_speed = 0
    movement_acceleration = 0
end

boss_dragon_adapter.configure = configure
boss_dragon_adapter.update = update

return boss_dragon_adapter
