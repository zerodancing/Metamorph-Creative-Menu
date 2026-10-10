if type(METAMORPH_CREATIVE_MENU_EW_PERK_SYNC) == "table" then return METAMORPH_CREATIVE_MENU_EW_PERK_SYNC end

local perk_sync = {}
local player_locator = dofile("mods/metamorph_creative_menu/files/platform/noita/player_locator.lua")
local perk_service = dofile("mods/metamorph_creative_menu/files/features/perks/service.lua")

local GLOBAL_PERKS = {
    NO_MORE_SHUFFLE=true, UNLIMITED_SPELLS=true, TRICK_BLOOD_MONEY=true,
    GOLD_IS_FOREVER=true, EXTRA_MONEY_TRICK_KILL=true, EXTRA_MONEY=true,
    PEACE_WITH_GODS=true, EXTRA_SHOP_ITEM=true, GENOME_MORE_LOVE=true,
    GENOME_MORE_HATRED=true, GLOBAL_GORE=true,
}

local REMOTE_SEQ = "mcm_global_perk_remove_remote_seq_v1"
local REMOTE_ACK = "mcm_global_perk_remove_remote_ack_v1"

local function ew_enabled()
    local ok, enabled = pcall(ModIsEnabled, "quant.ew")
    return ok and enabled == true
end

local function perk_data(perk_id)
    pcall(dofile_once, "data/scripts/perks/perk.lua")
    pcall(dofile_once, "data/scripts/perks/perk_list.lua")
    for _, perk in ipairs(type(perk_list) == "table" and perk_list or {}) do
        if type(perk) == "table" and perk.id == perk_id then return perk end
    end
    return nil
end

function perk_sync.ew_enabled() return ew_enabled() end
function perk_sync.is_global(perk_id) return GLOBAL_PERKS[tostring(perk_id or "")] == true end
function perk_sync.can_sync_remove(_) return false end

function perk_sync.request_remove(perk_id, amount)
    -- Backwards-compatible API name, local semantics. Never send a peer-wide RPC.
    local perk = perk_data(tostring(perk_id or ""))
    local player = player_locator.get()
    if type(perk) ~= "table" or player == nil or player == 0 or not EntityGetIsAlive(player) then
        return false, "target"
    end
    amount = tonumber(amount) or 1
    if amount < 0 then
        local removed, reason = perk_service.remove_all(player, perk)
        return removed > 0 or perk_service.count(perk.id) == 0, reason or "local"
    end
    amount = math.max(1, math.min(999, math.floor(amount)))
    for _ = 1, amount do
        if perk_service.count(perk.id) <= 0 then break end
        local ok, reason = perk_service.remove_one(player, perk)
        if not ok then return false, reason end
    end
    return true, "local_peer"
end

function perk_sync.update()
    -- This compatibility mailbox is acknowledge-only. Perk removal is always peer-local.
    if not ew_enabled() then return end
    local sequence = tonumber(GlobalsGetValue(REMOTE_SEQ, "0")) or 0
    GlobalsSetValue(REMOTE_ACK, tostring(sequence))
end

METAMORPH_CREATIVE_MENU_EW_PERK_SYNC = perk_sync
return perk_sync
