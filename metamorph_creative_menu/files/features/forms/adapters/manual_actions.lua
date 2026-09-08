local manual_actions = {}

local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local mimic_melee = dofile("mods/metamorph_creative_menu/files/features/forms/adapters/manual_actions/mimic_melee.lua")
local physics_projectile = dofile("mods/metamorph_creative_menu/files/features/forms/adapters/manual_actions/physics_projectile.lua")
local blood_crystal = dofile("mods/metamorph_creative_menu/files/features/forms/adapters/manual_actions/blood_crystal.lua")

local valid = component_ops.valid
local ensure_controls = component_ops.ensure_controls
local active_entity = 0

function manual_actions.reset()
    active_entity = 0
    mimic_melee.reset()
    physics_projectile.reset()
    blood_crystal.reset()
end

function manual_actions.configure(entity, path, profile)
    manual_actions.reset()
    if entity == nil or entity == 0 then return false end
    active_entity = entity
    local configured = false
    configured = mimic_melee.configure(entity, path) or configured
    configured = physics_projectile.configure(entity, path) or configured
    configured = blood_crystal.configure(entity, path) or configured
    return configured
end

function manual_actions.update(entity)
    if entity == nil or entity == 0 or entity ~= active_entity or not EntityGetIsAlive(entity) then return false end
    local controls = ensure_controls(entity)
    if not valid(controls) then return false end
    local used = false
    used = mimic_melee.update(entity, controls) or used
    used = physics_projectile.update(entity, controls) or used
    used = blood_crystal.update(entity, controls) or used
    return used
end

function manual_actions.owns_primary()
    return mimic_melee.owns_primary() or physics_projectile.owns_primary() or blood_crystal.owns_primary()
end

-- Reserved as a stable coordinator surface. Manual creature adapters currently do not
-- own secondary fire; dash support was intentionally removed rather than left dormant.
function manual_actions.owns_secondary()
    return false
end

return manual_actions
