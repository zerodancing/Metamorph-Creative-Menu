local root = assert(arg[1], "root required")
local native_dofile = dofile

-- First keep the existing manager-level regression for input quarantine and polymorph expiry.
local player_entity_id = 1
local polymorph_component_id = 77
local component_frames = 120
local tab_pressed = false
local current_frame = 42

function ModTextFileGetContent(path)
    if path == "data/scripts/debug/keycodes.lua" then return "Key_TAB = 9\n" end
    return ""
end
function InputIsKeyJustDown(key_code) return key_code == 9 and tab_pressed end
function GameGetFrameNum() return current_frame end
function GameGetGameEffect(entity, effect_name)
    if entity == player_entity_id and effect_name == "POLYMORPH" then return polymorph_component_id end
    return 0
end
function ComponentSetValue2(component_id, field_name, value)
    if component_id == polymorph_component_id and field_name == "frames" then component_frames = value end
end
function EntityGetFirstComponentIncludingDisabled() return 0 end
function EntityGetIsAlive(entity) return entity == player_entity_id end
function EntityHasTag() return false end
function ModDoesFileExist() return false end
function print(_) end

local dependency_stubs = {
    ["mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua"] = {get=function() return nil end},
    ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"] = {get=function() return player_entity_id end},
    ["mods/metamorph_creative_menu/files/core/hash.lua"] = {hex64=function(value) return tostring(value) end},
    ["mods/metamorph_creative_menu/files/core/xml_utils.lua"] = native_dofile(root .. "/files/core/xml_utils.lua"),
    ["mods/metamorph_creative_menu/files/features/forms/profile.lua"] = {},
    ["mods/metamorph_creative_menu/files/features/forms/runtime.lua"] = {reset=function() end},
}
dofile = function(path)
    if dependency_stubs[path] ~= nil then return dependency_stubs[path] end
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path, 1, #prefix) == prefix then return native_dofile(root .. "/" .. string.sub(path, #prefix + 1)) end
    return native_dofile(path)
end

local form_manager = native_dofile(root .. "/files/features/forms/manager.lua")
tab_pressed = true
assert(form_manager.handle_tab_return(true) == false, "Alt-Tab/input quarantine triggered form return")
assert(component_frames == 120, "blocked TAB modified polymorph effect")
assert(form_manager.handle_tab_return(false) == true, "TAB did not return active polymorph form")
assert(component_frames == 1, "TAB did not expire polymorph effect")

-- Then load the real init.lua with orchestration dependencies stubbed. This catches the
-- F4/open-menu regression that a manager-only test cannot observe.
local state = {
    menu_open = false,
    has_form = false,
    input_blocked = false,
    return_pressed = false,
    consume_counts = {},
    handle_calls = {},
    draw_calls = 0,
    painter_disable_calls = 0,
}

local function reset(overrides)
    state.menu_open = false
    state.has_form = false
    state.input_blocked = false
    state.return_pressed = false
    state.consume_counts = {}
    state.handle_calls = {}
    state.draw_calls = 0
    state.painter_disable_calls = 0
    for key, value in pairs(overrides or {}) do state[key] = value end
end

local function noop() end
local localization = {translate = function(_, fallback) return fallback end}
local input_guard = {update = noop, blocked = function() return state.input_blocked end}
local action_bindings = {
    update = noop,
    consume = function(action)
        state.consume_counts[action] = (state.consume_counts[action] or 0) + 1
        if action == "return_human" then return state.return_pressed end
        return false
    end,
}
local init_form_manager = {
    current_player = function() return 1 end,
    update = noop,
    has_active_form = function() return state.has_form end,
    handle_tab_return = function(blocked, pressed)
        state.handle_calls[#state.handle_calls + 1] = {blocked = blocked, pressed = pressed}
        return blocked ~= true and pressed == true
    end,
}
local weather = {update = noop, release = noop}
local world_rules = {update = noop, reset = noop, post_update = noop}
local menu_controller = {
    is_open = function() return state.menu_open end,
    draw = function() state.draw_calls = state.draw_calls + 1 end,
}
local keybinds = {update = noop}
local ew_resilience = {pre_init = noop, post_init = function() return 0, 0, 0 end}
local perk_service = {update = noop}
local effect_service = {update = noop, remove_all = noop}
local player_avatar = {update = noop}
local material_painter = {
    update = noop,
    adjust_brush = noop,
    is_enabled = function() return false end,
    set_enabled = function(enabled)
        if enabled == false then state.painter_disable_calls = state.painter_disable_calls + 1 end
        return true
    end,
}
local player_tools = {update = noop, visible_players = function() return {} end, teleport_to = noop}

local init_modules = {
    ["mods/metamorph_creative_menu/dev_mode.lua"] = 0,
    ["mods/metamorph_creative_menu/files/platform/noita/localization.lua"] = localization,
    ["mods/metamorph_creative_menu/files/platform/noita/input_guard.lua"] = input_guard,
    ["mods/metamorph_creative_menu/files/platform/noita/action_bindings.lua"] = action_bindings,
    ["mods/metamorph_creative_menu/files/features/forms/manager.lua"] = init_form_manager,
    ["mods/metamorph_creative_menu/files/features/weather/service.lua"] = weather,
    ["mods/metamorph_creative_menu/files/features/world_rules/service.lua"] = world_rules,
    ["mods/metamorph_creative_menu/files/ui/menu_controller.lua"] = menu_controller,
    ["mods/metamorph_creative_menu/files/features/possession/keybinds.lua"] = keybinds,
    ["mods/metamorph_creative_menu/files/integrations/ew/resilience.lua"] = ew_resilience,
    ["mods/metamorph_creative_menu/files/integrations/ew/perk_sync.lua"] = {},
    ["mods/metamorph_creative_menu/files/features/perks/service.lua"] = perk_service,
    ["mods/metamorph_creative_menu/files/features/effects/service.lua"] = effect_service,
    ["mods/metamorph_creative_menu/files/features/companion/player_avatar.lua"] = player_avatar,
    ["mods/metamorph_creative_menu/files/features/materials/painter.lua"] = material_painter,
    ["mods/metamorph_creative_menu/files/features/player_tools/service.lua"] = player_tools,
}

dofile_once = function() end
dofile = function(path)
    if init_modules[path] ~= nil then return init_modules[path] end
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path, 1, #prefix) == prefix then
        return native_dofile(root .. "/" .. string.sub(path, #prefix + 1))
    end
    return native_dofile(path)
end
function GameIsInventoryOpen() return false end

native_dofile(root .. "/init.lua")
assert(type(OnWorldPreUpdate) == "function", "real init.lua did not expose OnWorldPreUpdate")

reset({menu_open = true, has_form = true, return_pressed = true, input_blocked = false})
OnWorldPreUpdate()
assert(state.consume_counts.return_human == 1, "open menu suppressed return_human action consumption")
assert(#state.handle_calls == 1, "form return handler was not called exactly once")
assert(state.handle_calls[1].blocked == false and state.handle_calls[1].pressed == true,
    "form return handler received wrong state while menu was open")
assert(state.draw_calls == 0, "menu drew after successful form return")
assert(state.painter_disable_calls == 1, "successful form return did not disable the material painter")

reset({menu_open = false, has_form = true, return_pressed = true, input_blocked = false})
OnWorldPreUpdate()
assert(state.consume_counts.return_human == 1, "closed menu no longer consumes return_human exactly once")
assert(#state.handle_calls == 1
    and state.handle_calls[1].blocked == false
    and state.handle_calls[1].pressed == true,
    "closed-menu form return behavior changed")
assert(state.draw_calls == 0, "closed-menu successful form return did not short-circuit drawing")

reset({menu_open = true, has_form = false, return_pressed = true, input_blocked = false})
OnWorldPreUpdate()
assert((state.consume_counts.return_human or 0) == 0, "return_human was consumed without an active form")
assert(#state.handle_calls == 1
    and state.handle_calls[1].blocked == false
    and state.handle_calls[1].pressed == false,
    "inactive-form frame passed a return request to the handler")
assert(state.draw_calls == 1, "menu did not continue drawing without an active form")

reset({menu_open = true, has_form = true, return_pressed = true, input_blocked = true})
OnWorldPreUpdate()
assert(state.consume_counts.return_human == 1, "quarantined frame did not query return_human exactly once")
assert(#state.handle_calls == 1
    and state.handle_calls[1].blocked == true
    and state.handle_calls[1].pressed == true,
    "input quarantine state was not forwarded to handle_tab_return")
assert(state.draw_calls == 1, "blocked return incorrectly short-circuited menu drawing")
assert(state.painter_disable_calls == 0, "blocked return incorrectly disabled the material painter")

io.write("form_tab_return=PASS blocked_alt_tab=true active_tab_return=true open_menu=true closed_menu=true inactive_form=true quarantine=true\n")
