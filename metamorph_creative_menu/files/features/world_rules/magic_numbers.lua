if type(METAMORPH_CREATIVE_MENU_WORLD_RULE_MAGIC_NUMBERS) == "table" then return METAMORPH_CREATIVE_MENU_WORLD_RULE_MAGIC_NUMBERS end

local magic_number_adapter = {}
local patcher_bridge = dofile("mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua")
local rule_math = dofile("mods/metamorph_creative_menu/files/core/rule_math.lua")
local recovery = dofile("mods/metamorph_creative_menu/files/features/world_rules/recovery.lua")
local magic_state = {}

local function same_value(a, b)
    if type(a) == "number" or type(b) == "number" then return rule_math.same(a, b) end
    return a == b
end

local function magic_bridge(bootstrap)
    return patcher_bridge.get({ bootstrap_if_installed=bootstrap == true, capability="MagicNumbersSetValue" })
end

local function read_magic(key)
    if type(MagicNumbersGetValue) ~= "function" then return nil end
    local ok, raw = pcall(MagicNumbersGetValue, key)
    return ok and tonumber(raw) or nil
end

local function magic_record(key)
    local record = magic_state[key]
    if record ~= nil then return record end
    local value = read_magic(key)
    if value == nil then return nil end
    if not recovery.capture("magic", key, value) then return nil end
    record = { original=value, last_written=nil, phase="captured" }
    magic_state[key] = record
    return record
end

local function write_magic_verified(bridge, key, target)
    if bridge == nil or type(bridge.MagicNumbersSetValue) ~= "function" then return false, read_magic(key) end
    local ok = pcall(bridge.MagicNumbersSetValue, key, target)
    local after = read_magic(key)
    return ok and after ~= nil and same_value(after, target), after
end

local function mark_owned(key, record, value)
    record.last_written = value
    record.phase = "owned"
    recovery.update_last("magic", key, value)
end

local function mark_partial(key, record, value)
    if value ~= nil then record.last_written = value end
    record.phase = "partial"
    recovery.mark_partial("magic", key, value or record.last_written)
end

local function restore_previous_ownership(item, rollback_after)
    local record = item.record
    if item.previous_last ~= nil then
        record.last_written = item.previous_last
        record.phase = "owned"
        recovery.update_last("magic", item.key, item.previous_last)
    else
        magic_state[item.key] = nil
        recovery.clear("magic", item.key)
    end
end

local function rollback_changed(bridge, changed)
    local all_restored = true
    for index = #changed, 1, -1 do
        local item = changed[index]
        local restored, after = write_magic_verified(bridge, item.key, item.before)
        if restored then
            restore_previous_ownership(item, after)
        else
            mark_partial(item.key, item.record, after or item.applied_value)
            all_restored = false
        end
    end
    return all_restored
end

local function write_magic_multiplier(keys, factor)
    local bridge = nil
    local plan = {}
    for _, key in ipairs(keys or {}) do
        local record = magic_record(key)
        if record == nil then return false end
        local before = read_magic(key)
        if before == nil then return false end
        plan[#plan + 1] = {
            key=key,
            record=record,
            before=before,
            target=record.original * factor,
            previous_last=record.last_written,
        }
    end

    local changed = {}
    for _, item in ipairs(plan) do
        local key, record, target = item.key, item.record, item.target
        if not same_value(item.before, target) then
            bridge = bridge or magic_bridge(true)
            if bridge == nil then return false end
            local wrote, after = write_magic_verified(bridge, key, target)
            if wrote then
                item.applied_value = after
                changed[#changed + 1] = item
                mark_owned(key, record, after)
            else
                -- A setter can fail after partially changing its backing value. If the
                -- readback changed at all, that mutation is ours and must participate in
                -- the same verified rollback rather than being forgotten as a failed write.
                if after ~= nil and not same_value(after, item.before) then
                    item.applied_value = after
                    changed[#changed + 1] = item
                    mark_partial(key, record, after)
                end
                rollback_changed(bridge, changed)
                return false
            end
        end
        -- If the live value already equalled the requested target, no write happened.
        -- Keep only CAPTURED baseline state; NATIVE must not claim ownership later.
    end
    return true
end

local function restore_magic(keys)
    local has_tracked = false
    for _, key in ipairs(keys or {}) do
        if magic_state[key] ~= nil then has_tracked = true; break end
    end
    if not has_tracked then return true end
    local bridge = nil
    local ok_all = true
    for _, key in ipairs(keys or {}) do
        local record = magic_state[key]
        if record ~= nil then
            local current = read_magic(key)
            local key_ok = true
            if record.last_written == nil then
                -- Baseline captured but never owned: release metadata without writing.
                magic_state[key] = nil
                recovery.clear("magic", key)
            elseif current == nil then
                key_ok = false
            elseif not same_value(current, record.last_written) then
                -- Newer owner superseded us. CAS intentionally relinquishes ownership.
                magic_state[key] = nil
                recovery.clear("magic", key)
            else
                bridge = bridge or magic_bridge(true)
                if bridge == nil then
                    key_ok = false
                else
                    local restored, after = write_magic_verified(bridge, key, record.original)
                    if restored then
                        magic_state[key] = nil
                        recovery.clear("magic", key)
                    else
                        mark_partial(key, record, after or current)
                        key_ok = false
                    end
                end
            end
            if not key_ok then ok_all = false end
        end
    end
    return ok_all
end

local function recovery_magic_keys(rules)
    local result, seen = {}, {}
    for _, rule in ipairs(rules or {}) do
        if rule.kind == "magic_multiplier" then
            for _, key in ipairs(rule.magic_keys or {}) do
                if type(key) == "string" and key ~= "" and not seen[key] then
                    seen[key] = true
                    result[#result + 1] = key
                end
            end
        end
    end
    return result
end

function magic_number_adapter.recover_persisted(rules)
    local keys = recovery_magic_keys(rules)
    local pending = false
    for _, key in ipairs(keys) do if recovery.read("magic", key) ~= nil then pending = true; break end end
    if not pending then return true end
    if type(MagicNumbersGetValue) ~= "function" then return false end
    local bridge = nil
    local all_resolved = true
    for _, key in ipairs(keys) do
        local record = recovery.read("magic", key)
        if record ~= nil then
            local current = read_magic(key)
            if current == nil then
                all_resolved = false
            elseif record.phase == "captured" or record.last == nil then
                recovery.clear("magic", key)
                magic_state[key] = nil
            elseif same_value(current, record.original) then
                recovery.clear("magic", key)
                magic_state[key] = nil
            elseif same_value(current, record.last) then
                bridge = bridge or magic_bridge(true)
                if bridge == nil then
                    all_resolved = false
                else
                    local restored, after = write_magic_verified(bridge, key, record.original)
                    if restored then
                        recovery.clear("magic", key)
                        magic_state[key] = nil
                    else
                        recovery.mark_partial("magic", key, after or current)
                        all_resolved = false
                    end
                end
            else
                -- Another mod/game system changed the value after our last owned write.
                recovery.clear("magic", key)
                magic_state[key] = nil
            end
        end
    end
    return all_resolved
end

function magic_number_adapter.has_persisted_recovery(rules)
    for _, key in ipairs(recovery_magic_keys(rules)) do
        if recovery.read("magic", key) ~= nil then return true end
    end
    return false
end

function magic_number_adapter.supported()
    if type(MagicNumbersGetValue) ~= "function" then return false end
    if magic_bridge(false) ~= nil then return true end
    return type(patcher_bridge.bootstrap_available) == "function" and patcher_bridge.bootstrap_available()
end

function magic_number_adapter.apply(keys, factor)
    return write_magic_multiplier(keys, factor)
end

function magic_number_adapter.restore(keys)
    return restore_magic(keys)
end

function magic_number_adapter.reset_all()
    local keys = {}
    for key in pairs(magic_state) do keys[#keys + 1] = key end
    return restore_magic(keys)
end

function magic_number_adapter.owns(keys)
    for _, key in ipairs(keys or {}) do
        local record = magic_state[key]
        if record ~= nil and record.last_written ~= nil then return true end
    end
    return false
end

function magic_number_adapter.has_overrides()
    for _, record in pairs(magic_state) do if record.last_written ~= nil then return true end end
    return false
end

METAMORPH_CREATIVE_MENU_WORLD_RULE_MAGIC_NUMBERS = magic_number_adapter
return magic_number_adapter
