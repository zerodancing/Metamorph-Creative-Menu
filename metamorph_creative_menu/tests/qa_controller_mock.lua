local root = assert(arg[1], "root required")
local real_dofile = dofile
local key_down = false
local runner_loads = 0
local runner_starts = 0
local runner_updates = 0
local runner_stops = 0
local running = false
local start_should_error = false
local captured_error = nil
local important_message = nil

Key_z = 90
function dofile_once(_) return true end
function InputIsKeyJustDown(code) return code == 90 and key_down end
function GameIsInventoryOpen() return false end
function print(_) end
function GamePrintImportant(title,message) important_message=tostring(title)..":"..tostring(message) end
METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE=function(source,details) captured_error=tostring(source)..":"..tostring(details) end

local input_guard = { actions_allowed = function() return true end }
local runner = {
    start = function() runner_starts = runner_starts + 1; if start_should_error then error("mock_start_failure") end; running = true; return true end,
    stop = function() runner_stops = runner_stops + 1; running = false; return true end,
    update = function() runner_updates = runner_updates + 1 end,
    running = function() return running end,
}

dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/platform/noita/input_guard.lua" then return input_guard end
    if path == "mods/metamorph_creative_menu/files/platform/noita/keycodes.lua" then return { resolve=function() return 90 end } end
    if path == "mods/metamorph_creative_menu/files/qa/runner.lua" then
        runner_loads = runner_loads + 1
        return runner
    end
    return real_dofile(path)
end

local controller = real_dofile(root .. "/files/qa/controller.lua")
controller.update()
assert(runner_loads == 0, "QA runner loaded during normal gameplay")

key_down = true
controller.update()
assert(runner_loads == 1, "QA runner was not loaded on Z")
assert(runner_starts == 1, "QA runner did not start on first Z")
assert(runner_updates == 0, "new runner should not process the same key twice")

key_down = false
controller.update()
assert(runner_loads == 1, "QA runner loaded more than once")
assert(runner_updates == 1, "loaded QA runner did not receive updates")

key_down = true
controller.update()
assert(runner_stops == 1 and running == false, "second Z did not stop active QA")
key_down = false
controller.update()
assert(runner_updates == 2, "stopped loaded runner did not receive harmless idle update")
key_down = true
controller.update()
assert(runner_starts == 2 and running == true, "Z did not restart an already-loaded QA runner")

-- A startup exception must never leave the user with only a silent diagnostic scan.
key_down=false; controller.update()
key_down=true; controller.update() -- stop the running third session
assert(running==false,"precondition: QA did not stop")
key_down=false; controller.update()
start_should_error=true; key_down=true; controller.update()
assert(running==false,"failed QA start incorrectly marked running")
assert(captured_error and string.find(captured_error,"qa_controller.start",1,true),"QA start exception was not captured")
assert(important_message and string.find(important_message,"START FAILED",1,true),"QA start failure was not visible to user")
print("qa_controller_lazy_load=PASS start_failure_visible=true")
