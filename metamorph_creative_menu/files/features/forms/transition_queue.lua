if type(METAMORPH_CREATIVE_MENU_FORM_TRANSITION_QUEUE) == "table" then
    return METAMORPH_CREATIVE_MENU_FORM_TRANSITION_QUEUE
end

local transition_queue = {}
local pending = nil
local MAX_AGE_FRAMES = 30

local function copy_options(options)
    local result = {}
    if type(options) == "table" then
        for key, value in pairs(options) do result[key] = value end
    end
    return result
end

function transition_queue.schedule(entity_path, frames, options, requested_frame)
    pending = {
        entity_path = entity_path,
        frames = frames,
        options = copy_options(options),
        requested_frame = tonumber(requested_frame) or 0,
        human_frame = nil,
    }
    return true
end

local function expired(frame)
    if pending == nil then return false end
    local now = tonumber(frame)
    if now == nil then return false end
    local requested = tonumber(pending.requested_frame) or now
    return now - requested > MAX_AGE_FRAMES
end

function transition_queue.expire(frame)
    if not expired(frame) then return false end
    pending = nil
    return true
end

function transition_queue.has_pending()
    return pending ~= nil
end

function transition_queue.mark_human(frame)
    if pending == nil then return false end
    if pending.human_frame == nil then pending.human_frame = tonumber(frame) or 0 end
    return true
end

function transition_queue.ready(frame)
    if transition_queue.expire(frame) then return false end
    return pending ~= nil
        and pending.human_frame ~= nil
        and (tonumber(frame) or 0) > pending.human_frame
end

function transition_queue.take(frame)
    if not transition_queue.ready(frame) then return nil end
    local request = pending
    pending = nil
    return request
end

function transition_queue.clear()
    local had_pending = pending ~= nil
    pending = nil
    return had_pending
end

function transition_queue.peek()
    return pending
end

transition_queue.MAX_AGE_FRAMES = MAX_AGE_FRAMES

METAMORPH_CREATIVE_MENU_FORM_TRANSITION_QUEUE = transition_queue
return transition_queue
