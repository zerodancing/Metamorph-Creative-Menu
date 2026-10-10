local targeting = {}
local entity_tree = dofile("mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua")

-- Load the catalogue/classification service once.  Possession targeting can inspect dozens
-- of live entities in one click; re-entering the module loader for every candidate made
-- object/prop misses unnecessarily expensive even though the service itself is a singleton.
local creature_service = nil
do
    local ok, service = pcall(dofile, "mods/metamorph_creative_menu/files/features/creatures/service.lua")
    if ok and type(service) == "table" then creature_service = service end
end

local CREATURE_MOTOR_COMPONENTS = {
    "AnimalAIComponent", "WormComponent", "WormAIComponent", "PhysicsAIComponent", "CharacterDataComponent",
    "BossDragonComponent", "CrawlerAnimalComponent", "AdvancedFishAIComponent", "FishAIComponent", "GhostComponent",
    "IKLimbWalkerComponent", "IKLimbsAnimatorComponent", "LimbBossComponent",
}

local EW_REPLICA_CREATURE_TAGS = {
    "enemy", "helpless_animal", "worm", "boss", "boss_centipede",
    "plague_rat", "perk_fungus_tiny", "seed_c", "seed_d", "seed_e", "seed_f",
}

local CREATURE_HINT_TAGS = {
    "enemy", "helpless_animal", "worm", "boss", "boss_centipede",
    "plague_rat", "perk_fungus_tiny", "seed_c", "seed_d", "seed_e", "seed_f",
}

-- These engine directories are dominated by pickups, scenery, particles and projectiles.
-- They are NOT a global deny-list: a live entity with a real creature motor/tag still goes
-- through full validation.  The prefix only lets an ordinary rock/heart/prop miss stop before
-- a recursive entity-tree walk or XML/Base-chain classification.
local OBVIOUS_NON_CREATURE_PREFIXES = {
    "data/entities/items/",
    "data/entities/props/",
    "data/entities/buildings/",
    "data/entities/projectiles/",
    "data/entities/particles/",
}

local function valid_entity(entity)
    return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity)
end

local function has_any_tag(entity, tags)
    for _, tag in ipairs(tags) do
        if EntityHasTag(entity, tag) then return true end
    end
    return false
end

local function direct_motor(entity)
    for _, component_type in ipairs(CREATURE_MOTOR_COMPONENTS) do
        if EntityGetFirstComponentIncludingDisabled(entity, component_type) ~= nil then return true end
    end
    return false
end

local function obvious_non_creature_path(path)
    path = tostring(path or "")
    for _, prefix in ipairs(OBVIOUS_NON_CREATURE_PREFIXES) do
        if string.sub(path, 1, #prefix) == prefix then return true end
    end
    return false
end

local function hard_reject(entity, player_entity)
    if not valid_entity(entity) or entity == player_entity then return true end
    if EntityHasTag(entity, "player_unit") or EntityHasTag(entity, "polymorphed_player") then return true end
    if EntityHasTag(entity, "projectile") or EntityHasTag(entity, "item_pickup") or EntityHasTag(entity, "perk_entity") then
        return true
    end
    return false
end

-- One traversal collects all runtime structure needed by the possession policy.  The old
-- implementation walked the same tree once for DamageModel and then again for every motor
-- component type (up to ~14 full traversals per candidate).
local function tree_signature(root_entity, memo)
    memo = type(memo) == "table" and memo or nil
    local signatures = memo and memo.signatures or nil
    if signatures ~= nil and signatures[root_entity] ~= nil then return signatures[root_entity] end

    local signature = { damage=false, motor=false, hint=false, animal_path=false, ew_replica=false }
    entity_tree.walk(root_entity, function(current_entity)
        if not valid_entity(current_entity) then return end
        if EntityGetFirstComponentIncludingDisabled(current_entity, "DamageModelComponent") ~= nil then
            signature.damage = true
        end
        if direct_motor(current_entity) then signature.motor = true end
        if has_any_tag(current_entity, CREATURE_HINT_TAGS) then signature.hint = true end
        if EntityHasTag(current_entity, "ew_replicated") then signature.ew_replica = true end
        local path = tostring(EntityGetFilename(current_entity) or "")
        if string.sub(path, 1, 22) == "data/entities/animals/" then signature.animal_path = true end
        if signature.damage and signature.motor and signature.hint then return false end
    end)

    if memo ~= nil then
        memo.signatures = memo.signatures or {}
        memo.signatures[root_entity] = signature
    end
    return signature
end

local function service_allows_path(entity_filename)
    if type(creature_service) ~= "table" then return true end
    if type(creature_service.unsafe_reason) == "function" then
        local checked, reason = pcall(creature_service.unsafe_reason, entity_filename)
        if checked and reason ~= nil then return false end
    end
    if type(creature_service.is_internal_helper_path) == "function" then
        local checked, is_helper = pcall(creature_service.is_internal_helper_path, entity_filename)
        if checked and is_helper == true then return false end
    end
    return true
end

function targeting.is_creature(entity, player_entity, memo)
    if hard_reject(entity, player_entity) then return false end

    local entity_filename = tostring(EntityGetFilename(entity) or "")
    if entity_filename == "" then return false end

    local entity_is_replica = EntityHasTag(entity, "ew_replicated")
    local entity_has_hint = has_any_tag(entity, CREATURE_HINT_TAGS)
    local entity_has_motor = direct_motor(entity)

    -- Fast negative path for the exact class that caused the live hitch: a plain pickup,
    -- physics prop, scenery/building or projectile root with no creature runtime signal.
    -- Crucially this executes before creature_service.is_internal_helper_path(), which may
    -- recursively read/parse XML <Base> chains on the first encounter with a path.
    if obvious_non_creature_path(entity_filename)
        and not entity_is_replica and not entity_has_hint and not entity_has_motor then
        return false
    end

    local root = entity_tree.root(entity)
    if not valid_entity(root) then root = entity end
    local signature = tree_signature(root, memo)
    if not signature.damage then return false end

    -- Entangled Worlds deliberately removes AnimalAI/PhysicsAI/FishAI from client-side
    -- replicas. A replicated enemy is still a valid target when its path/tag identifies a
    -- creature and its live tree retains a damage model.
    if entity_is_replica or signature.ew_replica then
        if string.sub(entity_filename, 1, 22) == "data/entities/animals/" then
            return service_allows_path(entity_filename)
        end
        for _, tag in ipairs(EW_REPLICA_CREATURE_TAGS) do
            if EntityHasTag(entity, tag) or (root ~= entity and EntityHasTag(root, tag)) then
                return service_allows_path(entity_filename)
            end
        end
        -- A replicated physics prop with DamageModel but no creature identity remains a miss.
        if not signature.animal_path and not signature.hint then return false end
    end

    if not signature.motor then return false end
    return service_allows_path(entity_filename)
end

local function creature_from_entity(raw_entity, player_entity, memo)
    local current, seen, structural_fallback = raw_entity, {}, 0
    for _ = 1, 64 do
        if not valid_entity(current) or seen[current] then break end
        seen[current] = true
        if targeting.is_creature(current, player_entity, memo) then
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
    -- Only do the descendant fallback after the cheap parent path did not find a body.
    -- Runtime tree signatures are memoized for this click, so wrappers do not multiply
    -- recursive component work for every nearby child.
    local root = entity_tree.root(raw_entity)
    local found = 0
    local allow_descendant_fallback = valid_entity(root) and not hard_reject(root, player_entity)
    if allow_descendant_fallback then
        local root_path = tostring(EntityGetFilename(root) or "")
        if obvious_non_creature_path(root_path)
            and not EntityHasTag(root, "ew_replicated")
            and not has_any_tag(root, CREATURE_HINT_TAGS)
            and not direct_motor(root) then
            allow_descendant_fallback = false
        end
    end
    if allow_descendant_fallback then
        entity_tree.walk(root, function(candidate)
            if targeting.is_creature(candidate, player_entity, memo) then
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
    local memo = { signatures={} }
    for _, raw_entity in ipairs(nearby_entities) do
        -- Most click misses now terminate in is_creature's direct tag/path/component
        -- prefilter. No XML catalogue scan is performed for ordinary rocks/pickups/props.
        local creature = creature_from_entity(raw_entity, player_entity, memo)
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
    if type(creature_service) == "table" then
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
