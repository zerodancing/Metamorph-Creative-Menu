local root = assert(arg[1], "root required")
local load_count = 0
function ModDoesFileExist(path)
    return path == "mods/metamorph_creative_menu/files/lib/base64.lua"
end
function dofile_once(path)
    assert(path == "mods/metamorph_creative_menu/files/lib/base64.lua", "unexpected local serialization dependency")
    load_count = load_count + 1
    return { decode = function(value) return value == "encoded" and "serialized-player" or "" end }
end
METAMORPH_CREATIVE_MENU_EW_SERIALIZATION = nil
local serialization = assert(dofile(root .. "/files/integrations/ew/serialization.lua"))
assert(serialization.decode_base64("encoded") == "serialized-player", "local base64 decode failed")
assert(serialization.decode_base64("bad") == nil, "empty decoded data should be rejected")
assert(serialization.decode_base64("encoded") == "serialized-player", "cached decoder changed result")
assert(load_count == 1, "local base64 module was not cached")
print("ew_serialization=PASS local_codec=true isolated_from_ew=true")
