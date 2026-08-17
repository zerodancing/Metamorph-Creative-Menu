if type(METAMORPH_CREATIVE_MENU_DIAGNOSTIC_LOGGER) == "table" then return METAMORPH_CREATIVE_MENU_DIAGNOSTIC_LOGGER end

local logger = {}
local bounded_log = dofile("mods/metamorph_creative_menu/files/core/bounded_log.lua")

local LOG_PATH = "mods/metamorph_creative_menu/metamorph_creative_menu_v14_1_diagnostics.log"
local RECOVERY_TAIL_BYTES = 2 * 1024 * 1024
local LOG_MAX_BYTES = 8 * 1024 * 1024
local ERROR_RING_LIMIT = 64

local log_ready = false
local log_failure = nil
local session_started = false
local session_id = nil
local runtime_errors = {}

function logger.now_frame()
    local ok, value = pcall(GameGetFrameNum)
    return ok and tonumber(value) or 0
end

function logger.now_seconds()
    if type(GameGetRealWorldTimeSinceStarted) ~= "function" then return nil end
    local ok, value = pcall(GameGetRealWorldTimeSinceStarted)
    value = ok and tonumber(value) or nil
    if value ~= nil and value == value then return value end
    return nil
end

function logger.timestamp()
    if type(GameGetDateAndTimeLocal) == "function" then
        local ok, year, month, day, hour, minute, second = pcall(GameGetDateAndTimeLocal)
        if ok and tonumber(year) ~= nil then
            return string.format("%04d-%02d-%02d %02d:%02d:%02d",
                tonumber(year) or 0, tonumber(month) or 0, tonumber(day) or 0,
                tonumber(hour) or 0, tonumber(minute) or 0, tonumber(second) or 0)
        end
    end
    return "frame:" .. tostring(logger.now_frame())
end

function logger.one_line(value)
    value = tostring(value == nil and "nil" or value)
    value = string.gsub(value, "\r", " ")
    value = string.gsub(value, "\n", " ")
    value = string.gsub(value, "%s+", " ")
    if #value > 360 then value = string.sub(value, 1, 357) .. "..." end
    return value
end

function logger.append(text)
    return bounded_log.append(LOG_PATH, text, LOG_MAX_BYTES, RECOVERY_TAIL_BYTES)
end

local function read_existing_log(max_bytes)
    return bounded_log.read_tail(LOG_PATH, max_bytes)
end

local function last_line_matching(text, pattern)
    local last = nil
    for line in string.gmatch(tostring(text or ""), "[^\r\n]+") do
        if string.find(line, pattern, 1, true) then last = line end
    end
    return last
end

function logger.ensure_ready()
    if log_ready then return true end
    if log_failure ~= nil then return false, log_failure end
    if bounded_log.has_content(LOG_PATH) then log_ready = true; return true end
    local ok, err = logger.append(table.concat({
        "\n# ------------------------------------------------------------\n",
        "# Metamorph: Creative Menu bounded persistent diagnostics log\n",
        "# Z starts the scenario QA runner. Recent history is preserved across restarts.\n",
        "# Runtime/user/test format is intentionally line-oriented for postmortem analysis.\n",
        "# ------------------------------------------------------------\n",
    }))
    if ok then log_ready = true else log_failure = tostring(err or "write failed") end
    return ok, err
end

function logger.start_session_if_needed()
    if session_started then return end
    logger.ensure_ready()
    session_started = true
    session_id = logger.timestamp() .. "@" .. tostring(logger.now_frame())
    local old = read_existing_log(RECOVERY_TAIL_BYTES)
    local open_test = last_line_matching(old, "=== EWCM AUTOTEST BEGIN")
    local closed_test = last_line_matching(old, "=== EWCM AUTOTEST END")
    local open_pos = open_test and string.find(old, open_test, 1, true) or nil
    local close_pos = closed_test and string.find(old, closed_test, 1, true) or nil
    if open_pos ~= nil and (close_pos == nil or close_pos < open_pos) then
        local tail = string.sub(old, open_pos)
        local context = {}
        for line in string.gmatch(tail, "[^\r\n]+") do
            if string.find(line, "[STEP ", 1, true) or string.find(line, "[HEARTBEAT]", 1, true)
                or string.find(line, "[USER]", 1, true) or string.find(line, "[INPUT]", 1, true)
                or string.find(line, "[RUNTIME]", 1, true) or string.find(line, "[TEST]", 1, true)
                or string.find(line, "[STATE]", 1, true) or string.find(line, "[FRAME SPIKE]", 1, true)
                or string.find(line, "[EW PEERS]", 1, true) or string.find(line, "[EW REMOTE QA]", 1, true)
                or string.find(line, "[FORM DEATH]", 1, true) or string.find(line, "[FORM CORPSE", 1, true)
            then
                context[#context+1] = line
                while #context > 8 do table.remove(context, 1) end
            end
        end
        local last_record = context[#context] or open_test
        logger.append("[RECOVERY] time=" .. logger.timestamp() .. " probable_crash_or_forced_exit=true previous_open_test=1 last_record=" .. logger.one_line(last_record) .. "\n")
        for index, line in ipairs(context) do
            logger.append("[RECOVERY CONTEXT " .. tostring(index) .. "] " .. logger.one_line(line) .. "\n")
        end
    end
    logger.append("\n=== EWCM SESSION BEGIN id=" .. logger.one_line(session_id) .. " time=" .. logger.timestamp() .. " frame=" .. tostring(logger.now_frame()) .. " ===\n")
end

function logger.event(kind, details)
    logger.start_session_if_needed()
    local line = string.format("[%s] time=%s frame=%d %s\n",
        logger.one_line(kind or "EVENT"), logger.timestamp(), logger.now_frame(), logger.one_line(details or ""))
    return logger.append(line)
end

function logger.user_action(action, details)
    return logger.event("USER", "action=" .. logger.one_line(action or "unknown") .. (details and (" " .. logger.one_line(details)) or ""))
end

function logger.capture_error(source, message)
    local entry = {
        frame = logger.now_frame(),
        time = logger.timestamp(),
        source = logger.one_line(source or "unknown"),
        message = logger.one_line(message or "unknown"),
    }
    runtime_errors[#runtime_errors + 1] = entry
    while #runtime_errors > ERROR_RING_LIMIT do table.remove(runtime_errors, 1) end
    if logger.ensure_ready() then
        logger.append(string.format("[RUNTIME] time=%s frame=%d source=%s error=%s\n",
            entry.time, entry.frame, entry.source, entry.message))
    end
end

function logger.runtime_errors()
    return runtime_errors
end

function logger.path()
    return LOG_PATH
end

METAMORPH_CREATIVE_MENU_DIAGNOSTIC_LOGGER = logger
return logger
