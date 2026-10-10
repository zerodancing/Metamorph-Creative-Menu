-- Append to EW's stock death LuaComponent. This runs in the entity VM, possibly
-- during a native DES call: only write a mailbox, never re-enter ewext from here.
local policy = dofile_once("mods/metamorph_creative_menu/files/integrations/ew/boss_lifecycle_policy.lua")
local original_death = death
local function remember_death(responsible)
    local entity = GetUpdatedEntityID()
    if not policy.is_boss(entity) then return end
    local gid, owner = policy.identity(entity)
    if not gid or not owner then return end
    local damage = EntityGetFirstComponentIncludingDisabled(entity, "DamageModelComponent")
    local wait = damage and ComponentGetValue2(damage, "wait_for_kill_flag_on_death") == true
    local x, y = EntityGetTransform(entity)
    local key = policy.EVENT_GID .. tostring(entity)
    if GlobalsGetValue(key, "") == gid then return end
    GlobalsSetValue(key, gid)
    -- Printable ASCII only: this mailbox can be serialized into a Noita save.
    local event = string.format("%d,%s,%d,%.17g,%.17g,%d;",
        entity, gid, wait and 1 or 0, x, y, math.max(0, tonumber(responsible) or 0))
    GlobalsSetValue(policy.EVENTS, GlobalsGetValue(policy.EVENTS, "") .. event)
end

function death(damage_type_bit_field, damage_message, entity_thats_responsible, drop_items)
    -- An observer failure must not suppress the original callback or a boss mod's loot.
    pcall(remember_death, entity_thats_responsible)
    return original_death(damage_type_bit_field, damage_message, entity_thats_responsible, drop_items)
end
