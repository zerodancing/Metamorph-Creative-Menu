if type(METAMORPH_CREATIVE_MENU_KEYBINDS) == "table" then return METAMORPH_CREATIVE_MENU_KEYBINDS end

local possession_keybinds = {}
local input_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/input_guard.lua")
local keycodes = dofile("mods/metamorph_creative_menu/files/platform/noita/keycodes.lua")
local binding_codec = dofile("mods/metamorph_creative_menu/files/core/binding_codec.lua")
local action_bindings = dofile("mods/metamorph_creative_menu/files/platform/noita/action_bindings.lua")
local player_locator = dofile("mods/metamorph_creative_menu/files/platform/noita/player_locator.lua")
local possession = dofile("mods/metamorph_creative_menu/files/features/possession/service.lua")

local DEFAULT_BINDING = "Key_g"

local function decode_binding(value)
    local parsed = binding_codec.parse(type(value) == "string" and value or DEFAULT_BINDING)
    if parsed == nil or parsed.kind == "none" then return {kind="none",code=nil,name="NONE"} end
    if parsed.kind == "mouse" then return {kind="mouse",code=parsed.mouse_code,name=parsed.canonical} end
    return {kind="key",code=keycodes.resolve(parsed.base),name=parsed.canonical}
end

local function inventory_open()
    local ok, value = pcall(GameIsInventoryOpen)
    return ok and value == true
end

function possession_keybinds.update(menu_open)
    possession.update()
    action_bindings.update()
    if not input_guard.actions_allowed() or inventory_open() or menu_open == true then return false end
    if not action_bindings.consume("possession") then return false end
    local success, reason = possession.possess_under_cursor(player_locator.get())
    if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_USER_ACTION) == "function" then pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_USER_ACTION, "possession", "binding="..tostring(action_bindings.get("possession")).." result="..tostring(success).." reason="..tostring(reason)) end
    if not success then
        if reason == "no_target" then GamePrint(GameTextGetTranslatedOrNot("$mcm_possess_no_target"))
        else GamePrint(GameTextGetTranslatedOrNot("$mcm_possess_failed") .. ": " .. tostring(reason or "")) end
    end
    return success
end

function possession_keybinds.possess_key()
    local binding = decode_binding(action_bindings.get("possession"))
    return binding.kind == "key" and binding.code or nil
end

function possession_keybinds.possess_key_name()
    return action_bindings.get("possession")
end

function possession_keybinds.possess_binding()
    return decode_binding(action_bindings.get("possession"))
end

METAMORPH_CREATIVE_MENU_KEYBINDS = possession_keybinds
return possession_keybinds
