if type(METAMORPH_CREATIVE_MENU_WAND_HISTORY) == "table" then return METAMORPH_CREATIVE_MENU_WAND_HISTORY end

local history = {}
local blueprints = dofile("mods/metamorph_creative_menu/files/features/wands/blueprints.lua")
local codec = dofile("mods/metamorph_creative_menu/files/core/wand_blueprint_codec.lua")

local states = {}
local state_order = {}
local HISTORY_LIMIT = 30
local WAND_STATE_LIMIT = 16

local function touch_key(key)
    for index = #state_order, 1, -1 do
        if state_order[index] == key then table.remove(state_order, index); break end
    end
    state_order[#state_order + 1] = key
    while #state_order > WAND_STATE_LIMIT do
        local oldest = table.remove(state_order, 1)
        states[oldest] = nil
    end
end

local function state_for(wand)
    local key = tonumber(wand) or 0
    local state = states[key]
    if state == nil then
        state = {undo={}, redo={}}
        states[key] = state
    end
    touch_key(key)
    return state
end

local function frame_now()
    if type(GameGetFrameNum) == "function" then
        local ok, value = pcall(GameGetFrameNum)
        if ok then return tonumber(value) or 0 end
    end
    return 0
end

local function push_bounded(list, value)
    list[#list + 1] = value
    while #list > HISTORY_LIMIT do table.remove(list, 1) end
end

-- History is intentionally scoped to mutations whose complete state lives inside the wand.
-- Moving a card to world/player inventory needs a command-specific inverse; snapshot undo
-- alone would recreate the card in the wand without reclaiming the external entity.
function history.perform(player, wand, label, callback, options)
    if type(callback) ~= "function" then return false, "missing_callback" end
    local before, reason = blueprints.capture(wand)
    if before == nil then return false, reason end

    local call = {pcall(callback)}
    local call_ok = table.remove(call, 1)
    if not call_ok then return false, "operation_error" end
    if call[1] == false then return unpack(call) end

    local after = select(1, blueprints.capture(wand))
    if after == nil then return unpack(call) end
    if codec.encode(before) == codec.encode(after) then return unpack(call) end

    options = type(options) == "table" and options or {}
    local state = state_for(wand)
    local now = frame_now()
    local coalesce_key = options.coalesce_key
    local last = state.undo[#state.undo]
    if coalesce_key ~= nil and last ~= nil and last.coalesce_key == coalesce_key
        and now - (last.frame or 0) <= math.max(1, tonumber(options.coalesce_frames) or 30)
    then
        last.after, last.frame, last.label = after, now, tostring(label or last.label or "edit")
    else
        push_bounded(state.undo, {
            before=before, after=after, label=tostring(label or "edit"),
            coalesce_key=coalesce_key, frame=now,
        })
    end
    state.redo = {}
    return unpack(call)
end

function history.can_undo(wand) return #state_for(wand).undo > 0 end
function history.can_redo(wand) return #state_for(wand).redo > 0 end

function history.undo_label(wand)
    local record = state_for(wand).undo[#state_for(wand).undo]
    return record and record.label or nil
end

function history.redo_label(wand)
    local record = state_for(wand).redo[#state_for(wand).redo]
    return record and record.label or nil
end

function history.undo(player, wand)
    local state = state_for(wand)
    local record = state.undo[#state.undo]
    if record == nil then return false, "empty" end
    local ok, reason = blueprints.apply(player, wand, record.before)
    if not ok then return false, reason end
    table.remove(state.undo)
    push_bounded(state.redo, record)
    return true, record.label
end

function history.redo(player, wand)
    local state = state_for(wand)
    local record = state.redo[#state.redo]
    if record == nil then return false, "empty" end
    local ok, reason = blueprints.apply(player, wand, record.after)
    if not ok then return false, reason end
    table.remove(state.redo)
    push_bounded(state.undo, record)
    return true, record.label
end

function history.clear(wand)
    if wand == nil then
        states, state_order = {}, {}
        return
    end
    local key = tonumber(wand) or 0
    states[key] = nil
    for index = #state_order, 1, -1 do
        if state_order[index] == key then table.remove(state_order, index) end
    end
end

METAMORPH_CREATIVE_MENU_WAND_HISTORY = history
return history
