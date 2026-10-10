-- Structural before/after journal for perk transactions.
-- This module owns generic entity-tree/component snapshots only; exact setter calls
-- live in mutation_journal.lua and global/run-flag ownership lives in global_journal.lua.
local structural_snapshot = {}
local pending_cleanup = dofile("mods/metamorph_creative_menu/files/features/perks/transactions/pending_cleanup.lua")

local function valid_entity(entity)
    return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity)
end

local function parent_of(entity)
    if not valid_entity(entity) then return 0 end
    local ok, parent = pcall(EntityGetParent, entity)
    return ok and tonumber(parent) or 0
end

local function component_snapshot(entity, comp)
    local members = {}
    local ok, values = pcall(ComponentGetMembers, comp)
    if ok and type(values) == "table" then
        for name in pairs(values) do
            local ok_value, value = pcall(ComponentGetValue, comp, name)
            if ok_value and value ~= nil then members[name] = tostring(value) end
        end
    end
    local enabled = false
    local ok_enabled, value_enabled = pcall(ComponentGetIsEnabled, comp)
    if ok_enabled then enabled = value_enabled == true end
    return {
        id = comp,
        entity = entity,
        type = tostring(ComponentGetTypeName(comp) or ""),
        enabled = enabled,
        members = members,
    }
end

local function capture_entity_tree(root, result)
    local queue, index, seen = { root }, 1, {}
    while index <= #queue do
        local entity = queue[index]; index = index + 1
        if valid_entity(entity) and not seen[entity] then
            seen[entity] = true
            result.entities[entity] = { parent=parent_of(entity) }
            for _, comp in ipairs(EntityGetAllComponents(entity) or {}) do
                result.components[comp] = component_snapshot(entity, comp)
            end
            for _, child in ipairs(EntityGetAllChildren(entity) or {}) do queue[#queue + 1] = child end
        end
    end
end

local function snapshot(player, prior)
    local result = { entities = {}, components = {} }
    if valid_entity(player) then capture_entity_tree(player, result) end

    -- Some vanilla perks intentionally eject an existing inventory entity into the
    -- world (EXTRA_MANA drops spells that no longer fit). Such an entity is not deleted:
    -- it is a detached root. Capture that live root as part of the "after" state so the
    -- transaction can restore its fields/enabled flags and reparent it instead of
    -- declaring the whole perk irreversible. Never follow an entity that has been
    -- reparented under somebody else.
    if type(prior) == "table" and type(prior.entities) == "table" then
        local roots = {}
        for entity in pairs(prior.entities) do
            if result.entities[entity] == nil and valid_entity(entity) and parent_of(entity) == 0 then
                local ok_root, root = pcall(EntityGetRootEntity, entity)
                if not ok_root or root == nil or root == 0 or root == entity then roots[#roots + 1] = entity end
            end
        end
        for _, root in ipairs(roots) do
            if result.entities[root] == nil then capture_entity_tree(root, result) end
        end
    end

    local world = GameGetWorldStateEntity()
    if valid_entity(world) then
        local comp = EntityGetFirstComponentIncludingDisabled(world, "WorldStateComponent")
        if comp ~= nil and comp ~= 0 then result.components[comp] = component_snapshot(world, comp) end
    end
    return result
end

local function build_delta(before, after)
    local delta = {
        added_entities={}, added_components={}, fields={}, enabled={}, reparents={},
        reversible=true, reason="ok",
    }
    for entity in pairs(after.entities) do
        if before.entities[entity] == nil then delta.added_entities[#delta.added_entities + 1] = entity end
    end
    for entity, before_entity in pairs(before.entities) do
        local after_entity = after.entities[entity]
        if after_entity == nil then
            delta.reversible=false; delta.reason="removed_entity"
        elseif tonumber(before_entity.parent) ~= tonumber(after_entity.parent) then
            local before_parent = tonumber(before_entity.parent) or 0
            local after_parent = tonumber(after_entity.parent) or 0
            -- Detaching into the world is reversible while the same entity stays
            -- unowned. Moving an existing child *within the same player subtree* is also
            -- safe to own: both parents are part of the transaction snapshot and the
            -- preflight below refuses to steal the child if anything reclaims it later.
            local detached_to_world = after_parent == 0 and before_parent ~= 0
            local moved_inside_player_tree = before_parent ~= 0 and after_parent ~= 0
                and before.entities[before_parent] ~= nil and after.entities[after_parent] ~= nil
            if detached_to_world or moved_inside_player_tree then
                delta.reparents[#delta.reparents + 1] = {
                    entity=entity, before_parent=before_parent, after_parent=after_parent,
                }
            else
                delta.reversible=false; delta.reason="reparented_entity"
            end
        end
    end
    for comp, after_comp in pairs(after.components) do
        local before_comp = before.components[comp]
        if before_comp == nil then
            delta.added_components[#delta.added_components + 1] = {entity=after_comp.entity, component=comp}
        elseif before_comp.entity == after_comp.entity and before_comp.type == after_comp.type then
            if before_comp.enabled ~= after_comp.enabled then
                delta.enabled[#delta.enabled + 1] = {
                    entity=after_comp.entity, component=comp,
                    before=before_comp.enabled, after=after_comp.enabled,
                }
            end
            local names = {}
            for name in pairs(before_comp.members) do names[name] = true end
            for name in pairs(after_comp.members) do names[name] = true end
            for name in pairs(names) do
                local b, a = before_comp.members[name], after_comp.members[name]
                if b ~= a then
                    delta.fields[#delta.fields + 1] = {
                        component=comp, entity=after_comp.entity, field=name, before=b, after=a,
                    }
                end
            end
        end
    end
    for comp in pairs(before.components) do
        if after.components[comp] == nil then delta.reversible=false; delta.reason="removed_component" end
    end
    return delta
end

local function component_alive(comp)
    local ok, name = pcall(ComponentGetTypeName, comp)
    return ok and type(name) == "string" and name ~= ""
end

local function preflight_reparents(delta)
    for _, entry in ipairs(delta.reparents or {}) do
        if not valid_entity(entry.entity) or not valid_entity(entry.before_parent) then
            return false, "detached_entity_gone"
        end
        if parent_of(entry.entity) ~= (tonumber(entry.after_parent) or 0) then
            return false, "detached_entity_claimed"
        end
    end
    return true, "ok"
end

local function cleanup_structural_additions(delta)
    local retired_entities = {}
    for _, entity in ipairs(delta.added_entities or {}) do
        if valid_entity(entity) then
            local ok, reason = pending_cleanup.retire_entity(entity, "structural:" .. tostring(delta.transaction_id or ""))
            if not ok then return false, reason end
        end
        retired_entities[entity] = true
    end
    for _, entry in ipairs(delta.added_components or {}) do
        if not retired_entities[entry.entity] and valid_entity(entry.entity) and component_alive(entry.component) then
            local ok, reason = pending_cleanup.retire_component(entry.entity, entry.component,
                "structural:" .. tostring(delta.transaction_id or ""))
            if not ok then return false, reason end
        end
    end
    return true, "structural_additions_retired"
end

structural_snapshot.valid_entity = valid_entity
structural_snapshot.parent_of = parent_of
structural_snapshot.snapshot = snapshot
structural_snapshot.build_delta = build_delta
structural_snapshot.component_alive = component_alive
structural_snapshot.preflight_reparents = preflight_reparents
structural_snapshot.cleanup_structural_additions = cleanup_structural_additions

return structural_snapshot
