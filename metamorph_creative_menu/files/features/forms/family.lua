local form_family = {}

local entity_tree = dofile("mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua")
local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")

local valid = component_ops.valid
local component = component_ops.first

local function tree_has_component(entity, component_type)
    local found = false
    entity_tree.walk(entity, function(current_entity)
        if valid(component(current_entity, component_type)) then
            found = true
            return false
        end
    end)
    return found
end

function form_family.claim_root_lifecycle(entity)
    local disabled_temporary_lifetime = false
    for _, lifetime_component in ipairs(EntityGetComponentIncludingDisabled(entity, "LifetimeComponent") or {}) do
        disabled_temporary_lifetime = true
        pcall(EntitySetComponentIsEnabled, entity, lifetime_component, false)
    end
    return disabled_temporary_lifetime
end

function form_family.is_ik(entity)
    return tree_has_component(entity, "IKLimbsAnimatorComponent")
        or tree_has_component(entity, "LimbBossComponent")
        or tree_has_component(entity, "IKLimbWalkerComponent")
        or (tree_has_component(entity, "IKLimbComponent")
            and (valid(component(entity, "PhysicsAIComponent"))
                or valid(component(entity, "PhysicsBodyComponent"))
                or valid(component(entity, "PhysicsBody2Component"))))
end

function form_family.detect(entity)
    if valid(component(entity, "GhostComponent")) then return "ghost_native" end
    -- Boss forms receive a native WormPlayer driver during configuration. The authored
    -- BossDragon component remains the family discriminator even while disabled.
    if valid(component(entity, "BossDragonComponent")) then return "boss_dragon" end
    if valid(component(entity, "WormPlayerComponent")) then return "worm_native" end
    if valid(component(entity, "AdvancedFishAIComponent")) and valid(component(entity, "CharacterDataComponent")) then
        return "fish"
    end
    if form_family.is_ik(entity) then return "ik_physics" end
    if (valid(component(entity, "PhysicsBodyComponent")) or valid(component(entity, "PhysicsBody2Component")))
        and (valid(component(entity, "PhysicsAIComponent"))
            or valid(component(entity, "AnimalAIComponent"))
            or valid(component(entity, "AIAttackComponent")))
    then
        return "physics"
    end
    if valid(component(entity, "ControlsComponent")) and valid(component(entity, "CharacterDataComponent")) then
        return "character"
    end
    return "unknown"
end

function form_family.is_native_tank_path(entity_path)
    local entity_id = string.match(string.lower(tostring(entity_path or "")), "([^/]+)%.xml$") or ""
    return entity_id == "tank" or string.match(entity_id, "^tank_") ~= nil
end

return form_family
