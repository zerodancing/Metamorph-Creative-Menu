if type(METAMORPH_CREATIVE_MENU_HORIZONTAL_STRIP) == "table" then return METAMORPH_CREATIVE_MENU_HORIZONTAL_STRIP end

local horizontal_strip = {}
local pointer = dofile("mods/metamorph_creative_menu/files/platform/noita/pointer.lua")
local scroll_model = dofile("mods/metamorph_creative_menu/files/ui/widgets/scroll_model.lua")

local states = {}

local function state_for(key)
    key = tostring(key or "strip")
    local state = states[key]
    if state == nil then
        state = { offset=0 }
        states[key] = state
    end
    return state
end

function horizontal_strip.reset(key)
    if key == nil then states = {} else states[tostring(key)] = nil end
end

-- A slot strip is intentionally not a GuiBeginScrollContainer: Noita only exposes a
-- vertical scrollbar there. We render a bounded window and change its first logical item
-- only from the shared wheel input. LMB remains unambiguously reserved for slot selection
-- and spell drag-and-drop, so the strip cannot steal a card press.
function horizontal_strip.draw(key, count, viewport_width, step, draw_item, options)
    options = type(options) == "table" and options or {}
    count = math.max(0, math.floor(tonumber(count) or 0))
    step = math.max(1, tonumber(step) or 20)
    viewport_width = math.max(step, tonumber(viewport_width) or step)
    local visible_count = math.max(1, math.floor(viewport_width / step))
    local maximum_offset = math.max(0, count - visible_count)
    local state = state_for(key)
    state.offset = math.max(0, math.min(math.floor(tonumber(state.offset) or 0), maximum_offset))

    local clicked_index, right_index = nil, nil
    local first_x, first_y, last_x, last_y = nil, nil, nil, nil
    local first = state.offset
    local last = math.min(count - 1, first + visible_count - 1)

    GuiLayoutBeginHorizontal(options.gui, 0, 0, true, 0, 0)
    for index = first, last do
        local clicked, right, _, x, y, width, height = draw_item(index)
        x, y, width, height = tonumber(x), tonumber(y), tonumber(width), tonumber(height)
        if x ~= nil and y ~= nil and width ~= nil and height ~= nil then
            first_x = first_x == nil and x or math.min(first_x, x)
            first_y = first_y == nil and y or math.min(first_y, y)
            last_x = last_x == nil and (x + width) or math.max(last_x, x + width)
            last_y = last_y == nil and (y + height) or math.max(last_y, y + height)
        end
        if clicked == true then clicked_index = index end
        if right == true then right_index = index end
    end
    GuiLayoutEnd(options.gui)

    local hovered = false
    local mouse_x, mouse_y = pointer.gui_position(options.screen_width, options.screen_height)
    if first_x ~= nil then
        hovered = pointer.inside(first_x, first_y, last_x - first_x, last_y - first_y, mouse_x, mouse_y)
    end

    if hovered then
        local wheel = scroll_model.consume_wheel("horizontal:" .. tostring(key), true)
        if wheel ~= 0 then
            state.offset = select(1, scroll_model.horizontal_offset(state.offset, count, visible_count, wheel,
                options.wheel_step or scroll_model.HORIZONTAL_STEP))
        end
    end

    return {
        clicked=clicked_index,
        right_clicked=right_index,
        offset=state.offset,
        visible_count=visible_count,
        first=first,
        last=last,
        total=count,
        hovered=hovered,
        bounds=first_x and {x=first_x,y=first_y,width=last_x-first_x,height=last_y-first_y} or nil,
    }
end

METAMORPH_CREATIVE_MENU_HORIZONTAL_STRIP = horizontal_strip
return horizontal_strip
