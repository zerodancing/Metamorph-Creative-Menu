if type(METAMORPH_CREATIVE_MENU_HORIZONTAL_STRIP) == "table" then return METAMORPH_CREATIVE_MENU_HORIZONTAL_STRIP end

local horizontal_strip = {}
local pointer = dofile("mods/metamorph_creative_menu/files/platform/noita/pointer.lua")

local states = {}
local fallback_widget_id = 610000
local ARROW_LEFT = "mods/metamorph_creative_menu/files/ui/assets/page_left.png"
local ARROW_RIGHT = "mods/metamorph_creative_menu/files/ui/assets/page_right.png"

local function next_id(options)
    if type(options.next_id) == "function" then return options.next_id() end
    fallback_widget_id = fallback_widget_id + 1
    return fallback_widget_id
end

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

-- Pagination stays in the same row as the slots. No native scroll container, wheel
-- ownership or extra navigation row is involved.
function horizontal_strip.draw(key, count, viewport_width, step, draw_item, options)
    options = type(options) == "table" and options or {}
    count = math.max(0, math.floor(tonumber(count) or 0))
    step = math.max(1, tonumber(step) or 20)
    viewport_width = math.max(step, tonumber(viewport_width) or step)
    local unpaged_visible_count = math.max(1, math.floor(viewport_width / step))
    local paged = count > unpaged_visible_count
    local arrow_reserve = paged and 22 or 0
    local visible_count = math.max(1, math.floor(math.max(step, viewport_width - arrow_reserve) / step))
    local maximum_offset = math.max(0, count - visible_count)
    local state = state_for(key)
    state.offset = math.max(0, math.min(math.floor(tonumber(state.offset) or 0), maximum_offset))

    local clicked_index, right_index = nil, nil
    local first_x, first_y, last_x, last_y = nil, nil, nil, nil
    local first = state.offset
    local last = math.min(count - 1, first + visible_count - 1)

    GuiLayoutBeginHorizontal(options.gui, 0, 0, true, 0, 0)
    if paged then
        -- A single tall, thick image-arrow is easier to see than text chevrons while
        -- reserving less horizontal room for navigation.
        GuiColorSetForNextWidget(options.gui, 1, 1, 1, 1)
        GuiZSetForNextWidget(options.gui, -112)
        local previous = select(1, GuiImageButton(options.gui, next_id(options), 0, 0, "", ARROW_LEFT))
        if previous then
            state.offset = math.max(0, state.offset - visible_count)
            first = state.offset
            last = math.min(count - 1, first + visible_count - 1)
        end
    end
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
    if paged then
        GuiColorSetForNextWidget(options.gui, 1, 1, 1, 1)
        GuiZSetForNextWidget(options.gui, -112)
        local following = select(1, GuiImageButton(options.gui, next_id(options), 0, 0, "", ARROW_RIGHT))
        if following then state.offset = math.min(maximum_offset, state.offset + visible_count) end
    end
    GuiLayoutEnd(options.gui)

    local hovered = false
    local mouse_x, mouse_y = pointer.gui_position(options.screen_width, options.screen_height)
    if first_x ~= nil then
        hovered = pointer.inside(first_x, first_y, last_x - first_x, last_y - first_y, mouse_x, mouse_y)
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
