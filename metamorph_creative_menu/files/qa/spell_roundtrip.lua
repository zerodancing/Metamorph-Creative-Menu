if type(METAMORPH_CREATIVE_MENU_QA_SPELL_ROUNDTRIP) == "table" then return METAMORPH_CREATIVE_MENU_QA_SPELL_ROUNDTRIP end

local spell_roundtrip = {}

local function valid(entity)
    return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity)
end

local function active_wand_state(player)
    local inventory = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
    if inventory == nil or inventory == 0 then return nil end
    local wand = tonumber(ComponentGetValue2(inventory, "mActualActiveItem")) or tonumber(ComponentGetValue2(inventory, "mActiveItem")) or 0
    if not valid(wand) then return nil end
    local ability = EntityGetFirstComponentIncludingDisabled(wand, "AbilityComponent")
    if ability == nil or ability == 0 then return nil end
    local capacity = nil
    pcall(function() capacity = ComponentObjectGetValue2(ability, "gun_config", "deck_capacity") end)
    return {
        entity=wand, ability=ability,
        mana=tonumber(ComponentGetValue2(ability, "mana")),
        max=tonumber(ComponentGetValue2(ability, "mana_max")),
        charge=tonumber(ComponentGetValue2(ability, "mana_charge_speed")),
        cap=tonumber(capacity),
    }
end

local function set_object_field(component, object_name, field, value)
    if type(ComponentObjectSetValue2) == "function" then
        local ok = pcall(ComponentObjectSetValue2, component, object_name, field, value)
        if ok then return true end
    end
    if type(ComponentObjectSetValue) == "function" then
        return pcall(ComponentObjectSetValue, component, object_name, field, tostring(value))
    end
    return false
end

local function restore_wand_mana(snapshot)
    if type(snapshot) ~= "table" or not valid(snapshot.entity) then return end
    local ability = EntityGetFirstComponentIncludingDisabled(snapshot.entity, "AbilityComponent")
    if ability == nil or ability == 0 then return end
    for field, value in pairs({mana=snapshot.mana, mana_max=snapshot.max, mana_charge_speed=snapshot.charge}) do
        if value ~= nil then pcall(ComponentSetValue2, ability, field, value) end
    end
end

local function pick_test_action_id()
    pcall(dofile_once, "data/scripts/gun/gun_enums.lua")
    pcall(dofile_once, "data/scripts/gun/gun_actions.lua")
    if type(actions) ~= "table" then return nil end
    for _, action in ipairs(actions) do
        if type(action) == "table" and action.id == "LIGHT_BULLET" then return action.id end
    end
    for _, action in ipairs(actions) do
        if type(action) == "table" and type(action.id) == "string" and action.id ~= "" then return action.id end
    end
    return nil
end

function spell_roundtrip.begin(player)
    local wand = active_wand_state(player)
    if not wand then return nil, "no_active_wand" end
    if wand.cap == nil then return nil, "capacity_unreadable" end
    if type(CreateItemActionEntity) ~= "function" then return nil, "CreateItemActionEntity_missing" end
    local action_id = pick_test_action_id()
    if not action_id then return nil, "actions_missing" end

    local highest_slot, permanent_count = -1, 0
    for _, child in ipairs(EntityGetAllChildren(wand.entity) or {}) do
        local action_component = EntityGetFirstComponentIncludingDisabled(child, "ItemActionComponent")
        local item_component = EntityGetFirstComponentIncludingDisabled(child, "ItemComponent")
        if action_component and action_component ~= 0 and item_component and item_component ~= 0 then
            if ComponentGetValue2(item_component, "permanently_attached") == true then
                permanent_count = permanent_count + 1
            else
                local slot_x, slot_y = ComponentGetValue2(item_component, "inventory_slot")
                slot_x, slot_y = tonumber(slot_x), tonumber(slot_y) or 0
                if slot_x and slot_x >= 0 and slot_y == 0 then highest_slot = math.max(highest_slot, slot_x) end
            end
        end
    end

    local test_slot = highest_slot + 1
    local temporary_capacity = math.max(math.floor(wand.cap), test_slot + 1 + permanent_count)
    if temporary_capacity ~= wand.cap and not set_object_field(wand.ability, "gun_config", "deck_capacity", temporary_capacity) then
        return nil, "capacity_expand_failed"
    end

    local created_action = CreateItemActionEntity(action_id)
    if not valid(created_action) then
        if temporary_capacity ~= wand.cap then set_object_field(wand.ability, "gun_config", "deck_capacity", wand.cap) end
        return nil, "create_action_failed"
    end
    local item_component = EntityGetFirstComponentIncludingDisabled(created_action, "ItemComponent")
    if item_component == nil or item_component == 0 then
        EntityKill(created_action)
        if temporary_capacity ~= wand.cap then set_object_field(wand.ability, "gun_config", "deck_capacity", wand.cap) end
        return nil, "action_item_missing"
    end

    pcall(ComponentSetValue2, item_component, "inventory_slot", test_slot, 0)
    pcall(ComponentSetValue2, item_component, "has_been_picked_by_player", true)
    pcall(ComponentSetValue2, item_component, "permanently_attached", false)
    EntityAddChild(wand.entity, created_action)
    pcall(EntitySetComponentsWithTagEnabled, created_action, "enabled_in_world", false)
    pcall(GameRegenItemActionsInContainer, wand.entity)
    pcall(GameRegenItemActionsInPlayer, player)
    restore_wand_mana(wand)
    return {wand=wand, created=created_action, action_id=action_id, slot=test_slot, temp_cap=temporary_capacity}, "created"
end

function spell_roundtrip.cleanup(player, context)
    if type(context) ~= "table" then return false, "missing_context" end
    if valid(context.created) then
        pcall(EntityRemoveFromParent, context.created)
        pcall(EntityKill, context.created)
    end
    local wand = context.wand
    if type(wand) == "table" and valid(wand.entity) and wand.ability and wand.ability ~= 0 then
        set_object_field(wand.ability, "gun_config", "deck_capacity", wand.cap)
        pcall(GameRegenItemActionsInContainer, wand.entity)
        pcall(GameRegenItemActionsInPlayer, player)
        restore_wand_mana(wand)
        return true, "restored"
    end
    return false, "wand_lost"
end

METAMORPH_CREATIVE_MENU_QA_SPELL_ROUNDTRIP = spell_roundtrip
return spell_roundtrip
