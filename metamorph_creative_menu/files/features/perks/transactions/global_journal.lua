local global_journal = {}

-- Non-numeric Globals and run flags need ownership layering just like component fields.
-- Numeric Globals are reverted additively (subtract this pickup's delta), which naturally
-- composes when several perk stacks touch the same counter in any removal order.
local global_owners = {}
local run_flag_owners = {}

local function is_standard_perk_global(token, global_name)
    local perk_id = tostring(token and token.perk_id or "")
    return global_name == ("PERK_PICKED_" .. perk_id .. "_PICKUP_COUNT")
end

local function is_standard_perk_flag(token, flag_name)
    local perk_id = tostring(token and token.perk_id or "")
    return flag_name == ("PERK_PICKED_" .. perk_id)
end

local function find_layer(ownership, transaction_id)
    if type(ownership) ~= "table" then return nil end
    for index = #ownership.layers, 1, -1 do
        if ownership.layers[index].transaction_id == transaction_id then return index end
    end
    return nil
end

local function register_owner(registry, name, transaction_id, before_value, after_value)
    if transaction_id == nil then return end
    local ownership = registry[name]
    if ownership == nil then
        ownership = { baseline=before_value, layers={} }
        registry[name] = ownership
    end
    ownership.layers[#ownership.layers + 1] = {
        transaction_id=transaction_id,
        after=after_value,
    }
end

local function discard_owner(registry, name, transaction_id)
    local ownership = registry[name]
    local index = find_layer(ownership, transaction_id)
    if index == nil then return end
    table.remove(ownership.layers, index)
    if #ownership.layers == 0 then registry[name] = nil end
end

-- Temporarily intercept run-global mutations performed synchronously by vanilla
-- perk_pickup(). Entity/component/meta/object mutations are captured by mutation_journal.
function global_journal.start_capture(token, environment)
    if type(token) ~= "table" or token.capture_active then return false end
    local env = type(environment) == "table" and environment or _G
    local original_get = env.GlobalsGetValue
    local original_set = env.GlobalsSetValue
    local original_has_flag = env.GameHasFlagRun
    local original_add_flag = env.GameAddFlagRun
    local original_remove_flag = env.GameRemoveFlagRun
    if type(original_get) ~= "function" or type(original_set) ~= "function" then return false end

    token.global_changes = token.global_changes or {}
    token.global_reads = token.global_reads or {}
    token.run_flag_changes = token.run_flag_changes or {}
    token.capture_env = env
    token.capture_old = { original_get, original_set, original_has_flag, original_add_flag, original_remove_flag }
    token.capture_active = true

    env.GlobalsGetValue = function(global_name, default_value)
        local value = original_get(global_name, default_value)
        global_name = tostring(global_name or "")
        if token.global_reads[global_name] == nil and not is_standard_perk_global(token, global_name) then
            token.global_reads[global_name] = tostring(value or "")
        end
        return value
    end

    env.GlobalsSetValue = function(global_name, value)
        global_name = tostring(global_name or "")
        if not is_standard_perk_global(token, global_name) then
            local change = token.global_changes[global_name]
            if change == nil then
                local before_value = token.global_reads[global_name]
                if before_value == nil then before_value = tostring(original_get(global_name, "") or "") end
                change = {
                    before=before_value,
                    after=tostring(value or ""),
                    read_before_write=token.global_reads[global_name] ~= nil,
                    written=true,
                }
                token.global_changes[global_name] = change
            else
                change.after = tostring(value or "")
                change.written = true
            end
        end
        return original_set(global_name, value)
    end

    if type(original_has_flag) == "function" then
        env.GameHasFlagRun = function(flag_name)
            local flag_was_set = original_has_flag(flag_name) == true
            flag_name = tostring(flag_name or "")
            if token.run_flag_changes[flag_name] == nil and not is_standard_perk_flag(token, flag_name) then
                token.run_flag_changes[flag_name] = { before=flag_was_set, after=flag_was_set, written=false }
            end
            return flag_was_set
        end
    end

    if type(original_add_flag) == "function" then
        env.GameAddFlagRun = function(flag_name)
            flag_name = tostring(flag_name or "")
            if not is_standard_perk_flag(token, flag_name) then
                local change = token.run_flag_changes[flag_name]
                if change == nil then
                    change = {
                        before=type(original_has_flag) == "function" and original_has_flag(flag_name) == true or false,
                        after=true,
                        written=true,
                    }
                    token.run_flag_changes[flag_name] = change
                else
                    change.after = true
                    change.written = true
                end
            end
            return original_add_flag(flag_name)
        end
    end

    if type(original_remove_flag) == "function" then
        env.GameRemoveFlagRun = function(flag_name)
            flag_name = tostring(flag_name or "")
            if not is_standard_perk_flag(token, flag_name) then
                local change = token.run_flag_changes[flag_name]
                if change == nil then
                    change = {
                        before=type(original_has_flag) == "function" and original_has_flag(flag_name) == true or false,
                        after=false,
                        written=true,
                    }
                    token.run_flag_changes[flag_name] = change
                else
                    change.after = false
                    change.written = true
                end
            end
            return original_remove_flag(flag_name)
        end
    end
    return true
end

function global_journal.stop_capture(token)
    if type(token) ~= "table" or not token.capture_active then return end
    local env = token.capture_env
    local original_functions = token.capture_old
    if type(env) == "table" and type(original_functions) == "table" then
        env.GlobalsGetValue, env.GlobalsSetValue = original_functions[1], original_functions[2]
        env.GameHasFlagRun, env.GameAddFlagRun, env.GameRemoveFlagRun = original_functions[3], original_functions[4], original_functions[5]
    end
    token.capture_active = false
end

function global_journal.attach_delta(delta, token)
    if type(delta) ~= "table" then return end
    local transaction_id = type(token) == "table" and token.transaction_id or delta.transaction_id
    delta.transaction_id = delta.transaction_id or transaction_id
    delta.global_changes = {}
    for global_name, change in pairs(type(token) == "table" and token.global_changes or {}) do
        if change.written == true then
            local before_number = tonumber(change.before)
            local after_number = tonumber(change.after)
            -- A numeric value is treated as an additive counter only when the perk read
            -- that same Global before writing it. Direct constant writes (including 0/1
            -- state flags) use ownership layering instead of unsafe subtraction.
            local numeric_delta = nil
            if change.read_before_write == true and before_number ~= nil and after_number ~= nil then
                numeric_delta = after_number - before_number
            end
            local entry = {
                name=global_name,
                before=tostring(change.before),
                after=tostring(change.after),
                numeric_delta=numeric_delta,
            }
            if tostring(change.before) ~= tostring(change.after) or numeric_delta == nil then
                delta.global_changes[#delta.global_changes + 1] = entry
                if entry.numeric_delta == nil then
                    register_owner(global_owners, global_name, transaction_id, entry.before, entry.after)
                end
            end
        end
    end
    delta.run_flag_changes = {}
    for flag_name, change in pairs(type(token) == "table" and token.run_flag_changes or {}) do
        if change.written == true then
            local entry = { name=flag_name, before=change.before == true, after=change.after == true }
            delta.run_flag_changes[#delta.run_flag_changes + 1] = entry
            register_owner(run_flag_owners, flag_name, transaction_id, entry.before, entry.after)
        end
    end
end

local function preflight_layer(registry, name, transaction_id, current_value)
    local ownership = registry[name]
    local index = find_layer(ownership, transaction_id)
    if index == nil then return nil end
    local top = ownership.layers[#ownership.layers]
    if current_value ~= top.after then return false end
    return true
end

function global_journal.preflight_delta(delta)
    local transaction_id = type(delta) == "table" and delta.transaction_id or nil
    for _, change in ipairs(type(delta) == "table" and delta.global_changes or {}) do
        if change.numeric_delta == nil then
            local current = tostring(GlobalsGetValue(change.name, ""))
            local layered = preflight_layer(global_owners, change.name, transaction_id, current)
            if layered == false or (layered == nil and current ~= tostring(change.after)) then
                return false, "global_modified:" .. tostring(change.name)
            end
        end
    end
    for _, change in ipairs(type(delta) == "table" and delta.run_flag_changes or {}) do
        if type(GameHasFlagRun) == "function" then
            local current = GameHasFlagRun(change.name) == true
            local layered = preflight_layer(run_flag_owners, change.name, transaction_id, current)
            if layered == false or (layered == nil and current ~= (change.after == true)) then
                return false, "run_flag_modified:" .. tostring(change.name)
            end
        end
    end
    return true, "ok"
end

local function revert_string_global(change, transaction_id)
    local ownership = global_owners[change.name]
    local index = find_layer(ownership, transaction_id)
    if index == nil then
        if tostring(GlobalsGetValue(change.name, "")) == tostring(change.after) then
            GlobalsSetValue(change.name, change.before)
        end
        return
    end
    local current = tostring(GlobalsGetValue(change.name, ""))
    local removed = table.remove(ownership.layers, index)
    if #ownership.layers == 0 then
        if current == tostring(removed.after) then GlobalsSetValue(change.name, tostring(ownership.baseline)) end
        global_owners[change.name] = nil
        return
    end
    if index > #ownership.layers then
        local previous = ownership.layers[#ownership.layers]
        if current == tostring(removed.after) then GlobalsSetValue(change.name, tostring(previous.after)) end
    end
end

local function revert_run_flag(change, transaction_id)
    local ownership = run_flag_owners[change.name]
    local index = find_layer(ownership, transaction_id)
    local current = type(GameHasFlagRun) == "function" and GameHasFlagRun(change.name) == true or change.after == true
    if index == nil then
        if current == (change.after == true) then
            if change.before then pcall(GameAddFlagRun, change.name) else pcall(GameRemoveFlagRun, change.name) end
        end
        return
    end
    local removed = table.remove(ownership.layers, index)
    local target = nil
    if #ownership.layers == 0 then
        target = ownership.baseline == true
        run_flag_owners[change.name] = nil
    elseif index > #ownership.layers then
        target = ownership.layers[#ownership.layers].after == true
    end
    if target ~= nil and current == (removed.after == true) then
        if target then pcall(GameAddFlagRun, change.name) else pcall(GameRemoveFlagRun, change.name) end
    end
end

function global_journal.revert_delta(delta)
    local transaction_id = type(delta) == "table" and delta.transaction_id or nil
    for change_index = #(type(delta) == "table" and delta.global_changes or {}), 1, -1 do
        local change = delta.global_changes[change_index]
        if change.numeric_delta ~= nil then
            local current_value = tonumber(GlobalsGetValue(change.name, change.after))
            if current_value ~= nil then
                GlobalsSetValue(change.name, tostring(current_value - change.numeric_delta))
            else
                GlobalsSetValue(change.name, change.before)
            end
        else
            revert_string_global(change, transaction_id)
        end
    end
    for change_index = #(type(delta) == "table" and delta.run_flag_changes or {}), 1, -1 do
        revert_run_flag(delta.run_flag_changes[change_index], transaction_id)
    end
end

function global_journal.discard_delta(delta)
    local transaction_id = type(delta) == "table" and delta.transaction_id or nil
    for _, change in ipairs(type(delta) == "table" and delta.global_changes or {}) do
        if change.numeric_delta == nil then discard_owner(global_owners, change.name, transaction_id) end
    end
    for _, change in ipairs(type(delta) == "table" and delta.run_flag_changes or {}) do
        discard_owner(run_flag_owners, change.name, transaction_id)
    end
end

function global_journal.debug_active_owners()
    local globals, flags = 0, 0
    for _ in pairs(global_owners) do globals = globals + 1 end
    for _ in pairs(run_flag_owners) do flags = flags + 1 end
    return globals, flags
end

return global_journal
