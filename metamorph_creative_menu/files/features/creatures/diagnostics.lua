if type(METAMORPH_CREATIVE_MENU_CREATURE_DIAGNOSTICS) == "table" then return METAMORPH_CREATIVE_MENU_CREATURE_DIAGNOSTICS end

local diagnostics = {}
local hash = dofile("mods/metamorph_creative_menu/files/core/hash.lua")
local metadata = dofile("mods/metamorph_creative_menu/files/features/creatures/metadata.lua")
local classification = dofile("mods/metamorph_creative_menu/files/features/creatures/classification.lua")

local diagnostics_cache = nil
local diagnostics_index_cache = nil
local basename = metadata.basename
local read_text = metadata.read_text
local attr = metadata.attribute
local base_files = metadata.base_files
local path_is_technical = classification.path_is_technical
local probable_creature = classification.probable_creature

local function diagnostic_scan(path, visited, depth, components, bases, tags)
    if type(path) ~= "string" or path == "" or depth > 12 or visited[path] then
        return
    end
    visited[path] = true
    local content = read_text(path)
    if content == nil then
        return
    end
    local lower = string.lower(content)
    for _, marker in ipairs(DIAGNOSTIC_COMPONENT_MARKERS) do
        if string.find(lower, marker[2], 1, true) then
            components[marker[1]] = true
        end
    end
    local entity_tag = string.match(content, "<Entity[^>]*>")
    if entity_tag ~= nil then
        local entity_tags = attr(entity_tag, "tags")
        if type(entity_tags) == "string" and entity_tags ~= "" then
            for tag in string.gmatch(entity_tags, "[^,]+") do
                tag = string.match(tag, "^%s*(.-)%s*$")
                if tag ~= nil and tag ~= "" then
                    tags[tag] = true
                end
            end
        end
    end
    for _, base in ipairs(base_files(content)) do
        bases[base] = true
        diagnostic_scan(base, visited, depth + 1, components, bases, tags)
    end
end

local function sorted_keys(set)
    local result = {}
    for key, value in pairs(set or {}) do
        if value then
            result[#result + 1] = key
        end
    end
    table.sort(result)
    return result
end

local function target_set(rare)
    local result = {}
    local ok, entries = pcall(PolymorphTableGet, rare == true)
    if ok and type(entries) == "table" then
        for _, path in ipairs(entries) do
            if type(path) == "string" and path ~= "" then
                result[path] = true
            end
        end
    end
    return result
end

local function tag_attributes_summary(tag)
    local values = {}
    for key, value in string.gmatch(tag or "", '([%w_]+)%s*=%s*"([^"]*)"') do
        if key ~= "file" and key ~= "include_children" then
            values[key] = value
        end
    end
    for key, value in string.gmatch(tag or "", "([%w_]+)%s*=%s*'([^']*)'") do
        if key ~= "file" and key ~= "include_children" and values[key] == nil then
            values[key] = value
        end
    end
    local parts = {}
    for key, value in pairs(values) do
        parts[#parts + 1] = key .. "=" .. tostring(value)
    end
    table.sort(parts)
    return table.concat(parts, ",")
end

-- Inspect only the target file itself. This complements diagnostic_scan(), which
-- intentionally follows the complete inheritance graph. Keeping both views lets
-- us distinguish a normal creature from a thin biome/drunk/illusion wrapper.
local function inspect_root_structure(path)
    local result = {
        direct_bases = {},
        base_links = {},
        direct_components = {},
        base_override_components = {},
        base_override_values = {},
        game_effects = {},
        lua_scripts = {},
        child_entities = 0,
        definition_hash = "",
        definition_size = 0,
    }
    local content = read_text(path)
    if content == nil then
        return result
    end
    result.definition_hash = hash.hex64(content)
    result.definition_size = #content

    local direct_components = {}
    local base_override_components = {}
    local base_override_values = {}
    local game_effects = {}
    local lua_scripts = {}
    local entity_depth = 0
    local root_base_depth = 0

    for tag in string.gmatch(content, "<[^>]+>") do
        local lower = string.lower(tag)
        local is_close = string.match(lower, "^</") ~= nil
        local self_close = string.match(lower, "/%s*>$") ~= nil

        if string.match(lower, "^<%s*entity[%s>]" ) and not is_close then
            entity_depth = entity_depth + 1
            if entity_depth == 2 then
                result.child_entities = result.child_entities + 1
            end
        elseif string.match(lower, "^</%s*entity%s*>") then
            entity_depth = math.max(0, entity_depth - 1)
        elseif string.match(lower, "^<%s*base[%s>]" ) and not is_close then
            if entity_depth == 1 then
                local file = attr(tag, "file")
                local include_children = attr(tag, "include_children") or ""
                if type(file) == "string" and file ~= "" then
                    result.direct_bases[#result.direct_bases + 1] = file
                    result.base_links[#result.base_links + 1] = file .. "|include_children=" .. include_children
                end
                if not self_close then
                    root_base_depth = root_base_depth + 1
                end
            end
        elseif string.match(lower, "^</%s*base%s*>") then
            if entity_depth == 1 and root_base_depth > 0 then
                root_base_depth = root_base_depth - 1
            end
        else
            local component_name = string.match(tag, "^<%s*([%w_]+Component)[%s/>]")
            if component_name ~= nil and entity_depth == 1 then
                if root_base_depth > 0 then
                    base_override_components[component_name] = true
                    local attribute_summary = tag_attributes_summary(tag)
                    local key = component_name .. "{" .. attribute_summary .. "}"
                    base_override_values[key] = true
                else
                    direct_components[component_name] = true
                end
            end

            if string.match(lower, "^<%s*gameeffectcomponent[%s/>]") then
                local effect = attr(tag, "effect") or ""
                if effect ~= "" then
                    local scope = entity_depth > 1 and "child:" or "root:"
                    game_effects[scope .. effect] = true
                end
            end

            if string.match(lower, "^<%s*luacomponent[%s/>]") then
                for key, value in string.gmatch(tag, '(script_[%w_]+)%s*=%s*"([^"]+)"') do
                    lua_scripts[key .. "=" .. value] = true
                end
                for key, value in string.gmatch(tag, "(script_[%w_]+)%s*=%s*'([^']+)'") do
                    lua_scripts[key .. "=" .. value] = true
                end
            end
        end
    end

    result.direct_components = sorted_keys(direct_components)
    result.base_override_components = sorted_keys(base_override_components)
    result.base_override_values = sorted_keys(base_override_values)
    result.game_effects = sorted_keys(game_effects)
    result.lua_scripts = sorted_keys(lua_scripts)
    return result
end

local function strong_canonical_target(entry, root)
    if type(entry) ~= "table" or type(root) ~= "table" then
        return nil, nil
    end
    local wanted_id = tostring(entry.id or basename(entry.path))
    for _, base in ipairs(root.direct_bases or {}) do
        if base ~= entry.path
            and basename(base) == wanted_id
            and ModDoesFileExist(base)
            and probable_creature(base)
        then
            return base, "direct_base_same_id"
        end
    end
    return nil, nil
end

local function diagnostic_attack_scan(path, visited, depth, attacks)
    if type(path) ~= "string" or path == "" or depth > 12 or visited[path] then
        return
    end
    visited[path] = true
    local content = read_text(path)
    if content == nil then
        return
    end

    for tag in string.gmatch(content, "<[^>]+>") do
        local lower = string.lower(tag)
        local component_name = nil
        if string.match(lower, "^<%s*animalaicomponent[%s/>]") then
            component_name = "AnimalAIComponent"
        elseif string.match(lower, "^<%s*aiattackcomponent[%s/>]") then
            component_name = "AIAttackComponent"
        elseif string.match(lower, "^<%s*bossdragoncomponent[%s/>]") then
            component_name = "BossDragonComponent"
        elseif string.match(lower, "^<%s*abilitycomponent[%s/>]") then
            component_name = "AbilityComponent"
        end

        if component_name ~= nil then
            local fields = {
                "attack_ranged_entity_file",
                "attack_ranged_frames_between",
                "attack_ranged_action_frame",
                "attack_melee_enabled",
                "attack_melee_damage_min",
                "attack_melee_damage_max",
                "projectile_1",
                "projectile_1_count",
                "projectile_2",
                "projectile_2_count",
                "entity_file",
                "cooldown_frames",
            }
            for _, field in ipairs(fields) do
                local value = attr(tag, field)
                if value ~= nil and value ~= "" then
                    attacks[component_name .. "." .. field .. "=" .. value] = true
                end
            end
        end
    end

    for _, base in ipairs(base_files(content)) do
        diagnostic_attack_scan(base, visited, depth + 1, attacks)
    end
end

local function static_control_profile(component_list)
    local set = {}
    for _, name in ipairs(component_list or {}) do
        set[name] = true
    end

    local movement = {}
    local movement_order = {
        "ControlsComponent",
        "PlatformShooterPlayerComponent",
        "CharacterDataComponent",
        "CharacterPlatformingComponent",
        "AdvancedFishAIComponent",
        "FishAIComponent",
        "WormAIComponent",
        "WormComponent",
        "WormPlayerComponent",
        "BossDragonComponent",
        "PhysicsAIComponent",
        "PhysicsBodyComponent",
        "PhysicsBody2Component",
        "IKLimbComponent",
        "IKLimbWalkerComponent",
        "IKLimbsAnimatorComponent",
        "LimbBossComponent",
        "VerletPhysicsComponent",
        "VerletWorldJointComponent",
        "VelocityComponent",
    }
    for _, name in ipairs(movement_order) do
        if set[name] then movement[#movement + 1] = name end
    end

    local family = "unknown"
    if set.WormPlayerComponent or (set.WormAIComponent and set.WormComponent) then
        family = "worm_native_candidate"
    elseif set.ControlsComponent and set.CharacterDataComponent then
        family = "character_controls_candidate"
    elseif set.BossDragonComponent then
        family = "boss_dragon_ai_only_candidate"
    elseif set.IKLimbsAnimatorComponent or set.IKLimbWalkerComponent or set.LimbBossComponent then
        family = set.ControlsComponent and "ik_limb_with_controls_candidate" or "ik_limb_ai_only_candidate"
    elseif set.PhysicsAIComponent or set.PhysicsBodyComponent or set.PhysicsBody2Component then
        family = set.ControlsComponent and "physics_with_controls_candidate" or "physics_ai_only_candidate"
    elseif set.AdvancedFishAIComponent or set.FishAIComponent then
        family = set.ControlsComponent and "fish_with_controls_candidate" or "fish_ai_only_candidate"
    elseif set.ControlsComponent then
        family = "controls_present_candidate"
    end

    return family, movement
end

function diagnostics.collect(catalog_api)
    if diagnostics_cache ~= nil then
        return diagnostics_cache
    end
    local catalog = catalog_api.collect()
    local common = target_set(false)
    local rare = target_set(true)
    local verified = {}
    for _, path in ipairs(catalog_api.collect_transform_target_paths()) do
        verified[path] = true
    end

    local id_counts = {}
    local name_counts = {}
    for _, entry in ipairs(catalog) do
        local id = tostring(entry.id or "")
        local name = string.lower(tostring(entry.display_name or ""))
        id_counts[id] = (id_counts[id] or 0) + 1
        name_counts[name] = (name_counts[name] or 0) + 1
    end

    local scanned = {}
    local definition_counts = {}
    local structure_counts = {}
    for _, entry in ipairs(catalog) do
        local components = {}
        local bases = {}
        local tags = {}
        local attacks = {}
        diagnostic_scan(entry.path, {}, 0, components, bases, tags)
        diagnostic_attack_scan(entry.path, {}, 0, attacks)
        local root = inspect_root_structure(entry.path)
        local component_list = sorted_keys(components)
        local base_list = sorted_keys(bases)
        local tag_list = sorted_keys(tags)
        local attack_list = sorted_keys(attacks)
        local control_family, movement_components = static_control_profile(component_list)
        local structure_hash = hash.hex64(
            table.concat(component_list, ",") .. "|" .. table.concat(tag_list, ",")
        )
        local canonical_target, canonical_reason = strong_canonical_target(entry, root)
        scanned[#scanned + 1] = {
            entry = entry,
            components = component_list,
            bases = base_list,
            tags = tag_list,
            attacks = attack_list,
            control_family = control_family,
            movement_components = movement_components,
            root = root,
            structure_hash = structure_hash,
            canonical_target = canonical_target,
            canonical_reason = canonical_reason,
        }
        if root.definition_hash ~= "" then
            definition_counts[root.definition_hash] = (definition_counts[root.definition_hash] or 0) + 1
        end
        structure_counts[structure_hash] = (structure_counts[structure_hash] or 0) + 1
    end

    local result = {}
    for _, scan in ipairs(scanned) do
        local entry = scan.entry
        local root = scan.root
        local components_set = {}
        for _, name in ipairs(scan.components) do components_set[name] = true end

        local traits = {}
        local lower_path = string.lower(entry.path or "")
        if path_is_technical(entry.path) then traits[#traits + 1] = "technical_path" end
        if not probable_creature(entry.path) then traits[#traits + 1] = "not_probable_creature" end
        if components_set.ProjectileComponent then traits[#traits + 1] = "projectile_component" end
        if components_set.PhysicsBodyComponent or components_set.PhysicsImageShapeComponent then traits[#traits + 1] = "physics_body" end
        if not components_set.CharacterDataComponent then traits[#traits + 1] = "no_character_data" end
        if not components_set.GenomeDataComponent then traits[#traits + 1] = "no_genome_data" end
        if not components_set.DamageModelComponent then traits[#traits + 1] = "no_damage_model" end
        if components_set.BossHealthBarComponent then traits[#traits + 1] = "boss_healthbar" end
        if string.find(lower_path, "physics", 1, true) then traits[#traits + 1] = "physics_named_variant" end
        if (id_counts[tostring(entry.id or "")] or 0) > 1 then traits[#traits + 1] = "duplicate_id" end
        if (name_counts[string.lower(tostring(entry.display_name or ""))] or 0) > 1 then traits[#traits + 1] = "duplicate_name" end
        if (definition_counts[root.definition_hash] or 0) > 1 then traits[#traits + 1] = "duplicate_definition" end
        if (structure_counts[scan.structure_hash] or 0) > 1 then traits[#traits + 1] = "duplicate_structure" end
        if scan.canonical_target ~= nil then traits[#traits + 1] = "wrapper_same_id" end
        if #(root.base_override_components or {}) > 0 then traits[#traits + 1] = "base_override" end
        if tonumber(root.child_entities) ~= nil and root.child_entities > 0 then traits[#traits + 1] = "child_entities" end
        if #(root.game_effects or {}) > 0 then traits[#traits + 1] = "game_effects" end
        if #(root.lua_scripts or {}) > 0 then traits[#traits + 1] = "lua_scripts" end
        if scan.control_family == "worm_native_candidate" then traits[#traits + 1] = "native_worm_control_candidate" end
        if scan.control_family == "ik_limb_ai_only_candidate" then traits[#traits + 1] = "custom_control_adapter_candidate" end
        if scan.control_family == "boss_dragon_ai_only_candidate" then traits[#traits + 1] = "custom_control_adapter_candidate" end
        if scan.control_family == "physics_ai_only_candidate" then traits[#traits + 1] = "custom_control_adapter_candidate" end

        local compatibility_status, compatibility_reason = "unsupported", "compatibility_api_unavailable"
        if type(catalog_api.compatibility_status) == "function" then
            local ok_status, status, reason = pcall(catalog_api.compatibility_status, entry.path)
            if ok_status then
                compatibility_status = tostring(status or "unsupported")
                compatibility_reason = tostring(reason or "unknown")
            end
        end
        local is_verified = verified[entry.path] == true or compatibility_status == "verified"
        local verification_reason = compatibility_reason
        if common[entry.path] then
            verification_reason = "polymorph_common"
        elseif rare[entry.path] then
            verification_reason = "polymorph_rare"
        elseif verified[entry.path] == true and compatibility_status ~= "verified" then
            verification_reason = "explicit_transform_safe"
        end

        local canonical_registered = false
        if scan.canonical_target ~= nil then
            canonical_registered = verified[scan.canonical_target] == true
        end

        result[#result + 1] = {
            path = entry.path,
            target_hash = hash.hex64(entry.path),
            id = entry.id,
            display_name = entry.display_name,
            source = entry.source,
            category = entry.category,
            icon = entry.icon,
            progress_index = entry.progress_index,
            verified = is_verified,
            verification_reason = verification_reason,
            compatibility_status = compatibility_status,
            compatibility_reason = compatibility_reason,
            common_poly = common[entry.path] == true,
            rare_poly = rare[entry.path] == true,
            technical_path = path_is_technical(entry.path),
            probable_creature = probable_creature(entry.path),
            definition_hash = root.definition_hash,
            definition_size = root.definition_size,
            definition_duplicate_count = definition_counts[root.definition_hash] or 0,
            structure_hash = scan.structure_hash,
            structure_duplicate_count = structure_counts[scan.structure_hash] or 0,
            direct_bases = root.direct_bases,
            base_links = root.base_links,
            canonical_target = scan.canonical_target,
            canonical_reason = scan.canonical_reason,
            canonical_registered = canonical_registered,
            root_child_entities = root.child_entities,
            base_override_components = root.base_override_components,
            base_override_values = root.base_override_values,
            direct_components = root.direct_components,
            game_effects = root.game_effects,
            lua_scripts = root.lua_scripts,
            static_control_family = scan.control_family,
            movement_components = scan.movement_components,
            attack_descriptors = scan.attacks,
            components = scan.components,
            bases = scan.bases,
            entity_tags = scan.tags,
            duplicate_id_count = id_counts[tostring(entry.id or "")] or 0,
            duplicate_name_count = name_counts[string.lower(tostring(entry.display_name or ""))] or 0,
            traits = traits,
        }
    end
    diagnostics_cache = result
    diagnostics_index_cache = {}
    for _, info in ipairs(result) do
        diagnostics_index_cache[info.path] = info
    end
    return diagnostics_cache
end

function diagnostics.info(catalog_api, path)
    if diagnostics_cache == nil then
        diagnostics.collect(catalog_api)
    end
    if diagnostics_index_cache ~= nil and diagnostics_index_cache[path] ~= nil then
        return diagnostics_index_cache[path]
    end
    return {
        path = path,
        id = basename(path),
        display_name = basename(path),
        source = "unknown",
        category = "OTHER",
        verified = false,
        verification_reason = "not_in_catalog",
    }
end


METAMORPH_CREATIVE_MENU_CREATURE_DIAGNOSTICS = diagnostics
return diagnostics
