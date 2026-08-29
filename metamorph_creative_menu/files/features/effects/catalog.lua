if type(METAMORPH_CREATIVE_MENU_EFFECT_CATALOG) == "table" then return METAMORPH_CREATIVE_MENU_EFFECT_CATALOG end

local catalog_api = {}
local effect_policy = dofile("mods/metamorph_creative_menu/files/features/effects/policy.lua")

-- Effect catalog deliberately contains only entity-backed effects. Stain/ingestion
-- states are discovered from Noita's own status_list.lua at runtime so names, icons
-- and ordering follow the game and the active language instead of a mod-local list.
local EFFECT_PATHS = {
    "data/entities/misc/effect_ability_actions_materialized.xml",
    "data/entities/misc/effect_allergy_radioactive.xml",
    "data/entities/misc/effect_berserk.xml",
    "data/entities/misc/effect_blindness.xml",
    "data/entities/misc/effect_brain_damage.xml",
    "data/entities/misc/effect_breath_underwater.xml",
    "data/entities/misc/effect_card_munching.xml",
    "data/entities/misc/effect_charm_short.xml",
    "data/entities/misc/effect_charm.xml",
    "data/entities/misc/effect_confusion.xml",
    "data/entities/misc/effect_critical_hit_boost.xml",
    "data/entities/misc/effect_curse_cloud_00.xml",
    "data/entities/misc/effect_curse_cloud_01_temporary.xml",
    "data/entities/misc/effect_curse_cloud_01.xml",
    "data/entities/misc/effect_curse_cloud_02.xml",
    "data/entities/misc/effect_curse_rain.xml",
    "data/entities/misc/effect_damage_multiplier.xml",
    "data/entities/misc/effect_drunk_00.xml",
    "data/entities/misc/effect_drunk_01.xml",
    "data/entities/misc/effect_drunk_forever.xml",
    "data/entities/misc/effect_drunk.xml",
    "data/entities/misc/effect_edit_wands_everywhere.xml",
    "data/entities/misc/effect_electricity.xml",
    "data/entities/misc/effect_exploding_corpse_shots.xml",
    "data/entities/misc/effect_exploding_corpse.xml",
    "data/entities/misc/effect_extra_money_trick_kill.xml",
    "data/entities/misc/effect_extra_money.xml",
    "data/entities/misc/effect_farts.xml",
    "data/entities/misc/effect_faster_levitation.xml",
    "data/entities/misc/effect_food_poisoning.xml",
    "data/entities/misc/effect_frozen_short.xml",
    "data/entities/misc/effect_frozen_speed_up.xml",
    "data/entities/misc/effect_frozen.xml",
    "data/entities/misc/effect_global_gore.xml",
    "data/entities/misc/effect_healhurt.xml",
    "data/entities/misc/effect_healing_blood.xml",
    "data/entities/misc/effect_hover_boost.xml",
    "data/entities/misc/effect_internal_fire.xml",
    "data/entities/misc/effect_internal_ice.xml",
    "data/entities/misc/effect_invisibility_short.xml",
    "data/entities/misc/effect_invisibility.xml",
    "data/entities/misc/effect_iron_stomach.xml",
    "data/entities/misc/effect_jarate.xml",
    "data/entities/misc/effect_knockback_immunity.xml",
    "data/entities/misc/effect_knockback.xml",
    "data/entities/misc/effect_levitation.xml",
    "data/entities/misc/effect_low_hp_damage_boost.xml",
    "data/entities/misc/effect_mana_regeneration.xml",
    "data/entities/misc/effect_melee_counter.xml",
    "data/entities/misc/effect_movement_faster_2x.xml",
    "data/entities/misc/effect_movement_faster.xml",
    "data/entities/misc/effect_movement_slower_2x.xml",
    "data/entities/misc/effect_movement_slower.xml",
    "data/entities/misc/effect_necromancy.xml",
    "data/entities/misc/effect_nightvision.xml",
    "data/entities/misc/effect_no_heal_in_meat_biome.xml",
    "data/entities/misc/effect_no_heal.xml",
    "data/entities/misc/effect_no_slime_slowdown.xml",
    "data/entities/misc/effect_projectile_homing.xml",
    "data/entities/misc/effect_protection_all_short_evil.xml",
    "data/entities/misc/effect_protection_all_short.xml",
    "data/entities/misc/effect_protection_all_ultrashort.xml",
    "data/entities/misc/effect_protection_all.xml",
    "data/entities/misc/effect_protection_during_teleport.xml",
    "data/entities/misc/effect_protection_electricity.xml",
    "data/entities/misc/effect_protection_explosion.xml",
    "data/entities/misc/effect_protection_fire.xml",
    "data/entities/misc/effect_protection_food_poisoning.xml",
    "data/entities/misc/effect_protection_freeze.xml",
    "data/entities/misc/effect_protection_melee.xml",
    "data/entities/misc/effect_protection_polymorph.xml",
    "data/entities/misc/effect_protection_radioactivity.xml",
    "data/entities/misc/effect_rainbow_farts.xml",
    "data/entities/misc/effect_regeneration.xml",
    "data/entities/misc/effect_remove_fog_of_war.xml",
    "data/entities/misc/effect_saving_grace.xml",
    "data/entities/misc/effect_spirit_berserk.xml",
    "data/entities/misc/effect_spirit_confusion.xml",
    "data/entities/misc/effect_spirit_slime.xml",
    "data/entities/misc/effect_spirit_weakness.xml",
    "data/entities/misc/effect_stainless_armour.xml",
    "data/entities/misc/effect_stains_drop_faster.xml",
    "data/entities/misc/effect_stun_protection_electricity.xml",
    "data/entities/misc/effect_stun_protection_freeze.xml",
    "data/entities/misc/effect_telepathy.xml",
    "data/entities/misc/effect_teleportation_enemy.xml",
    "data/entities/misc/effect_teleportation.xml",
    "data/entities/misc/effect_teleportitis.xml",
    "data/entities/misc/effect_trip_00.xml",
    "data/entities/misc/effect_trip_01.xml",
    "data/entities/misc/effect_trip_02.xml",
    "data/entities/misc/effect_trip_03.xml",
    "data/entities/misc/effect_unstable_teleportation.xml",
    "data/entities/misc/effect_weakness.xml",
    "data/entities/misc/effect_worm_attractor.xml",
    "data/entities/misc/effect_worm_detractor.xml",
}

local RESERVED_EFFECTS = {
    POLYMORPH = true,
    POLYMORPH_RANDOM = true,
    POLYMORPH_UNSTABLE = true,
    POLYMORPH_CESSATION = true,
    RESPAWN = true,
    NO_WAND_EDITING = true,
}

-- These status IDs correspond to visible surface materials. Adding real stains makes
-- Noita itself own their decay instead of the mod running a timer or repeatedly
-- forcing a percentage. The game status table still supplies all presentation data.
local STATUS_MATERIAL_BY_ID = {
    WET = "water",
    OILED = "oil",
    BLOODY = "blood",
    SLIMY = "slime",
    RADIOACTIVE = "radioactive_liquid",
    POISONED = "poison",
}

local catalog = nil
local status_entries = nil
local xml_cache = {}
local metadata_cache = {}
local function translated(value)
    if type(value) ~= "string" or value == "" then return "" end
    local result = GameTextGetTranslatedOrNot(value)
    if result == nil or result == "" then return value end
    return result
end

local function pretty_name(path)
    local name = tostring(path or "")
    name = string.match(name, "([^/]+)%.xml$") or name
    name = string.gsub(name, "^effect_", "")
    name = string.gsub(name, "_", " ")
    name = string.gsub(name, "(%a)([%w']*)", function(a, b)
        return string.upper(a) .. string.lower(b)
    end)
    return name
end

local function read_text(path)
    if xml_cache[path] ~= nil then return xml_cache[path] ~= false and xml_cache[path] or nil end
    local ok, content = pcall(ModTextFileGetContent, path)
    if not ok or type(content) ~= "string" or content == "" then
        xml_cache[path] = false
        return nil
    end
    xml_cache[path] = content
    return content
end

local function attr(tag, name)
    local escaped = string.gsub(name, "([%%%-%+%*%?%[%]%^%$%(%)%.])", "%%%1")
    return string.match(tag or "", escaped .. '%s*=%s*"([^"]*)"')
        or string.match(tag or "", escaped .. "%s*=%s*'([^']*)'")
end

local function merge_meta(dst, src)
    if type(src) ~= "table" then return end
    for key, value in pairs(src) do
        if (dst[key] == nil or dst[key] == "") and value ~= nil and value ~= "" then dst[key] = value end
    end
end

local function read_effect_metadata(path, visited, depth)
    if metadata_cache[path] ~= nil then return metadata_cache[path] end
    if type(path) ~= "string" or path == "" or depth > 12 then return {} end
    visited = visited or {}
    if visited[path] then return {} end
    visited[path] = true
    local content = read_text(path)
    if content == nil then return {} end

    local meta = { path = path }
    for base_tag in string.gmatch(content, "<Base[^>]*>") do
        local base_path = attr(base_tag, "file")
        if type(base_path) == "string" and base_path ~= "" then
            merge_meta(meta, read_effect_metadata(base_path, visited, depth + 1))
        end
    end
    local ui_tag = string.match(content, "<UIIconComponent[^>]*>")
    if ui_tag ~= nil then
        meta.name = attr(ui_tag, "name") or meta.name
        meta.description = attr(ui_tag, "description") or meta.description
        meta.icon = attr(ui_tag, "icon_sprite_file") or meta.icon
    end
    local game_tag = string.match(content, "<GameEffectComponent[^>]*>")
    if game_tag ~= nil then
        meta.effect = attr(game_tag, "effect") or meta.effect
        meta.custom_effect_id = attr(game_tag, "custom_effect_id") or meta.custom_effect_id
        local disabled = attr(game_tag, "disable_movement")
        if disabled ~= nil then meta.disable_movement = disabled == "1" or disabled == "true" end
    end
    metadata_cache[path] = meta
    visited[path] = nil
    return meta
end

local function status_value(entry, key_candidates)
    for _, key in ipairs(key_candidates) do
        local value = entry[key]
        if value ~= nil and value ~= "" then return value end
    end
    return nil
end

local function load_status_entries()
    if status_entries ~= nil then return status_entries end
    status_entries = {}
    local ok = pcall(dofile_once, "data/scripts/status_effects/status_list.lua")
    if not ok or type(status_effects) ~= "table" then return status_entries end

    -- status_list.lua contains presentation variants and, depending on the game build,
    -- repeated semantic status ids. Build one canonical entry per id and merge richer
    -- presentation data into it instead of exposing duplicates as blank-looking cells.
    local by_id = {}
    for index, status in ipairs(status_effects) do
        if type(status) == "table" and type(status.id) == "string" and status.id ~= "" then
            local path = status_value(status, { "effect_entity", "effect_entity_file", "entity_file" })
            local icon = status_value(status, { "ui_icon", "icon", "icon_sprite_file" })
            local name = status_value(status, { "ui_name", "name" })
            local description = status_value(status, { "ui_description", "description" })
            local meta = type(path) == "string" and ModDoesFileExist(path) and read_effect_metadata(path, {}, 0) or {}
            local candidate = {
                kind = "status",
                id = status.id,
                status_index = index,
                path = type(path) == "string" and path or "",
                icon = type(icon) == "string" and icon or (meta.icon or ""),
                name_key = name or meta.name,
                description_key = description or meta.description,
                display_name = translated(name or meta.name),
                display_description = translated(description or meta.description),
                material = STATUS_MATERIAL_BY_ID[status.id],
                game_effect = meta.effect,
                custom_effect_id = meta.custom_effect_id,
            }
            local current = by_id[status.id]
            if current == nil then
                by_id[status.id] = candidate
                status_entries[#status_entries + 1] = candidate
            else
                -- Keep the first status_index: StatusEffectDataComponent vectors are
                -- indexed in vanilla list order. Only fill missing presentation/entity
                -- metadata from later duplicate declarations.
                if current.path == "" and candidate.path ~= "" then current.path = candidate.path end
                if current.icon == "" and candidate.icon ~= "" then current.icon = candidate.icon end
                if current.display_name == "" and candidate.display_name ~= "" then current.display_name = candidate.display_name end
                if current.display_description == "" and candidate.display_description ~= "" then current.display_description = candidate.display_description end
                current.name_key = current.name_key or candidate.name_key
                current.description_key = current.description_key or candidate.description_key
                current.material = current.material or candidate.material
                current.game_effect = current.game_effect or candidate.game_effect
                current.custom_effect_id = current.custom_effect_id or candidate.custom_effect_id
            end
        end
    end
    return status_entries
end

local function normalize_display(entry)
    if entry.display_name == nil or entry.display_name == "" or string.sub(entry.display_name, 1, 1) == "$" then
        entry.display_name = entry.id or pretty_name(entry.path)
    end
    if entry.display_description == nil or entry.display_description == entry.display_name then
        entry.display_description = ""
    elseif type(entry.display_description) == "string" and type(entry.display_name) == "string" then
        -- UIIcon descriptions in some vanilla effects repeat the localized name as
        -- their first line. The tile already renders the title separately.
        local prefix = entry.display_name
        if string.sub(entry.display_description, 1, #prefix) == prefix then
            local rest = string.sub(entry.display_description, #prefix + 1)
            rest = string.gsub(rest, "^[%s:%-–—]+", "")
            entry.display_description = rest
        end
    end
    return entry
end

local function semantic_identity(entry)
    if type(entry) ~= "table" then return "" end
    -- Material statuses are distinct even when their presentation entity shares a
    -- generic effect. For entity-backed effects, custom/effect ids are the semantic
    -- identity; path is only a fallback.
    if type(entry.material) == "string" and entry.material ~= "" then
        return "status:" .. tostring(entry.id or entry.material)
    end
    local custom = tostring(entry.custom_effect_id or "")
    if custom ~= "" and custom ~= "CUSTOM" then return "custom:" .. string.upper(custom) end
    local effect = tostring(entry.game_effect or "")
    if effect ~= "" and effect ~= "CUSTOM" then return "effect:" .. string.upper(effect) end
    -- status_list often omits effect_entity even when the status id is exactly the
    -- GameEffect enum used by data/entities/misc/effect_*.xml. Canonicalize that pair
    -- so BERSERK status + effect_berserk entity is one tile whose metadata is merged.
    if entry.kind == "status" and tostring(entry.id or "") ~= "" then
        return "effect:" .. string.upper(tostring(entry.id))
    end
    local path = tostring(entry.path or "")
    if path ~= "" then return "path:" .. path end
    return "id:" .. tostring(entry.id or "")
end

local function richer(existing, candidate)
    if existing == nil then return candidate end
    local function score(value) return type(value) == "string" and value ~= "" and 1 or 0 end
    -- Prefer the declaration that actually has a visible icon/name. Preserve status
    -- semantics if either entry is a status because those use native stain/ingestion
    -- removal rather than merely expiring an entity.
    local e_score = score(existing.icon) * 4 + score(existing.display_name) * 2 + score(existing.display_description)
    local c_score = score(candidate.icon) * 4 + score(candidate.display_name) * 2 + score(candidate.display_description)
    local keep, other = existing, candidate
    if c_score > e_score and existing.kind ~= "status" then keep, other = candidate, existing end
    if keep.icon == "" then keep.icon = other.icon or "" end
    if keep.display_name == "" then keep.display_name = other.display_name or "" end
    if keep.display_description == "" then keep.display_description = other.display_description or "" end
    if keep.path == "" then keep.path = other.path or "" end
    keep.name_key = keep.name_key or other.name_key
    keep.description_key = keep.description_key or other.description_key
    keep.game_effect = keep.game_effect or other.game_effect
    keep.custom_effect_id = keep.custom_effect_id or other.custom_effect_id
    return keep
end

function catalog_api.entries()
    if catalog ~= nil then return catalog end
    local ordered, by_identity, by_path, by_presentation, seen_path = {}, {}, {}, {}, {}

    local function include(entry)
        local effect_id = string.upper(tostring(entry and (entry.game_effect or entry.id) or ""))
        local custom_id = string.upper(tostring(entry and entry.custom_effect_id or ""))
        -- status_list.lua also contains polymorph lifecycle statuses. Those change the
        -- player entity and cannot be treated as ordinary removable effects, so filter
        -- their semantic ids before any catalogue merge.
        if RESERVED_EFFECTS[effect_id] or RESERVED_EFFECTS[custom_id] then return end
        entry = normalize_display(entry)
        -- Internal status-vector aliases and service effects have no presentation of
        -- their own. They are not usable menu entries and previously produced a large
        -- block of neutral placeholder tiles.
        if not effect_policy.visible(entry, ModDoesFileExist) then return end
        local identity = semantic_identity(entry)
        if identity == "" then return end
        local presentation = ""
        if type(entry.path) == "string" and entry.path ~= "" and type(entry.icon) == "string" and entry.icon ~= ""
            and type(entry.display_name) == "string" and entry.display_name ~= ""
        then
            presentation = entry.path .. "|" .. entry.icon .. "|" .. string.lower(entry.display_name)
        end
        local path_key = type(entry.path) == "string" and entry.path ~= "" and entry.path or nil
        local existing = by_identity[identity]
        -- Vanilla status_list contains presentation aliases such as OILED/HYDRATED
        -- that intentionally point at the exact same effect entity. An effect menu
        -- should expose that implementation once, not one localized tile plus a second
        -- English/blank alias for the same XML.
        if existing == nil and path_key ~= nil then existing = by_path[path_key] end
        if existing == nil and presentation ~= "" then existing = by_presentation[presentation] end
        if existing == nil then
            by_identity[identity] = entry
            if path_key ~= nil then by_path[path_key] = entry end
            if presentation ~= "" then by_presentation[presentation] = entry end
            ordered[#ordered + 1] = entry
        else
            local merged = richer(existing, entry)
            by_identity[identity] = merged
            if path_key ~= nil then by_path[path_key] = merged end
            if presentation ~= "" then by_presentation[presentation] = merged end
            if merged ~= existing then
                for key, value in pairs(by_identity) do if value == existing then by_identity[key] = merged end end
                for key, value in pairs(by_path) do if value == existing then by_path[key] = merged end end
                for key, value in pairs(by_presentation) do if value == existing then by_presentation[key] = merged end end
                for i, value in ipairs(ordered) do if value == existing then ordered[i] = merged; break end end
            end
        end
        if type(entry.path) == "string" and entry.path ~= "" then seen_path[entry.path] = true end
    end

    for _, entry in ipairs(load_status_entries()) do include(entry) end
    for _, path in ipairs(EFFECT_PATHS) do
        if not seen_path[path] and ModDoesFileExist(path) then
            local meta = read_effect_metadata(path, {}, 0)
            local effect_name = tostring(meta.effect or "")
            local custom_effect_id = tostring(meta.custom_effect_id or "")
            if not RESERVED_EFFECTS[effect_name] and not RESERVED_EFFECTS[custom_effect_id] then
                include({
                    kind = "game_effect",
                    id = (custom_effect_id ~= "" and custom_effect_id) or (effect_name ~= "" and effect_name) or pretty_name(path),
                    path = path,
                    icon = meta.icon or "",
                    name_key = meta.name,
                    description_key = meta.description,
                    display_name = translated(meta.name),
                    display_description = translated(meta.description),
                    game_effect = meta.effect,
                    custom_effect_id = meta.custom_effect_id,
                    disable_movement = meta.disable_movement == true,
                })
            end
        end
    end

    catalog = ordered
    table.sort(catalog, function(a, b)
        local aa = string.lower(tostring(a.display_name or a.id or a.path))
        local bb = string.lower(tostring(b.display_name or b.id or b.path))
        if aa == bb then return tostring(a.id or a.path) < tostring(b.id or b.path) end
        return aa < bb
    end)
    return catalog
end


function catalog_api.status_entries()
    return load_status_entries()
end

function catalog_api.reserved_effects()
    return RESERVED_EFFECTS
end

METAMORPH_CREATIVE_MENU_EFFECT_CATALOG = catalog_api
return catalog_api
