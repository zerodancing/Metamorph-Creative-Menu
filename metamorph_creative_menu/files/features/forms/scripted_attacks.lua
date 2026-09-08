if type(METAMORPH_CREATIVE_MENU_FORM_SCRIPTED_ATTACKS) == "table" then
    return METAMORPH_CREATIVE_MENU_FORM_SCRIPTED_ATTACKS
end

local scripted = {}
local entity_tree = dofile("mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua")
local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local mathx = dofile("mods/metamorph_creative_menu/files/features/forms/scripted_attack_math.lua")

local valid = component_ops.valid
local get_value = component_ops.get
local ensure_controls = component_ops.ensure_controls
local walk_entity_tree = entity_tree.walk

local SCRIPT = {
    MONK = "data/scripts/animals/monk_hand_shoot.lua",
    FUNGUS_GIGA = "data/scripts/animals/fungus_giga_pollen.lua",
    BOSS_DRAGON = "data/scripts/projectiles/orb_green_dragon.lua",
    BOSS_LIMBS = "data/entities/animals/boss_limbs/boss_limbs_update.lua",
    BOSS_MEAT_SHOT = "data/entities/animals/boss_meat/shot.lua",
    BOSS_MEAT_EYE = "data/entities/animals/boss_meat/eye.lua",
    FISH_GIGA = "data/entities/animals/boss_fish/eye.lua",
    BOSS_ROBOT = "data/entities/animals/boss_robot/state.lua",
    BOSS_PIT = "data/entities/animals/boss_pit/boss_pit_logic.lua",
    MAGGOT_TINY = "data/entities/animals/maggot_tiny/shot.lua",
    BOSS_WIZARD = "data/entities/animals/boss_wizard/bloodtentacle.lua",
    BOSS_CENTIPEDE = "data/entities/animals/boss_centipede/boss_centipede_update.lua",
    BOSS_CENTIPEDE_BEFORE_FIGHT = "data/entities/animals/boss_centipede/boss_centipede_before_fight.lua",
    BOSS_GHOST_LASERS = "data/entities/animals/boss_ghost/lasers.lua",
}

local MANAGED = {}
for key, path in pairs(SCRIPT) do
    if key ~= "BOSS_GHOST_LASERS" and key ~= "BOSS_CENTIPEDE_BEFORE_FIGHT" then MANAGED[path] = true end
end

local SUPPRESS_ONLY = {
    [SCRIPT.BOSS_CENTIPEDE_BEFORE_FIGHT] = true,
}

-- Arena-gated coroutine controllers are authored disabled until vanilla encounter
-- setup starts them. A transformed form has no arena trigger, so these controllers
-- are the only scripts we intentionally make available from an initially-disabled
-- component. Ordinary disabled attack scripts (for example boss_wizard's tagged
-- blood-tentacle phase) stay unavailable until their owning vanilla state enables them.
local REPLAY_WHEN_INITIALLY_DISABLED = {
    [SCRIPT.BOSS_CENTIPEDE] = true,
}

local active_entity = 0
local active_path = ""
local records = {}
local by_script = {}
local state = {}
local target_entity = 0
local manages_lasers = false

local function frame_num()
    return tonumber(GameGetFrameNum()) or 0
end

local function mouse_target(x, y)
    local ok, mx, my = pcall(DEBUG_GetMouseWorld)
    if ok and tonumber(mx) ~= nil and tonumber(my) ~= nil then return tonumber(mx), tonumber(my) end
    return x, y - 100
end

local function component_enabled(_, comp)
    if type(ComponentGetIsEnabled) ~= "function" then return false end
    local ok, enabled = pcall(ComponentGetIsEnabled, comp)
    return ok and enabled == true
end

local function find_variable(entity, name)
    local result = nil
    walk_entity_tree(entity, function(current)
        for _, comp in ipairs(EntityGetComponentIncludingDisabled(current, "VariableStorageComponent") or {}) do
            if tostring(get_value(comp, "name", "") or "") == name then
                result = comp
                return false
            end
        end
    end)
    return result
end

local function get_herd(entity)
    local comp = EntityGetFirstComponentIncludingDisabled(entity, "GenomeDataComponent")
    return valid(comp) and (tonumber(get_value(comp, "herd_id", -1)) or -1) or -1
end

local function set_velocity(entity, vx, vy)
    for _, comp in ipairs(EntityGetComponentIncludingDisabled(entity, "VelocityComponent") or {}) do
        pcall(ComponentSetValue2, comp, "mVelocity", vx, vy)
    end
end

-- Deliberately mirrors data/scripts/lib/utilities.lua::shoot_projectile. Scripted
-- vanilla attacks author explicit velocities, so GameShootProjectile alone is not
-- sufficient: utilities.lua also stamps shooter metadata and the VelocityComponent.
local function shoot_velocity(who, path, x, y, vx, vy, send_message)
    path = tostring(path or "")
    if path == "" then return 0 end
    local projectile = EntityLoad(path, x, y)
    if projectile == nil or projectile == 0 then return 0 end
    local send = send_message ~= false
    local ok = pcall(GameShootProjectile, who, x, y, x + vx, y + vy, projectile, send)
    if not ok then
        pcall(EntityKill, projectile)
        return 0
    end
    local herd = get_herd(who)
    for _, comp in ipairs(EntityGetComponentIncludingDisabled(projectile, "ProjectileComponent") or {}) do
        pcall(ComponentSetValue2, comp, "mWhoShot", who)
        pcall(ComponentSetValue2, comp, "mShooterHerdId", herd)
    end
    set_velocity(projectile, vx, vy)
    return projectile
end

local function ensure_target()
    if target_entity ~= 0 and EntityGetIsAlive(target_entity) then return target_entity end
    target_entity = EntityCreateNew("metamorph_creative_menu_scripted_attack_target") or 0
    if target_entity ~= 0 then
        EntityAddTag(target_entity, "metamorph_creative_menu_runtime")
        EntityAddTag(target_entity, "metamorph_creative_menu_attack_target")
    end
    return target_entity
end

local function update_target(entity)
    local x, y = EntityGetTransform(entity)
    if x == nil then return 0 end
    local tx, ty = mouse_target(x, y)
    local target = ensure_target()
    if target ~= 0 then pcall(EntitySetTransform, target, tx, ty) end
    return target
end

local function due(key, interval, frame)
    local next_frame = tonumber(state[key]) or 0
    if frame < next_frame then return false end
    state[key] = frame + math.max(1, tonumber(interval) or 1)
    return true
end

local function owners(script_path)
    return by_script[script_path] or {}
end

local function first_owner(script_path)
    local list = owners(script_path)
    return type(list[1]) == "table" and list[1].owner or nil
end

local function authored_next_frame(record, fallback_interval, now)
    if type(record) ~= "table" or not valid(record.component) then return now end
    local interval = tonumber(get_value(record.component, "execute_every_n_frame", fallback_interval)) or fallback_interval
    if interval == nil or interval < 1 then return now end
    local last = tonumber(get_value(record.component, "mLastExecutionFrame", -1)) or -1
    if last >= 0 then return math.max(now, last + interval) end
    return now + interval
end

local function root_position(entity)
    local x, y = EntityGetTransform(entity)
    return x, y
end

local function random_float(low, high)
    if type(Random) == "function" then
        local ok, r = pcall(Random)
        if ok and tonumber(r) ~= nil then return low + tonumber(r) * (high - low) end
    end
    return low
end

local function fire_monk(entity, frame, held)
    for index, record in ipairs(owners(SCRIPT.MONK)) do
        local key = "monk_" .. tostring(index)
        local next_frame = tonumber(state[key]) or 0
        if frame >= next_frame then
            local owner = record.owner
            local sprite = EntityGetFirstComponentIncludingDisabled(owner, "SpriteComponent")
            local x, y = EntityGetTransform(owner)
            if type(EntityGetFirstHitboxCenter) == "function" then
                local ok, hx, hy = pcall(EntityGetFirstHitboxCenter, owner)
                if ok and hx ~= nil then x, y = hx, hy end
            end
            local can_shoot = held == true and x ~= nil
            local tx, ty = x, y
            if can_shoot then
                tx, ty = mouse_target(x, y)
                -- Vanilla target search caps this attack at 200px. Under player
                -- authority the cursor is explicit intent rather than an AI-acquired
                -- enemy, so range must not reject the shot. Preserve the authored LOS
                -- requirement because it is part of the attack itself, not acquisition.
                if type(RaytraceSurfacesAndLiquiform) == "function" then
                    local ok, blocked = pcall(RaytraceSurfacesAndLiquiform, x, y, tx, ty)
                    if ok and blocked == true then can_shoot = false end
                end
            end
            if not can_shoot then
                if valid(sprite) and tostring(get_value(sprite, "rect_animation", "") or "") ~= "open" then
                    pcall(ComponentSetValue2, sprite, "rect_animation", "open")
                end
                state[key] = frame + 60
            else
                local hand_open = valid(sprite) and tostring(get_value(sprite, "rect_animation", "") or "") == "open"
                if hand_open then
                    pcall(ComponentSetValue2, sprite, "rect_animation", "close")
                    state[key] = frame + 60
                else
                    local vx, vy = mathx.aimed(x, y, tx, ty, 1)
                    x, y = x + vx * 8, y + vy * 8
                    if type(SetRandomSeed) == "function" then pcall(SetRandomSeed, x + frame, y) end
                    local scatter = random_float(-0.2, 0.2)
                    vx, vy = mathx.rotate(vx, vy, scatter)
                    shoot_velocity(entity, "data/entities/projectiles/orb_green_accelerating.xml", x, y, vx * 20, vy * 20)
                    local delay = 55
                    if type(Random) == "function" then
                        local ok, value = pcall(Random, 10)
                        if ok and tonumber(value) ~= nil then delay = 55 + tonumber(value) end
                    end
                    state[key] = frame + math.max(55, math.floor(delay))
                end
            end
        end
    end
end

local function fire_fungus_giga(entity, frame, held)
    if not held or not due("fungus_giga", 10, frame) then return end
    local x, y = root_position(entity)
    if x == nil then return end
    -- fungus_giga_pollen.lua normally requires an AI target inside 64px. Player-held
    -- fire is already the target-acquisition decision, so keep the authored cadence and
    -- projectile spread without applying that AI-only radius to the cursor.
    if type(SetRandomSeed) == "function" then pcall(SetRandomSeed, x + entity, y + frame) end
    local vx, vy = -300, -300
    if type(Random) == "function" then
        local okx, rx = pcall(Random, -300, 300)
        local oky, ry = pcall(Random, -300, 10)
        if okx and tonumber(rx) ~= nil then vx = tonumber(rx) end
        if oky and tonumber(ry) ~= nil then vy = tonumber(ry) end
    end
    shoot_velocity(entity, "data/entities/projectiles/pollen.xml", x, y, vx, vy)
end

local function fire_boss_dragon(entity, frame, held)
    if not held or not due("boss_dragon", 80, frame) then return end
    local owner = first_owner(SCRIPT.BOSS_DRAGON) or entity
    local x, y = EntityGetTransform(owner)
    if x == nil then return end
    for _, v in ipairs(mathx.radial(10, 100, 0, false)) do
        local px, py = x + v.x * 0.1, y + v.y * 0.1
        if type(GameEntityPlaySound) == "function" then pcall(GameEntityPlaySound, owner, "duplicate") end
        shoot_velocity(owner, "data/entities/projectiles/orb_green_boss_dragon.xml", px, py, v.x, v.y)
    end
    if type(GamePlaySound) == "function" then
        pcall(GamePlaySound, "data/audio/Desktop/projectiles.bank", "projectiles/orb_dragon/create", x, y)
    end
end

local function boss_meat_eye_step(entity)
    local status_comp = find_variable(entity, "status")
    if not valid(status_comp) then return end
    local status = tonumber(get_value(status_comp, "value_int", 0)) or 0
    local x, y = root_position(entity)
    if status == 1 then
        if type(GamePlayAnimation) == "function" then pcall(GamePlayAnimation, entity, "open", 0, "opened", 0) end
        -- Vanilla eye.lua disables the `vacuum_NOT` group here, which is also the
        -- group containing shot.lua. Preserve that firing window even though the Lua
        -- component itself is held disabled by this replay layer.
        state.boss_meat_acid_enabled = false
        if type(EntitySetComponentsWithTagEnabled) == "function" then
            pcall(EntitySetComponentsWithTagEnabled, entity, "vacuum", true)
            pcall(EntitySetComponentsWithTagEnabled, entity, "vacuum_NOT", false)
        end
        local hit = EntityGetFirstComponentIncludingDisabled(entity, "HitboxComponent")
        if valid(hit) then pcall(ComponentSetValue2, hit, "damage_multiplier", 1.0) end
    elseif status == 3 then
        if type(GamePlayAnimation) == "function" then pcall(GamePlayAnimation, entity, "close", 0, "stand", 0) end
        state.boss_meat_acid_enabled = true
        if type(EntitySetComponentsWithTagEnabled) == "function" then
            pcall(EntitySetComponentsWithTagEnabled, entity, "vacuum", false)
            -- In vanilla boss_meat.xml the only `vacuum_NOT` component is shot.lua.
            -- That script is owned and replayed manually by this module, so enabling
            -- the tag here would run the original acid attack in parallel. Keep the
            -- native script disabled and let boss_meat_acid_enabled represent the
            -- same eye-closed firing window for the manual replay.
        end
        local hit = EntityGetFirstComponentIncludingDisabled(entity, "HitboxComponent")
        if valid(hit) then pcall(ComponentSetValue2, hit, "damage_multiplier", 0) end
        if x ~= nil then shoot_velocity(entity, "data/entities/animals/boss_meat/orb_big.xml", x, y, 0, 0) end
    end
    pcall(ComponentSetValue2, status_comp, "value_int", (status + 1) % 4)
end

local function fire_boss_meat(entity, frame, held)
    if not held then return end
    local x, y = root_position(entity)
    if x == nil then return end
    if state.boss_meat_acid_enabled ~= false and due("boss_meat_acid", 20, frame) then
        if type(SetRandomSeed) == "function" then pcall(SetRandomSeed, x + frame, y) end
        local rnd = 0
        if type(Random) == "function" then
            local ok, value = pcall(Random, 0, 99)
            if ok and tonumber(value) ~= nil then rnd = tonumber(value) * 0.01 end
        end
        local angle = math.pi * 2 * rnd
        shoot_velocity(entity, "data/entities/animals/boss_meat/acidshot_slow.xml", x, y,
            math.cos(angle) * 90, -math.sin(angle) * 90)
    end
    if due("boss_meat_eye", 80, frame) then boss_meat_eye_step(entity) end
end

local function fire_fish_giga(entity, frame, held)
    local owner = first_owner(SCRIPT.FISH_GIGA)
    if owner == nil then return end
    local key = "fish_timer"
    local timer = tonumber(state[key]) or 0
    local sprite = EntityGetFirstComponentIncludingDisabled(owner, "SpriteComponent")
    local root = EntityGetRootEntity(owner)
    if root == nil or root == 0 then root = entity end
    local hitbox = EntityGetFirstComponentIncludingDisabled(root, "HitboxComponent")
    local function set_eye_hitbox(value)
        if valid(hitbox) then pcall(EntitySetComponentIsEnabled, owner, hitbox, value == true) end
    end
    local current = valid(sprite) and tostring(get_value(sprite, "rect_animation", "") or "") or ""
    if current == "" then
        current = "closed"
        if valid(sprite) then pcall(ComponentSetValue2, sprite, "rect_animation", current) end
        set_eye_hitbox(false)
    end
    timer = timer + 1
    local player_driving_attack = held == true
    if player_driving_attack then
        local x = EntityGetTransform(owner)
        if x == nil then player_driving_attack = false end
    end
    -- Vanilla opens this eye only while a player is inside a 160px acquisition radius.
    -- In a controlled form the local fire button replaces that acquisition condition.
    if not player_driving_attack then
        if current == "opened" and valid(sprite) then
            pcall(ComponentSetValue2, sprite, "rect_animation", "close")
            pcall(ComponentSetValue2, sprite, "next_rect_animation", "closed")
            timer = 0
            set_eye_hitbox(false)
        elseif current == "close" and timer > 36 and valid(sprite) then
            pcall(ComponentSetValue2, sprite, "rect_animation", "closed")
            pcall(ComponentSetValue2, sprite, "next_rect_animation", "closed")
            timer = 0
        end
        state[key] = timer
        return
    end
    if current == "closed" and valid(sprite) then
        pcall(ComponentSetValue2, sprite, "rect_animation", "open")
        pcall(ComponentSetValue2, sprite, "next_rect_animation", "opened")
        timer = 0
    elseif current == "open" and timer > 36 and valid(sprite) then
        pcall(ComponentSetValue2, sprite, "rect_animation", "opened")
        pcall(ComponentSetValue2, sprite, "next_rect_animation", "opened")
        timer = 0
        set_eye_hitbox(true)
    elseif current == "opened" and timer > 360 then
        timer = 0
        local x, y = EntityGetTransform(owner)
        if x ~= nil then
            if type(SetRandomSeed) == "function" then pcall(SetRandomSeed, x + y, frame) end
            local offset = 0.01 * math.pi
            if type(Random) == "function" then
                local ok, r = pcall(Random, 1, 100)
                if ok and tonumber(r) ~= nil then offset = tonumber(r) * 0.01 * math.pi end
            end
            for _, v in ipairs(mathx.radial(8, 80, offset, true)) do
                shoot_velocity(entity, "data/entities/animals/boss_fish/orb_big.xml", x, y, v.x, v.y)
            end
        end
    end
    state[key] = timer
end

local function fire_maggot(entity, frame, held)
    if not held or not due("maggot", 20, frame) then return end
    local var = find_variable(entity, "shooter_part")
    if not valid(var) then return end
    local current = tonumber(get_value(var, "value_int", 1)) or 1
    if current > 0 and current <= 11 then
        local children = EntityGetAllChildren(entity) or {}
        local n = 0
        for _, child in ipairs(children) do
            if valid(EntityGetFirstComponentIncludingDisabled(child, "GenomeDataComponent")) then
                n = n + 1
                if n == current then
                    local x, y = EntityGetTransform(child)
                    if x ~= nil then shoot_velocity(entity, "data/entities/animals/maggot_tiny/orb.xml", x, y, 0, 0) end
                    break
                end
            end
        end
    end
    current = current + 1
    if current > 33 then current = 1 end
    pcall(ComponentSetValue2, var, "value_int", current)
end

local function fire_boss_wizard(entity, frame, held)
    if not held or not due("boss_wizard", 16, frame) then return end
    local x, y = root_position(entity)
    if x == nil then return end
    for i = 1, 2 do
        if type(SetRandomSeed) == "function" then pcall(SetRandomSeed, x * frame, y + i) end
        local r = 0
        if type(Random) == "function" then
            local ok, value = pcall(Random, 0, 100)
            if ok and tonumber(value) ~= nil then r = tonumber(value) end
        end
        local arc = r * 0.01 * math.pi * 2
        shoot_velocity(entity, "data/entities/animals/boss_wizard/bloodtentacle.xml", x, y - 32,
            math.cos(arc) * 150, -math.sin(arc) * 150)
    end
end

local function set_laser_object(comp, key, value)
    if type(ComponentObjectSetValue2) == "function" then pcall(ComponentObjectSetValue2, comp, "laser", key, value) end
end

local function boss_robot_step(entity, frame)
    local state_comp = find_variable(entity, "state")
    if not valid(state_comp) then return end
    local value = (tonumber(get_value(state_comp, "value_int", 0)) or 0) + 1
    local x, y = root_position(entity)
    if x == nil then return end
    if type(SetRandomSeed) == "function" then pcall(SetRandomSeed, x + frame, y + entity) end
    local lasers = EntityGetComponentIncludingDisabled(entity, "LaserEmitterComponent") or {}
    local eatercomp = find_variable(entity, "spell_eater")
    if value == 2 then
        if valid(eatercomp) then pcall(ComponentSetValue2, eatercomp, "value_int", 0) end
        -- The vanilla state script gates this rocket phase on a nearby target. The
        -- controlled form already has explicit player fire intent, so do not suppress
        -- the phase merely because the cursor is beyond the AI's 300px search radius.
        for _ = 1, 10 do
            local angle_roll, length = 0, 100
            if type(Random) == "function" then
                local oka, a = pcall(Random, 0, 100); if oka and tonumber(a) ~= nil then angle_roll = tonumber(a) end
                local okl, l = pcall(Random, 100, 250); if okl and tonumber(l) ~= nil then length = tonumber(l) end
            end
            local a = math.pi * (angle_roll * 0.01)
            shoot_velocity(entity, "data/entities/animals/boss_robot/rocket_roll.xml", x, y,
                math.cos(a) * length, -math.sin(a) * length)
        end
    elseif value == 4 then
        if valid(eatercomp) then pcall(ComponentSetValue2, eatercomp, "value_int", 1) end
    elseif value == 6 then
        if valid(eatercomp) then pcall(ComponentSetValue2, eatercomp, "value_int", 0) end
        local tx, ty = mouse_target(x, y)
        local a = math.atan2(ty - y, tx - x)
        for _, laser in ipairs(lasers) do
            pcall(ComponentSetValue2, laser, "laser_angle_add_rad", a)
            set_laser_object(laser, "beam_radius", 1.5)
            set_laser_object(laser, "damage_to_entities", 0)
            set_laser_object(laser, "damage_to_cells", 10)
            set_laser_object(laser, "max_cell_durability_to_destroy", 2)
            set_laser_object(laser, "audio_enabled", false)
            pcall(ComponentSetValue2, laser, "is_emitting", true)
        end
    elseif value == 8 then
        for index, laser in ipairs(lasers) do
            set_laser_object(laser, "beam_radius", 10.5)
            set_laser_object(laser, "damage_to_entities", 0.6)
            set_laser_object(laser, "damage_to_cells", 700000)
            set_laser_object(laser, "max_cell_durability_to_destroy", 14)
            if index == 1 then set_laser_object(laser, "audio_enabled", true) end
        end
    elseif value == 10 then
        for _, laser in ipairs(lasers) do
            pcall(ComponentSetValue2, laser, "is_emitting", false)
            set_laser_object(laser, "beam_radius", 1.5)
            set_laser_object(laser, "damage_to_entities", 0)
            set_laser_object(laser, "damage_to_cells", 10)
            set_laser_object(laser, "max_cell_durability_to_destroy", 2)
            set_laser_object(laser, "audio_enabled", false)
        end
        if valid(eatercomp) then pcall(ComponentSetValue2, eatercomp, "value_int", 1) end
    elseif value >= 13 then
        if type(EntityGetWithTag) == "function" then
            local ok, healers = pcall(EntityGetWithTag, "healer")
            if ok and type(healers) == "table" and #healers < 3 then
                pcall(EntityLoad, "data/entities/animals/robobase/healerdrone_physics.xml", x, y)
            end
        end
        value = 0
    end
    pcall(ComponentSetValue2, state_comp, "value_int", value)
end

local function boss_robot_laser_cycle_active(entity)
    local state_comp = find_variable(entity, "state")
    if not valid(state_comp) then return false end
    local value = tonumber(get_value(state_comp, "value_int", 0)) or 0
    return value >= 6 and value < 10
end

local function boss_robot_stop_lasers(entity)
    for _, laser in ipairs(EntityGetComponentIncludingDisabled(entity, "LaserEmitterComponent") or {}) do
        pcall(ComponentSetValue2, laser, "is_emitting", false)
        set_laser_object(laser, "beam_radius", 1.5)
        set_laser_object(laser, "damage_to_entities", 0)
        set_laser_object(laser, "damage_to_cells", 10)
        set_laser_object(laser, "max_cell_durability_to_destroy", 2)
        set_laser_object(laser, "audio_enabled", false)
    end
end

local function fire_boss_robot(entity, frame, held)
    -- Player input starts/continues the authored cycle, but once state 6 has enabled
    -- the laser we must advance through state 10 even after fire is released. Otherwise
    -- the manually-owned LaserEmitterComponent can remain damaging forever.
    if (held or boss_robot_laser_cycle_active(entity)) and due("boss_robot", 40, frame) then
        boss_robot_step(entity, frame)
    end
end

local function add_homing_to_target(projectile)
    if projectile == nil or projectile == 0 then return end
    update_target(active_entity)
    pcall(EntityAddComponent2, projectile, "HomingComponent", {
        homing_targeting_coeff = 30.0,
        homing_velocity_multiplier = 0.16,
        target_tag = "metamorph_creative_menu_attack_target",
    })
end

local function boss_pit_step(entity, frame)
    local state_comp = find_variable(entity, "state")
    local memory_comp = find_variable(entity, "memory")
    if not valid(state_comp) then return end
    local current = ((tonumber(get_value(state_comp, "value_int", 0)) or 0) + 1) % 10
    local x, y = root_position(entity)
    if x == nil then return end
    if type(SetRandomSeed) == "function" then pcall(SetRandomSeed, x, y * frame) end
    if current == 1 then
        local memory = valid(memory_comp) and tostring(get_value(memory_comp, "value_string", "") or "") or ""
        if memory == "" then
            memory = "data/entities/projectiles/enlightened_laser_darkbeam.xml"
            if valid(memory_comp) then pcall(ComponentSetValue2, memory_comp, "value_string", memory) end
        end
        local angle_roll, pick = 1, 1
        if type(Random) == "function" then
            local oka, a = pcall(Random, 1, 200); if oka and tonumber(a) ~= nil then angle_roll = tonumber(a) end
            local okp, r = pcall(Random, 1, 7); if okp and tonumber(r) ~= nil then pick = tonumber(r) end
        end
        local a = angle_roll * math.pi
        local spells = {"rocket", "rocket_tier_2", "rocket_tier_3", "grenade", "grenade_tier_2", "grenade_tier_3", "rubber_ball"}
        local path = "data/entities/projectiles/deck/" .. spells[math.max(1, math.min(#spells, math.floor(pick)))] .. ".xml"
        local wand = shoot_velocity(entity, "data/entities/animals/boss_pit/wand.xml", x, y, math.cos(a) * 100, -math.cos(a) * 100)
        if wand ~= 0 then
            for _, comp in ipairs(EntityGetComponentIncludingDisabled(wand, "VariableStorageComponent") or {}) do
                pcall(ComponentSetValue2, comp, "value_string", path)
            end
            add_homing_to_target(wand)
            pcall(EntityAddComponent2, wand, "VariableStorageComponent", {
                name="mult", value_float=string.find(path, "rocket", 1, true) ~= nil and 0.5 or 1.2,
            })
        end
    elseif current == 7 then
        local stuck_comp = find_variable(entity, "pathfinding_frames_stuck")
        local stuck = valid(stuck_comp) and (tonumber(get_value(stuck_comp, "value_int", 0)) or 0) or 0
        if stuck > 160 then
            shoot_velocity(entity, "data/entities/projectiles/remove_ground.xml", x, y, 0, 0)
        else
            local opts = {"orb_poly", "orb_neutral", "orb_tele", "orb_dark"}
            local pick, off = 1, 1
            if type(Random) == "function" then
                local okp, p = pcall(Random, 1, #opts); if okp and tonumber(p) ~= nil then pick = tonumber(p) end
                local oko, o = pcall(Random, 1, 10); if oko and tonumber(o) ~= nil then off = tonumber(o) end
            end
            local path = "data/entities/projectiles/" .. opts[math.max(1, math.min(#opts, math.floor(pick)))] .. ".xml"
            local offset = math.pi * (off * 0.1)
            for _, v in ipairs(mathx.radial(8, 300, offset, true)) do shoot_velocity(entity, path, x, y, v.x, v.y) end
        end
    end
    pcall(ComponentSetValue2, state_comp, "value_int", current)
end

local function boss_pit_maintenance(entity, frame)
    if not due("boss_pit_maintenance", 40, frame) then return end
    local hitbox = EntityGetFirstComponentIncludingDisabled(entity, "HitboxComponent")
    if valid(hitbox) then
        local multiplier = tonumber(get_value(hitbox, "damage_multiplier", 1)) or 1
        if multiplier < 1 then
            pcall(ComponentSetValue2, hitbox, "damage_multiplier", math.min(1, multiplier + 0.35))
        end
    end
    if type(EntitySetComponentsWithTagEnabled) == "function" then
        pcall(EntitySetComponentsWithTagEnabled, entity, "invincible", false)
    end
end

local function fire_boss_pit(entity, frame, held)
    -- boss_pit_logic.lua contains two independent responsibilities. Its defensive
    -- recovery is passive and must keep ticking even under player control; only the
    -- projectile state machine is gated by primary fire.
    boss_pit_maintenance(entity, frame)
    if held and due("boss_pit", 40, frame) then boss_pit_step(entity, frame) end
end

local function boss_limbs_set_hitboxes(entity, weak)
    if type(EntitySetComponentsWithTagEnabled) == "function" then
        pcall(EntitySetComponentsWithTagEnabled, entity, "hitbox_weak_spot", weak == true)
        pcall(EntitySetComponentsWithTagEnabled, entity, "hitbox_default", weak ~= true)
    end
end

local function boss_limbs_set_details(entity, hidden)
    local sprites = EntityGetComponentIncludingDisabled(entity, "SpriteComponent") or {}
    local animation = hidden and "invisible" or "stand"
    -- Vanilla boss_limbs_update.lua treats the first SpriteComponent as the main
    -- body and every later sprite as a cosmetic detail.
    for index = 2, #sprites do
        pcall(ComponentSetValue2, sprites[index], "rect_animation", animation)
    end
end

local function boss_limbs_update_lifecycle(entity, frame)
    local weak_due = tonumber(state.boss_limbs_weak_due)
    if weak_due ~= nil and frame >= weak_due then
        boss_limbs_set_hitboxes(entity, true)
        state.boss_limbs_weak_due = nil
    end

    local close_due = tonumber(state.boss_limbs_close_due)
    if close_due ~= nil and frame >= close_due then
        if type(GamePlayAnimation) == "function" then pcall(GamePlayAnimation, entity, "close", 0, "stand", 0) end
        state.boss_limbs_close_due = nil
    end

    local default_due = tonumber(state.boss_limbs_default_hitbox_due)
    if default_due ~= nil and frame >= default_due then
        boss_limbs_set_hitboxes(entity, false)
        state.boss_limbs_default_hitbox_due = nil
    end

    local details_due = tonumber(state.boss_limbs_details_due)
    if details_due ~= nil and frame >= details_due then
        boss_limbs_set_details(entity, false)
        state.boss_limbs_details_due = nil
    end
end

local function boss_limbs_begin_expose(entity, frame)
    if type(GamePlayAnimation) == "function" then pcall(GamePlayAnimation, entity, "open", 0, "opened", 0) end
    boss_limbs_set_details(entity, true)
    state.boss_limbs_weak_due = frame + 10
end

local function boss_limbs_schedule_close(frame, close_delay)
    local close_due = frame + close_delay
    state.boss_limbs_close_due = close_due
    state.boss_limbs_default_hitbox_due = close_due + 10
    state.boss_limbs_details_due = close_due + 40
end

local function fire_boss_limbs(entity, frame, primary, secondary)
    boss_limbs_update_lifecycle(entity, frame)
    local mode = state.boss_limbs_mode
    local sequence = state.boss_limbs_sequence
    if type(sequence) ~= "table" then
        if frame < (tonumber(state.boss_limbs_next) or 0) then return end
        if primary then
            state.boss_limbs_mode = "circle"
            state.boss_limbs_sequence = {step=1, due=frame + 45}
            boss_limbs_begin_expose(entity, frame)
        elseif secondary then
            state.boss_limbs_mode = "homing"
            state.boss_limbs_sequence = {step=1, due=frame + 45}
            boss_limbs_begin_expose(entity, frame)
        end
        return
    end
    if frame < (tonumber(sequence.due) or frame) then return end
    local x, y = root_position(entity)
    if x == nil then return end
    if mode == "circle" then
        for _, v in ipairs(mathx.radial_degrees(8, 230, 0)) do
            shoot_velocity(entity, "data/entities/animals/boss_limbs/orb_boss_limbs.xml", x, y, v.x, v.y)
        end
        if type(GamePlayAnimation) == "function" then pcall(GamePlayAnimation, entity, "attack_ranged", 0, "opened", 0) end
        sequence.step = sequence.step + 1
        if sequence.step <= 3 then
            sequence.due = frame + 65
        else
            -- phase1 after the third ring keeps the weak spot exposed for 240f, then
            -- closes it (40f) and waits 10f before another phase can begin.
            boss_limbs_schedule_close(frame, 240)
            state.boss_limbs_next = frame + 290
            state.boss_limbs_sequence=nil; state.boss_limbs_mode=nil
        end
    else
        shoot_velocity(entity, "data/entities/animals/boss_limbs/orb_pink_big.xml", x, y, 0, -30)
        if type(GamePlayAnimation) == "function" then pcall(GamePlayAnimation, entity, "attack_ranged", 0, "opened", 0) end
        sequence.step = sequence.step + 1
        if sequence.step <= 2 then
            sequence.due = frame + 55
        else
            -- phase4: after the second homing shot vanilla waits 120f, performs the
            -- 40f close sequence, then waits 10f before returning to phase0.
            boss_limbs_schedule_close(frame, 120)
            state.boss_limbs_next = frame + 170
            state.boss_limbs_sequence=nil; state.boss_limbs_mode=nil
        end
    end
end

local function centipede_orbcount(entity)
    local comp = find_variable(entity, "orbcount")
    if valid(comp) then return math.max(0, tonumber(get_value(comp, "value_int", 0)) or 0) end
    if type(GameGetOrbCountThisRun) == "function" then
        local ok, value = pcall(GameGetOrbCountThisRun)
        if ok and tonumber(value) ~= nil then return math.max(0, tonumber(value)) end
    end
    return 0
end

local function centipede_cursor_distance(entity)
    local x, y = root_position(entity); if x == nil then return math.huge end
    local tx, ty = mouse_target(x, y)
    local dx, dy = tx - x, ty - y
    return math.sqrt(dx * dx + dy * dy)
end

local function centipede_eye(entity, opened)
    opened = opened == true
    if state.centipede_eye_open == opened then return end
    state.centipede_eye_open = opened
    if type(GamePlayAnimation) == "function" then
        if opened then pcall(GamePlayAnimation, entity, "open", 0, "opened", 0)
        else pcall(GamePlayAnimation, entity, "close", 0, "stand", 0) end
    end
    if type(GameEntityPlaySound) == "function" then
        pcall(GameEntityPlaySound, entity, opened and "open_mouth" or "close_mouth")
    end
end

local function centipede_shield_entity(entity)
    if type(EntityGetName) ~= "function" then return 0 end
    for _, child in ipairs(EntityGetAllChildren(entity) or {}) do
        local ok, name = pcall(EntityGetName, child)
        if ok and tostring(name or "") == "shield_entity" then return child end
    end
    return 0
end


local function centipede_initialize_form(entity)
    local initialized = find_variable(entity, "initialized")
    local orbcount_comp = find_variable(entity, "orbcount")
    -- The vanilla boss contract contains both variables. If a modded derivative removes
    -- either one, do not invent initialization state for it; keep its authored values.
    if not valid(initialized) or not valid(orbcount_comp) then return false end

    local already_initialized = get_value(initialized, "value_bool", false) == true
    local orbcount = tonumber(get_value(orbcount_comp, "value_int", 0)) or 0
    if not already_initialized then
        local newgame_n = 0
        if type(SessionNumbersGetValue) == "function" then
            local ok, value = pcall(SessionNumbersGetValue, "NEW_GAME_PLUS_COUNT")
            if ok then newgame_n = tonumber(value) or 0 end
        end
        local run_orbs = 0
        if type(GameGetOrbCountThisRun) == "function" then
            local ok, value = pcall(GameGetOrbCountThisRun)
            if ok then run_orbs = tonumber(value) or 0 end
        end
        orbcount = math.max(0, math.floor(run_orbs + newgame_n))
        pcall(ComponentSetValue2, initialized, "value_bool", true)
        pcall(ComponentSetValue2, orbcount_comp, "value_int", orbcount)

        local damage = EntityGetFirstComponentIncludingDisabled(entity, "DamageModelComponent")
        if valid(damage) then
            local boss_hp = 46.0 + (2.0 ^ (orbcount + 1.3)) + (orbcount * 15.5)
            pcall(ComponentSetValue2, damage, "max_hp", boss_hp)
            pcall(ComponentSetValue2, damage, "hp", boss_hp)
            if type(ComponentObjectSetValue2) == "function" then
                if orbcount >= 3 then
                    pcall(ComponentObjectSetValue2, damage, "damage_multipliers", "melee", 1.5)
                    pcall(ComponentObjectSetValue2, damage, "damage_multipliers", "drill", 0.25)
                    pcall(ComponentObjectSetValue2, damage, "damage_multipliers", "projectile", 0.2)
                    pcall(ComponentObjectSetValue2, damage, "damage_multipliers", "fire", 0)
                    pcall(ComponentObjectSetValue2, damage, "damage_multipliers", "ice", 0)
                    pcall(ComponentObjectSetValue2, damage, "damage_multipliers", "electricity", 0)
                end
                if orbcount >= 5 then
                    pcall(ComponentObjectSetValue2, damage, "damage_multipliers", "melee", 1.0)
                    pcall(ComponentObjectSetValue2, damage, "damage_multipliers", "drill", 0.01)
                end
                if orbcount >= 9 then
                    pcall(ComponentObjectSetValue2, damage, "damage_multipliers", "slice", 0.5)
                    pcall(ComponentObjectSetValue2, damage, "damage_multipliers", "physics_hit", 0.5)
                    pcall(ComponentObjectSetValue2, damage, "damage_multipliers", "radioactive", 0.5)
                    pcall(ComponentObjectSetValue2, damage, "damage_multipliers", "poison", 0.5)
                end
                if orbcount >= 11 then
                    pcall(ComponentObjectSetValue2, damage, "damage_multipliers", "melee", 0.5)
                end
            end
        end

        if type(EntitySetDamageFromMaterial) == "function" then
            if orbcount >= 4 then pcall(EntitySetDamageFromMaterial, entity, "acid", 0.01) end
            if orbcount >= 7 then pcall(EntitySetDamageFromMaterial, entity, "acid", 0.0) end
            if orbcount == 12 then pcall(EntitySetDamageFromMaterial, entity, "magic_liquid_polymorph", 0.35) end
            if orbcount == 13 then pcall(EntitySetDamageFromMaterial, entity, "magic_liquid_random_polymorph", 0.35) end
            if orbcount == 14 then pcall(EntitySetDamageFromMaterial, entity, "magic_liquid_teleportation", 0.35) end
            if orbcount == 15 then pcall(EntitySetDamageFromMaterial, entity, "magic_liquid_movement_faster", 0.35) end
            if orbcount == 16 then pcall(EntitySetDamageFromMaterial, entity, "material_confusion", 0.35) end
        end
        if orbcount > 30 and type(EntityAddTag) == "function" then pcall(EntityAddTag, entity, "touchmagic_immunity") end

        if centipede_shield_entity(entity) == 0 and type(EntityLoad) == "function" and type(EntityAddChild) == "function" then
            local x, y = root_position(entity)
            if x ~= nil then
                local shield_path = orbcount == 0
                    and "data/entities/animals/boss_centipede/boss_centipede_shield_weak.xml"
                    or "data/entities/animals/boss_centipede/boss_centipede_shield_strong.xml"
                local ok_load, shield = pcall(EntityLoad, shield_path, x, y)
                if ok_load and shield ~= nil and shield ~= 0 then pcall(EntityAddChild, entity, shield) end
            end
        end
    end

    -- Vanilla init_boss() does this on every load, not only first initialization.
    if type(EntitySetComponentsWithTagEnabled) == "function" then
        for _, child in ipairs(EntityGetAllChildren(entity) or {}) do
            pcall(EntitySetComponentsWithTagEnabled, child, "disabled_at_start", true)
        end
    end
    state.centipede_orbcount = orbcount
    return true
end

local function centipede_shield(entity, enabled)
    enabled = enabled == true
    if state.centipede_shield_enabled == enabled then return end
    state.centipede_shield_enabled = enabled
    local shield = centipede_shield_entity(entity)
    if shield == 0 then return end
    if type(EntitySetComponentsWithTagEnabled) == "function" then
        pcall(EntitySetComponentsWithTagEnabled, shield, "shield", enabled)
    end
    local x, y = root_position(entity)
    if x ~= nil then
        pcall(EntityLoad,
            enabled
                and "data/entities/particles/muzzle_flashes/muzzle_flash_circular_large_pink_reverse.xml"
                or "data/entities/particles/muzzle_flashes/muzzle_flash_circular_large_pink.xml",
            x, y)
    end
    if type(GameEntityPlaySound) == "function" then
        pcall(GameEntityPlaySound, shield, enabled and "activate" or "deactivate")
    end
end

local function centipede_muzzle(entity, path)
    local x, y = root_position(entity)
    if x == nil then return end
    pcall(EntityLoad, path, x, y)
    if type(GamePlaySound) == "function" then
        pcall(GamePlaySound, "data/audio/Desktop/projectiles.bank", "projectiles/magic/create", x, y)
    end
end

local function centipede_event(q, due_frame, kind)
    q.events = q.events or {}
    q.events[#q.events + 1] = {due=due_frame, kind=kind}
end

local function centipede_process_events(entity, frame, q)
    local remaining = {}
    for _, event in ipairs(type(q.events) == "table" and q.events or {}) do
        if frame >= (tonumber(event.due) or frame) then
            if event.kind == "shield_on" then centipede_shield(entity, true)
            elseif event.kind == "shield_off" then centipede_shield(entity, false)
            elseif event.kind == "eye_open" then centipede_eye(entity, true)
            elseif event.kind == "eye_close" then centipede_eye(entity, false)
            elseif event.kind == "circle_start_sound" and type(GameEntityPlaySound) == "function" then
                pcall(GameEntityPlaySound, entity, "phase_circleshot_start")
            elseif event.kind == "fire_sound" and type(GameEntityPlaySound) == "function" then
                pcall(GameEntityPlaySound, entity, "shoot_fire")
            elseif event.kind == "homing_sound" and type(GameEntityPlaySound) == "function" then
                pcall(GameEntityPlaySound, entity, "shoot_homingshot")
            end
        else
            remaining[#remaining + 1] = event
        end
    end
    q.events = remaining
end

local function centipede_start_sequence(entity, frame, kind)
    local orbcount = centipede_orbcount(entity)
    local q = {kind=kind, orbcount=orbcount, events={}}
    if kind == "circle" then
        -- phase_circleshot: move/wait50 -> shield_on -> wait10 -> open_eye/wait55.
        q.repeat_left = 1
        q.shot_left = 0
        q.due = frame + 115
        centipede_event(q, frame + 50, "shield_on")
        centipede_event(q, frame + 60, "eye_open")
        centipede_event(q, frame + 115, "circle_start_sound")
    elseif kind == "fire" then
        q.repeat_left = 2
        q.due = frame + 115
        centipede_event(q, frame + 50, "shield_on")
        centipede_event(q, frame + 60, "eye_open")
        centipede_event(q, frame + 115, "fire_sound")
    elseif kind == "homing" then
        q.left = 4 + math.floor(orbcount * 0.5)
        q.due = frame + 55
        centipede_eye(entity, true)
    elseif kind == "poly" then
        q.due = frame + 85 -- open_eye 55 + explicit 30f wait
        centipede_eye(entity, true)
    elseif kind == "melee" then
        q.due = frame + 55
        centipede_eye(entity, true)
    elseif kind == "clear" then
        q.due = frame + 25
    elseif kind == "aggro" then
        q.left = 12 + math.floor(orbcount / 3)
        q.stage = "rings"
        q.due = frame + 60
        if type(GamePlayAnimation) == "function" then pcall(GamePlayAnimation, entity, "aggro", 0, "aggro", 0) end
    else
        return false
    end
    state.centipede_sequence = q
    return true
end

local function centipede_finish(entity, frame, cooldown, close_eye)
    if close_eye == true then centipede_eye(entity, false) end
    state.centipede_sequence = nil
    state.centipede_next = frame + math.max(1, tonumber(cooldown) or 1)
end

local function centipede_circle_ring(entity, frame, q)
    local x, y = root_position(entity); if x == nil then return false end
    if (tonumber(q.shot_left) or 0) <= 0 then
        local r = 0
        if type(ProceduralRandomf) == "function" then
            local ok, value = pcall(ProceduralRandomf, frame, frame)
            if ok and tonumber(value) ~= nil then r = tonumber(value) end
        end
        q.shot_left = 10 + math.floor((tonumber(q.orbcount) or 0) / 3)
        q.branches = 6 + (tonumber(q.orbcount) or 0) - (tonumber(q.repeat_left) or 0)
        q.angle_step = 25 * (r * 2 - 1)
        q.angle = r * 180 + q.angle_step
    end
    for _, v in ipairs(mathx.radial_degrees(q.branches, 80, q.angle)) do
        shoot_velocity(entity, "data/entities/animals/boss_centipede/orb_circleshot.xml", x, y, v.x, v.y)
    end
    centipede_muzzle(entity, "data/entities/particles/muzzle_flashes/muzzle_flash_circular_pink.xml")
    q.angle = q.angle + q.angle_step
    q.shot_left = q.shot_left - 1
    if q.shot_left > 0 then
        q.due = frame + 12
    elseif (tonumber(q.repeat_left) or 0) > 0 then
        -- Final loop wait12, then next_phase() turns the shield off after the 60f
        -- tail; repeated phase turns it back on after its own 50f move wait. Eye
        -- remains open because close_eye() is suppressed while repeats are queued.
        q.repeat_left = q.repeat_left - 1
        q.shot_left = 0
        centipede_event(q, frame + 12, "shield_off")
        centipede_event(q, frame + 122, "shield_on")
        centipede_event(q, frame + 132, "circle_start_sound")
        q.due = frame + 132
    else
        -- Last ring waits12 before close_eye(), whose animation lasts50; only then
        -- does next_phase() disable the shield, followed by the 60f phase tail.
        centipede_event(q, frame + 12, "eye_close")
        centipede_event(q, frame + 62, "shield_off")
        q.finish_at = frame + 122
        q.due = q.finish_at
        q.stage = "finish"
    end
    return true
end

local function centipede_aggro_ring(entity, frame, q)
    local x, y = root_position(entity); if x == nil then return false end
    local branches = 4 + (tonumber(q.orbcount) or 0)
    for i = 1, branches do
        local r = 0
        if type(ProceduralRandomf) == "function" then
            local ok, value = pcall(ProceduralRandomf, frame + i, frame)
            if ok and tonumber(value) ~= nil then r = tonumber(value) end
        end
        local a = math.rad(r * 360)
        shoot_velocity(entity, "data/entities/animals/boss_centipede/orb_circleshot.xml", x, y,
            math.cos(a) * 120, math.sin(a) * 120)
    end
    if type(GameCreateParticle) == "function" then
        pcall(GameCreateParticle, "slime_green", x, y, 50, 0, -20, true, false)
    end
    centipede_muzzle(entity, "data/entities/particles/muzzle_flashes/muzzle_flash_circular_pink.xml")
    q.left = q.left - 1
    if q.left > 0 then
        q.due = frame + 12
    else
        -- Final ring's wait12 + explicit wait20 precede explosion_attack().
        q.stage = "explosion"
        q.due = frame + 32
    end
    return true
end

local function update_centipede_sequence(entity, frame)
    local q = state.centipede_sequence
    if type(q) ~= "table" then return false end
    centipede_process_events(entity, frame, q)
    if frame < (tonumber(q.due) or frame) then return false end
    if q.stage == "finish" then
        state.centipede_sequence = nil
        state.centipede_next = frame
        return true
    end
    local x, y = root_position(entity); if x == nil then state.centipede_sequence=nil; return false end
    if q.kind == "circle" then
        return centipede_circle_ring(entity, frame, q)
    elseif q.kind == "fire" then
        local amount = 10 + (tonumber(q.orbcount) or 0) - (tonumber(q.repeat_left) or 0) * 2
        for _, v in ipairs(mathx.firepillar(amount)) do
            shoot_velocity(entity, "data/entities/animals/boss_centipede/firepillar.xml", x, y, v.x, v.y)
        end
        centipede_muzzle(entity, "data/entities/particles/muzzle_flashes/muzzle_flash_circular.xml")
        if (tonumber(q.repeat_left) or 0) > 0 then
            q.repeat_left = q.repeat_left - 1
            -- close_eye() is suppressed. After the 40f tail next_phase() disables
            -- shield; repeated phase re-enables it after its 50f movement wait.
            centipede_event(q, frame + 40, "shield_off")
            centipede_event(q, frame + 90, "shield_on")
            centipede_event(q, frame + 100, "fire_sound")
            q.due = frame + 100
        else
            -- Final phase closes the eye immediately, waits50+40, then next_phase()
            -- turns off the shield.
            centipede_eye(entity, false)
            centipede_event(q, frame + 90, "shield_off")
            q.finish_at = frame + 90
            q.due = q.finish_at
            q.stage = "finish"
        end
        return true
    elseif q.kind == "homing" then
        local vy = -200
        if type(ProceduralRandomf) == "function" then
            local ok, value = pcall(ProceduralRandomf, x, y + frame, -200, 50)
            if ok and tonumber(value) ~= nil then vy = tonumber(value) end
        end
        shoot_velocity(entity, "data/entities/animals/boss_centipede/orb_homing.xml", x, y, 0, vy)
        q.left = q.left - 1
        if type(GameEntityPlaySound) == "function" then pcall(GameEntityPlaySound, entity, "shoot_homingshot") end
        if q.left > 0 then q.due = frame + 20
        else
            centipede_event(q, frame + 20, "eye_close")
            q.due = frame + 70
            q.stage = "finish"
        end
        return true
    elseif q.kind == "poly" then
        shoot_velocity(entity, "data/entities/animals/boss_centipede/orb_polymorph.xml", x, y - 10, 0, -50)
        shoot_velocity(entity, "data/entities/animals/boss_centipede/orb_polymorph.xml", x - 5, y, -30, 20)
        shoot_velocity(entity, "data/entities/animals/boss_centipede/orb_polymorph.xml", x - 5, y, -30, 20)
        if type(GameEntityPlaySound) == "function" then pcall(GameEntityPlaySound, entity, "shoot_homingshot") end
        centipede_event(q, frame + 20, "eye_close")
        q.due = frame + 70
        q.stage = "finish"
        return true
    elseif q.kind == "melee" then
        shoot_velocity(entity, "data/entities/animals/boss_centipede/melee.xml", x, y, 0, 0)
        if type(GameEntityPlaySound) == "function" then pcall(GameEntityPlaySound, entity, "phase_rush_start") end
        centipede_event(q, frame + 50, "eye_close")
        q.due = frame + 100
        q.stage = "finish"
        return true
    elseif q.kind == "clear" then
        shoot_velocity(entity, "data/entities/animals/boss_centipede/clear_materials.xml", x, y, 0, 0)
        centipede_finish(entity, frame, 1, false)
        return true
    elseif q.kind == "aggro" then
        if q.stage == "rings" then return centipede_aggro_ring(entity, frame, q) end
        shoot_velocity(entity, "data/entities/animals/boss_centipede/melee.xml", x, y, 0, 0)
        centipede_finish(entity, frame, 60, false)
        return true
    end
    state.centipede_sequence = nil
    return false
end

local function centipede_choose_projectile_phase(entity, frame)
    local orbcount = centipede_orbcount(entity)
    if find_variable(entity, "aggro") ~= nil then return "aggro" end
    local distance = centipede_cursor_distance(entity)
    if distance < 65 then return "melee" end
    -- 700px is the boss AI's target-acquisition ceiling. Player cursor distance should
    -- still select a projectile phase beyond it rather than turning primary fire off.
    local subphase = tonumber(state.centipede_subphase) or 0
    if subphase >= 6 then
        state.centipede_subphase = 0
        return "clear"
    end
    local choices = {"circle", "fire"}
    if orbcount >= 2 then choices[#choices+1] = "homing" end
    if orbcount >= 11 then choices[#choices+1] = "poly" end
    local pick = 1
    local x, y = root_position(entity)
    local tx, ty = mouse_target(x or 0, y or 0)
    -- Vanilla next_phase seeds with boss position + target position + subphase. The
    -- cursor is the controlled form's target, so preserve that exact dependency.
    if type(SetRandomSeed) == "function" then pcall(SetRandomSeed, (x or 0) + tx + subphase, (y or 0) + ty) end
    if type(Random) == "function" then
        local ok, value = pcall(Random, 1, #choices)
        if ok and tonumber(value) ~= nil then pick = tonumber(value) end
    end
    state.centipede_subphase = subphase + 1
    return choices[math.max(1, math.min(#choices, math.floor(pick)))]
end

local function fire_boss_centipede(entity, frame, primary, secondary)
    if update_centipede_sequence(entity, frame) then return end
    if state.centipede_sequence ~= nil or frame < (tonumber(state.centipede_next) or 0) then return end
    if not primary and not secondary then return end

    local kind = nil
    if secondary then
        local orbcount = centipede_orbcount(entity)
        local options = {"circle", "fire"}
        if orbcount >= 2 then options[#options+1] = "homing" end
        if orbcount >= 11 then options[#options+1] = "poly" end
        local index = (tonumber(state.centipede_secondary) or 0) + 1
        if index > #options then index = 1 end
        state.centipede_secondary = index
        kind = options[index]
    else
        kind = centipede_choose_projectile_phase(entity, frame)
    end
    if kind ~= nil then centipede_start_sequence(entity, frame, kind) end
end

local function restore_components()
    for _, record in ipairs(records) do
        if valid(record.component) and record.owner ~= nil and record.owner ~= 0 and EntityGetIsAlive(record.owner) then
            pcall(EntitySetComponentIsEnabled, record.owner, record.component, record.enabled == true)
        end
    end
end

function scripted.reset()
    if active_entity ~= 0 and EntityGetIsAlive(active_entity) and #owners(SCRIPT.BOSS_ROBOT) > 0 then
        boss_robot_stop_lasers(active_entity)
    end
    if active_entity ~= 0 and EntityGetIsAlive(active_entity) and #owners(SCRIPT.BOSS_LIMBS) > 0 then
        boss_limbs_set_hitboxes(active_entity, false)
        boss_limbs_set_details(active_entity, false)
    end
    if active_entity ~= 0 and EntityGetIsAlive(active_entity) and #owners(SCRIPT.BOSS_CENTIPEDE) > 0 then
        if state.centipede_eye_open == true then centipede_eye(active_entity, false) end
        if state.centipede_shield_enabled == true then centipede_shield(active_entity, false) end
    end
    restore_components()
    if target_entity ~= 0 and EntityGetIsAlive(target_entity) then pcall(EntityKill, target_entity) end
    target_entity = 0
    active_entity = 0
    active_path = ""
    records = {}
    by_script = {}
    state = {}
    manages_lasers = false
end

function scripted.configure(entity, target_path)
    if active_entity ~= 0 and active_entity ~= entity then scripted.reset() end
    active_entity = entity or 0
    active_path = tostring(target_path or "")
    records = {}
    by_script = {}
    state = {}
    manages_lasers = false
    if entity == nil or entity == 0 then return false end
    walk_entity_tree(entity, function(current)
        for _, comp in ipairs(EntityGetComponentIncludingDisabled(current, "LuaComponent") or {}) do
            local source = tostring(get_value(comp, "script_source_file", "") or "")
            if source == SCRIPT.BOSS_GHOST_LASERS and component_enabled(current, comp) then
                -- This script is already a complete self-contained vanilla laser state
                -- machine: it rotates the cross and derives emission/range/damage from
                -- laser_status without targeting player_unit. Keep it native and merely
                -- prevent the generic cursor-laser adapter from overwriting it.
                manages_lasers = true
            elseif SUPPRESS_ONLY[source] == true then
                local enabled = component_enabled(current, comp)
                records[#records + 1] = {component=comp, owner=current, source=source, enabled=enabled, suppress_only=true}
                pcall(EntitySetComponentIsEnabled, current, comp, false)
            elseif MANAGED[source] then
                local enabled = component_enabled(current, comp)
                local record = {component=comp, owner=current, source=source, enabled=enabled}
                records[#records + 1] = record
                if enabled or REPLAY_WHEN_INITIALLY_DISABLED[source] == true then
                    by_script[source] = by_script[source] or {}
                    by_script[source][#by_script[source] + 1] = record
                    if source == SCRIPT.BOSS_ROBOT then manages_lasers = true end
                end
                pcall(EntitySetComponentIsEnabled, current, comp, false)
            end
        end
    end)

    if #owners(SCRIPT.BOSS_CENTIPEDE) > 0 then
        centipede_initialize_form(entity)
    end

    local now = frame_num()
    for index, record in ipairs(owners(SCRIPT.MONK)) do
        state["monk_" .. tostring(index)] = authored_next_frame(record, 60, now)
    end
    local singleton_schedules = {
        {SCRIPT.FUNGUS_GIGA, "fungus_giga", 10},
        {SCRIPT.BOSS_DRAGON, "boss_dragon", 80},
        {SCRIPT.BOSS_MEAT_SHOT, "boss_meat_acid", 20},
        {SCRIPT.BOSS_MEAT_EYE, "boss_meat_eye", 80},
        {SCRIPT.MAGGOT_TINY, "maggot", 20},
        {SCRIPT.BOSS_WIZARD, "boss_wizard", 16},
        {SCRIPT.BOSS_ROBOT, "boss_robot", 40},
        {SCRIPT.BOSS_PIT, "boss_pit", 40},
    }
    for _, spec in ipairs(singleton_schedules) do
        local list = owners(spec[1])
        if type(list[1]) == "table" then state[spec[2]] = authored_next_frame(list[1], spec[3], now) end
    end
    local pit = owners(SCRIPT.BOSS_PIT)
    if type(pit[1]) == "table" then
        state.boss_pit_maintenance = authored_next_frame(pit[1], 40, now)
    end
    local fish_timer = find_variable(entity, "phase_timer")
    if valid(fish_timer) then state.fish_timer = tonumber(get_value(fish_timer, "value_int", 0)) or 0 end
    state.boss_meat_acid_enabled = #owners(SCRIPT.BOSS_MEAT_SHOT) > 0
    return #records > 0
end

function scripted.active()
    return active_entity ~= 0 and #records > 0
end

function scripted.manages_lasers()
    return manages_lasers == true
end

function scripted.update(entity, allow_secondary, allow_primary)
    if allow_secondary == nil then allow_secondary = true end
    if allow_primary == nil then allow_primary = true end
    if entity == nil or entity == 0 or entity ~= active_entity or #records == 0 then return false end
    local controls = ensure_controls(entity)
    if not valid(controls) then return false end
    local primary = allow_primary and get_value(controls, "mButtonDownFire", false) == true
    local secondary = allow_secondary and get_value(controls, "mButtonDownFire2", false) == true
    local frame = frame_num()
    update_target(entity)

    if #owners(SCRIPT.MONK) > 0 then fire_monk(entity, frame, primary) end
    if #owners(SCRIPT.FUNGUS_GIGA) > 0 then fire_fungus_giga(entity, frame, primary) end
    if #owners(SCRIPT.BOSS_DRAGON) > 0 then fire_boss_dragon(entity, frame, primary) end
    if #owners(SCRIPT.BOSS_MEAT_SHOT) > 0 or #owners(SCRIPT.BOSS_MEAT_EYE) > 0 then fire_boss_meat(entity, frame, primary) end
    if #owners(SCRIPT.FISH_GIGA) > 0 then fire_fish_giga(entity, frame, primary) end
    if #owners(SCRIPT.MAGGOT_TINY) > 0 then fire_maggot(entity, frame, primary) end
    if #owners(SCRIPT.BOSS_WIZARD) > 0 then fire_boss_wizard(entity, frame, primary) end
    if #owners(SCRIPT.BOSS_ROBOT) > 0 then fire_boss_robot(entity, frame, primary) end
    if #owners(SCRIPT.BOSS_PIT) > 0 then fire_boss_pit(entity, frame, primary) end
    if #owners(SCRIPT.BOSS_LIMBS) > 0 then fire_boss_limbs(entity, frame, primary, secondary) end
    if #owners(SCRIPT.BOSS_CENTIPEDE) > 0 then fire_boss_centipede(entity, frame, primary, secondary) end
    return true
end

function scripted.sources()
    local out = {}
    for _, record in ipairs(records) do out[#out+1] = record.source end
    table.sort(out)
    return out
end

METAMORPH_CREATIVE_MENU_FORM_SCRIPTED_ATTACKS = scripted
return scripted
