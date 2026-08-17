if type(METAMORPH_CREATIVE_MENU_CREATURE_CLASSIFICATION) == "table" then return METAMORPH_CREATIVE_MENU_CREATURE_CLASSIFICATION end

local classification = {}
local metadata = dofile("mods/metamorph_creative_menu/files/features/creatures/metadata.lua")
local compatibility = dofile("mods/metamorph_creative_menu/files/features/creatures/compatibility.lua")
local creature_cache = {}
local structural_cache = {}

-- These are diagnostic hints only. They are intentionally NOT used to decide whether a
-- form is transformable. A working creature must never be rejected just because its
-- filename happens to contain "physics", "effect", "body", "sprite", etc.
local TECHNICAL_NAME_HINTS = {
    "projectile", "particle", "explosion", "_effect", "/effects/", "_sprite.xml",
    "/sprite.xml", "_shield", "shield_", "verlet", "_trigger", "spawn_check",
    "countered_", "projectile_counter", "_glow", "_tail_", "/tail/", "_limb_",
    "/limbs/", "_hair_", "/hair/", "_pupil", "_body_", "/body/", "_spawner",
    "/spawners/", "/_test", "_test_", "/rewards/", "/ending/", "reference_point",
    "clear_materials", "victoryroom_", "wand_orb", "wand_rotate", "create_wand",
    "/hair_", "/boss_limbs/orb_", "_body.xml",
}

local TECHNICAL_BASENAME_HINTS = {
    body=true, body_chunks=true, eye=true, eyea=true, eyeb=true, pupil=true,
    knee=true, limb=true, limb_a=true, limb_b=true, hair1=true, hair2=true,
    hair3=true, key=true, wand=true, mouth=true, head=true, torso=true,
    spawner=true, hair_piece=true, hair_piece_thin=true,
}

local OBSERVED_ROOT_COMPONENTS = {
    AnimalAIComponent=true, AdvancedFishAIComponent=true, FishAIComponent=true,
    WormAIComponent=true, WormComponent=true, WormPlayerComponent=true,
    BossDragonComponent=true, PhysicsAIComponent=true, CharacterDataComponent=true,
    LimbBossComponent=true, IKLimbWalkerComponent=true, IKLimbsAnimatorComponent=true,
    CrawlerAnimalComponent=true, GhostComponent=true,
    PhysicsBodyComponent=true, PhysicsBody2Component=true,
}

local PRIMARY_CREATURE_COMPONENTS = {
    "AnimalAIComponent", "AdvancedFishAIComponent", "FishAIComponent",
    "WormAIComponent", "WormComponent", "WormPlayerComponent",
    "BossDragonComponent", "PhysicsAIComponent", "CharacterDataComponent",
    "CrawlerAnimalComponent", "GhostComponent",
}

function classification.known_playable_exception(path)
    return compatibility.safe_reason(path) ~= nil
end

function classification.unsafe_reason(path)
    return compatibility.unsafe_reason(path)
end

function classification.path_is_technical(path)
    local lower = string.lower(path or "")
    local id = string.lower(metadata.basename(lower))
    if TECHNICAL_BASENAME_HINTS[id] then return true end
    for _, fragment in ipairs(TECHNICAL_NAME_HINTS) do
        if string.find(lower, fragment, 1, true) then return true end
    end
    return false
end

local function structural_scan(path, visited, depth, found)
    if type(path) ~= "string" or path == "" or depth > 12 then return end
    visited = visited or {}
    found = found or {}
    if visited[path] then return end
    visited[path] = true

    local content = metadata.read_text(path)
    if content == nil then return end
    local entity_depth, base_depth = 0, 0
    local inherited_bases = {}
    for tag in string.gmatch(content, "<[^>]+>") do
        local lower = string.lower(tag)
        local is_close = string.match(lower, "^</") ~= nil
        local self_close = string.match(lower, "/%s*>$") ~= nil
        if string.match(lower, "^<%s*entity[%s>]") and not is_close then
            entity_depth = entity_depth + 1
            if self_close then entity_depth = math.max(0, entity_depth - 1) end
        elseif string.match(lower, "^</%s*entity%s*>") then
            entity_depth = math.max(0, entity_depth - 1)
        elseif entity_depth == 1 and string.match(lower, "^<%s*base[%s>]") and not is_close then
            local file = metadata.attribute(tag, "file")
            if type(file) == "string" and file ~= "" then inherited_bases[#inherited_bases + 1] = file end
            if not self_close then base_depth = base_depth + 1 end
        elseif entity_depth == 1 and string.match(lower, "^</%s*base%s*>") then
            base_depth = math.max(0, base_depth - 1)
        elseif entity_depth == 1 then
            local component_name = string.match(tag, "^<%s*([%w_]+Component)[%s/>]")
            if component_name ~= nil and OBSERVED_ROOT_COMPONENTS[component_name] then
                found[component_name] = true
            end
        end
    end
    for _, base in ipairs(inherited_bases) do structural_scan(base, visited, depth + 1, found) end
end

function classification.structural_components(path)
    if structural_cache[path] ~= nil then return structural_cache[path] end
    local found = {}
    structural_scan(path, {}, 0, found)
    structural_cache[path] = found
    return found
end

function classification.structural_creature(path)
    local components = classification.structural_components(path)
    for _, component_name in ipairs(PRIMARY_CREATURE_COMPONENTS) do
        if components[component_name] then return true end
    end
    local has_ik_family = components.LimbBossComponent or components.IKLimbWalkerComponent or components.IKLimbsAnimatorComponent
    local has_physics_body = components.PhysicsBodyComponent or components.PhysicsBody2Component or components.PhysicsAIComponent
    return has_ik_family == true and has_physics_body == true
end

-- Legacy API name retained for callers, but the decision is structural now. A path is
-- considered an internal/helper-like entity only when it exposes creature-adjacent IK/
-- physics pieces without enough root structure to be a standalone supported body.
-- Directory names and filename fragments never decide this result.
function classification.internal_helper_path(path)
    if compatibility.safe_reason(path) ~= nil then return false end
    local components = classification.structural_components(path)
    return next(components) ~= nil and not classification.structural_creature(path)
end

function classification.probable_creature(path)
    if creature_cache[path] ~= nil then return creature_cache[path] end
    local result = classification.unsafe_reason(path) == nil
        and classification.structural_creature(path)
        and not classification.internal_helper_path(path)
    creature_cache[path] = result == true
    return result == true
end

function classification.catalog_creature(path)
    return classification.probable_creature(path)
end

function classification.compatibility_status(path)
    return compatibility.status(path, classification.probable_creature(path))
end

function classification.known_unsafe_forms()
    return compatibility.known_unsafe_forms()
end

function classification.known_safe_forms()
    return compatibility.known_safe_forms()
end

METAMORPH_CREATIVE_MENU_CREATURE_CLASSIFICATION = classification
return classification
