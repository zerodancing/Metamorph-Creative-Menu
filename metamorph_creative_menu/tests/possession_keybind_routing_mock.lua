local root = assert(arg[1], "root required")
local native_dofile = dofile
local pressed_key = nil
local possession_calls = 0
local updates = 0
local frame = 10

METAMORPH_CREATIVE_MENU_KEYBINDS = nil

local stubs = {
    ["mods/metamorph_creative_menu/files/platform/noita/input_guard.lua"] = {actions_allowed=function() return true end},
    ["mods/metamorph_creative_menu/files/platform/noita/keycodes.lua"] = {
        resolve_binding=function(binding_name, fallback_name)
            if binding_name == "Key_g" then return 10, "Key_g" end
            return 10, fallback_name
        end,
    },
    ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"] = {get=function() return 1 end},
    ["mods/metamorph_creative_menu/files/features/possession/service.lua"] = {
        update=function() updates=updates+1 end,
        possess_under_cursor=function(player)
            assert(player == 1, "wrong player passed to possession")
            possession_calls=possession_calls+1
            return true, "pending"
        end,
    },
}

dofile = function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

function GameGetFrameNum() return frame end
function ModSettingGet(_) return "Key_g" end
function GameIsInventoryOpen() return false end
function InputIsKeyJustDown(code) return code == pressed_key end
function InputIsMouseButtonJustDown() return false end
function GamePrint() end
function GameTextGetTranslatedOrNot(value) return value end

local keybinds = assert(native_dofile(root .. "/files/features/possession/keybinds.lua"))

-- TAB must never be treated as the configured G possession action.
pressed_key = 43
assert(keybinds.update() == false, "TAB incorrectly triggered possession")
assert(possession_calls == 0, "TAB reached possession service")

-- The configured G key must retain the old possession path.
frame = frame + 1
pressed_key = 10
assert(keybinds.update() == true, "G no longer triggers possession")
assert(possession_calls == 1, "G did not call possession exactly once")
assert(updates == 2, "pending possession update cadence changed")

print("possession_keybind_routing=PASS tab_is_return_only=true g_is_possession=true")
