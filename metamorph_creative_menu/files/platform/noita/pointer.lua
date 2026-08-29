if type(METAMORPH_CREATIVE_MENU_POINTER) == "table" then return METAMORPH_CREATIVE_MENU_POINTER end

local pointer = {}

local function magic_number(name)
    if type(MagicNumbersGetValue) ~= "function" then return nil end
    local ok, value = pcall(MagicNumbersGetValue, name)
    return ok and tonumber(value) or nil
end

function pointer.gui_position(screen_width, screen_height)
    screen_width, screen_height = tonumber(screen_width), tonumber(screen_height)
    if screen_width ~= nil and screen_height ~= nil
        and type(DEBUG_GetMouseWorld) == "function" and type(GameGetCameraPos) == "function"
    then
        local ok_mouse, world_x, world_y = pcall(DEBUG_GetMouseWorld)
        local ok_camera, camera_x, camera_y = pcall(GameGetCameraPos)
        local virtual_width = magic_number("VIRTUAL_RESOLUTION_X")
        local virtual_offset = magic_number("VIRTUAL_RESOLUTION_OFFSET_X") or 0
        virtual_width = virtual_width ~= nil and virtual_width + virtual_offset or nil
        if ok_mouse and ok_camera and tonumber(world_x) ~= nil and tonumber(world_y) ~= nil
            and tonumber(camera_x) ~= nil and tonumber(camera_y) ~= nil
            and virtual_width ~= nil and virtual_width > 0
        then
            local scale = screen_width / virtual_width
            return screen_width * 0.5 + (world_x - camera_x) * scale,
                screen_height * 0.5 + (world_y - camera_y) * scale
        end
    end
    if type(InputGetMousePosOnScreen) == "function" then
        local ok, mouse_x, mouse_y = pcall(InputGetMousePosOnScreen)
        if ok and tonumber(mouse_x) ~= nil and tonumber(mouse_y) ~= nil then
            return tonumber(mouse_x), tonumber(mouse_y)
        end
    end
    return nil, nil
end

function pointer.world_position()
    if type(DEBUG_GetMouseWorld) ~= "function" then return nil, nil end
    local ok, world_x, world_y = pcall(DEBUG_GetMouseWorld)
    if not ok or tonumber(world_x) == nil or tonumber(world_y) == nil then return nil, nil end
    return tonumber(world_x), tonumber(world_y)
end

local function mouse_code(...)
    for index = 1, select("#", ...) do
        local value = rawget(_G, select(index, ...))
        if tonumber(value) ~= nil then return tonumber(value) end
    end
    return nil
end

local function button_down(default_code, ...)
    if type(InputIsMouseButtonDown) ~= "function" then return false end
    local code = mouse_code(...) or default_code
    local ok, result = pcall(InputIsMouseButtonDown, code)
    return ok and result == true
end

local function button_just_down(default_code, ...)
    if type(InputIsMouseButtonJustDown) ~= "function" then return false end
    local code = mouse_code(...) or default_code
    local ok, result = pcall(InputIsMouseButtonJustDown, code)
    return ok and result == true
end

function pointer.left_down() return button_down(1, "Mouse_left", "MOUSE_LEFT") end
function pointer.left_just_down() return button_just_down(1, "Mouse_left", "MOUSE_LEFT") end
function pointer.right_down() return button_down(2, "Mouse_right", "MOUSE_RIGHT") end

function pointer.wheel_delta()
    if type(InputIsMouseButtonJustDown) ~= "function" then return 0 end
    local ok_up, up = pcall(InputIsMouseButtonJustDown, 4)
    local ok_down, down = pcall(InputIsMouseButtonJustDown, 5)
    if ok_up and up == true then return -1 end
    if ok_down and down == true then return 1 end
    return 0
end

function pointer.inside(x, y, width, height, mouse_x, mouse_y)
    x, y, width, height = tonumber(x), tonumber(y), tonumber(width), tonumber(height)
    mouse_x, mouse_y = tonumber(mouse_x), tonumber(mouse_y)
    return x ~= nil and y ~= nil and width ~= nil and height ~= nil and mouse_x ~= nil and mouse_y ~= nil
        and mouse_x >= x and mouse_x <= x + width and mouse_y >= y and mouse_y <= y + height
end

METAMORPH_CREATIVE_MENU_POINTER = pointer
return pointer
