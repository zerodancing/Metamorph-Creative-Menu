local root = assert(arg[1], "root required")
local native_dofile = dofile
local frame_number = 1
local real_time_seconds = 0.0
local alt_down = false
local alt_just_up = false

local keycode_stub = {
    matching_name_fragment = function(fragment)
        assert(fragment == "ALT", "input guard requested unexpected key group")
        return {56}
    end,
}
dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/platform/noita/keycodes.lua" then return keycode_stub end
    return native_dofile(path:gsub("^mods/metamorph_creative_menu/", root.."/"))
end

function GameGetFrameNum() return frame_number end
function GameGetRealWorldTimeSinceStarted() return real_time_seconds end
function InputIsKeyDown(code) return code == 56 and alt_down end
function InputIsKeyJustUp(code)
    local result = code == 56 and alt_just_up
    alt_just_up = false
    return result
end

METAMORPH_CREATIVE_MENU_INPUT_GUARD = nil
local guard = assert(native_dofile(root .. "/files/platform/noita/input_guard.lua"))
assert(guard.actions_allowed() == true, "fresh input guard unexpectedly blocked actions")

alt_down = true
frame_number = 2
real_time_seconds = 0.1
guard.update()
assert(guard.blocked() == true, "held Alt did not quarantine actions")

alt_down = false
alt_just_up = true
frame_number = 3
real_time_seconds = 0.2
guard.update()
assert(guard.resume_serial() == 1, "Alt release did not mark resume")
assert(guard.blocked() == true, "Alt release quarantine missing")

frame_number = 20
real_time_seconds = 0.5
assert(guard.actions_allowed() == true, "frame quarantine did not expire")
assert(guard.heavy_updates_allowed() == false, "heavy-work resume quarantine expired too early")

frame_number = 21
real_time_seconds = 1.1
-- 0.9 second gap since the last update at 0.2 triggers the independent focus-resume guard.
guard.update()
assert(guard.resume_serial() == 2, "real-time focus gap did not mark resume")
assert(guard.blocked() == true, "real-time focus gap did not quarantine actions")
print("input_guard=PASS alt_tab=true focus_gap=true")

-- A slow first search is not an Alt-Tab. Keyboard focus must survive a long frame.
local text_guard=native_dofile(root.."/files/platform/noita/text_entry_guard.lua")
frame_number=100; real_time_seconds=1.11; guard.update()
local serial=guard.resume_serial()
text_guard.focus("materials")
frame_number=101; real_time_seconds=2.2; guard.update()
assert(guard.resume_serial()==serial and not guard.blocked(),"first-search stall treated as focus loss")
alt_down=true; frame_number=102; guard.update()
assert(guard.blocked(),"text focus disabled explicit Alt protection")
text_guard.clear()
print("input_guard_search_stall=PASS timing_gap_keeps_focus=true explicit_alt_guard=true")
