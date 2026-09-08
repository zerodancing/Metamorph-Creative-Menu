if type(METAMORPH_CREATIVE_MENU_GAMEPLAY_INPUT) == "table" then
    return METAMORPH_CREATIVE_MENU_GAMEPLAY_INPUT
end

local gameplay_input = {}
local input_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/input_guard.lua")

local ui_blocked = false
local release_latches = { primary=false, secondary=false }
local previous = { primary=false, secondary=false }

local function mouse_code(surface)
    if surface == "secondary" then
        return tonumber(rawget(_G, "Mouse_right")) or tonumber(rawget(_G, "MOUSE_RIGHT")) or 2
    end
    return tonumber(rawget(_G, "Mouse_left")) or tonumber(rawget(_G, "MOUSE_LEFT")) or 1
end

local function inventory_open()
    if type(GameIsInventoryOpen) ~= "function" then return false end
    local ok, value = pcall(GameIsInventoryOpen)
    return ok and value == true
end

local function raw_mouse_down(surface)
    if type(InputIsMouseButtonDown) ~= "function" then return false end
    local ok, down = pcall(InputIsMouseButtonDown, mouse_code(surface))
    return ok and down == true
end

local function controls_down(controls, surface)
    if controls == nil or controls == 0 or type(ComponentGetValue2) ~= "function" then return false end
    local field = surface == "secondary" and "mButtonDownFire2" or "mButtonDownFire"
    local ok, down = pcall(ComponentGetValue2, controls, field)
    return ok and down == true
end

local function input_allowed()
    if ui_blocked or inventory_open() then return false end
    if type(input_guard.actions_allowed) == "function" and input_guard.actions_allowed() ~= true then return false end
    return true
end

local function combined_down(controls, surface)
    if not input_allowed() then return false end
    return controls_down(controls, surface) or raw_mouse_down(surface)
end

function gameplay_input.set_ui_blocked(blocked)
    ui_blocked = blocked == true
    if ui_blocked then
        -- A mouse press used inside MCM must never become a gameplay edge when the menu
        -- closes or a polymorph swaps the ControlsComponent under that same held click.
        release_latches.primary = true
        release_latches.secondary = true
        previous.primary = false
        previous.secondary = false
    end
end

function gameplay_input.ui_blocked()
    return ui_blocked
end

function gameplay_input.require_release(surface)
    surface = surface == "secondary" and "secondary" or "primary"
    release_latches[surface] = true
    previous[surface] = false
end

function gameplay_input.down(controls, surface)
    surface = surface == "secondary" and "secondary" or "primary"
    local down = combined_down(controls, surface)
    if release_latches[surface] then
        if not down then release_latches[surface] = false end
        return false
    end
    return down
end

function gameplay_input.just_pressed(controls, surface)
    surface = surface == "secondary" and "secondary" or "primary"
    local down = gameplay_input.down(controls, surface)
    local pressed = down and not previous[surface]
    previous[surface] = down
    return pressed
end

function gameplay_input.reset()
    release_latches.primary = false
    release_latches.secondary = false
    previous.primary = false
    previous.secondary = false
end

METAMORPH_CREATIVE_MENU_GAMEPLAY_INPUT = gameplay_input
return gameplay_input
