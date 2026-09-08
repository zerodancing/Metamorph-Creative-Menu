local blood_crystal = {}

local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local gameplay_input = dofile("mods/metamorph_creative_menu/files/platform/noita/gameplay_input.lua")

local valid = component_ops.valid
local get_value = component_ops.get

local SUPPORTED = {
    ["data/entities/animals/bloodcrystal_physics.xml"] = true,
    ["data/entities/animals/the_end/bloodcrystal_physics.xml"] = true,
}

local COLLISION_SCRIPT = "data/scripts/animals/bloodcrystal_explosion.lua"
local PROJECTILE = "data/entities/projectiles/orb_pink.xml"
local state = nil

local function component_enabled(component)
    if not valid(component) or type(ComponentGetIsEnabled) ~= "function" then return false end
    local ok, enabled = pcall(ComponentGetIsEnabled, component)
    return ok and enabled == true
end

local function restore_owned_components()
    if state == nil then return end
    for _, record in ipairs(state.suppressed or {}) do
        if valid(record.component) and record.owner ~= nil and record.owner ~= 0 and EntityGetIsAlive(record.owner) then
            pcall(EntitySetComponentIsEnabled, record.owner, record.component, record.enabled == true)
        end
    end
    state.suppressed = {}
end

local function suppress_vanilla_collision_attack(entity)
    local suppressed = {}
    for _, lua in ipairs(EntityGetComponentIncludingDisabled(entity, "LuaComponent") or {}) do
        local collision = tostring(get_value(lua, "script_collision_trigger_hit", "") or "")
        if collision == COLLISION_SCRIPT then
            suppressed[#suppressed + 1] = { owner=entity, component=lua, enabled=component_enabled(lua) }
            pcall(EntitySetComponentIsEnabled, entity, lua, false)
        end
    end
    return suppressed
end

local function set_projectile_velocity(projectile, vx, vy)
    local velocity = EntityGetFirstComponentIncludingDisabled(projectile, "VelocityComponent")
    if valid(velocity) then pcall(ComponentSetValue2, velocity, "mVelocity", vx, vy) end
end

local function shoot(entity, path, x, y, vx, vy)
    local projectile = EntityLoad(path, x, y)
    if projectile == nil or projectile == 0 then return false end
    local ok = pcall(GameShootProjectile, entity, x, y, x + vx, y + vy, projectile, true)
    if not ok then
        pcall(EntityKill, projectile)
        return false
    end
    set_projectile_velocity(projectile, vx, vy)
    return true
end

local function radial_attack(entity)
    local x, y = EntityGetTransform(entity)
    if x == nil then return false end
    -- Byte-for-behaviour translation of bloodcrystal_explosion.lua: 12 pink orbs,
    -- 30 degrees apart, speed 100, spawned five pixels around the crystal.  The spawn
    -- position intentionally uses the *next* theta just like the vanilla script.
    local how_many = 12
    local angle_inc = (2 * math.pi) / how_many
    local theta = 0
    local speed = 100
    local dist = 5
    local fired = false
    for _ = 1, how_many do
        local vx = math.cos(theta) * speed
        local vy = math.sin(theta) * speed
        theta = theta + angle_inc
        local px = x + math.cos(theta) * dist
        local py = y + math.sin(theta) * dist
        fired = shoot(entity, PROJECTILE, px, py, vx, vy) or fired
    end
    return fired
end

function blood_crystal.reset()
    restore_owned_components()
    state = nil
end

function blood_crystal.configure(entity, path)
    blood_crystal.reset()
    if SUPPORTED[tostring(path or "")] ~= true then return false end
    state = {
        entity = entity,
        next_frame = 0,
        cooldown = 10, -- script_wait_frames(entity, 10) in vanilla
        suppressed = suppress_vanilla_collision_attack(entity),
    }
    gameplay_input.require_release("primary")
    return true
end

function blood_crystal.update(entity, controls)
    if state == nil or entity ~= state.entity then return false end
    local frame = tonumber(GameGetFrameNum()) or 0
    if gameplay_input.down(controls, "primary") and frame >= state.next_frame then
        if radial_attack(entity) then state.next_frame = frame + state.cooldown end
    end
    return true
end

function blood_crystal.owns_primary()
    return state ~= nil
end

return blood_crystal
