local external_polymorph = {}

local human_restore = dofile("mods/metamorph_creative_menu/files/features/forms/human_restore.lua")

local RANDOM_TARGETS = {
    ["[RANDOM]"] = true,
    ["[RANDOM_SUPER]"] = true,
}

local function alive(entity)
    return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity)
end

local function component_target(components)
    for _, component in ipairs(components or {}) do
        local ok, target = pcall(ComponentGetValue2, component, "polymorph_target")
        target = ok and tostring(target or "") or ""
        if target ~= "" and not RANDOM_TARGETS[target] then return target end
    end
    return ""
end

local function entity_target(entity, components)
    if type(EntityGetFilename) == "function" then
        local ok, path = pcall(EntityGetFilename, entity)
        path = ok and tostring(path or "") or ""
        -- For random/unstable polymorph the GameEffect keeps a generic target marker;
        -- the live body filename is the only exact creature identity and therefore the
        -- correct input for MCM's attack/profile replay.
        if path ~= "" then return path end
    end
    return component_target(components)
end

-- Describe only a real local polymorph body. Ownership/local-player selection remains
-- the caller's job (form_manager uses player_locator); this module deliberately knows
-- nothing about EW, menu state, input, or the form session lifecycle.
function external_polymorph.describe(entity)
    if not alive(entity) or not EntityHasTag(entity, "polymorphed_player") then return nil end

    local components = human_restore.polymorph_effect_components(entity)
    if #components == 0 then return nil end

    local target = entity_target(entity, components)
    if target == "" then return nil end

    local backup = human_restore.serialized_backup_from_effects(components)
    return {
        entity = entity,
        target = target,
        requested_target = target,
        components = components,
        original_backup = backup,
        allow_death_handoff = type(backup) == "string" and backup ~= "",
    }
end

function external_polymorph.is_active(entity)
    return external_polymorph.describe(entity) ~= nil
end

return external_polymorph
