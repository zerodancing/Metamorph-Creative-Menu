-- State helpers for the two vanilla wand perks that require typed rollback instead of
-- a whole player-tree structural delta. No ownership is stored here; transactions.lua
-- remains the coordinator and the mutation/global journals remain authoritative.
local wand_special_states = {}
local structural_snapshot = dofile("mods/metamorph_creative_menu/files/features/perks/transactions/structural_snapshot.lua")
local valid_entity = structural_snapshot.valid_entity
local parent_of = structural_snapshot.parent_of

local function object_get(comp, object, field)
    if comp == nil or comp == 0 then return nil end
    if type(ComponentObjectGetValue2) == "function" then
        local ok, value = pcall(ComponentObjectGetValue2, comp, object, field)
        if ok and value ~= nil then return value end
    end
    if type(ComponentObjectGetValue) == "function" then
        local ok, value = pcall(ComponentObjectGetValue, comp, object, field)
        if ok and value ~= nil then return value end
    end
    return nil
end

local function scalar_same(left, right)
    local a, b = tonumber(left), tonumber(right)
    if a ~= nil and b ~= nil then return math.abs(a - b) < 0.000001 end
    return tostring(left) == tostring(right)
end

local function object_set(comp, object, field, value)
    if comp == nil or comp == 0 then return false end
    local wrote = false
    if type(ComponentObjectSetValue2) == "function" then
        wrote = pcall(ComponentObjectSetValue2, comp, object, field, value)
    end
    if not wrote and type(ComponentObjectSetValue) == "function" then
        wrote = pcall(ComponentObjectSetValue, comp, object, field, tostring(value))
    end
    if not wrote then return false end
    local after = object_get(comp, object, field)
    return after ~= nil and scalar_same(after, value)
end

local function extra_mana_state(player)
    if not valid_entity(player) then return nil end
    local inventory = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
    if inventory == nil or inventory == 0 then return nil end
    local wand = 0
    -- Match vanilla EXTRA_MANA's target selection when perk utilities are loaded.
    if type(find_the_wand_held) == "function" then
        local ok_wand, candidate = pcall(find_the_wand_held, player)
        candidate = ok_wand and tonumber(candidate) or 0
        if candidate ~= nil and candidate ~= 0 and valid_entity(candidate) then wand = candidate end
    end
    if wand == 0 then
        for _, field in ipairs({"mActualActiveItem", "mActiveItem"}) do
            local ok_item, candidate = pcall(ComponentGetValue2, inventory, field)
            candidate = ok_item and tonumber(candidate) or 0
            if candidate ~= nil and candidate ~= 0 and valid_entity(candidate) then wand = candidate; break end
        end
    end
    if wand == nil or wand == 0 or not valid_entity(wand) then return nil end
    local ability = EntityGetFirstComponentIncludingDisabled(wand, "AbilityComponent")
    if ability == nil or ability == 0 then return nil end
    local ok_gun, use_gun = pcall(ComponentGetValue2, ability, "use_gun_script")
    if not ok_gun or use_gun ~= true then return nil end
    local deck = object_get(ability, "gun_config", "deck_capacity")
    local ok_max, mana_max = pcall(ComponentGetValue2, ability, "mana_max")
    local ok_charge, mana_charge = pcall(ComponentGetValue2, ability, "mana_charge_speed")
    if deck == nil or not ok_max or not ok_charge then return nil end
    local actions = {}
    for _, child in ipairs(EntityGetAllChildren(wand) or {}) do
        if EntityGetFirstComponentIncludingDisabled(child, "ItemActionComponent") ~= nil then
            local enabled = {}
            for _, comp in ipairs(EntityGetAllComponents(child) or {}) do
                local ok_enabled, value = pcall(ComponentGetIsEnabled, comp)
                if ok_enabled then enabled[comp] = value == true end
            end
            actions[child] = { parent=wand, enabled=enabled }
        end
    end
    return {
        wand=wand, ability=ability, deck_capacity=tostring(deck),
        mana_max=tostring(mana_max), mana_charge_speed=tostring(mana_charge), actions=actions,
    }
end

local function same_scalar(a, b)
    return scalar_same(a, b)
end


local function no_more_shuffle_state()
    if type(EntityGetWithTag) ~= "function" then return nil end
    local ok, wands = pcall(EntityGetWithTag, "wand")
    if not ok or type(wands) ~= "table" then return nil end
    local result = {}
    for _, wand in ipairs(wands) do
        if valid_entity(wand) then
            local ability = EntityGetFirstComponentIncludingDisabled(wand, "AbilityComponent")
            if ability ~= nil and ability ~= 0 then
                local value = object_get(ability, "gun_config", "shuffle_deck_when_empty")
                if value ~= nil then
                    result[wand] = { wand=wand, ability=ability, value=tostring(value) }
                end
            end
        end
    end
    return result
end

local function no_more_shuffle_delta(before)
    if type(before) ~= "table" then return nil, "no_more_shuffle_snapshot" end
    local changes = {}
    for wand, entry in pairs(before) do
        if valid_entity(wand) then
            local ability = EntityGetFirstComponentIncludingDisabled(wand, "AbilityComponent")
            if ability ~= entry.ability then return nil, "no_more_shuffle_wand_changed" end
            local after = object_get(ability, "gun_config", "shuffle_deck_when_empty")
            if after == nil then return nil, "no_more_shuffle_read" end
            if not same_scalar(after, entry.value) then
                changes[#changes + 1] = {
                    wand=wand, ability=ability, before=entry.value, after=tostring(after),
                }
            end
        end
    end
    return changes, "ok"
end

wand_special_states.object_get = object_get
wand_special_states.object_set = object_set
wand_special_states.extra_mana_state = extra_mana_state
wand_special_states.same_scalar = same_scalar
wand_special_states.no_more_shuffle_state = no_more_shuffle_state
wand_special_states.no_more_shuffle_delta = no_more_shuffle_delta

return wand_special_states
