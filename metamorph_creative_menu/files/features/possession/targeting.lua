local targeting = {}
local entity_tree = dofile("mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua")

local CREATURE_MOTOR_COMPONENTS = {
    "AnimalAIComponent", "WormComponent", "WormAIComponent", "PhysicsAIComponent", "CharacterDataComponent",
    "BossDragonComponent", "CrawlerAnimalComponent", "AdvancedFishAIComponent", "FishAIComponent", "GhostComponent",
    "IKLimbWalkerComponent", "IKLimbsAnimatorComponent", "LimbBossComponent",
}

local function valid_entity(entity)
    return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity)
end

local function tree_has_component(root_entity, component_type)
    local found = false
    entity_tree.walk(root_entity, function(current_entity)
        if valid_entity(current_entity)
            and EntityGetFirstComponentIncludingDisabled(current_entity, component_type) ~= nil then
            found = true
            return false
        end
    end)
    return found
end

function targeting.is_creature(entity, player_entity)
    if not valid_entity(entity) or entity == player_entity then return false end
    if EntityHasTag(entity, "player_unit") or EntityHasTag(entity, "polymorphed_player") then return false end
    if EntityHasTag(entity, "projectile") or EntityHasTag(entity, "item_pickup") or EntityHasTag(entity, "perk_entity") then return false end

    local entity_filename = tostring(EntityGetFilename(entity) or "")
    if entity_filename == "" then return false end

    -- Runtime tags are insufficient: mines/projectile helpers can have DamageModel plus
    -- movement-like children. Reuse the MOBS catalog's XML classification first.
    local loaded, creature_service = pcall(dofile, "mods/metamorph_creative_menu/files/features/creatures/service.lua")
    if loaded and type(creature_service) == "table" then
        if type(creature_service.is_internal_helper_path) == "function" then
            local checked, is_helper = pcall(creature_service.is_internal_helper_path, entity_filename)
            if checked and is_helper == true then return false end
        end
        -- Apply the same exact-path compatibility policy to world possession as the MOBS
        -- menu. This blocks confirmed crash targets without introducing filename bans;
        -- structurally valid uncatalogued mod creatures can still pass the service check.
        if type(creature_service.is_transformable_creature_path) == "function" then
            local checked, is_root_creature = pcall(creature_service.is_transformable_creature_path, entity_filename)
            if checked and is_root_creature ~= true then return false end
        end
    end

    if not tree_has_component(entity, "DamageModelComponent") then return false end
    for _, component_type in ipairs(CREATURE_MOTOR_COMPONENTS) do
        if tree_has_component(entity, component_type) then return true end
    end
    return false
end

function targeting.center(entity)
    if type(EntityGetFirstHitboxCenter) == "function" then
        local read_succeeded, x, y = pcall(EntityGetFirstHitboxCenter, entity)
        if read_succeeded and x ~= nil and y ~= nil then return x, y end
    end
    return EntityGetTransform(entity)
end

function targeting.target_under_cursor(player_entity, radius)
    if not valid_entity(player_entity) then return 0 end
    local mouse_read, mouse_x, mouse_y = pcall(DEBUG_GetMouseWorld)
    if not mouse_read or mouse_x == nil or mouse_y == nil then return 0 end
    radius = math.max(8, tonumber(radius) or 28)
    local query_succeeded, nearby_entities = pcall(EntityGetInRadius, mouse_x, mouse_y, radius)
    if not query_succeeded or type(nearby_entities) ~= "table" then return 0 end

    local best_entity, best_distance_squared = 0, math.huge
    local visited_roots = {}
    for _, raw_entity in ipairs(nearby_entities) do
        local root_entity = entity_tree.root(raw_entity)
        if valid_entity(root_entity) and not visited_roots[root_entity] then
            visited_roots[root_entity] = true
            if targeting.is_creature(root_entity, player_entity) then
                local center_x, center_y = targeting.center(root_entity)
                if center_x ~= nil then
                    local delta_x, delta_y = center_x - mouse_x, center_y - mouse_y
                    local distance_squared = delta_x * delta_x + delta_y * delta_y
                    if distance_squared < best_distance_squared then
                        best_entity, best_distance_squared = root_entity, distance_squared
                    end
                end
            end
        end
    end
    return best_entity
end

function targeting.transform_plan(entity_filename)
    local loaded, creature_service = pcall(dofile, "mods/metamorph_creative_menu/files/features/creatures/service.lua")
    if loaded and type(creature_service) == "table" then
        if type(creature_service.transform_plan) == "function" then
            local resolved, plan = pcall(creature_service.transform_plan, entity_filename)
            if resolved and type(plan) == "table" and type(plan.target_path) == "string" and plan.target_path ~= "" then
                return plan.target_path, tostring(plan.mode or "possession")
            end
        elseif type(creature_service.canonical_transform_path) == "function" then
            local resolved, canonical_path = pcall(creature_service.canonical_transform_path, entity_filename)
            if resolved and type(canonical_path) == "string" and canonical_path ~= "" then
                return canonical_path, "possession"
            end
        end
    end
    return entity_filename, "possession"
end

return targeting
