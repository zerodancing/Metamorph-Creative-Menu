local root = assert(arg[1], "root required")

-- Runtime path: Noita executes keycodes.lua and exposes authoritative Key_* globals.
function dofile_once(path)
    assert(path == "data/scripts/debug/keycodes.lua", "wrong keycode source")
    Key_TAB = 43
    Key_g = 10
    KEY_Z = 29
    Key_LALT = 56
    Key_RALT = 184
end

-- Deliberately conflicting source values prove that runtime globals win. Text parsing
-- remains a fallback only for environments where dofile_once cannot populate globals.
function ModTextFileGetContent(path)
    assert(path == "data/scripts/debug/keycodes.lua", "wrong parser fallback source")
    return [[
Key_TAB = 10
Key_g = 43
KEY_Z = 99
Key_LALT = 0x38
Key_RALT = 184
Key_BACKSPACE = 14
]]
end

METAMORPH_CREATIVE_MENU_NOITA_KEYCODES = nil
local keycodes = assert(dofile(root .. "/files/platform/noita/keycodes.lua"))
assert(keycodes.resolve("Key_TAB") == 43, "TAB must use Noita's loaded runtime keycode")
assert(keycodes.resolve("Key_g") == 10, "G must use Noita's loaded runtime keycode")
local code, name = keycodes.resolve_binding("Key_g", "KEY_Z")
assert(code == 10 and name == "Key_g", "configured G binding resolved to another key")
local fallback_code, fallback_name = keycodes.resolve_binding("Missing", "KEY_Z")
assert(fallback_code == 29 and fallback_name == "KEY_Z", "binding fallback changed")
local alt = keycodes.matching_name_fragment("ALT")
assert(#alt == 2 and alt[1] == 56 and alt[2] == 184, "ALT discovery changed")
print("keycodes=PASS noita_globals_authoritative=true tab_and_g_distinct=true")
