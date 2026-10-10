if type(METAMORPH_CREATIVE_MENU_WORLD_STATE_RULE_ADAPTER) == "table" then return METAMORPH_CREATIVE_MENU_WORLD_STATE_RULE_ADAPTER end

local world_state_adapter = {}
local rule_math = dofile("mods/metamorph_creative_menu/files/core/rule_math.lua")
local recovery = dofile("mods/metamorph_creative_menu/files/features/world_rules/recovery.lua")
local field_state = {}

local function world_component()
    local world_entity = GameGetWorldStateEntity()
    if world_entity == nil or world_entity == 0 then return nil end
    local component_id = EntityGetFirstComponentIncludingDisabled(world_entity, "WorldStateComponent")
    return component_id ~= nil and component_id ~= 0 and component_id or nil
end

local function values_equal(a, b)
    if type(a) == "number" or type(b) == "number" then
        return rule_math.same(a, b)
    end
    return a == b
end

local function read_field(comp, field)
    local ok, value = pcall(ComponentGetValue2, comp, field)
    if not ok then return false, nil end
    return true, value
end

local function capture_field(comp, field)
    if field_state[field] ~= nil then return true end
    local ok, value = read_field(comp, field)
    if not ok then return false end
    if not recovery.capture("world", field, value) then return false end
    field_state[field] = { original=value, last_written=nil, phase="captured" }
    return true
end

local WORLD_BOOLEAN_FIELDS = {
    perk_gold_is_forever=true,
    perk_infinite_spells=true,
    consume_actions=true,
    open_fog_of_war_everywhere=true,
    perk_trick_kills_blood_money=true,
    perk_rats_player_friendly=true,
}

local function boolean_value(value)
    return value == true or value == 1 or value == "1" or value == "true"
end

local function value_for_set(field, live, desired)
    -- LensValue<bool> fields such as consume_actions are exposed as 0/1 numbers,
    -- but ComponentSetValue2 still requires a Lua boolean. This explicit schema is
    -- needed because the getter's representation is not the setter's type contract.
    if WORLD_BOOLEAN_FIELDS[field] then return boolean_value(desired) end
    if type(live) == "number" and type(desired) == "boolean" then return desired and 1 or 0 end
    if type(live) == "boolean" and type(desired) == "number" then return desired ~= 0 end
    if type(live) == "string" then return tostring(desired) end
    return desired
end

local function value_for_readback(field, live, set_value)
    if WORLD_BOOLEAN_FIELDS[field] and type(live) == "number" then return set_value and 1 or 0 end
    return set_value
end

local function set_field_value(comp, field, value)
    local read_before, live = read_field(comp, field)
    if not read_before then return false, nil end
    local target = value_for_set(field, live, value)
    local expected = value_for_readback(field, live, target)
    local ok = pcall(ComponentSetValue2, comp, field, target)
    local read_ok, after = false, nil
    if ok then read_ok, after = read_field(comp, field) end
    if read_ok and values_equal(after, expected) then return true, after end
    -- Some WorldState LensValue fields accept the legacy string setter even when the
    -- typed setter returns without changing the backing value. Use it only as a verified
    -- fallback, then read back again; never treat an unchecked write as success.
    if type(ComponentSetValue) == "function" and not WORLD_BOOLEAN_FIELDS[field] then
        local legacy_ok = pcall(ComponentSetValue, comp, field, tostring(target))
        if legacy_ok then
            local legacy_read_ok, legacy_after = read_field(comp, field)
            if legacy_read_ok and values_equal(legacy_after, expected) then return true, legacy_after end
            after = legacy_after
        end
    end
    return false, after
end

local function write_field(comp, field, value)
    if not capture_field(comp, field) then return false end
    local read_ok, live = read_field(comp, field)
    if not read_ok then return false end
    local target = value_for_set(field, live, value)
    local expected = value_for_readback(field, live, target)
    local record = field_state[field]
    if values_equal(live, expected) then
        -- Matching an already-existing value is not ownership. Keep a captured baseline
        -- so reassertion can use the same native value, but NATIVE/RESET must not write it.
        return true
    end
    local ok, after = set_field_value(comp, field, value)
    if not ok then return false end
    if record.last_written == nil or not values_equal(record.last_written, after) then
        recovery.update_last("world", field, after)
    end
    record.last_written = after
    record.phase = "owned"
    return true
end

local function restore_field(comp, field)
    local record = field_state[field]
    if type(record) ~= "table" then return true end
    -- Capturing a baseline is not ownership. If no verified write ever happened,
    -- releasing the rule must not overwrite a value another mod may have changed later.
    if record.last_written == nil then
        recovery.clear("world", field)
        return true
    end
    local ok, current = read_field(comp, field)
    if not ok then return false end
    -- Compare-and-swap: do not overwrite a newer mutation made by another mod/game
    -- after our last successful write.
    if not values_equal(current, record.last_written) then
        recovery.clear("world", field)
        return true
    end
    local wrote, after = set_field_value(comp, field, record.original)
    if wrote == true then
        recovery.clear("world", field)
        return true
    end
    recovery.mark_partial("world", field, after or current)
    record.phase = "partial"
    if after ~= nil then record.last_written = after end
    return false
end

local function apply_field_choice(comp, rule, choice)
    if choice.native == true then
        local ok = restore_field(comp, rule.field)
        if ok then field_state[rule.field] = nil end
        return ok
    end
    local value = choice.value
    if rule.integer and tonumber(value) ~= nil then value = math.floor(tonumber(value) + 0.5) end
    local ok = write_field(comp, rule.field, value)
    
    return ok
end

local function rollback_field_write(comp, field, before_value, previous_last)
    local record = field_state[field]
    if type(record) ~= "table" then return true end
    if record.last_written == nil then
        if previous_last == nil then
            field_state[field] = nil
            recovery.clear("world", field)
        end
        return true
    end
    local restored, after = set_field_value(comp, field, before_value)
    if restored then
        if previous_last ~= nil then
            record.last_written = previous_last
            record.phase = "owned"
            recovery.update_last("world", field, previous_last)
        else
            field_state[field] = nil
            recovery.clear("world", field)
        end
        return true
    end
    record.phase = "partial"
    if after ~= nil then record.last_written = after end
    recovery.mark_partial("world", field, after or record.last_written)
    return false
end

local function apply_infinite_spells(comp, rule, choice)
    if choice.native == true then
        local a = restore_field(comp, rule.field)
        local b = restore_field(comp, rule.secondary)
        if a and b then
            field_state[rule.field], field_state[rule.secondary] = nil, nil
        end
        return a and b
    end
    local enabled = choice.value == true
    local ok_before_a, before_a = read_field(comp, rule.field)
    local ok_before_b, before_b = read_field(comp, rule.secondary)
    if not ok_before_a or not ok_before_b then return false end
    local previous_last_a = field_state[rule.field] and field_state[rule.field].last_written or nil
    local previous_last_b = field_state[rule.secondary] and field_state[rule.secondary].last_written or nil
    local a = write_field(comp, rule.field, enabled)
    local b = write_field(comp, rule.secondary, not enabled)
    if not (a and b) then
        -- This is one logical rule backed by two engine fields. Roll back every field
        -- with the same verified write/readback contract. Failed rollback remains owned
        -- as PARTIAL so startup recovery/RESET can retry instead of losing metadata.
        local rollback_a = rollback_field_write(comp, rule.field, before_a, previous_last_a)
        local rollback_b = rollback_field_write(comp, rule.secondary, before_b, previous_last_b)
        return false, (rollback_a and rollback_b) and "write_failed_rolled_back" or "partial_rollback"
    end
    return true
end


local function recovery_fields(rules)
    local result, seen = {}, {}
    for _, rule in ipairs(rules or {}) do
        for _, field in ipairs({rule.field, rule.secondary}) do
            if type(field) == "string" and field ~= "" and not seen[field] then
                seen[field] = true
                result[#result + 1] = field
            end
        end
    end
    return result
end

function world_state_adapter.recover_persisted(rules)
    local fields = recovery_fields(rules)
    local has_pending = false
    for _, field in ipairs(fields) do
        if recovery.read("world", field) ~= nil then has_pending = true; break end
    end
    if not has_pending then return true end
    local component_id = world_component()
    if component_id == nil then return false end
    local all_resolved = true
    for _, field in ipairs(fields) do
        local record = recovery.read("world", field)
        if record ~= nil then
            local read_ok, current = read_field(component_id, field)
            if not read_ok then
                all_resolved = false
            elseif record.phase == "captured" or record.last == nil then
                -- Baseline-only records never acquired ownership and therefore never write.
                recovery.clear("world", field)
                field_state[field] = nil
            elseif values_equal(current, record.original) then
                recovery.clear("world", field)
                field_state[field] = nil
            elseif record.last ~= nil and values_equal(current, record.last) then
                local restored = set_field_value(component_id, field, record.original)
                if restored then
                    recovery.clear("world", field)
                    field_state[field] = nil
                else
                    all_resolved = false
                end
            else
                -- Another mod/game system changed the value after our last owned write.
                -- Do not overwrite that newer state on startup; relinquish stale ownership.
                recovery.clear("world", field)
                field_state[field] = nil
            end
        end
    end
    return all_resolved
end

function world_state_adapter.has_persisted_recovery(rules)
    for _, field in ipairs(recovery_fields(rules)) do
        if recovery.read("world", field) ~= nil then return true end
    end
    return false
end

function world_state_adapter.component()
    return world_component()
end

function world_state_adapter.supported(rule)
    if type(rule) ~= "table" then return false end
    local component_id = world_component()
    if component_id == nil then return false end
    local readable = read_field(component_id, rule.field)
    if not readable then return false end
    if rule.secondary ~= nil then return read_field(component_id, rule.secondary) end
    return true
end

function world_state_adapter.apply(rule, choice)
    local component_id = world_component()
    if component_id == nil then return false, "world" end
    local applied
    if rule.kind == "infinite_spells" then applied = apply_infinite_spells(component_id, rule, choice)
    else applied = apply_field_choice(component_id, rule, choice) end
    return applied, applied and "ok" or "write_readback"
end

function world_state_adapter.reset_all()
    local component_id = world_component()
    if component_id == nil and next(field_state) ~= nil then return false end
    local all_restored = true
    local fields = {}
    for field in pairs(field_state) do fields[#fields + 1] = field end
    for _, field in ipairs(fields) do
        if component_id ~= nil and restore_field(component_id, field) then field_state[field] = nil else all_restored = false end
    end
    return all_restored
end

function world_state_adapter.owns_rule(rule)
    if type(rule) ~= "table" then return false end
    if rule.kind == "infinite_spells" then
        return field_state[rule.field] ~= nil or field_state[rule.secondary] ~= nil
    end
    return field_state[rule.field] ~= nil
end

function world_state_adapter.has_overrides()
    return next(field_state) ~= nil
end

METAMORPH_CREATIVE_MENU_WORLD_STATE_RULE_ADAPTER = world_state_adapter
return world_state_adapter
