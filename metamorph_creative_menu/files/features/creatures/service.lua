local metadata = dofile("mods/metamorph_creative_menu/files/features/creatures/metadata.lua")
local classification = dofile("mods/metamorph_creative_menu/files/features/creatures/classification.lua")
local compatibility = dofile("mods/metamorph_creative_menu/files/features/creatures/compatibility.lua")
local transform_routing = dofile("mods/metamorph_creative_menu/files/features/creatures/transform_routing.lua")
local creature_diagnostics = dofile("mods/metamorph_creative_menu/files/features/creatures/diagnostics.lua")
local catalog_builder = dofile("mods/metamorph_creative_menu/files/features/creatures/catalog_builder.lua")
local existing_creature_service = METAMORPH_CREATIVE_MENU_CREATURE_SERVICE or METAMORPH_CREATIVE_MENU_CREATURE_API
if type(existing_creature_service) == "table" then return existing_creature_service end

local creature_service = {}

local basename = metadata.basename
local unsafe_reason = classification.unsafe_reason
local internal_helper_path = classification.internal_helper_path
local catalog_creature = classification.catalog_creature

function creature_service.transform_plan(path)
    path = tostring(path or "")
    if path == "" or not ModDoesFileExist(path) then return nil end
    return transform_routing.plan(path, compatibility.canonical_target(path))
end

function creature_service.canonical_transform_path(path)
    local plan = creature_service.transform_plan(path)
    return type(plan) == "table" and plan.target_path or nil
end

function creature_service.is_transformable_creature_path(path)
    if type(path) ~= "string" or path == "" or not ModDoesFileExist(path) or unsafe_reason(path) ~= nil then return false end
    -- Noita's progress catalogue contains a few structurally unusual but legitimate
    -- creatures. Once admitted by the catalogue, runtime targeting must agree with it.
    return catalog_creature(path) or catalog_builder.has_catalog_path(path)
end

function creature_service.best_vanilla_path_for_id(id_or_path)
    local creature_id = basename(tostring(id_or_path or ""))
    if creature_id == "" then return nil end
    for _, candidate_path in ipairs(catalog_builder.static_candidates_by_id()[creature_id] or {}) do
        if type(candidate_path) == "string" and candidate_path ~= "" and catalog_creature(candidate_path) then
            return candidate_path
        end
    end
    return nil
end

function creature_service.is_internal_helper_path(path) return internal_helper_path(path) end
function creature_service.unsafe_reason(path) return unsafe_reason(path) end
function creature_service.known_unsafe_forms() return classification.known_unsafe_forms() end
function creature_service.compatibility_status(path)
    return classification.compatibility_status(path)
end
function creature_service.known_safe_forms() return classification.known_safe_forms() end
function creature_service.collect_transform_target_paths() return catalog_builder.collect_transform_target_paths() end
function creature_service.collect_target_paths() return catalog_builder.collect_transform_target_paths() end
function creature_service.collect() return catalog_builder.collect() end
function creature_service.warmup_step(budget) return catalog_builder.warmup_step(budget) end
function creature_service.catalog_version() return catalog_builder.catalog_version() end

function creature_service.collect_diagnostics()
    return creature_diagnostics.collect(creature_service)
end

function creature_service.diagnostic_info_for_path(path)
    return creature_diagnostics.info(creature_service, path)
end

function creature_service.collect_prewarm_candidates()
    -- Prewarm is intentionally broader than the lazy UI catalogue. Exact polymorph XML
    -- must be published before the world starts, while full structural admission stays
    -- lazy for menu performance.
    local result, seen = {}, {}
    local function push(path, trusted_catalog)
        path = type(path) == "table" and path.path or path
        if type(path) ~= "string" or path == "" or seen[path] then return end
        if unsafe_reason(path) ~= nil or not ModDoesFileExist(path) then return end
        if trusted_catalog ~= true and string.sub(path, 1, 22) == "data/entities/animals/"
            and internal_helper_path(path) then return end
        seen[path] = true
        result[#result + 1] = { path = path }
    end
    for _, entry in ipairs(creature_service.collect()) do push(entry, true) end
    for _, entry in ipairs(catalog_builder.static_catalog()) do push(entry, false) end
    for _, path in ipairs(creature_service.collect_transform_target_paths()) do push(path, false) end
    return result
end

-- Historical UI compatibility API: full catalogue entries, never prewarm-only records.
function creature_service.collect_all_candidates()
    return creature_service.collect()
end

function creature_service.spawn_at(entity_path, x, y)
    if type(entity_path) ~= "string" or entity_path == "" or not ModDoesFileExist(entity_path) then return 0 end
    return EntityLoad(entity_path, x or 0, y or 0) or 0
end

function creature_service.spawn_near_player(player_entity, entity_path, offset_x, offset_y)
    if player_entity == nil or player_entity == 0 or not EntityGetIsAlive(player_entity) then return 0 end
    local player_x, player_y = EntityGetTransform(player_entity)
    if player_x == nil or player_y == nil then return 0 end
    return creature_service.spawn_at(entity_path, player_x + (offset_x or 32), player_y + (offset_y or -4))
end

METAMORPH_CREATIVE_MENU_CREATURE_SERVICE = creature_service
-- Legacy singleton alias kept for compatibility with older callers.
METAMORPH_CREATIVE_MENU_CREATURE_API = creature_service
return creature_service
