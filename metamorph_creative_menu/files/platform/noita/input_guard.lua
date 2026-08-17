if type(METAMORPH_CREATIVE_MENU_INPUT_GUARD) == "table" then return METAMORPH_CREATIVE_MENU_INPUT_GUARD end

local input_guard = {}
local keycodes = dofile("mods/metamorph_creative_menu/files/platform/noita/keycodes.lua")

local alt_key_codes = nil
local alt_was_down = false
local action_quarantine_until_frame = -1
local previous_real_time_seconds = nil
local resume_serial = 0
local heavy_work_quarantine_until_seconds = -1
local last_resume_mark_frame = -100000

local ALT_HELD_QUARANTINE_FRAMES = 8
local ALT_RELEASE_QUARANTINE_FRAMES = 12
local FOCUS_RESUME_QUARANTINE_FRAMES = 18
local FOCUS_GAP_SECONDS = 0.35
local ALT_RESUME_HEAVY_QUARANTINE_SECONDS = 0.75
local FOCUS_RESUME_HEAVY_QUARANTINE_SECONDS = 1.5

local function get_alt_key_codes()
    if alt_key_codes == nil then alt_key_codes = keycodes.matching_name_fragment("ALT") end
    return alt_key_codes
end

local function any_alt_down()
    for _, key_code in ipairs(get_alt_key_codes()) do
        local read_succeeded, is_down = pcall(InputIsKeyDown, key_code)
        if read_succeeded and is_down == true then return true end
    end
    return false
end

local function any_alt_just_up()
    for _, key_code in ipairs(get_alt_key_codes()) do
        local read_succeeded, was_released = pcall(InputIsKeyJustUp, key_code)
        if read_succeeded and was_released == true then return true end
    end
    return false
end

local function quarantine_actions(frame_number, quarantine_frames)
    action_quarantine_until_frame = math.max(
        action_quarantine_until_frame,
        frame_number + (tonumber(quarantine_frames) or ALT_RELEASE_QUARANTINE_FRAMES)
    )
end

local function mark_resume(frame_number, real_time_seconds, heavy_quarantine_seconds)
    if frame_number ~= last_resume_mark_frame then
        resume_serial = resume_serial + 1
        last_resume_mark_frame = frame_number
    end
    if type(real_time_seconds) == "number" then
        heavy_work_quarantine_until_seconds = math.max(
            heavy_work_quarantine_until_seconds,
            real_time_seconds + (tonumber(heavy_quarantine_seconds) or ALT_RESUME_HEAVY_QUARANTINE_SECONDS)
        )
    end
end

function input_guard.update()
    local frame_number = GameGetFrameNum()
    local alt_is_down = any_alt_down()

    -- This catches the common Alt-Tab path even if the engine reports the Alt key
    -- release only after focus returns.
    if alt_is_down then
        quarantine_actions(frame_number, ALT_HELD_QUARANTINE_FRAMES)
    elseif alt_was_down or any_alt_just_up() then
        quarantine_actions(frame_number, ALT_RELEASE_QUARANTINE_FRAMES)
        local time_read_succeeded, real_time_seconds = pcall(GameGetRealWorldTimeSinceStarted)
        mark_resume(
            frame_number,
            time_read_succeeded and real_time_seconds or nil,
            ALT_RESUME_HEAVY_QUARANTINE_SECONDS
        )
    end
    alt_was_down = alt_is_down

    -- Focus can be lost before an in-game update observes Alt. Real-world time continues
    -- while updates are suspended, so a discontinuity is a key-independent resume guard.
    local time_read_succeeded, real_time_seconds = pcall(GameGetRealWorldTimeSinceStarted)
    if time_read_succeeded and type(real_time_seconds) == "number" then
        if previous_real_time_seconds ~= nil and real_time_seconds - previous_real_time_seconds > FOCUS_GAP_SECONDS then
            quarantine_actions(frame_number, FOCUS_RESUME_QUARANTINE_FRAMES)
            mark_resume(frame_number, real_time_seconds, FOCUS_RESUME_HEAVY_QUARANTINE_SECONDS)
        end
        previous_real_time_seconds = real_time_seconds
    end
end

function input_guard.actions_allowed()
    return not alt_was_down and GameGetFrameNum() > action_quarantine_until_frame
end

function input_guard.blocked()
    return not input_guard.actions_allowed()
end

function input_guard.resume_serial()
    return resume_serial
end

function input_guard.heavy_updates_allowed()
    if not input_guard.actions_allowed() then return false end
    local time_read_succeeded, real_time_seconds = pcall(GameGetRealWorldTimeSinceStarted)
    if time_read_succeeded and type(real_time_seconds) == "number"
        and real_time_seconds < heavy_work_quarantine_until_seconds
    then
        return false
    end
    return true
end

METAMORPH_CREATIVE_MENU_INPUT_GUARD = input_guard
return input_guard
