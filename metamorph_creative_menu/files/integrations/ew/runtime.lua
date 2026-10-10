if type(METAMORPH_CREATIVE_MENU_EW_RUNTIME) == "table" then return METAMORPH_CREATIVE_MENU_EW_RUNTIME end

local ew_runtime = {}

local STABLE_API_PATH = "mods/quant.ew/files/api/ew_crosscalls.lua"
local retry_every_frames = 60
local cached_inventory_api = nil
local last_inventory_attempt = -100000

local function frame_number()
    local ok, value = pcall(GameGetFrameNum)
    return ok and tonumber(value) or 0
end

function ew_runtime.enabled()
    local enabled = false
    pcall(function() enabled = ModIsEnabled("quant.ew") == true end)
    return enabled
end

function ew_runtime.inventory_api()
    if not ew_runtime.enabled() then
        cached_inventory_api = nil
        return nil
    end
    if type(cached_inventory_api) == "table"
        and type(cached_inventory_api.force_update_inventory) == "function"
    then
        return cached_inventory_api
    end

    local frame = frame_number()
    if frame - last_inventory_attempt < retry_every_frames then return nil end
    last_inventory_attempt = frame

    if not ModDoesFileExist(STABLE_API_PATH) then return nil end
    local ok, result = pcall(dofile, STABLE_API_PATH)
    if ok and type(result) == "table" and type(result.force_update_inventory) == "function" then
        cached_inventory_api = result
        return result
    end
    return nil
end

function ew_runtime.force_inventory_sync()
    local stable = ew_runtime.inventory_api()
    if stable == nil then return false end
    local ok = pcall(stable.force_update_inventory)
    if not ok then
        -- EW may reload a Lua context or replace its stable API table. Do not keep
        -- retrying a function that has already proved stale; rediscover it later.
        cached_inventory_api = nil
        last_inventory_attempt = -100000
    end
    return ok
end

function ew_runtime.mode()
    if not ew_runtime.enabled() then return "off" end
    -- EW's own init.lua sets this run flag from ctx.is_host. Unlike guessed Globals,
    -- this is also the flag EW itself consults in host-authoritative world scripts.
    local ok, host = pcall(GameHasFlagRun, "ew_flag_this_is_host")
    if ok and host == true then return "host" end
    return "client"
end

METAMORPH_CREATIVE_MENU_EW_RUNTIME = ew_runtime
return ew_runtime
