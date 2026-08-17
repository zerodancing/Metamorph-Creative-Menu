-- Loaded by ModLuaFileAppend into data/scripts/perks/perk.lua. It observes ordinary
-- vanilla pickups so perks obtained outside Metamorph: Creative Menu can use the same ownership
-- journal when the user later removes them from the menu.
if METAMORPH_CREATIVE_MENU_PERK_PICKUP_HOOK_V2 == true then return end
METAMORPH_CREATIVE_MENU_PERK_PICKUP_HOOK_V2 = true

local original_perk_pickup = perk_pickup
if type(original_perk_pickup) ~= "function" then return end
local unpack_values = unpack or table.unpack
local observer = nil

local function pack_values(...)
    return { n = select("#", ...), ... }
end

local function get_observer()
    if observer == nil then
        local ok, value = pcall(dofile, "mods/metamorph_creative_menu/files/features/perks/external_observer.lua")
        if ok and type(value) == "table" then observer = value else observer = false end
    end
    return observer ~= false and observer or nil
end

perk_pickup = function(perk_entity, player_entity, item_name, ...)
    if METAMORPH_CREATIVE_MENU_PERK_CAPTURE_ACTIVE == true then
        return original_perk_pickup(perk_entity, player_entity, item_name, ...)
    end
    local active_observer = get_observer()
    if active_observer == nil then return original_perk_pickup(perk_entity, player_entity, item_name, ...) end
    local context = active_observer.before_pickup(perk_entity, player_entity, item_name, _G)
    local extra_arguments = pack_values(...)
    local call_results = pack_values(xpcall(function()
        return original_perk_pickup(
            perk_entity,
            player_entity,
            item_name,
            unpack_values(extra_arguments, 1, extra_arguments.n)
        )
    end, function(error_value)
        return type(debug) == "table" and type(debug.traceback) == "function"
            and debug.traceback(tostring(error_value), 2) or tostring(error_value)
    end))
    local pickup_succeeded = call_results[1] == true
    pcall(active_observer.after_pickup, context, pickup_succeeded)
    if not pickup_succeeded then error(call_results[2]) end
    local result_count = call_results.n - 1
    local results = { n = result_count }
    for index = 1, result_count do results[index] = call_results[index + 1] end
    return unpack_values(results, 1, results.n)
end
