local root = assert(arg[1], "root required")
local real_dofile = dofile
local is_host = false
local globals = {}

function GlobalsGetValue(key, fallback) local value=globals[key]; if value==nil then return fallback end; return value end
function GlobalsSetValue(key, value) globals[key]=tostring(value) end
function ModIsEnabled(name) return name == "quant.ew" end
function GameHasFlagRun(flag) return flag == "ew_flag_this_is_host" and is_host end
function GameGetFrameNum() return 0 end
function print(_) end

METAMORPH_CREATIVE_MENU_WEATHER_EDITOR = nil
local prefix = "mods/metamorph_creative_menu/"
dofile = function(path)
    if string.sub(path, 1, #prefix) == prefix then
        return real_dofile(root .. "/" .. string.sub(path, #prefix + 1))
    end
    return real_dofile(path)
end
local weather = real_dofile(root .. "/files/features/weather/service.lua")
is_host = false
local client_allowed, client_role = weather.can_edit()
is_host = true
local host_allowed, host_role = weather.can_edit()
assert(client_allowed == true and client_role == "ew_peer", "weather denied EW client")
assert(host_allowed == true and host_role == "ew_host", "weather denied EW host")

METAMORPH_CREATIVE_MENU_WORLD_RULES_EDITOR = nil
local stubs = {
    ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"] = { get=function() return 0 end },
    ["mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua"] = {},
    ["mods/metamorph_creative_menu/files/core/rule_math.lua"] = { same=function(a,b) return a==b end },
    ["mods/metamorph_creative_menu/files/platform/noita/input_guard.lua"] = { actions_allowed=function() return true end },
    ["mods/metamorph_creative_menu/files/features/world_rules/gold_lifetime.lua"] = { restore_missing_lifetimes=function() return 0 end },
}
dofile = function(path)
    if stubs[path] ~= nil then return stubs[path] end
    if string.sub(path, 1, #prefix) == prefix then
        return real_dofile(root .. "/" .. string.sub(path, #prefix + 1))
    end
    return real_dofile(path)
end
local rules = real_dofile(root .. "/files/features/world_rules/service.lua")
is_host = false
client_allowed, client_role = rules.can_edit()
is_host = true
host_allowed, host_role = rules.can_edit()
assert(client_allowed == true and client_role == "ew_peer", "world rules denied EW client")
assert(host_allowed == true and host_role == "ew_host", "world rules denied EW host")
print("equal_peer_rights=PASS weather=true world_rules=true")
