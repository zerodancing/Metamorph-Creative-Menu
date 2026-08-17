if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS) == "table" then return METAMORPH_CREATIVE_MENU_DIAGNOSTICS end

local diagnostics = {}
local logger = dofile("mods/metamorph_creative_menu/files/diagnostics/logger.lua")
local runtime_recorder = dofile("mods/metamorph_creative_menu/files/diagnostics/runtime_recorder.lua")
local scanner = dofile("mods/metamorph_creative_menu/files/diagnostics/scanner.lua")

local PERF_SAMPLE_TARGET = 180
local run_counter = 0
local active_report = nil

function diagnostics.event(kind, details)
    return logger.event(kind, details)
end

function diagnostics.user_action(action, details)
    return logger.user_action(action, details)
end

function diagnostics.test_action(_action, _details)
    -- STEP BEGIN in the QA runner is the durable destructive breadcrumb.
    return true
end

diagnostics.capture_error = logger.capture_error
METAMORPH_CREATIVE_MENU_DIAGNOSTICS_USER_ACTION = function(action, details) pcall(diagnostics.user_action, action, details) end
METAMORPH_CREATIVE_MENU_DIAGNOSTICS_EVENT = function(kind, details) pcall(diagnostics.event, kind, details) end
METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE = logger.capture_error

local function start_scan()
    if active_report ~= nil then
        GamePrint("Metamorph: Creative Menu diagnostics already running")
        return false
    end

    run_counter = run_counter + 1
    local current_frame = logger.now_frame()
    local current_time = logger.now_seconds()
    active_report = {
        run_id = run_counter,
        started_frame = current_frame,
        started_time = current_time,
        started_stamp = logger.timestamp(),
        rows = {}, pass = 0, warn = 0, fail = 0, info = 0, modules = {}, frame_ms = {},
        previous_sample_time = nil,
        runtime_error_count_at_start = scanner.runtime_error_count(),
        new_runtime_errors = 0,
        scan_stage = "prepare", scan_index = 1, runtime_done = false,
    }

    local writable, err = logger.ensure_ready()
    -- Scanner owns report formatting, but the file-boundary result belongs to the lifecycle.
    local level = writable and "PASS" or "FAIL"
    active_report.pass = writable and 1 or 0
    active_report.fail = writable and 0 or 1
    active_report.rows[#active_report.rows + 1] = string.format("[%s] diagnostic.file_append path=%s status=%s%s",
        level, logger.path(), tostring(writable), err and (" error=" .. tostring(err)) or "")
    if writable then
        logger.append(string.format("\n=== EWCM DIAGNOSTIC BEGIN run=%d time=%s frame=%d ===\n",
            active_report.run_id, active_report.started_stamp, active_report.started_frame))
    end

    scanner.initialize(active_report)
    GamePrintImportant("Metamorph: Creative Menu diagnostics", "STARTED (Z). Non-destructive scan + frame sampling...")
    return true
end

function diagnostics.running()
    return active_report ~= nil
end

function diagnostics.log_path()
    return logger.path()
end

function diagnostics.start_scan()
    return start_scan()
end

function diagnostics.start()
    return start_scan()
end

function diagnostics.update()
    logger.start_session_if_needed()
    runtime_recorder.update()

    local report = active_report
    if report == nil then return end

    local current_time = logger.now_seconds()
    if current_time ~= nil and report.previous_sample_time ~= nil then
        local frame_ms = (current_time - report.previous_sample_time) * 1000
        if type(frame_ms) == "number" and frame_ms == frame_ms and frame_ms >= 0 and frame_ms < 5000 then
            report.frame_ms[#report.frame_ms + 1] = frame_ms
        end
    end
    report.previous_sample_time = current_time

    if report.scan_stage ~= "sampling" then
        scanner.step(report)
    elseif #report.frame_ms >= PERF_SAMPLE_TARGET then
        scanner.finish(report)
        active_report = nil
    end
end

METAMORPH_CREATIVE_MENU_DIAGNOSTICS = diagnostics
return diagnostics
