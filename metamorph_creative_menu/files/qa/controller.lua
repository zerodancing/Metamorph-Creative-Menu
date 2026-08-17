-- Lightweight QA entrypoint. The heavy scenario runner is loaded only after the user
-- explicitly presses Z, keeping normal startup and gameplay free from QA dependencies.
if type(METAMORPH_CREATIVE_MENU_QA_CONTROLLER) == "table" then return METAMORPH_CREATIVE_MENU_QA_CONTROLLER end

local qa_controller = {}
local input_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/input_guard.lua")
local keycodes = dofile("mods/metamorph_creative_menu/files/platform/noita/keycodes.lua")
local qa_runner = nil
local qa_key_code = nil

local function qa_key_pressed()
    if qa_key_code == nil then qa_key_code = keycodes.resolve("Key_z", "KEY_Z") end
    if qa_key_code == nil or type(InputIsKeyJustDown) ~= "function" then return false end
    local read_succeeded, is_pressed = pcall(InputIsKeyJustDown, qa_key_code)
    return read_succeeded and is_pressed == true
end

local function actions_allowed()
    if type(input_guard.actions_allowed) == "function" then
        local guard_succeeded, allowed = pcall(input_guard.actions_allowed)
        if not guard_succeeded or allowed ~= true then return false end
    end
    if type(GameIsInventoryOpen) == "function" then
        local read_succeeded, inventory_open = pcall(GameIsInventoryOpen)
        if read_succeeded and inventory_open == true then return false end
    end
    return true
end

local function load_runner()
    if qa_runner ~= nil then return qa_runner end
    local load_succeeded, loaded_runner = pcall(dofile, "mods/metamorph_creative_menu/files/qa/runner.lua")
    if not load_succeeded or type(loaded_runner) ~= "table" then
        local details = tostring(loaded_runner or "qa_runner returned no module")
        if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE) == "function" then
            pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE, "qa_controller.load", details)
        end
        print("[Metamorph: Creative Menu] QA runner load failed: " .. details)
        return nil
    end
    qa_runner = loaded_runner
    return qa_runner
end


local function start_runner(runner)
    if type(runner) ~= "table" or type(runner.start) ~= "function" then return false end
    local ok, result = xpcall(runner.start, function(error_value)
        return type(debug) == "table" and type(debug.traceback) == "function"
            and debug.traceback(tostring(error_value), 2) or tostring(error_value)
    end)
    if ok then return result ~= false end
    local details = tostring(result or "unknown QA start error")
    if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE) == "function" then
        pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE, "qa_controller.start", details)
    end
    print("[Metamorph: Creative Menu] QA start failed: " .. details)
    if type(GamePrintImportant) == "function" then
        pcall(GamePrintImportant, "Metamorph: Creative Menu QA", "START FAILED - see diagnostics log")
    end
    return false
end

function qa_controller.update()
    if qa_runner == nil then
        if not qa_key_pressed() or not actions_allowed() then return end
        local runner = load_runner()
        if runner ~= nil then start_runner(runner) end
        return
    end

    if qa_key_pressed() and actions_allowed() then
        local is_running = type(qa_runner.running) == "function" and qa_runner.running() == true
        if is_running and type(qa_runner.stop) == "function" then
            qa_runner.stop()
        elseif not is_running and type(qa_runner.start) == "function" then
            start_runner(qa_runner)
        end
        return
    end
    qa_runner.update()
end

function qa_controller.running()
    return qa_runner ~= nil and type(qa_runner.running) == "function" and qa_runner.running() == true
end

METAMORPH_CREATIVE_MENU_QA_CONTROLLER = qa_controller
return qa_controller
