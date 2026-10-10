local boss_pit_wand = {}

local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local gameplay_input = dofile("mods/metamorph_creative_menu/files/platform/noita/gameplay_input.lua")

local valid = component_ops.valid
local get_value = component_ops.get
local ensure_controls = component_ops.ensure_controls

local WAND_LUA = "data/entities/animals/boss_pit/wand.lua"
local WAND_ROTATE_LUA = "data/entities/animals/boss_pit/wand_rotate.lua"
local ATTACKS = {
    "data/entities/projectiles/deck/rocket.xml",
    "data/entities/projectiles/deck/rocket_tier_2.xml",
    "data/entities/projectiles/deck/rocket_tier_3.xml",
    "data/entities/projectiles/deck/grenade.xml",
    "data/entities/projectiles/deck/grenade_tier_2.xml",
    "data/entities/projectiles/deck/grenade_tier_3.xml",
    "data/entities/projectiles/deck/rubber_ball.xml",
}

local active_entity = 0
local visual_entity = 0
local projectile_path = ""
local projectile_mult = 1.0
local next_fire_frame = 0
local last_attack_index = 0
local last_visual_index = 0

local function random_int(low, high)
    if low >= high then return low end
    if type(Random) == "function" then
        local ok, value = pcall(Random, low, high)
        if ok and tonumber(value) ~= nil then
            return math.max(low, math.min(high, math.floor(tonumber(value))))
        end
    end
    return low
end

local function seed(entity)
    if type(SetRandomSeed) ~= "function" then return end
    local x, y = EntityGetTransform(entity)
    local frame = type(GameGetFrameNum) == "function" and tonumber(GameGetFrameNum()) or 0
    pcall(SetRandomSeed, tonumber(x) or 0, (tonumber(y) or 0) * math.max(1, frame))
end

local function next_nonrepeating(low, high, previous)
    local value = random_int(low, high)
    if high > low and value == previous then
        value = value + 1
        if value > high then value = low end
    end
    return value
end

local function mouse_target(x, y)
    if type(DEBUG_GetMouseWorld) == "function" then
        local ok, mx, my = pcall(DEBUG_GetMouseWorld)
        if ok and tonumber(mx) ~= nil and tonumber(my) ~= nil then return tonumber(mx), tonumber(my) end
    end
    return x + 100, y
end

local function velocity_component(entity)
    local velocity = EntityGetFirstComponentIncludingDisabled(entity, "VelocityComponent")
    return valid(velocity) and velocity or nil
end

local function set_velocity(entity, vx, vy)
    local velocity = velocity_component(entity)
    if not valid(velocity) then return false end
    return pcall(ComponentSetValue2, velocity, "mVelocity", tonumber(vx) or 0, tonumber(vy) or 0)
end

local function destroy_visual()
    if visual_entity ~= 0 and EntityGetIsAlive(visual_entity) then pcall(EntityKill, visual_entity) end
    visual_entity = 0
end

local function make_visual(entity, index)
    destroy_visual()
    local visual = EntityCreateNew("metamorph_creative_menu_boss_pit_wand_visual") or 0
    if visual == 0 then return 0 end
    EntityAddTag(visual, "metamorph_creative_menu_runtime")
    EntityAddTag(visual, "ew_no_enemy_sync")
    local ok, sprite = pcall(EntityAddComponent2, visual, "SpriteComponent", {
        image_file = string.format("data/entities/animals/boss_pit/wand_0%d.png", index),
        offset_x = 16,
        offset_y = 16,
        alpha = 1,
        z_index = 0,
    })
    if not ok or not valid(sprite) then
        EntityKill(visual)
        return 0
    end
    if type(EntityRefreshSprite) == "function" then pcall(EntityRefreshSprite, visual, sprite) end
    local x, y, rotation, sx, sy = EntityGetTransform(entity)
    if x ~= nil then EntitySetTransform(visual, x, y, rotation or 0, sx or 1, sy or 1) end
    visual_entity = visual
    return visual
end

local function suppress_projectile_lifecycle(entity)
    for _, projectile in ipairs(EntityGetComponentIncludingDisabled(entity, "ProjectileComponent") or {}) do
        pcall(ComponentSetValue2, projectile, "on_death_explode", false)
        pcall(ComponentSetValue2, projectile, "on_lifetime_out_explode", false)
        pcall(EntitySetComponentIsEnabled, entity, projectile, false)
    end
    for _, lua in ipairs(EntityGetComponentIncludingDisabled(entity, "LuaComponent") or {}) do
        local source = tostring(get_value(lua, "script_source_file", "") or "")
        if source == WAND_LUA or source == WAND_ROTATE_LUA then
            pcall(EntitySetComponentIsEnabled, entity, lua, false)
        end
    end
end

local function configure_root_sprite(entity, index)
    -- Keep a concrete authored sprite on the root for EW/vanilla serialization and peers
    -- without MCM. Some local polymorph paths still suppress projectile rendering, so a
    -- separate presentation entity is created as the local visual fallback below.
    for _, sprite in ipairs(EntityGetComponentIncludingDisabled(entity, "SpriteComponent") or {}) do
        pcall(ComponentSetValue2, sprite, "image_file", string.format("data/entities/animals/boss_pit/wand_0%d.png", index))
        pcall(ComponentSetValue2, sprite, "alpha", 1)
        pcall(EntitySetComponentIsEnabled, entity, sprite, true)
        if type(EntityRefreshSprite) == "function" then pcall(EntityRefreshSprite, entity, sprite) end
    end
end

local function write_memory(entity, value)
    for _, storage in ipairs(EntityGetComponentIncludingDisabled(entity, "VariableStorageComponent") or {}) do
        if tostring(get_value(storage, "name", "") or "") == "memory" then
            pcall(ComponentSetValue2, storage, "value_string", value)
            return true
        end
    end
    return false
end

local function fire(entity, x, y, tx, ty)
    if projectile_path == "" then return false end
    local dx, dy = tx - x, ty - y
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 0.001 then dx, dy, length = 1, 0, 1 end
    dx, dy = dx / length, dy / length
    local speed = 500
    if valid(EntityGetFirstComponentIncludingDisabled(entity, "HomingComponent")) then speed = 300 end

    local projectile = EntityLoad(projectile_path, x, y)
    if projectile == nil or projectile == 0 then return false end
    local ok = pcall(GameShootProjectile, entity, x, y, tx, ty, projectile, true)
    if not ok then
        pcall(EntityKill, projectile)
        return false
    end
    local velocity = EntityGetFirstComponentIncludingDisabled(projectile, "VelocityComponent")
    if valid(velocity) then
        pcall(ComponentSetValue2, velocity, "mVelocity", dx * speed * projectile_mult, dy * speed * projectile_mult)
    end
    local projectile_component = EntityGetFirstComponentIncludingDisabled(projectile, "ProjectileComponent")
    if valid(projectile_component) then
        local damage = tonumber(get_value(projectile_component, "damage", 0)) or 0
        pcall(ComponentSetValue2, projectile_component, "damage", damage + 0.2)
    end
    return true
end

function boss_pit_wand.reset()
    destroy_visual()
    active_entity = 0
    projectile_path = ""
    projectile_mult = 1.0
    next_fire_frame = 0
    -- last_attack_index/last_visual_index intentionally survive a form reset so repeated
    -- transformations do not appear to be the same deterministic wand every time.
end

function boss_pit_wand.configure(entity)
    boss_pit_wand.reset()
    if entity == nil or entity == 0 then return false end
    active_entity = entity
    local controls = ensure_controls(entity)
    if valid(controls) then pcall(ComponentSetValue2, controls, "polymorph_hax", false) end
    suppress_projectile_lifecycle(entity)

    seed(entity)
    local attack_index = next_nonrepeating(1, #ATTACKS, last_attack_index)
    last_attack_index = attack_index
    projectile_path = ATTACKS[attack_index]
    projectile_mult = string.find(projectile_path, "rocket", 1, true) ~= nil and 0.5 or 1.2
    write_memory(entity, projectile_path)

    local visual_index = next_nonrepeating(1, 9, last_visual_index)
    last_visual_index = visual_index
    configure_root_sprite(entity, visual_index)
    make_visual(entity, visual_index)
    gameplay_input.require_release("primary")
    return true
end

function boss_pit_wand.update(entity)
    if entity == nil or entity == 0 or entity ~= active_entity or not EntityGetIsAlive(entity) then return false end
    local controls = ensure_controls(entity)
    if not valid(controls) then return false end
    local x, y, _, sx, sy = EntityGetTransform(entity)
    if x == nil then return false end

    local mx = (get_value(controls, "mButtonDownRight", false) == true and 1 or 0)
        - (get_value(controls, "mButtonDownLeft", false) == true and 1 or 0)
    local my = (get_value(controls, "mButtonDownDown", false) == true and 1 or 0)
        - ((get_value(controls, "mButtonDownUp", false) == true or get_value(controls, "mButtonDownFly", false) == true) and 1 or 0)
    local move_length = math.sqrt(mx * mx + my * my)
    if move_length > 0 then mx, my = mx / move_length, my / move_length end
    set_velocity(entity, mx * 85, my * 85)

    local tx, ty = mouse_target(x, y)
    local angle = math.atan2 and math.atan2(ty - y, tx - x) or math.atan((ty - y) / math.max(0.001, tx - x))
    if visual_entity ~= 0 and EntityGetIsAlive(visual_entity) then
        EntitySetTransform(visual_entity, x, y, angle, sx or 1, sy or 1)
    end

    local frame = tonumber(GameGetFrameNum()) or 0
    if gameplay_input.down(controls, "primary") and frame >= next_fire_frame then
        if fire(entity, x, y, tx, ty) then next_fire_frame = frame + 40 end
    end
    return true
end

function boss_pit_wand.visual_entity()
    return visual_entity
end

return boss_pit_wand
