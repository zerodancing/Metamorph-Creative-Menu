if type(METAMORPH_CREATIVE_MENU_TEXT_ENTRY_GUARD) == "table" then
    return METAMORPH_CREATIVE_MENU_TEXT_ENTRY_GUARD
end

-- Single keyboard-focus owner shared by editable UI fields and the input layers that
-- must suppress gameplay/hotkeys while typing. Runtime widgets own focus transitions;
-- consumers only query active()/key(). A blur callback lets stateful editors resolve
-- an unfinished draft even when the focused widget disappears on a tab/context switch.
local guard = {}
local active_key = nil
local blur_callback = nil

local function normalized_key(key)
    key = tostring(key or "")
    return key ~= "" and key or "text"
end

local function invoke_blur(callback, reason, key)
    if type(callback) == "function" then pcall(callback, reason or "blur", key) end
end

function guard.focus(key, on_blur)
    key = normalized_key(key)
    if active_key ~= nil and active_key ~= key then
        local previous_key, previous_callback = active_key, blur_callback
        active_key, blur_callback = nil, nil
        invoke_blur(previous_callback, "replaced", previous_key)
    end
    active_key = key
    blur_callback = type(on_blur) == "function" and on_blur or nil
    return active_key
end

function guard.set_blur_callback(key, on_blur)
    if active_key ~= normalized_key(key) then return false end
    blur_callback = type(on_blur) == "function" and on_blur or nil
    return true
end

function guard.clear(key, reason)
    if key ~= nil and active_key ~= normalized_key(key) then return false end
    if active_key == nil then return false end
    local previous_key, previous_callback = active_key, blur_callback
    active_key, blur_callback = nil, nil
    invoke_blur(previous_callback, reason or "blur", previous_key)
    return true
end

function guard.active()
    return active_key ~= nil
end

function guard.key()
    return active_key
end

METAMORPH_CREATIVE_MENU_TEXT_ENTRY_GUARD = guard
return guard
