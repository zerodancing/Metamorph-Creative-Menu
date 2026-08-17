if type(METAMORPH_CREATIVE_MENU_EW_SERIALIZATION) == "table" then
    return METAMORPH_CREATIVE_MENU_EW_SERIALIZATION
end

local serialization = {}
local LOCAL_BASE64_PATH = "mods/metamorph_creative_menu/files/lib/base64.lua"
local cached_base64_module = nil

local function base64_module()
    if cached_base64_module ~= nil then
        return cached_base64_module ~= false and cached_base64_module or nil
    end
    if type(ModDoesFileExist) ~= "function" or not ModDoesFileExist(LOCAL_BASE64_PATH) then
        cached_base64_module = false
        return nil
    end
    local loaded, loaded_base64_module = pcall(dofile_once, LOCAL_BASE64_PATH)
    cached_base64_module = loaded and type(loaded_base64_module) == "table" and loaded_base64_module or false
    return cached_base64_module ~= false and cached_base64_module or nil
end

function serialization.decode_base64(encoded_data)
    if type(encoded_data) ~= "string" or encoded_data == "" then return nil end
    local base64_codec = base64_module()
    if type(base64_codec) ~= "table" or type(base64_codec.decode) ~= "function" then return nil end
    local decoded, data = pcall(base64_codec.decode, encoded_data)
    if decoded and type(data) == "string" and data ~= "" then return data end
    return nil
end

METAMORPH_CREATIVE_MENU_EW_SERIALIZATION = serialization
return serialization
