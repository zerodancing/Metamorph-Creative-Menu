local targeting = {}
local entity_tree = dofile("mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua")

local CREATURE_MOTOR_COMPONENTS = {
    "AnimalAIComponent", "WormComponent", "WormAIComponent", "PhysicsAIComponent", "CharacterDataComponent",
    "BossDragonComponent", "CrawlerAnimalComponent", "AdvancedFishAIComponent", "FishAIComponent", "GhostComponent",
    "IKLimbWalkerComponent", "IKLimbsAnimatorComponent", "LimbBossComponent",
}

local EW_REPLICA_CREATURE_TAGS = {
    "enemy", "helpless_animal", "worm", "boss", "boss_centipede",
    "plague_rat", "perk_fungus_tiny", "seed_c", "seed_d", "seed_e", "seed_f",
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
        -- The catalogue is intentionally not an allow-list here. Naturally spawned and
        -- modded creatures can be absent from it even though their live component tree is
        -- perfectly valid. Reject only exact known-unsafe paths, then validate structure.
        if type(creature_service.unsafe_reason) == "function" then
            local checked, reason = pcall(creature_service.unsafe_reason, entity_filename)
            if checked and reason ~= nil then return false end
        end
    end

    if not tree_has_component(entity, "DamageModelComponent") then return false end

    -- Entangled Worlds deliberately removes AnimalAI/PhysicsAI/FishAI from client-side
    -- replicas. Requiring those components made possession accept only mobs authored by
    -- this machine. A replicated enemy is still a valid target when its path/tag
    -- identifies a creature and its live tree retains a damage model.
    if EntityHasTag(entity, "ew_replicated") then
        if string.sub(entity_filename, 1, 22) == "data/entities/animals/" then return true end
        for _, tag in ipairs(EW_REPLICA_CREATURE_TAGS) do
            if EntityHasTag(entity, tag) then return true end
        end
    end
    for _, component_type in ipairs(CREATURE_MOTOR_COMPONENTS) do
        if tree_has_component(entity, component_type) then return true end
    end
    return false
end

local function creature_from_entity(raw_entity, player_entity)
    local current, seen, structural_fallback = raw_entity, {}, 0
    for _ = 1, 64 do
        if not valid_entity(current) or seen[current] then break end
        seen[current] = true
        if targeting.is_creature(current, player_entity) then
            if EntityGetFirstComponentIncludingDisabled(current, "DamageModelComponent") ~= nil then
                return current
            end
            if structural_fallback == 0 then structural_fallback = current end
        end
        if type(EntityGetParent) ~= "function" then break end
        local parent_ok, parent = pcall(EntityGetParent, current)
        if not parent_ok or parent == nil or parent == 0 then break end
        current = parent
    end

    -- EW and some creature XMLs add a non-creature synchronization/controller root.
    -- If the radius query returned that wrapper, inspect its tree for the actual mob.
    local root = entity_tree.root(raw_entity)
    local found = 0
    if valid_entity(root) then
        entity_tree.walk(root, function(candidate)
            if targeting.is_creature(candidate, player_entity) then
                if EntityGetFirstComponentIncludingDisabled(candidate, "DamageModelComponent") ~= nil then
                    found = candidate
                    return false
                end
                if structural_fallback == 0 then structural_fallback = candidate end
            end
        end)
    end
    return found ~= 0 and found or structural_fallback
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
    local visited_creatures = {}
    for _, raw_entity in ipairs(nearby_entities) do
        local creature = creature_from_entity(raw_entity, player_entity)
        if valid_entity(creature) and not visited_creatures[creature] then
            visited_creatures[creature] = true
            local center_x, center_y = targeting.center(creature)
            if center_x ~= nil then
                local delta_x, delta_y = center_x - mouse_x, center_y - mouse_y
                local distance_squared = delta_x * delta_x + delta_y * delta_y
                if distance_squared < best_distance_squared then
                    best_entity, best_distance_squared = creature, distance_squared
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
