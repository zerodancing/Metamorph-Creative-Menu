local physics_projectile = {}

local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local gameplay_input = dofile("mods/metamorph_creative_menu/files/platform/noita/gameplay_input.lua")

local valid = component_ops.valid
local get_value = component_ops.get
local boolean_value = component_ops.boolean

local SUPPORTED = {
    ["data/entities/animals/crystal_physics.xml"] = true,
    ["data/entities/animals/skycrystal_physics.xml"] = true,
}

local state = nil

local function mouse_target(x, y)
    if type(DEBUG_GetMouseWorld) == "function" then
        local ok, mx, my = pcall(DEBUG_GetMouseWorld)
        if ok and tonumber(mx) ~= nil and tonumber(my) ~= nil then return tonumber(mx), tonumber(my) end
    end
    return x + 100, y
end

local function find_descriptor(entity)
    for _, ai in ipairs(EntityGetComponentIncludingDisabled(entity, "AnimalAIComponent") or {}) do
        local path = tostring(get_value(ai, "attack_ranged_entity_file", "") or "")
        if boolean_value(get_value(ai, "attack_ranged_enabled", false)) == true and path ~= "" then return ai end
    end
    return nil
end

function physics_projectile.reset()
    state = nil
end

function physics_projectile.configure(entity, path)
    physics_projectile.reset()
    if SUPPORTED[tostring(path or "")] ~= true then return false end
    local ai = find_descriptor(entity)
    if not valid(ai) then return false end
    state = {
        component = ai,
        projectile = tostring(get_value(ai, "attack_ranged_entity_file", "") or ""),
        offset_x = tonumber(get_value(ai, "attack_ranged_offset_x", 0)) or 0,
        offset_y = tonumber(get_value(ai, "attack_ranged_offset_y", 0)) or 0,
        action_frame = math.max(0, math.floor(tonumber(get_value(ai, "attack_ranged_action_frame", 0)) or 0)),
        cooldown = math.max(1, math.floor(tonumber(get_value(ai, "attack_ranged_frames_between", 30)) or 30)),
        next_frame = 0,
        pending_frame = -1,
    }
    gameplay_input.require_release("primary")
    return state.projectile ~= ""
end

local function fire(entity)
    if state == nil or not valid(state.component) then return false end
    -- Live XML/component state remains authoritative so a phase script or another mod can
    -- disable/rewrite the projectile while the player is already transformed.
    if boolean_value(get_value(state.component, "attack_ranged_enabled", false)) ~= true then return false end
    local projectile_path = tostring(get_value(state.component, "attack_ranged_entity_file", "") or "")
    if projectile_path == "" then return false end
    local x, y, _, sx = EntityGetTransform(entity)
    if x == nil then return false end
    sx = tonumber(sx) or 1
    local ox = state.offset_x
    if sx < 0 then ox = -ox end
    local px, py = x + ox, y + state.offset_y
    local tx, ty = mouse_target(px, py)
    local projectile = EntityLoad(projectile_path, px, py)
    if projectile == nil or projectile == 0 then return false end
    local ok = pcall(GameShootProjectile, entity, px, py, tx, ty, projectile, true)
    if not ok then pcall(EntityKill, projectile) end
    return ok
end

function physics_projectile.update(entity, controls)
    if state == nil then return false end
    local frame = tonumber(GameGetFrameNum()) or 0
    if state.pending_frame >= 0 and frame >= state.pending_frame then
        state.pending_frame = -1
        fire(entity)
    end
    if gameplay_input.down(controls, "primary") and state.pending_frame < 0 and frame >= state.next_frame then
        state.pending_frame = frame + state.action_frame
        state.next_frame = frame + state.cooldown
        if state.action_frame <= 0 then
            state.pending_frame = -1
            fire(entity)
        end
    end
    return true
end

function physics_projectile.owns_primary()
    return state ~= nil
end

return physics_projectile
