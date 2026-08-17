if type(METAMORPH_CREATIVE_MENU_KEYBINDS) == "table" then return METAMORPH_CREATIVE_MENU_KEYBINDS end

local possession_keybinds = {}
local input_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/input_guard.lua")
local keycodes = dofile("mods/metamorph_creative_menu/files/platform/noita/keycodes.lua")
local player_locator = dofile("mods/metamorph_creative_menu/files/platform/noita/player_locator.lua")
local possession = dofile("mods/metamorph_creative_menu/files/features/possession/service.lua")

local SETTING_ID = "metamorph_creative_menu.possession_key"
local DEFAULT_BINDING = "Key_g"
local cached_setting = nil
local cached_binding = nil
local next_refresh_frame = -1

local function decode_binding(value)
    value = type(value) == "string" and value or DEFAULT_BINDING
    local mouse = string.match(value, "^Mouse:(%-?%d+)$")
    if mouse ~= nil then
        return { kind="mouse", code=tonumber(mouse), name=value }
    end
    local code, resolved_name = keycodes.resolve_binding(value, DEFAULT_BINDING)
    value = resolved_name or DEFAULT_BINDING
    code = tonumber(code) or 10
    return { kind="key", code=code, name=value }
end

local function configured_binding()
    local frame = tonumber(GameGetFrameNum()) or 0
    if cached_binding ~= nil and frame < next_refresh_frame then return cached_binding end
    next_refresh_frame = frame + 15

    local ok, value = pcall(ModSettingGet, SETTING_ID)
    local binding = decode_binding(ok and value or DEFAULT_BINDING)
    cached_setting, cached_binding = binding.name, binding
    return binding
end

local function inventory_open()
    local ok, value = pcall(GameIsInventoryOpen)
    return ok and value == true
end

local function binding_just_down(binding)
    if type(binding) ~= "table" or binding.code == nil then return false end
    if binding.kind == "mouse" then
        local ok, pressed = pcall(InputIsMouseButtonJustDown, binding.code)
        return ok and pressed == true
    end
    local ok, pressed = pcall(InputIsKeyJustDown, binding.code)
    return ok and pressed == true
end

function possession_keybinds.update()
    possession.update()
    local binding = configured_binding()
    if not input_guard.actions_allowed() or inventory_open() then return false end
    if not binding_just_down(binding) then return false end
    local success, reason = possession.possess_under_cursor(player_locator.get())
    if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_USER_ACTION) == "function" then pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_USER_ACTION, "possession", "binding="..tostring(binding.name).." result="..tostring(success).." reason="..tostring(reason)) end
    if not success then
        if reason == "no_target" then GamePrint(GameTextGetTranslatedOrNot("$mcm_possess_no_target"))
        else GamePrint(GameTextGetTranslatedOrNot("$mcm_possess_failed") .. ": " .. tostring(reason or "")) end
    end
    return success
end

function possession_keybinds.possess_key()
    local binding = configured_binding()
    return binding.kind == "key" and binding.code or nil
end

function possession_keybinds.possess_key_name()
    configured_binding()
    return cached_setting or DEFAULT_BINDING
end

function possession_keybinds.possess_binding()
    return configured_binding()
end

METAMORPH_CREATIVE_MENU_KEYBINDS = possession_keybinds
return possession_keybinds
