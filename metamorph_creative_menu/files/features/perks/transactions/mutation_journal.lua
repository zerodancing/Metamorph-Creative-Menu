local mutation_journal = {}
local pending_cleanup = dofile("mods/metamorph_creative_menu/files/features/perks/transactions/pending_cleanup.lua")

local unpack_values = unpack or table.unpack
local next_transaction_id = 0
local property_owners = {}

local function pack_values(...)
    return { n = select("#", ...), ... }
end

local function copy_pack(values)
    if type(values) ~= "table" then return { n = 0 } end
    local copy = { n = tonumber(values.n) or #values }
    for index = 1, copy.n do copy[index] = values[index] end
    return copy
end

local function scalar_equal(left, right)
    if type(left) == "number" and type(right) == "number" then
        return math.abs(left - right) < 0.0000001
    end
    return left == right or tostring(left) == tostring(right)
end

local function packs_equal(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then return false end
    local left_count = tonumber(left.n) or #left
    local right_count = tonumber(right.n) or #right
    if left_count ~= right_count then return false end
    for index = 1, left_count do
        if not scalar_equal(left[index], right[index]) then return false end
    end
    return true
end

local function safe_pack_call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local result = pack_values(pcall(fn, ...))
    if result[1] ~= true then return nil end
    local values = { n = result.n - 1 }
    for index = 2, result.n do values[index - 1] = result[index] end
    return values
end

local function property_key(kind, ...)
    local parts = { kind }
    for index = 1, select("#", ...) do parts[#parts + 1] = tostring(select(index, ...)) end
    return table.concat(parts, "\31")
end

local function note_property(token, record)
    if type(token) ~= "table" or type(record) ~= "table" or type(record.key) ~= "string" then return end
    token.mutation_properties = token.mutation_properties or {}
    local existing = token.mutation_properties[record.key]
    if existing == nil then
        token.mutation_properties[record.key] = record
    else
        existing.after = copy_pack(record.after)
    end
end

local function note_created_entity(token, entity_id)
    entity_id = tonumber(entity_id) or entity_id
    if type(token) ~= "table" or entity_id == nil or entity_id == 0 then return end
    token.created_entities = token.created_entities or {}
    token.created_entities[entity_id] = true
end

local function note_created_component(token, entity_id, component_id)
    component_id = tonumber(component_id) or component_id
    if type(token) ~= "table" or component_id == nil or component_id == 0 then return end
    token.created_components = token.created_components or {}
    token.created_components[component_id] = tonumber(entity_id) or entity_id
end

local function record_set(token, descriptor, reader, writer)
    local before = reader()
    local result = pack_values(writer())
    local after = reader()
    if before ~= nil and after ~= nil and not packs_equal(before, after) then
        descriptor.before = copy_pack(before)
        descriptor.after = copy_pack(after)
        note_property(token, descriptor)
    end
    return unpack_values(result, 1, result.n)
end

local function component_alive(component_id)
    if component_id == nil or component_id == 0 or type(ComponentGetTypeName) ~= "function" then return false end
    local ok, component_type = pcall(ComponentGetTypeName, component_id)
    return ok and type(component_type) == "string" and component_type ~= ""
end

local function entity_alive(entity_id)
    if entity_id == nil or entity_id == 0 or type(EntityGetIsAlive) ~= "function" then return false end
    local ok, alive = pcall(EntityGetIsAlive, entity_id)
    return ok and alive == true
end

local function current_value(record)
    if record.kind == "component_value2" then
        return safe_pack_call(ComponentGetValue2, record.component, record.field)
    elseif record.kind == "component_value" then
        return safe_pack_call(ComponentGetValue, record.component, record.field)
    elseif record.kind == "meta_custom" then
        return safe_pack_call(ComponentGetMetaCustom, record.component, record.field)
    elseif record.kind == "object_value2" then
        return safe_pack_call(ComponentObjectGetValue2, record.component, record.object, record.field)
    elseif record.kind == "object_value" then
        return safe_pack_call(ComponentObjectGetValue, record.component, record.object, record.field)
    elseif record.kind == "component_enabled" then
        return safe_pack_call(ComponentGetIsEnabled, record.component)
    elseif record.kind == "entity_parent" then
        return safe_pack_call(EntityGetParent, record.entity)
    elseif record.kind == "entity_tag" then
        return safe_pack_call(EntityHasTag, record.entity, record.tag)
    elseif record.kind == "component_tag" then
        return safe_pack_call(ComponentHasTag, record.component, record.tag)
    end
    return nil
end

local function restore_value(record, values)
    if type(values) ~= "table" then return false end
    if record.kind ~= "component_enabled" and record.kind ~= "entity_parent" and record.kind ~= "entity_tag"
        and not component_alive(record.component) then return false end
    local count = tonumber(values.n) or #values
    local wrote = false
    if record.kind == "component_value2" and type(ComponentSetValue2) == "function" then
        wrote = pcall(ComponentSetValue2, record.component, record.field, unpack_values(values, 1, count))
    elseif record.kind == "component_value" and type(ComponentSetValue) == "function" then
        wrote = pcall(ComponentSetValue, record.component, record.field, unpack_values(values, 1, count))
    elseif record.kind == "meta_custom" and type(ComponentSetMetaCustom) == "function" then
        wrote = pcall(ComponentSetMetaCustom, record.component, record.field, unpack_values(values, 1, count))
    elseif record.kind == "object_value2" and type(ComponentObjectSetValue2) == "function" then
        wrote = pcall(ComponentObjectSetValue2, record.component, record.object, record.field, unpack_values(values, 1, count))
    elseif record.kind == "object_value" and type(ComponentObjectSetValue) == "function" then
        wrote = pcall(ComponentObjectSetValue, record.component, record.object, record.field, unpack_values(values, 1, count))
    elseif record.kind == "component_enabled" and type(EntitySetComponentIsEnabled) == "function"
        and entity_alive(record.entity) and component_alive(record.component)
    then
        wrote = pcall(EntitySetComponentIsEnabled, record.entity, record.component, values[1] == true)
    elseif record.kind == "entity_parent" and entity_alive(record.entity) then
        local wanted_parent = tonumber(values[1]) or 0
        if wanted_parent == 0 and type(EntityRemoveFromParent) == "function" then
            wrote = pcall(EntityRemoveFromParent, record.entity)
        elseif wanted_parent ~= 0 and entity_alive(wanted_parent) and type(EntityAddChild) == "function" then
            wrote = pcall(EntityAddChild, wanted_parent, record.entity)
        end
    elseif record.kind == "entity_tag" and entity_alive(record.entity) then
        local wanted = values[1] == true
        if wanted and type(EntityAddTag) == "function" then wrote = pcall(EntityAddTag, record.entity, record.tag)
        elseif not wanted and type(EntityRemoveTag) == "function" then wrote = pcall(EntityRemoveTag, record.entity, record.tag) end
    elseif record.kind == "component_tag" and component_alive(record.component) then
        local wanted = values[1] == true
        if wanted and type(ComponentAddTag) == "function" then wrote = pcall(ComponentAddTag, record.component, record.tag)
        elseif not wanted and type(ComponentRemoveTag) == "function" then wrote = pcall(ComponentRemoveTag, record.component, record.tag) end
    end
    if not wrote then return false end
    local after = current_value(record)
    return after ~= nil and packs_equal(after, values)
end

local function target_gone(record)
    if record.kind == "entity_parent" or record.kind == "entity_tag" then return not entity_alive(record.entity) end
    if record.kind == "component_enabled" then return not entity_alive(record.entity) or not component_alive(record.component) end
    return not component_alive(record.component)
end

local function register_property(delta, record)
    local ownership = property_owners[record.key]
    if ownership == nil then
        ownership = { baseline = copy_pack(record.before), layers = {} }
        property_owners[record.key] = ownership
    end
    ownership.layers[#ownership.layers + 1] = {
        transaction_id = delta.transaction_id,
        after = copy_pack(record.after),
    }
end

local function unregister_property(delta, record)
    local ownership = property_owners[record.key]
    if ownership == nil then
        local current = current_value(record)
        if current == nil then return target_gone(record) end
        if packs_equal(current, record.after) then return restore_value(record, record.before) end
        return true
    end

    local removed_index = nil
    for index = #ownership.layers, 1, -1 do
        if ownership.layers[index].transaction_id == delta.transaction_id then
            removed_index = index
            break
        end
    end
    if removed_index == nil then return true end

    local current = current_value(record)
    if current == nil and not target_gone(record) then return false end
    local is_newest = removed_index == #ownership.layers
    if is_newest and current ~= nil and packs_equal(current, record.after) then
        local target = (#ownership.layers == 1) and ownership.baseline or ownership.layers[#ownership.layers - 1].after
        -- Ownership is not removed until the setter and readback both confirm the
        -- rollback. A failed scalar restore therefore keeps the transaction retryable.
        if not restore_value(record, target) then return false end
    end

    table.remove(ownership.layers, removed_index)
    if #ownership.layers == 0 then property_owners[record.key] = nil end
    return true
end

function mutation_journal.prepare(token)
    if type(token) ~= "table" then return false end
    if token.transaction_id == nil then
        next_transaction_id = next_transaction_id + 1
        token.transaction_id = next_transaction_id
    end
    return true
end

function mutation_journal.start_capture(token, environment)
    if type(token) ~= "table" or token.mutation_capture_active then return false end
    mutation_journal.prepare(token)
    local env = type(environment) == "table" and environment or _G
    local old = {}
    token.mutation_env = env
    token.mutation_old = old
    token.mutation_capture_active = true

    local function wrap_setter(name, getter_name, kind, key_builder, args_builder)
        local original_setter = env[name]
        local original_getter = env[getter_name]
        if type(original_setter) ~= "function" or type(original_getter) ~= "function" then return end
        old[name] = original_setter
        env[name] = function(...)
            local arguments = pack_values(...)
            local descriptor = args_builder(arguments)
            descriptor.kind = kind
            descriptor.key = key_builder(arguments)
            local function reader()
                if kind == "component_value2" or kind == "component_value" or kind == "meta_custom" then
                    return safe_pack_call(original_getter, arguments[1], arguments[2])
                end
                return safe_pack_call(original_getter, arguments[1], arguments[2], arguments[3])
            end
            return record_set(token, descriptor, reader, function()
                return original_setter(unpack_values(arguments, 1, arguments.n))
            end)
        end
    end

    wrap_setter("ComponentSetValue2", "ComponentGetValue2", "component_value2",
        function(a) return property_key("component", a[1], a[2]) end,
        function(a) return { component=a[1], field=a[2] } end)
    wrap_setter("ComponentSetValue", "ComponentGetValue", "component_value",
        function(a) return property_key("component", a[1], a[2]) end,
        function(a) return { component=a[1], field=a[2] } end)
    wrap_setter("ComponentSetMetaCustom", "ComponentGetMetaCustom", "meta_custom",
        function(a) return property_key("meta", a[1], a[2]) end,
        function(a) return { component=a[1], field=a[2] } end)
    wrap_setter("ComponentObjectSetValue2", "ComponentObjectGetValue2", "object_value2",
        function(a) return property_key("object", a[1], a[2], a[3]) end,
        function(a) return { component=a[1], object=a[2], field=a[3] } end)
    wrap_setter("ComponentObjectSetValue", "ComponentObjectGetValue", "object_value",
        function(a) return property_key("object", a[1], a[2], a[3]) end,
        function(a) return { component=a[1], object=a[2], field=a[3] } end)

    if type(env.EntitySetComponentIsEnabled) == "function" and type(env.ComponentGetIsEnabled) == "function" then
        local original_set_enabled = env.EntitySetComponentIsEnabled
        local original_get_enabled = env.ComponentGetIsEnabled
        old.EntitySetComponentIsEnabled = original_set_enabled
        env.EntitySetComponentIsEnabled = function(entity_id, component_id, enabled)
            local descriptor = {
                kind="component_enabled", entity=entity_id, component=component_id,
                key=property_key("enabled", component_id),
            }
            return record_set(token, descriptor,
                function() return safe_pack_call(original_get_enabled, component_id) end,
                function() return original_set_enabled(entity_id, component_id, enabled) end)
        end
    end

    if type(env.EntitySetComponentsWithTagEnabled) == "function" and type(env.EntityGetAllComponents) == "function"
        and type(env.ComponentHasTag) == "function" and type(env.ComponentGetIsEnabled) == "function"
    then
        local original_set_tag = env.EntitySetComponentsWithTagEnabled
        old.EntitySetComponentsWithTagEnabled = original_set_tag
        env.EntitySetComponentsWithTagEnabled = function(entity_id, component_tag, enabled)
            local tracked = {}
            for _, component_id in ipairs(env.EntityGetAllComponents(entity_id) or {}) do
                local tag_ok, has_tag = pcall(env.ComponentHasTag, component_id, component_tag)
                if tag_ok and has_tag == true then
                    tracked[#tracked + 1] = {
                        kind="component_enabled", entity=entity_id, component=component_id,
                        key=property_key("enabled", component_id),
                        before=safe_pack_call(env.ComponentGetIsEnabled, component_id),
                    }
                end
            end
            local results = pack_values(original_set_tag(entity_id, component_tag, enabled))
            for _, record in ipairs(tracked) do
                record.after = safe_pack_call(env.ComponentGetIsEnabled, record.component)
                if record.before ~= nil and record.after ~= nil and not packs_equal(record.before, record.after) then
                    note_property(token, record)
                end
            end
            return unpack_values(results, 1, results.n)
        end
    end

    local function wrap_tag_mutation(add_name, remove_name, has_name, kind, target_kind)
        local original_add = env[add_name]
        local original_remove = env[remove_name]
        local original_has = env[has_name]
        if type(original_add) ~= "function" or type(original_remove) ~= "function" or type(original_has) ~= "function" then return end
        old[add_name] = original_add
        old[remove_name] = original_remove
        local function call(original, target_id, tag)
            local descriptor = { kind=kind, tag=tag }
            if target_kind == "entity" then
                descriptor.entity = target_id
                descriptor.key = property_key("entity_tag", target_id, tag)
            else
                descriptor.component = target_id
                descriptor.key = property_key("component_tag", target_id, tag)
            end
            return record_set(token, descriptor,
                function() return safe_pack_call(original_has, target_id, tag) end,
                function() return original(target_id, tag) end)
        end
        env[add_name] = function(target_id, tag) return call(original_add, target_id, tag) end
        env[remove_name] = function(target_id, tag) return call(original_remove, target_id, tag) end
    end

    wrap_tag_mutation("EntityAddTag", "EntityRemoveTag", "EntityHasTag", "entity_tag", "entity")
    wrap_tag_mutation("ComponentAddTag", "ComponentRemoveTag", "ComponentHasTag", "component_tag", "component")

    for _, function_name in ipairs({"EntityLoad", "EntityLoadCameraBound", "EntityCreateNew"}) do
        if type(env[function_name]) == "function" then
            local original = env[function_name]
            old[function_name] = original
            env[function_name] = function(...)
                local results = pack_values(original(...))
                note_created_entity(token, results[1])
                return unpack_values(results, 1, results.n)
            end
        end
    end

    for _, function_name in ipairs({"EntityAddComponent", "EntityAddComponent2"}) do
        if type(env[function_name]) == "function" then
            local original = env[function_name]
            old[function_name] = original
            env[function_name] = function(entity_id, ...)
                local results = pack_values(original(entity_id, ...))
                note_created_component(token, entity_id, results[1])
                return unpack_values(results, 1, results.n)
            end
        end
    end

    -- Reparenting an existing entity is a mutation too. Without this, a perk that
    -- attaches a pre-existing entity to the player can only be seen as an "added child"
    -- and removal would destroy it instead of restoring its original parent.
    if type(env.EntityAddChild) == "function" and type(env.EntityGetParent) == "function" then
        local original_add_child = env.EntityAddChild
        local original_get_parent = env.EntityGetParent
        old.EntityAddChild = original_add_child
        env.EntityAddChild = function(parent_entity_id, child_entity_id)
            if token.created_entities and token.created_entities[child_entity_id] then
                return original_add_child(parent_entity_id, child_entity_id)
            end
            local descriptor = {
                kind="entity_parent", entity=child_entity_id,
                key=property_key("parent", child_entity_id),
            }
            return record_set(token, descriptor,
                function() return safe_pack_call(original_get_parent, child_entity_id) end,
                function() return original_add_child(parent_entity_id, child_entity_id) end)
        end
    end

    if type(env.EntityRemoveFromParent) == "function" and type(env.EntityGetParent) == "function" then
        local original_remove_parent = env.EntityRemoveFromParent
        local original_get_parent = env.EntityGetParent
        old.EntityRemoveFromParent = original_remove_parent
        env.EntityRemoveFromParent = function(child_entity_id)
            if token.created_entities and token.created_entities[child_entity_id] then
                return original_remove_parent(child_entity_id)
            end
            local descriptor = {
                kind="entity_parent", entity=child_entity_id,
                key=property_key("parent", child_entity_id),
            }
            return record_set(token, descriptor,
                function() return safe_pack_call(original_get_parent, child_entity_id) end,
                function() return original_remove_parent(child_entity_id) end)
        end
    end

    return true
end

function mutation_journal.stop_capture(token)
    if type(token) ~= "table" or not token.mutation_capture_active then return end
    local env = token.mutation_env
    for name, original in pairs(token.mutation_old or {}) do
        if type(env) == "table" then env[name] = original end
    end
    token.mutation_capture_active = false
end

function mutation_journal.attach_delta(delta, token)
    if type(delta) ~= "table" or type(token) ~= "table" then return end
    mutation_journal.prepare(token)
    delta.transaction_id = token.transaction_id
    delta.mutations = {}
    local keys = {}
    for key in pairs(token.mutation_properties or {}) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local record = token.mutation_properties[key]
        if record.before ~= nil and record.after ~= nil and not packs_equal(record.before, record.after) then
            local copy = {}
            for record_key, value in pairs(record) do
                if record_key == "before" or record_key == "after" then copy[record_key] = copy_pack(value)
                else copy[record_key] = value end
            end
            delta.mutations[#delta.mutations + 1] = copy
            register_property(delta, copy)
        end
    end
    delta.created_entities = {}
    for entity_id in pairs(token.created_entities or {}) do delta.created_entities[#delta.created_entities + 1] = entity_id end
    table.sort(delta.created_entities, function(a, b) return tostring(a) < tostring(b) end)
    delta.created_components = {}
    for component_id, entity_id in pairs(token.created_components or {}) do
        delta.created_components[#delta.created_components + 1] = {entity=entity_id, component=component_id}
    end
end

-- Exact objects created by a pickup are hard ownership, unlike scalar fields where a
-- later game/mod write can legitimately supersede our value.  Clean and verify these
-- objects *before* changing any reversible scalar state so a failed EntityKill cannot
-- make the transaction report success and then forget the residue.
function mutation_journal.cleanup_owned_objects(delta)
    if type(delta) ~= "table" then return true, "no_delta" end

    -- EntityKill/EntityRemoveComponent are allowed to complete at the engine's end-of-frame
    -- boundary. Queue exact owned ids for verification instead of interpreting same-frame
    -- liveness as a failed rollback that requires another click.
    for index = #(delta.created_entities or {}), 1, -1 do
        local entity_id = delta.created_entities[index]
        if entity_alive(entity_id) then
            local ok, reason = pending_cleanup.retire_entity(entity_id, "mutation:" .. tostring(delta.transaction_id or ""))
            if not ok then return false, reason end
        end
    end

    for index = #(delta.created_components or {}), 1, -1 do
        local entry = delta.created_components[index]
        if type(entry) == "table" and entity_alive(entry.entity) and component_alive(entry.component) then
            local ok, reason = pending_cleanup.retire_component(entry.entity, entry.component,
                "mutation:" .. tostring(delta.transaction_id or ""))
            if not ok then return false, reason end
        end
    end

    return true, "owned_objects_retired"
end

function mutation_journal.revert_properties(delta)
    if type(delta) ~= "table" then return true, "no_delta" end
    for mutation_index = #(delta.mutations or {}), 1, -1 do
        if not unregister_property(delta, delta.mutations[mutation_index]) then
            return false, "property_restore:" .. tostring(delta.mutations[mutation_index].key or mutation_index)
        end
    end
    return true, "properties_restored"
end

function mutation_journal.revert_delta(delta)
    local objects_ok, objects_reason = mutation_journal.cleanup_owned_objects(delta)
    if not objects_ok then return false, objects_reason end
    local properties_ok, properties_reason = mutation_journal.revert_properties(delta)
    if not properties_ok then return false, properties_reason end
    return true, "reverted"
end

function mutation_journal.discard_delta(delta)
    if type(delta) ~= "table" then return end
    for _, record in ipairs(delta.mutations or {}) do
        local ownership = property_owners[record.key]
        if ownership ~= nil then
            for index = #ownership.layers, 1, -1 do
                if ownership.layers[index].transaction_id == delta.transaction_id then
                    table.remove(ownership.layers, index)
                    break
                end
            end
            if #ownership.layers == 0 then property_owners[record.key] = nil end
        end
    end
end


local function rebound_record_key(record)
    if record.kind == "component_value2" or record.kind == "component_value" then
        return property_key("component", record.component, record.field)
    elseif record.kind == "meta_custom" then
        return property_key("meta", record.component, record.field)
    elseif record.kind == "object_value2" or record.kind == "object_value" then
        return property_key("object", record.component, record.object, record.field)
    elseif record.kind == "component_enabled" then
        return property_key("enabled", record.component)
    elseif record.kind == "entity_parent" then
        return property_key("parent", record.entity)
    elseif record.kind == "entity_tag" then
        return property_key("entity_tag", record.entity, record.tag)
    elseif record.kind == "component_tag" then
        return property_key("component_tag", record.component, record.tag)
    end
    return record.key
end

-- Player polymorph/serialization replaces entity and component ids while preserving the
-- semantic player tree. transactions.lua resolves its stored locators and passes the id
-- map here so mutation ownership survives that replacement instead of becoming stale.
function mutation_journal.rebind_delta(delta, entity_map, component_map)
    if type(delta) ~= "table" then return end
    entity_map = type(entity_map) == "table" and entity_map or {}
    component_map = type(component_map) == "table" and component_map or {}
    for _, record in ipairs(delta.mutations or {}) do
        if record.entity ~= nil and entity_map[record.entity] ~= nil then record.entity = entity_map[record.entity] end
        if record.component ~= nil and component_map[record.component] ~= nil then record.component = component_map[record.component] end
        record.key = rebound_record_key(record)
    end
    for index, entity_id in ipairs(delta.created_entities or {}) do
        if entity_map[entity_id] ~= nil then delta.created_entities[index] = entity_map[entity_id] end
    end
    for _, entry in ipairs(delta.created_components or {}) do
        if entry.entity ~= nil and entity_map[entry.entity] ~= nil then entry.entity = entity_map[entry.entity] end
        if entry.component ~= nil and component_map[entry.component] ~= nil then entry.component = component_map[entry.component] end
    end
end

function mutation_journal.rebuild_ownership(deltas)
    property_owners = {}
    table.sort(deltas, function(a, b)
        return (tonumber(a and a.transaction_id) or 0) < (tonumber(b and b.transaction_id) or 0)
    end)
    for _, delta in ipairs(deltas or {}) do
        if type(delta) == "table" then
            for _, record in ipairs(delta.mutations or {}) do register_property(delta, record) end
        end
    end
end

function mutation_journal.active_property_count()
    local count = 0
    for _ in pairs(property_owners) do count = count + 1 end
    return count
end

return mutation_journal
