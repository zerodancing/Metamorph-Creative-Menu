if type(METAMORPH_CREATIVE_MENU_SCROLL_MODEL) == "table" then return METAMORPH_CREATIVE_MENU_SCROLL_MODEL end

local scroll_model = {}
local pointer = dofile("mods/metamorph_creative_menu/files/platform/noita/pointer.lua")

scroll_model.VERTICAL_STEP = 20
scroll_model.HORIZONTAL_STEP = 3
scroll_model.SCROLLBAR_WIDTH = 8
scroll_model.PADDING_X = 2
scroll_model.PADDING_Y = 2

local wheel_delta = nil
local wheel_owner = nil
local wheel_delivered = false

local function clamp(value, minimum, maximum)
    value = tonumber(value) or 0
    minimum = tonumber(minimum) or 0
    maximum = math.max(minimum, tonumber(maximum) or minimum)
    return math.max(minimum, math.min(maximum, value))
end

function scroll_model.begin_frame()
    wheel_delta = nil
    wheel_owner = nil
    wheel_delivered = false
end

local function current_wheel()
    if wheel_delta == nil then wheel_delta = pointer.wheel_delta() end
    return tonumber(wheel_delta) or 0
end

-- Wheel ownership is deliberately first-claim within the rendered hierarchy. Nested
-- horizontal strips and nested viewports finish before their parent viewport, so the
-- child consumes the tick and the parent sees zero for the same physical event.
function scroll_model.consume_wheel(owner, hovered)
    local delta = current_wheel()
    if delta == 0 or hovered ~= true then return 0 end
    owner = tostring(owner or "scroll")
    if wheel_owner == nil then wheel_owner = owner end
    if wheel_owner ~= owner or wheel_delivered then return 0 end
    wheel_delivered = true
    return delta
end

function scroll_model.scroll_offset(offset, content_height, viewport_height, wheel, step)
    viewport_height = math.max(1, tonumber(viewport_height) or 1)
    content_height = math.max(0, tonumber(content_height) or 0)
    local maximum = math.max(0, content_height - viewport_height)
    local next_offset = clamp(offset, 0, maximum)
    wheel = tonumber(wheel) or 0
    step = math.max(1, tonumber(step) or scroll_model.VERTICAL_STEP)
    if wheel ~= 0 then next_offset = clamp(next_offset + wheel * step, 0, maximum) end
    return next_offset, maximum
end

function scroll_model.horizontal_offset(offset, count, visible_count, wheel, step)
    count = math.max(0, math.floor(tonumber(count) or 0))
    visible_count = math.max(1, math.floor(tonumber(visible_count) or 1))
    local maximum = math.max(0, count - visible_count)
    local next_offset = clamp(math.floor(tonumber(offset) or 0), 0, maximum)
    wheel = tonumber(wheel) or 0
    step = math.max(1, math.floor(tonumber(step) or scroll_model.HORIZONTAL_STEP))
    if wheel ~= 0 then next_offset = clamp(next_offset + wheel * step, 0, maximum) end
    return next_offset, maximum
end

function scroll_model.grid_metrics(container_width, step, options)
    options = type(options) == "table" and options or {}
    container_width = math.max(1, tonumber(container_width) or 1)
    step = math.max(1, tonumber(step) or 20)
    local padding_left = math.max(0, tonumber(options.padding_left) or scroll_model.PADDING_X)
    local padding_right = math.max(0, tonumber(options.padding_right) or scroll_model.PADDING_X)
    local scrollbar_width = options.reserve_scrollbar == false and 0
        or math.max(0, tonumber(options.scrollbar_width) or scroll_model.SCROLLBAR_WIDTH)
    local content_width = math.max(step, container_width - padding_left - padding_right - scrollbar_width)
    local columns = math.max(1, math.floor(content_width / step))
    local grid_width = columns * step
    return {
        container_width=container_width,
        content_width=content_width,
        columns=columns,
        grid_width=grid_width,
        step=step,
        padding_left=padding_left,
        padding_right=padding_right,
        scrollbar_width=scrollbar_width,
        remainder=math.max(0, content_width - grid_width),
    }
end

METAMORPH_CREATIVE_MENU_SCROLL_MODEL = scroll_model
return scroll_model
