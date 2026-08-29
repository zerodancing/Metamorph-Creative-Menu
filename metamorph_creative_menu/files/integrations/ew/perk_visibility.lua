if type(METAMORPH_CREATIVE_MENU_EW_PERK_VISIBILITY) == "table" then return METAMORPH_CREATIVE_MENU_EW_PERK_VISIBILITY end

local perk_visibility = {}
local ew_runtime = dofile("mods/metamorph_creative_menu/files/integrations/ew/runtime.lua")
local HIDDEN_COUNT_PREFIX = "mcm_creative_perk_hidden_count_v1:"

local function key(perk_id)
    return HIDDEN_COUNT_PREFIX .. tostring(perk_id or "")
end

function perk_visibility.publish(perk_id, count)
    if type(perk_id) ~= "string" or perk_id == "" then return false, "invalid" end
    if not ew_runtime.enabled() then return true, "singleplayer" end
    local value = math.max(0, math.floor(tonumber(count) or 0))
    GlobalsSetValue(key(perk_id), tostring(value))
    return true, "published"
end

function perk_visibility.refresh(perk_id, player, transactions)
    if not ew_runtime.enabled() then return true, "singleplayer" end
    if type(transactions) ~= "table" or type(transactions.source_count) ~= "function" then
        return false, "source_count_unavailable"
    end
    local count = transactions.source_count(perk_id, "mcm_creative", player)
    return perk_visibility.publish(perk_id, count)
end

function perk_visibility.hidden_count(perk_id)
    if type(GlobalsGetValue) ~= "function" then return 0 end
    return math.max(0, tonumber(GlobalsGetValue(key(perk_id), "0")) or 0)
end

METAMORPH_CREATIVE_MENU_EW_PERK_VISIBILITY = perk_visibility
return perk_visibility
