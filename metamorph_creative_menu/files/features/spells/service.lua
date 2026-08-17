local spell_service = {}
local ew_runtime = dofile("mods/metamorph_creative_menu/files/integrations/ew/runtime.lua")

local MAX_VISIBLE_CAPACITY = 128

local function valid_component(component_id)
    return component_id ~= nil and component_id ~= 0
end

function spell_service.held_wand(player_entity_id)
    local inventory_component = EntityGetFirstComponentIncludingDisabled(player_entity_id, "Inventory2Component")
    if not valid_component(inventory_component) then return 0 end
    local active_item_entity_id = ComponentGetValue2(inventory_component, "mActiveItem") or 0
    if active_item_entity_id == 0 or not EntityGetIsAlive(active_item_entity_id) then return 0 end
    local ability_component = EntityGetFirstComponentIncludingDisabled(active_item_entity_id, "AbilityComponent")
    if not valid_component(ability_component) or ComponentGetValue2(ability_component, "use_gun_script") ~= true then return 0 end
    return active_item_entity_id
end

-- Modified/generated wands can contain several actions reporting slot 0. Normalize them
-- into stable logical slots before any destructive operation so no action is lost.
function spell_service.contents(wand_entity_id)
    local entries = {}
    local occupied_slots = {}
    local permanent_action_count = 0
    for _, child_entity_id in ipairs(EntityGetAllChildren(wand_entity_id) or {}) do
        local action_component = EntityGetFirstComponentIncludingDisabled(child_entity_id, "ItemActionComponent")
        local item_component = EntityGetFirstComponentIncludingDisabled(child_entity_id, "ItemComponent")
        if valid_component(action_component) and valid_component(item_component) then
            local permanently_attached = ComponentGetValue2(item_component, "permanently_attached") == true
            local action_id = ComponentGetValue2(action_component, "action_id")
            local slot_x, slot_y = ComponentGetValue2(item_component, "inventory_slot")
            slot_x = tonumber(slot_x)
            slot_y = tonumber(slot_y) or 0
            if permanently_attached then
                permanent_action_count = permanent_action_count + 1
            elseif type(action_id) == "string" and slot_x ~= nil and slot_x >= 0 and slot_y == 0 then
                local entry = {
                    entity = child_entity_id,
                    item_component = item_component,
                    action_id = action_id,
                    actual_slot = slot_x,
                    slot = nil,
                }
                if slot_x > 0 and not occupied_slots[slot_x] then
                    entry.slot = slot_x
                    occupied_slots[slot_x] = true
                end
                entries[#entries + 1] = entry
            end
        end
    end

    local next_free_slot = 0
    for _, entry in ipairs(entries) do
        if entry.slot == nil then
            while occupied_slots[next_free_slot] do next_free_slot = next_free_slot + 1 end
            entry.slot = next_free_slot
            occupied_slots[next_free_slot] = true
        end
    end

    local entries_by_slot = {}
    local highest_slot = -1
    for _, entry in ipairs(entries) do
        entries_by_slot[entry.slot] = entry
        highest_slot = math.max(highest_slot, entry.slot)
    end
    return entries_by_slot, highest_slot, permanent_action_count, entries
end

local function normalize_slots(entries)
    for _, entry in ipairs(entries or {}) do
        if entry.actual_slot ~= entry.slot then
            pcall(ComponentSetValue2, entry.item_component, "inventory_slot", entry.slot, 0)
        end
    end
end

function spell_service.capacity(wand_entity_id, highest_slot, permanent_action_count)
    local deck_capacity = 0
    local ability_component = EntityGetFirstComponentIncludingDisabled(wand_entity_id, "AbilityComponent")
    if valid_component(ability_component) then
        local read_succeeded, value = pcall(ComponentObjectGetValue2, ability_component, "gun_config", "deck_capacity")
        if read_succeeded then deck_capacity = tonumber(value) or 0 end
    end
    deck_capacity = deck_capacity - (permanent_action_count or 0)
    return math.min(math.max(math.floor(deck_capacity), (highest_slot or -1) + 1, 1), MAX_VISIBLE_CAPACITY)
end

local function capture_mana_state(wand_entity_id)
    if wand_entity_id == nil or wand_entity_id == 0 or not EntityGetIsAlive(wand_entity_id) then return nil end
    local ability_component = EntityGetFirstComponentIncludingDisabled(wand_entity_id, "AbilityComponent")
    if not valid_component(ability_component) then return nil end
    local mana_state = { ability = ability_component }
    for _, field_name in ipairs({ "mana", "mana_max", "mana_charge_speed" }) do
        local read_succeeded, value = pcall(ComponentGetValue2, ability_component, field_name)
        if read_succeeded and value ~= nil then mana_state[field_name] = value end
    end
    return mana_state
end

local function restore_mana_state(mana_state)
    if type(mana_state) ~= "table" or not valid_component(mana_state.ability) then return end
    for _, field_name in ipairs({ "mana", "mana_max", "mana_charge_speed" }) do
        local original_value = mana_state[field_name]
        if original_value ~= nil then
            local read_succeeded, current_value = pcall(ComponentGetValue2, mana_state.ability, field_name)
            if read_succeeded and current_value ~= original_value then
                pcall(ComponentSetValue2, mana_state.ability, field_name, original_value)
            end
        end
    end
end

local function refresh_wand_and_inventory(player_entity_id, wand_entity_id)
    local inventory_component = EntityGetFirstComponentIncludingDisabled(player_entity_id, "Inventory2Component")
    if valid_component(inventory_component) then
        -- Do not clear active-item pointers; that can visually hide the held wand until
        -- vanilla inventory code repairs it.
        pcall(ComponentSetValue2, inventory_component, "mForceRefresh", true)
    end
    local mana_state = capture_mana_state(wand_entity_id)
    if wand_entity_id ~= nil and wand_entity_id ~= 0 then pcall(GameRegenItemActionsInContainer, wand_entity_id) end
    pcall(GameRegenItemActionsInPlayer, player_entity_id)
    restore_mana_state(mana_state)
    ew_runtime.force_inventory_sync()
end

function spell_service.replace(player_entity_id, wand_entity_id, slot_index, action_id, existing_entry, entries)
    local created_entity_id = CreateItemActionEntity(action_id)
    if created_entity_id == nil or created_entity_id == 0 then return false end
    local item_component = EntityGetFirstComponentIncludingDisabled(created_entity_id, "ItemComponent")
    local action_component = EntityGetFirstComponentIncludingDisabled(created_entity_id, "ItemActionComponent")
    if not valid_component(item_component) or not valid_component(action_component) then
        EntityKill(created_entity_id)
        return false
    end
    pcall(ComponentSetValue2, item_component, "inventory_slot", slot_index, 0)
    pcall(ComponentSetValue2, item_component, "has_been_picked_by_player", true)
    pcall(ComponentSetValue2, item_component, "permanently_attached", false)
    normalize_slots(entries)

    local attached = pcall(EntityAddChild, wand_entity_id, created_entity_id)
    local parent_ok = false
    if attached and type(EntityGetParent) == "function" then
        local ok_parent, parent = pcall(EntityGetParent, created_entity_id)
        parent_ok = ok_parent and tonumber(parent) == tonumber(wand_entity_id)
    end
    local ok_slot, actual_slot_x, actual_slot_y = pcall(ComponentGetValue2, item_component, "inventory_slot")
    local ok_action, actual_action = pcall(ComponentGetValue2, action_component, "action_id")
    local verified = attached and parent_ok and ok_slot
        and tonumber(actual_slot_x) == tonumber(slot_index) and (tonumber(actual_slot_y) or 0) == 0
        and ok_action and tostring(actual_action or "") == tostring(action_id or "")
    if not verified then
        if type(EntityRemoveFromParent) == "function" then pcall(EntityRemoveFromParent, created_entity_id) end
        pcall(EntityKill, created_entity_id)
        return false
    end

    EntitySetComponentsWithTagEnabled(created_entity_id, "enabled_in_world", false)
    if existing_entry ~= nil and existing_entry.entity ~= nil and EntityGetIsAlive(existing_entry.entity) then
        -- Commit point: the replacement is already a verified child of the wand. Only
        -- now retire the old action so a failed attach can never destroy the user's spell.
        pcall(EntityRemoveFromParent, existing_entry.entity)
        pcall(EntityKill, existing_entry.entity)
    end
    refresh_wand_and_inventory(player_entity_id, wand_entity_id)
    return true
end

function spell_service.remove(player_entity_id, wand_entity_id, existing_entry, entries, drop_into_world)
    if existing_entry == nil or existing_entry.entity == nil or not EntityGetIsAlive(existing_entry.entity) then return false end
    normalize_slots(entries)
    EntityRemoveFromParent(existing_entry.entity)
    if drop_into_world then
        local player_x, player_y = EntityGetTransform(player_entity_id)
        local item_component = existing_entry.item_component
        if valid_component(item_component) then
            pcall(ComponentSetValue2, item_component, "inventory_slot", -1, -1)
            pcall(ComponentSetValue2, item_component, "permanently_attached", false)
        end
        EntitySetComponentsWithTagEnabled(existing_entry.entity, "enabled_in_hand", false)
        EntitySetComponentsWithTagEnabled(existing_entry.entity, "enabled_in_inventory", false)
        EntitySetComponentsWithTagEnabled(existing_entry.entity, "enabled_in_world", true)
        if player_x ~= nil then EntitySetTransform(existing_entry.entity, player_x + 12, player_y - 8) end
    else
        EntityKill(existing_entry.entity)
    end
    refresh_wand_and_inventory(player_entity_id, wand_entity_id)
    return true
end

return spell_service
