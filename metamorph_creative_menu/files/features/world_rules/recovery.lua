if type(METAMORPH_CREATIVE_MENU_WORLD_RULE_RECOVERY) == "table" then return METAMORPH_CREATIVE_MENU_WORLD_RULE_RECOVERY end

local recovery = {}
local PREFIX = "mcm_world_rules_recovery_v1:"
local SEP = string.char(30)

local function value_key(scope, id, part)
    return PREFIX .. tostring(scope) .. ":" .. tostring(id) .. ":" .. tostring(part)
end

local function index_key(scope)
    return PREFIX .. "index:" .. tostring(scope)
end

local function encode(value)
    local kind = type(value)
    if kind == "boolean" then return value and "b:1" or "b:0" end
    if kind == "number" then return "n:" .. string.format("%.17g", value) end
    if kind == "string" then return "s:" .. value end
    return nil
end

local function decode(raw)
    if type(raw) ~= "string" or raw == "" then return nil, false end
    local prefix = string.sub(raw, 1, 2)
    local body = string.sub(raw, 3)
    if prefix == "b:" then return body == "1", true end
    if prefix == "n:" then
        local number = tonumber(body)
        return number, number ~= nil
    end
    if prefix == "s:" then return body, true end
    return nil, false
end

local function read_index(scope)
    local raw = GlobalsGetValue(index_key(scope), "")
    local list, seen = {}, {}
    if raw ~= "" then
        for id in string.gmatch(raw, "[^" .. SEP .. "]+") do
            if not seen[id] then
                seen[id] = true
                list[#list + 1] = id
            end
        end
    end
    return list, seen
end

local function write_index(scope, list)
    GlobalsSetValue(index_key(scope), table.concat(list or {}, SEP))
end

local function ensure_indexed(scope, id)
    id = tostring(id)
    local list, seen = read_index(scope)
    if seen[id] then return end
    list[#list + 1] = id
    write_index(scope, list)
end

local function write_phase(scope, id, phase)
    GlobalsSetValue(value_key(scope, id, "phase"), tostring(phase or "captured"))
end

function recovery.list(scope)
    local list = read_index(scope)
    return list
end

function recovery.read(scope, id)
    local original_raw = GlobalsGetValue(value_key(scope, id, "original"), "")
    if original_raw == "" then return nil end
    local original, original_ok = decode(original_raw)
    if not original_ok then return nil end
    local last, last_ok = decode(GlobalsGetValue(value_key(scope, id, "last"), ""))
    local phase = GlobalsGetValue(value_key(scope, id, "phase"), "")
    -- Backwards-compatible migration for recovery records created by earlier builds.
    -- A record with a last-written value had acquired ownership; an empty last value
    -- was only a captured baseline and must never write original during RESET/restart.
    if phase ~= "captured" and phase ~= "owned" and phase ~= "partial" then
        phase = last_ok and "owned" or "captured"
    end
    return {
        original = original,
        last = last_ok and last or nil,
        phase = phase,
        meta = GlobalsGetValue(value_key(scope, id, "meta"), ""),
    }
end

function recovery.capture(scope, id, original, meta)
    if recovery.read(scope, id) ~= nil then return true end
    local encoded = encode(original)
    if encoded == nil then return false end
    GlobalsSetValue(value_key(scope, id, "original"), encoded)
    GlobalsSetValue(value_key(scope, id, "last"), "")
    write_phase(scope, id, "captured")
    GlobalsSetValue(value_key(scope, id, "meta"), tostring(meta or ""))
    ensure_indexed(scope, id)
    return true
end

function recovery.replace(scope, id, original, meta)
    local encoded = encode(original)
    if encoded == nil then return false end
    GlobalsSetValue(value_key(scope, id, "original"), encoded)
    GlobalsSetValue(value_key(scope, id, "last"), "")
    write_phase(scope, id, "captured")
    GlobalsSetValue(value_key(scope, id, "meta"), tostring(meta or ""))
    ensure_indexed(scope, id)
    return true
end

function recovery.update_last(scope, id, value)
    if recovery.read(scope, id) == nil then return false end
    local encoded = encode(value)
    if encoded == nil then return false end
    GlobalsSetValue(value_key(scope, id, "last"), encoded)
    write_phase(scope, id, "owned")
    return true
end

function recovery.mark_partial(scope, id, value)
    if recovery.read(scope, id) == nil then return false end
    if value ~= nil then
        local encoded = encode(value)
        if encoded ~= nil then GlobalsSetValue(value_key(scope, id, "last"), encoded) end
    end
    write_phase(scope, id, "partial")
    return true
end

function recovery.clear_last(scope, id)
    if recovery.read(scope, id) == nil then return false end
    GlobalsSetValue(value_key(scope, id, "last"), "")
    write_phase(scope, id, "captured")
    return true
end

function recovery.clear(scope, id)
    id = tostring(id)
    GlobalsSetValue(value_key(scope, id, "original"), "")
    GlobalsSetValue(value_key(scope, id, "last"), "")
    GlobalsSetValue(value_key(scope, id, "phase"), "")
    GlobalsSetValue(value_key(scope, id, "meta"), "")
    local list = read_index(scope)
    local kept = {}
    for _, current in ipairs(list) do
        if current ~= id then kept[#kept + 1] = current end
    end
    write_index(scope, kept)
end

function recovery.has(scope)
    local list = read_index(scope)
    return #list > 0
end

METAMORPH_CREATIVE_MENU_WORLD_RULE_RECOVERY = recovery
return recovery
