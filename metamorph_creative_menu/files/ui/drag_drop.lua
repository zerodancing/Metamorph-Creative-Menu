if type(METAMORPH_CREATIVE_MENU_DRAG_DROP) == "table" then return METAMORPH_CREATIVE_MENU_DRAG_DROP end

local drag_drop = {}
local pointer = dofile("mods/metamorph_creative_menu/files/platform/noita/pointer.lua")

local state = nil
local targets = {}
local screen_width, screen_height = nil, nil
local last_result = nil
local DRAG_THRESHOLD = 4

local function point_inside(bounds, x, y)
    if type(bounds) ~= "table" then return false end
    return pointer.inside(bounds.x, bounds.y, bounds.width, bounds.height, x, y)
end

local function source_hit(source_bounds, clip_bounds, x, y, hovered)
    if type(source_bounds) == "table" then
        if not point_inside(source_bounds, x, y) then return false end
        if type(clip_bounds) == "table" and not point_inside(clip_bounds, x, y) then return false end
        return true
    end
    -- Backward-compatible fallback for older callers. New draggable tiles should pass
    -- their measured bounds so ownership follows the physical press origin rather than
    -- GuiGetPreviousWidgetInfo().hovered, which can change at clipping boundaries.
    return hovered == true or source_bounds == true
end

function drag_drop.begin_frame(width, height)
    screen_width, screen_height = tonumber(width), tonumber(height)
    targets = {}
    if state ~= nil then
        local x, y = pointer.gui_position(screen_width, screen_height)
        if x ~= nil then
            state.mouse_x, state.mouse_y = x, y
            if pointer.left_down() and state.start_x ~= nil then
                local dx, dy = x - state.start_x, y - state.start_y
                if dx * dx + dy * dy >= DRAG_THRESHOLD * DRAG_THRESHOLD then state.active = true end
            end
        end
    end
end

-- source_bounds is the measured tile hitbox. clip_bounds is optional and should be the
-- visible viewport when a tile is rendered inside a clipped scroll container. Once the
-- press is claimed, neither later hover state nor the source being virtualized away can
-- revoke ownership; only release/cancel can finish the gesture.
function drag_drop.source(id, payload, source_bounds, clip_bounds, hovered)
    if state ~= nil or not pointer.left_just_down() then return false end
    local x, y = pointer.gui_position(screen_width, screen_height)
    if x == nil or not source_hit(source_bounds, clip_bounds, x, y, hovered) then return false end
    state = {
        id=tostring(id or "source"), payload=payload,
        start_x=x, start_y=y, mouse_x=x, mouse_y=y, active=false,
    }
    return true
end

function drag_drop.target(id, bounds, accepts, on_drop, priority)
    if type(bounds) ~= "table" or tonumber(bounds.x) == nil or tonumber(bounds.y) == nil
        or tonumber(bounds.width) == nil or tonumber(bounds.height) == nil
    then
        return
    end
    targets[#targets + 1] = {
        id=tostring(id or "target"), bounds=bounds, accepts=accepts, on_drop=on_drop,
        priority=tonumber(priority) or 0,
    }
end

function drag_drop.active()
    return state ~= nil and state.active == true
end

function drag_drop.pending()
    return state ~= nil
end

function drag_drop.press_owned()
    return state ~= nil
end

function drag_drop.payload()
    return drag_drop.active() and state.payload or nil
end

function drag_drop.source_id()
    return state and state.id or nil
end

function drag_drop.mouse_position()
    if state ~= nil then return state.mouse_x, state.mouse_y end
    return pointer.gui_position(screen_width, screen_height)
end

function drag_drop.cancel()
    state = nil
    -- Closing, minimizing or suppressing the menu is a lifecycle boundary. A completed
    -- release that was not consumed by its source tab must not survive that boundary and
    -- execute unexpectedly when the menu is opened again.
    last_result = nil
end

function drag_drop.take_result()
    local result = last_result
    last_result = nil
    return result
end

function drag_drop.end_frame()
    if state == nil or pointer.left_down() then return nil end
    local completed = state
    state = nil
    local release_x, release_y = pointer.gui_position(screen_width, screen_height)
    local world_x, world_y = pointer.world_position()
    local release = {
        start_x=completed.start_x, start_y=completed.start_y,
        release_x=release_x, release_y=release_y,
        world_x=world_x, world_y=world_y,
    }
    if completed.active ~= true then
        last_result = {
            source=completed.id, click=true, ok=true, payload=completed.payload,
            start_x=release.start_x, start_y=release.start_y,
            release_x=release.release_x, release_y=release.release_y,
            world_x=release.world_x, world_y=release.world_y,
        }
        return last_result
    end
    local candidates = {}
    for _, target in ipairs(targets) do
        if pointer.inside(target.bounds.x, target.bounds.y, target.bounds.width, target.bounds.height, release_x, release_y) then
            local accepted = true
            if type(target.accepts) == "function" then
                local ok, value = pcall(target.accepts, completed.payload)
                accepted = ok and value == true
            end
            if accepted then candidates[#candidates + 1] = target end
        end
    end
    table.sort(candidates, function(a, b) return a.priority > b.priority end)
    local target = candidates[1]
    if target ~= nil and type(target.on_drop) == "function" then
        local ok, result, reason = pcall(target.on_drop, completed.payload)
        last_result = {
            source=completed.id, target=target.id, ok=ok and result ~= false, result=result, reason=reason, payload=completed.payload,
            start_x=release.start_x, start_y=release.start_y,
            release_x=release.release_x, release_y=release.release_y,
            world_x=release.world_x, world_y=release.world_y,
        }
    else
        last_result = {
            source=completed.id, target=nil, ok=false, reason="no_target", payload=completed.payload,
            start_x=release.start_x, start_y=release.start_y,
            release_x=release.release_x, release_y=release.release_y,
            world_x=release.world_x, world_y=release.world_y,
        }
    end
    return last_result
end

function drag_drop.last_result() return last_result end

METAMORPH_CREATIVE_MENU_DRAG_DROP = drag_drop
return drag_drop
