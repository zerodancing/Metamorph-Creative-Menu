if type(METAMORPH_CREATIVE_MENU_PERK_PENDING_CLEANUP) == "table" then return METAMORPH_CREATIVE_MENU_PERK_PENDING_CLEANUP end

-- Noita can retire entities/components at the end of the frame rather than immediately.
-- A rollback must therefore distinguish "deletion requested" from a real persistent residue.
-- This module owns that asynchronous boundary; perk transactions never require another user click.
local pending_cleanup = {}

local pending = {}
local failed = {}
local fallback_tick = 0
local VERIFY_FRAMES = 30

local function now_frame()
    if type(GameGetFrameNum) == "function" then
        local ok, frame = pcall(GameGetFrameNum)
        if ok and tonumber(frame) ~= nil then return tonumber(frame) end
    end
    return fallback_tick
end

local function entity_alive(entity_id)
    if entity_id == nil or entity_id == 0 or type(EntityGetIsAlive) ~= "function" then return false end
    local ok, alive = pcall(EntityGetIsAlive, entity_id)
    return ok and alive == true
end

local function component_alive(component_id, expected_entity_id)
    if component_id == nil or component_id == 0 then return false end
    if type(ComponentGetTypeName) == "function" then
        local ok, type_name = pcall(ComponentGetTypeName, component_id)
        if not ok or type_name == nil or tostring(type_name) == "" then return false end
    elseif type(ComponentGetValue2) ~= "function" and type(ComponentGetValue) ~= "function" then
        return false
    end
    if expected_entity_id ~= nil and expected_entity_id ~= 0 and type(ComponentGetEntity) == "function" then
        local ok, owner = pcall(ComponentGetEntity, component_id)
        if not ok or tonumber(owner) ~= tonumber(expected_entity_id) then return false end
    end
    return true
end

local function disable_entity_scripts(entity_id)
    if not entity_alive(entity_id) then return end
    if type(EntityGetComponentIncludingDisabled) ~= "function" or type(EntitySetComponentIsEnabled) ~= "function" then return end
    for _, component_id in ipairs(EntityGetComponentIncludingDisabled(entity_id, "LuaComponent") or {}) do
        pcall(EntitySetComponentIsEnabled, entity_id, component_id, false)
    end
end

local function key_for(kind, entity_id, component_id)
    if kind == "entity" then return "entity:" .. tostring(entity_id) end
    return "component:" .. tostring(entity_id) .. ":" .. tostring(component_id)
end

local function attempt(record)
    if record.kind == "entity" then
        if not entity_alive(record.entity) then return true end
        disable_entity_scripts(record.entity)
        if type(EntityKill) ~= "function" then return false, "entity_kill_unavailable" end
        local ok = pcall(EntityKill, record.entity)
        if not ok then return false, "entity_kill_failed" end
        return not entity_alive(record.entity), "pending_engine_entity_delete"
    end

    if not entity_alive(record.entity) or not component_alive(record.component, record.entity) then return true end
    if type(EntityRemoveComponent) ~= "function" then return false, "component_remove_unavailable" end
    local ok = pcall(EntityRemoveComponent, record.entity, record.component)
    if not ok then return false, "component_remove_failed" end
    return not component_alive(record.component, record.entity), "pending_engine_component_delete"
end

local function enqueue(record)
    local key = key_for(record.kind, record.entity, record.component)
    local existing = pending[key] or failed[key]
    if existing ~= nil then return true, existing.failed and "cleanup_failed_pending_retry" or "cleanup_pending" end
    local frame = now_frame()
    record.requested_frame = frame
    record.deadline_frame = frame + VERIFY_FRAMES
    record.key = key
    local gone, reason = attempt(record)
    if gone then return true, "clean" end
    if reason == "entity_kill_unavailable" or reason == "entity_kill_failed"
        or reason == "component_remove_unavailable" or reason == "component_remove_failed" then
        return false, reason
    end
    pending[key] = record
    return true, "cleanup_pending"
end

function pending_cleanup.retire_entity(entity_id, source)
    entity_id = tonumber(entity_id) or 0
    if entity_id == 0 or not entity_alive(entity_id) then return true, "already_gone" end
    return enqueue({kind="entity", entity=entity_id, source=tostring(source or "perk")})
end

function pending_cleanup.retire_component(entity_id, component_id, source)
    entity_id = tonumber(entity_id) or 0
    component_id = tonumber(component_id) or 0
    if entity_id == 0 or component_id == 0 or not entity_alive(entity_id)
        or not component_alive(component_id, entity_id) then return true, "already_gone" end
    return enqueue({kind="component", entity=entity_id, component=component_id, source=tostring(source or "perk")})
end

function pending_cleanup.update()
    fallback_tick = fallback_tick + 1
    local frame = now_frame()
    local keys = {}
    for key in pairs(pending) do keys[#keys + 1] = key end
    for _, key in ipairs(keys) do
        local record = pending[key]
        if record ~= nil then
            local gone = select(1, attempt(record)) == true
            if gone then
                pending[key] = nil
            elseif frame >= (tonumber(record.deadline_frame) or frame) then
                pending[key] = nil
                record.failed = true
                record.failed_frame = frame
                failed[key] = record
            end
        end
    end

    -- A timed-out object can still disappear later because another engine subsystem
    -- finally completed the request. Keep retrying, and clear the diagnostic failure once clean.
    local failed_keys = {}
    for key in pairs(failed) do failed_keys[#failed_keys + 1] = key end
    for _, key in ipairs(failed_keys) do
        local record = failed[key]
        if record ~= nil and select(1, attempt(record)) == true then failed[key] = nil end
    end
end

function pending_cleanup.debug_state()
    local pending_count, failed_count = 0, 0
    local pending_items, failed_items = {}, {}
    for key, record in pairs(pending) do
        pending_count = pending_count + 1
        pending_items[#pending_items + 1] = key .. "@" .. tostring(record.source or "")
    end
    for key, record in pairs(failed) do
        failed_count = failed_count + 1
        failed_items[#failed_items + 1] = key .. "@" .. tostring(record.source or "")
    end
    table.sort(pending_items); table.sort(failed_items)
    return {pending=pending_count, failed=failed_count, pending_items=pending_items, failed_items=failed_items}
end

function pending_cleanup.has_failures()
    return next(failed) ~= nil
end

METAMORPH_CREATIVE_MENU_PERK_PENDING_CLEANUP = pending_cleanup
return pending_cleanup
