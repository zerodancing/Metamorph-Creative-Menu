if type(METAMORPH_CREATIVE_MENU_FORM_EXACT_EFFECTS) == "table" then return METAMORPH_CREATIVE_MENU_FORM_EXACT_EFFECTS end

local exact_effects = {}
local hash = dofile("mods/metamorph_creative_menu/files/core/hash.lua")
local xml_utils = dofile("mods/metamorph_creative_menu/files/core/xml_utils.lua")
local GENERATED_DIR = "mods/metamorph_creative_menu/files/generated/"
local LONG_DURATION = 2147480000
local exact_effect_path_by_target = {}
local exact_entity_clone_by_target = {}
local prepared_exact_effect_count = 0

local function effect_xml(target)
    return string.format(
        '<Entity><GameEffectComponent effect="POLYMORPH" frames="%d" disable_movement="0" polymorph_target="%s"></GameEffectComponent></Entity>',
        LONG_DURATION,
        xml_utils.escape_attribute(target)
    )
end

local RUNTIME_ENTITY_CLONE_MODE = {
    -- `sheep.xml` is treated specially by Noita's polymorph path and repeatedly
    -- resolves to sheep_bat/sheep_fly in the user's build. A byte-identical copy keeps
    -- the ordinary sheep data while removing the magic filename from the target.
    ["data/entities/animals/sheep.xml"] = "exact",

    -- These NPCs run wand_ghost.lua on their first update. That script owns NPC wand
    -- state and can delete the entity before our next compatibility update when a
    -- polymorphed player has no suitable wand. Replace only that lifecycle script in
    -- the player-form copy; world NPCs remain completely untouched.
    ["data/entities/animals/wand_ghost.xml"] = "wand_ghost_safe",
    ["data/entities/animals/playerghost.xml"] = "wand_ghost_safe",
}

local FORM_NOOP_SCRIPT = "mods/metamorph_creative_menu/files/features/forms/noop.lua"

local function patch_runtime_clone(content, mode)
    if mode ~= "wand_ghost_safe" then return content end
    local dangerous = "data/scripts/animals/wand_ghost.lua"
    local dangerous_pattern = string.gsub(dangerous, "%.", "%%.")
    content = string.gsub(content,
        'script_source_file%s*=%s*"' .. dangerous_pattern .. '"',
        'script_source_file="' .. FORM_NOOP_SCRIPT .. '"')
    content = string.gsub(content,
        "script_source_file%s*=%s*'" .. dangerous_pattern .. "'",
        'script_source_file="' .. FORM_NOOP_SCRIPT .. '"')
    return content
end

local function exact_runtime_entity_target(target)
    local mode = RUNTIME_ENTITY_CLONE_MODE[target]
    if mode == nil then return target end
    local cached = exact_entity_clone_by_target[target]
    if cached ~= nil then return cached ~= false and cached or target end
    local ok_read, content = pcall(ModTextFileGetContent, target)
    if not ok_read or type(content) ~= "string" or content == "" then
        exact_entity_clone_by_target[target] = false
        return target
    end
    content = patch_runtime_clone(content, mode)
    local clone = GENERATED_DIR .. "runtime_exact_creature_" .. hash.hex64(target .. ":" .. mode) .. ".xml"
    local ok_write = pcall(ModTextFileSetContent, clone, content)
    if not ok_write then
        exact_entity_clone_by_target[target] = false
        return target
    end
    exact_entity_clone_by_target[target] = clone
    return clone
end

local function publish_exact_effect_for_target(target)
    if type(target) ~= "string" or target == "" then
        return false
    end
    if exact_effect_path_by_target[target] ~= nil then
        return exact_effect_path_by_target[target] ~= false
    end
    if not ModDoesFileExist(target) then
        exact_effect_path_by_target[target] = false
        return false
    end

    local path = GENERATED_DIR .. "runtime_exact_polymorph_" .. hash.hex64(target) .. ".xml"
    local runtime_target = exact_runtime_entity_target(target)
    local ok = pcall(ModTextFileSetContent, path, effect_xml(runtime_target))
    if not ok then
        exact_effect_path_by_target[target] = false
        return false
    end

    exact_effect_path_by_target[target] = path
    prepared_exact_effect_count = prepared_exact_effect_count + 1
    return true
end

function exact_effects.prepare(entries)
    if type(entries) ~= "table" then
        return 0
    end

    for _, entry in ipairs(entries) do
        local target = type(entry) == "table" and entry.path or entry
        publish_exact_effect_for_target(target)
    end
    return prepared_exact_effect_count
end

function exact_effects.prepare_from_catalog()
    local ok_api, creature_service = pcall(dofile, "mods/metamorph_creative_menu/files/features/creatures/service.lua")
    if not ok_api or type(creature_service) ~= "table" then
        return 0
    end

    local all_entries = {}
    local collector = creature_service.collect_prewarm_candidates
    if type(collector) ~= "function" then collector = creature_service.collect_all_candidates end
    if type(collector) == "function" then
        local ok_all, catalog = pcall(collector)
        if ok_all and type(catalog) == "table" then
            all_entries = catalog
        end
    end
    exact_effects.prepare(all_entries)

    return prepared_exact_effect_count
end

function exact_effects.invalidate_failed_target(entity_path)
    if type(entity_path) ~= "string" or entity_path == "" then return false end
    if exact_effect_path_by_target[entity_path] == false then
        exact_effect_path_by_target[entity_path] = nil
    end
    if exact_entity_clone_by_target[entity_path] == false then
        exact_entity_clone_by_target[entity_path] = nil
    end
    return true
end

function exact_effects.effect_path(entity_path)
    if type(entity_path) ~= "string" or entity_path == "" then
        return nil
    end
    local path = exact_effect_path_by_target[entity_path]
    return type(path) == "string" and path or nil
end

-- Expose the actual XML filename produced by an exact transform. Most targets are
-- unchanged. A tiny set of engine-special paths are cloned
-- to generated filenames either to bypass filename-specific polymorph substitution or to
-- neutralize an NPC-only first-frame lifecycle script. The requested species remains the
-- session target; this function only exposes the runtime filename alias.
function exact_effects.runtime_target(entity_path)
    if type(entity_path) ~= "string" or entity_path == "" then return nil end
    return exact_runtime_entity_target(entity_path)
end



function exact_effects.default_duration_frames()
    return LONG_DURATION
end

function exact_effects.prepared_count()
    return prepared_exact_effect_count
end

METAMORPH_CREATIVE_MENU_FORM_EXACT_EFFECTS = exact_effects
return exact_effects
