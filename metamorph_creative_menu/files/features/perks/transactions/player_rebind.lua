local player_rebind = {}

local function alive(entity_id)
    if entity_id == nil or entity_id == 0 or type(EntityGetIsAlive) ~= "function" then return false end
    local ok, value = pcall(EntityGetIsAlive, entity_id)
    return ok and value == true
end

local function safe_string_call(fn, ...)
    if type(fn) ~= "function" then return "" end
    local ok, value = pcall(fn, ...)
    return ok and tostring(value or "") or ""
end

local function entity_signature(entity_id)
    return safe_string_call(EntityGetFilename, entity_id) .. "\31" .. safe_string_call(EntityGetName, entity_id)
end

local function copy_path(path)
    local result = {}
    for index, segment in ipairs(path or {}) do
        result[index] = {
            index = segment.index,
            signature = segment.signature,
            ordinal = segment.ordinal,
        }
    end
    return result
end

local function all_components(entity_id)
    if type(EntityGetAllComponents) ~= "function" then return {} end
    local ok, values = pcall(EntityGetAllComponents, entity_id)
    return ok and type(values) == "table" and values or {}
end

local function all_children(entity_id)
    if type(EntityGetAllChildren) ~= "function" then return {} end
    local ok, values = pcall(EntityGetAllChildren, entity_id)
    return ok and type(values) == "table" and values or {}
end

-- Capture semantic locations only for the *current* player subtree. Detached world
-- entities intentionally keep their original ids because form serialization does not
-- recreate them. The path uses filename/name + same-signature ordinal, with child index
-- as a fallback for anonymous children.
function player_rebind.capture(player_entity_id)
    if not alive(player_entity_id) then return nil end
    local capture = { player=player_entity_id, entities={}, components={} }
    local queue = { {entity=player_entity_id, path={}} }
    local cursor = 1
    while cursor <= #queue do
        local current = queue[cursor]
        cursor = cursor + 1
        local entity_id = current.entity
        if alive(entity_id) and capture.entities[entity_id] == nil then
            capture.entities[entity_id] = copy_path(current.path)

            local component_ordinals = {}
            for _, component_id in ipairs(all_components(entity_id)) do
                local component_type = safe_string_call(ComponentGetTypeName, component_id)
                component_ordinals[component_type] = (component_ordinals[component_type] or 0) + 1
                capture.components[component_id] = {
                    entity=entity_id,
                    component_type=component_type,
                    ordinal=component_ordinals[component_type],
                }
            end

            local signature_ordinals = {}
            for child_index, child_entity_id in ipairs(all_children(entity_id)) do
                if alive(child_entity_id) then
                    local signature = entity_signature(child_entity_id)
                    signature_ordinals[signature] = (signature_ordinals[signature] or 0) + 1
                    local child_path = copy_path(current.path)
                    child_path[#child_path + 1] = {
                        index=child_index,
                        signature=signature,
                        ordinal=signature_ordinals[signature],
                    }
                    queue[#queue + 1] = {entity=child_entity_id, path=child_path}
                end
            end
        end
    end
    return capture
end

local function signature_matches(entity_id, signature)
    return entity_signature(entity_id) == tostring(signature or "")
end

local function resolve_entity_path(new_player_entity_id, path)
    local current = new_player_entity_id
    for _, segment in ipairs(path or {}) do
        if not alive(current) then return nil end
        local children = all_children(current)
        local selected = nil
        local wanted_signature = tostring(segment.signature or "")
        local wanted_ordinal = tonumber(segment.ordinal) or 1
        if wanted_signature ~= "\31" then
            local seen = 0
            for _, child_entity_id in ipairs(children) do
                if alive(child_entity_id) and signature_matches(child_entity_id, wanted_signature) then
                    seen = seen + 1
                    if seen == wanted_ordinal then selected = child_entity_id; break end
                end
            end
        end
        if selected == nil then
            local indexed = children[tonumber(segment.index) or -1]
            if alive(indexed) and (wanted_signature == "\31" or signature_matches(indexed, wanted_signature)) then
                selected = indexed
            end
        end
        if selected == nil then return nil end
        current = selected
    end
    return alive(current) and current or nil
end

function player_rebind.resolve(capture, new_player_entity_id)
    if type(capture) ~= "table" or not alive(new_player_entity_id) then return nil, nil, "invalid" end
    local entity_map = {}
    for old_entity_id, path in pairs(capture.entities or {}) do
        local new_entity_id = resolve_entity_path(new_player_entity_id, path)
        if new_entity_id ~= nil then entity_map[old_entity_id] = new_entity_id end
    end
    entity_map[capture.player] = new_player_entity_id

    local component_map = {}
    for old_component_id, locator in pairs(capture.components or {}) do
        local new_entity_id = entity_map[locator.entity]
        if new_entity_id ~= nil then
            local seen = 0
            for _, component_id in ipairs(all_components(new_entity_id)) do
                if safe_string_call(ComponentGetTypeName, component_id) == tostring(locator.component_type or "") then
                    seen = seen + 1
                    if seen == (tonumber(locator.ordinal) or 1) then
                        component_map[old_component_id] = component_id
                        break
                    end
                end
            end
        end
    end
    return entity_map, component_map, "ok"
end

local function remap_id(value, map)
    return map[value] or value
end

local function remap_keyed_table(source, key_map, value_rewriter)
    if type(source) ~= "table" then return source end
    local result = {}
    for old_key, value in pairs(source) do
        local new_key = key_map[old_key] or old_key
        result[new_key] = value_rewriter and value_rewriter(value, old_key, new_key) or value
    end
    return result
end

-- Rewrite every structural reference owned by transactions.lua. This deliberately does
-- not recursively rewrite arbitrary numbers: perk state contains numeric values that can
-- coincidentally equal entity ids. Only fields whose semantics are ids are changed.
function player_rebind.remap_delta(delta, entity_map, component_map, new_player_entity_id)
    if type(delta) ~= "table" then return end
    entity_map = type(entity_map) == "table" and entity_map or {}
    component_map = type(component_map) == "table" and component_map or {}
    delta.player = new_player_entity_id or remap_id(delta.player, entity_map)

    for index, entity_id in ipairs(delta.added_entities or {}) do
        delta.added_entities[index] = remap_id(entity_id, entity_map)
    end
    for _, entry in ipairs(delta.added_components or {}) do
        entry.entity = remap_id(entry.entity, entity_map)
        entry.component = remap_id(entry.component, component_map)
    end
    for _, entry in ipairs(delta.fields or {}) do
        entry.entity = remap_id(entry.entity, entity_map)
        entry.component = remap_id(entry.component, component_map)
    end
    for _, entry in ipairs(delta.enabled or {}) do
        entry.entity = remap_id(entry.entity, entity_map)
        entry.component = remap_id(entry.component, component_map)
    end
    for _, entry in ipairs(delta.reparents or {}) do
        entry.entity = remap_id(entry.entity, entity_map)
        entry.before_parent = remap_id(entry.before_parent, entity_map)
        entry.after_parent = remap_id(entry.after_parent, entity_map)
    end

    if delta.kind == "extra_mana" then
        delta.wand = remap_id(delta.wand, entity_map)
        delta.ability = remap_id(delta.ability, component_map)
        if type(delta.before) == "table" then
            delta.before.wand = remap_id(delta.before.wand, entity_map)
            delta.before.ability = remap_id(delta.before.ability, component_map)
            delta.before.actions = remap_keyed_table(delta.before.actions, entity_map, function(state)
                if type(state) == "table" then
                    state.parent = remap_id(state.parent, entity_map)
                    state.enabled = remap_keyed_table(state.enabled, component_map)
                end
                return state
            end)
        end
        delta.actions = remap_keyed_table(delta.actions, entity_map, function(state)
            if type(state) == "table" then
                state.after_parent = remap_id(state.after_parent, entity_map)
                if type(state.before) == "table" then
                    state.before.parent = remap_id(state.before.parent, entity_map)
                    state.before.enabled = remap_keyed_table(state.before.enabled, component_map)
                end
            end
            return state
        end)
    elseif delta.kind == "no_more_shuffle" then
        for _, entry in ipairs(delta.changes or {}) do
            entry.wand = remap_id(entry.wand, entity_map)
            entry.ability = remap_id(entry.ability, component_map)
        end
    end

    if type(delta.extra_mana) == "table" then
        delta.extra_mana.wand = remap_id(delta.extra_mana.wand, entity_map)
        delta.extra_mana.ability = remap_id(delta.extra_mana.ability, component_map)
    end
    for _, entry in ipairs(delta.no_more_shuffle or {}) do
        entry.wand = remap_id(entry.wand, entity_map)
        entry.ability = remap_id(entry.ability, component_map)
    end
end

return player_rebind
