local spell_service = {}
local ew_runtime = dofile("mods/metamorph_creative_menu/files/integrations/ew/runtime.lua")
local ew_world_items = dofile("mods/metamorph_creative_menu/files/integrations/ew/world_items.lua")
local wand_api = dofile("mods/metamorph_creative_menu/files/platform/noita/wand.lua")
local inventory_slots = dofile("mods/metamorph_creative_menu/files/platform/noita/inventory_slots.lua")
local spell_factory = dofile("mods/metamorph_creative_menu/files/features/spells/factory.lua")

local function valid_component(component_id)
    return component_id ~= nil and component_id ~= 0
end

local function alive(entity_id)
    return entity_id ~= nil and entity_id ~= 0 and EntityGetIsAlive(entity_id) == true
end

function spell_service.held_wand(player_entity_id) return wand_api.held(player_entity_id) end

-- Modified/generated wands can contain several actions reporting slot 0. Build a stable
-- logical view first; mutations normalize only when they can roll the change back.
function spell_service.contents(wand_entity_id)
    local entries = {}
    local permanent_entries = {}
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
                if type(action_id) == "string" and action_id ~= "" then
                    permanent_entries[#permanent_entries + 1] = {
                        entity = child_entity_id,
                        item_component = item_component,
                        action_component = action_component,
                        action_id = action_id,
                        actual_slot = slot_x,
                        actual_slot_y = slot_y,
                        permanent = true,
                    }
                end
            elseif type(action_id) == "string" and slot_x ~= nil and slot_x >= 0 and slot_y == 0 then
                entries[#entries + 1] = {
                    entity = child_entity_id,
                    item_component = item_component,
                    action_component = action_component,
                    action_id = action_id,
                    actual_slot = slot_x,
                    actual_slot_y = slot_y,
                    slot = nil,
                    permanent = false,
                }
            end
        end
    end

    -- EntityGetAllChildren ordering is not an API contract. Sort before resolving duplicate
    -- coordinates so a malformed/modded wand gets the same logical slot assignment each draw.
    table.sort(entries, function(left, right)
        if left.actual_slot ~= right.actual_slot then return left.actual_slot < right.actual_slot end
        return tonumber(left.entity) < tonumber(right.entity)
    end)

    -- Reserve non-zero coordinates first. Several generated wands report every action as 0:0;
    -- treating zero as ambiguous lets exactly one of those actions occupy slot zero afterwards.
    for _, entry in ipairs(entries) do
        if entry.actual_slot > 0 and not occupied_slots[entry.actual_slot] then
            entry.slot = entry.actual_slot
            occupied_slots[entry.actual_slot] = true
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

    table.sort(permanent_entries, function(left, right)
        if tostring(left.action_id) ~= tostring(right.action_id) then
            return tostring(left.action_id) < tostring(right.action_id)
        end
        return tonumber(left.entity) < tonumber(right.entity)
    end)

    local entries_by_slot = {}
    local highest_slot = -1
    for _, entry in ipairs(entries) do
        entries_by_slot[entry.slot] = entry
        highest_slot = math.max(highest_slot, entry.slot)
    end
    return entries_by_slot, highest_slot, permanent_action_count, entries, permanent_entries
end

local function set_slot(item_component, x, y)
    if not valid_component(item_component) then return false end
    local wrote = pcall(ComponentSetValue2, item_component, "inventory_slot", x, y or 0)
    if not wrote then return false end
    local read, actual_x, actual_y = pcall(ComponentGetValue2, item_component, "inventory_slot")
    return read and tonumber(actual_x) == tonumber(x) and (tonumber(actual_y) or 0) == (tonumber(y) or 0)
end

local function rollback_slot_changes(changes)
    for index = #(changes or {}), 1, -1 do
        local change = changes[index]
        pcall(ComponentSetValue2, change.component, "inventory_slot", change.x, change.y)
    end
end

local function normalize_slots(entries, excluded_entity)
    local changes = {}
    for _, entry in ipairs(entries or {}) do
        if entry.entity ~= excluded_entity and entry.actual_slot ~= entry.slot then
            changes[#changes + 1] = {
                component=entry.item_component,
                x=entry.actual_slot,
                y=entry.actual_slot_y or 0,
            }
            if not set_slot(entry.item_component, entry.slot, 0) then
                rollback_slot_changes(changes)
                return false, {}, "slot_normalization_failed"
            end
        end
    end
    return true, changes, "ok"
end

function spell_service.capacity(wand_entity_id, highest_slot, permanent_action_count)
    local deck_capacity = 0
    local ability_component = EntityGetFirstComponentIncludingDisabled(wand_entity_id, "AbilityComponent")
    if valid_component(ability_component) then
        local read_succeeded, value = pcall(ComponentObjectGetValue2, ability_component, "gun_config", "deck_capacity")
        if read_succeeded then deck_capacity = tonumber(value) or 0 end
    end
    deck_capacity = deck_capacity - (permanent_action_count or 0)
    if deck_capacity ~= deck_capacity or deck_capacity == math.huge or deck_capacity == -math.huge then deck_capacity = 0 end
    -- The horizontal strip virtualizes rendering, so large modded capacities no longer need
    -- the old 128-slot UI cap. highest_slot still keeps malformed-but-populated wands editable.
    return math.max(math.floor(deck_capacity), (highest_slot or -1) + 1, 1)
end

local function capture_mana_state(wand_entity_id)
    if not alive(wand_entity_id) then return nil end
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

function spell_service.refresh(player_entity_id, wand_entity_id)
    refresh_wand_and_inventory(player_entity_id, wand_entity_id)
end

local function configure_action_entity(entity_id, action_id, slot_index)
    if not alive(entity_id) then return nil, nil, "create_failed" end
    local item_component = EntityGetFirstComponentIncludingDisabled(entity_id, "ItemComponent")
    local action_component = EntityGetFirstComponentIncludingDisabled(entity_id, "ItemActionComponent")
    if not valid_component(item_component) or not valid_component(action_component) then
        pcall(EntityKill, entity_id)
        return nil, nil, "components_missing"
    end
    if slot_index ~= nil and not set_slot(item_component, slot_index, 0) then
        pcall(EntityKill, entity_id)
        return nil, nil, "slot_write_failed"
    end
    pcall(ComponentSetValue2, item_component, "has_been_picked_by_player", true)
    pcall(ComponentSetValue2, item_component, "permanently_attached", false)
    local ok_action, actual_action = pcall(ComponentGetValue2, action_component, "action_id")
    if not ok_action or tostring(actual_action or "") ~= tostring(action_id or "") then
        pcall(EntityKill, entity_id)
        return nil, nil, "action_mismatch"
    end
    return item_component, action_component, "ok"
end

local function detach_verified(entity_id)
    if not alive(entity_id) then return false end
    local detached = pcall(EntityRemoveFromParent, entity_id)
    if not detached then return false end
    if type(EntityGetParent) ~= "function" then return true end
    local read, parent = pcall(EntityGetParent, entity_id)
    return read and tonumber(parent) == 0
end

local function attach_verified(parent_id, entity_id)
    local attached = pcall(EntityAddChild, parent_id, entity_id)
    if not attached then return false end
    if type(EntityGetParent) ~= "function" then return true end
    local read, parent = pcall(EntityGetParent, entity_id)
    return read and tonumber(parent) == tonumber(parent_id)
end

function spell_service.replace(player_entity_id, wand_entity_id, slot_index, action_id, existing_entry, entries)
    slot_index = math.max(0, math.floor(tonumber(slot_index) or 0))
    if type(action_id) ~= "string" or action_id == "" then return false, "invalid_action" end
    if existing_entry ~= nil and tostring(existing_entry.action_id or "") == action_id then
        return true, "unchanged"
    end

    local created_entity_id = select(1, spell_factory.create(action_id))
    if created_entity_id == nil or created_entity_id == 0 then return false, "create_failed" end
    local item_component, action_component, configure_reason = configure_action_entity(created_entity_id, action_id, slot_index)
    if item_component == nil then return false, configure_reason end

    -- Prepare and verify the replacement before mutating any existing card. This is the
    -- reversible side of the transaction.
    if not attach_verified(wand_entity_id, created_entity_id) then
        pcall(EntityRemoveFromParent, created_entity_id)
        pcall(EntityKill, created_entity_id)
        return false, "attach_failed"
    end
    local ok_slot, actual_slot_x, actual_slot_y = pcall(ComponentGetValue2, item_component, "inventory_slot")
    local ok_action, actual_action = pcall(ComponentGetValue2, action_component, "action_id")
    if not ok_slot or tonumber(actual_slot_x) ~= slot_index or (tonumber(actual_slot_y) or 0) ~= 0
        or not ok_action or tostring(actual_action or "") ~= action_id
    then
        pcall(EntityRemoveFromParent, created_entity_id)
        pcall(EntityKill, created_entity_id)
        return false, "verification_failed"
    end

    local normalized, slot_changes, normalize_reason = normalize_slots(entries, existing_entry and existing_entry.entity or nil)
    if not normalized then
        pcall(EntityRemoveFromParent, created_entity_id)
        pcall(EntityKill, created_entity_id)
        return false, normalize_reason
    end

    if existing_entry ~= nil and alive(existing_entry.entity) then
        if not detach_verified(existing_entry.entity) then
            rollback_slot_changes(slot_changes)
            pcall(EntityRemoveFromParent, created_entity_id)
            pcall(EntityKill, created_entity_id)
            return false, "old_detach_failed"
        end
        local killed = pcall(EntityKill, existing_entry.entity)
        if not killed then
            -- Best-effort rollback: restore the detached original before removing the candidate.
            pcall(EntityAddChild, wand_entity_id, existing_entry.entity)
            set_slot(existing_entry.item_component, existing_entry.actual_slot, existing_entry.actual_slot_y or 0)
            rollback_slot_changes(slot_changes)
            pcall(EntityRemoveFromParent, created_entity_id)
            pcall(EntityKill, created_entity_id)
            return false, "old_kill_failed"
        end
    end

    EntitySetComponentsWithTagEnabled(created_entity_id, "enabled_in_world", false)
    refresh_wand_and_inventory(player_entity_id, wand_entity_id)
    return true, "replaced"
end

function spell_service.remove(player_entity_id, wand_entity_id, existing_entry, entries, drop_into_world, defer_world_notify)
    if existing_entry == nil or not alive(existing_entry.entity) then return false, "missing_action" end

    -- Detach first, while every other card is untouched. If any later preparatory step fails,
    -- the original card can be reattached with its exact old coordinate.
    if not detach_verified(existing_entry.entity) then return false, "detach_failed" end

    local normalized, slot_changes, normalize_reason = normalize_slots(entries, existing_entry.entity)
    if not normalized then
        pcall(EntityAddChild, wand_entity_id, existing_entry.entity)
        set_slot(existing_entry.item_component, existing_entry.actual_slot, existing_entry.actual_slot_y or 0)
        return false, normalize_reason
    end

    if drop_into_world then
        local player_x, player_y = EntityGetTransform(player_entity_id)
        if player_x == nil then
            rollback_slot_changes(slot_changes)
            pcall(EntityAddChild, wand_entity_id, existing_entry.entity)
            set_slot(existing_entry.item_component, existing_entry.actual_slot, existing_entry.actual_slot_y or 0)
            return false, "position_failed"
        end
        local item_component = existing_entry.item_component
        if valid_component(item_component) then
            pcall(ComponentSetValue2, item_component, "inventory_slot", -1, -1)
            pcall(ComponentSetValue2, item_component, "permanently_attached", false)
        end
        EntitySetComponentsWithTagEnabled(existing_entry.entity, "enabled_in_hand", false)
        EntitySetComponentsWithTagEnabled(existing_entry.entity, "enabled_in_inventory", false)
        EntitySetComponentsWithTagEnabled(existing_entry.entity, "enabled_in_world", true)
        EntitySetTransform(existing_entry.entity, player_x + 12, player_y - 8)
        if defer_world_notify ~= true then ew_world_items.notify_world_item(existing_entry.entity) end
    else
        local killed = pcall(EntityKill, existing_entry.entity)
        if not killed then
            rollback_slot_changes(slot_changes)
            pcall(EntityAddChild, wand_entity_id, existing_entry.entity)
            set_slot(existing_entry.item_component, existing_entry.actual_slot, existing_entry.actual_slot_y or 0)
            return false, "kill_failed"
        end
    end
    refresh_wand_and_inventory(player_entity_id, wand_entity_id)
    return true, drop_into_world and "dropped" or "deleted"
end

local function enable_world(entity_id)
    EntitySetComponentsWithTagEnabled(entity_id, "enabled_in_hand", false)
    EntitySetComponentsWithTagEnabled(entity_id, "enabled_in_inventory", false)
    EntitySetComponentsWithTagEnabled(entity_id, "enabled_in_world", true)
end

local function enable_world_verified(entity_id)
    local hand = pcall(EntitySetComponentsWithTagEnabled, entity_id, "enabled_in_hand", false)
    local inventory = pcall(EntitySetComponentsWithTagEnabled, entity_id, "enabled_in_inventory", false)
    local world = pcall(EntitySetComponentsWithTagEnabled, entity_id, "enabled_in_world", true)
    return hand and inventory and world
end

local function player_velocity(player_entity_id)
    local character = EntityGetFirstComponentIncludingDisabled(player_entity_id, "CharacterDataComponent")
    if not valid_component(character) then return 0, 0 end
    local ok, vx, vy = pcall(ComponentGetValue2, character, "mVelocity")
    if not ok then return 0, 0 end
    return tonumber(vx) or 0, tonumber(vy) or 0
end

local function set_throw_velocity(entity_id, vx, vy)
    local components = {}
    if type(EntityGetComponentIncludingDisabled) == "function" then
        local ok, value = pcall(EntityGetComponentIncludingDisabled, entity_id, "VelocityComponent")
        if ok and type(value) == "table" then components = value end
    end
    if #components == 0 and type(EntityAddComponent2) == "function" then
        local ok, component = pcall(EntityAddComponent2, entity_id, "VelocityComponent", {_tags="enabled_in_world"})
        if ok and valid_component(component) then components = {component} end
    end
    local wrote = false
    for _, component in ipairs(components) do
        if pcall(ComponentSetValue2, component, "mVelocity", vx, vy) then wrote = true end
    end
    return wrote
end

local function prepare_world_launch(player_entity_id, target_x, target_y)
    local player_x, player_y = EntityGetTransform(player_entity_id)
    if tonumber(player_x) == nil or tonumber(player_y) == nil then return nil, "position_failed" end
    target_x, target_y = tonumber(target_x), tonumber(target_y)
    if target_x == nil or target_y == nil then target_x, target_y = player_x + 100, player_y - 8 end
    local dx, dy = target_x - player_x, target_y - player_y
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 0.001 then dx, dy, length = 1, -0.08, 1.003 end
    local nx, ny = dx / length, dy / length
    local inherited_x, inherited_y = player_velocity(player_entity_id)
    local speed = 145
    return {
        x=player_x + nx * 13,
        y=player_y - 6 + ny * 8,
        vx=nx * speed + inherited_x * 0.35,
        vy=ny * speed + inherited_y * 0.35,
    }, "ok"
end

function spell_service.prepare_world_launch(player_entity_id, target_x, target_y)
    return prepare_world_launch(player_entity_id, target_x, target_y)
end

function spell_service.apply_world_launch(entity_id, plan, notify_world)
    if not alive(entity_id) then return false, "missing_action" end
    if type(plan) ~= "table" or tonumber(plan.x) == nil or tonumber(plan.y) == nil then
        return false, "invalid_launch_plan"
    end
    local item_component = EntityGetFirstComponentIncludingDisabled(entity_id, "ItemComponent")
    if valid_component(item_component) then
        pcall(ComponentSetValue2, item_component, "inventory_slot", -1, -1)
        pcall(ComponentSetValue2, item_component, "permanently_attached", false)
    end
    if not enable_world_verified(entity_id) then return false, "world_enable_failed" end
    local moved = pcall(EntitySetTransform, entity_id, plan.x, plan.y)
    if not moved then return false, "world_position_failed" end
    set_throw_velocity(entity_id, tonumber(plan.vx) or 0, tonumber(plan.vy) or 0)
    if notify_world == true then pcall(ew_world_items.notify_world_item, entity_id) end
    return true, "thrown"
end

function spell_service.launch_world_entity(player_entity_id, entity_id, target_x, target_y, notify_world)
    if not alive(entity_id) then return false, "missing_action" end
    local plan, reason = prepare_world_launch(player_entity_id, target_x, target_y)
    if plan == nil then return false, reason end
    return spell_service.apply_world_launch(entity_id, plan, notify_world)
end

function spell_service.throw_catalog(player_entity_id, action_id, target_x, target_y)
    if type(action_id) ~= "string" or action_id == "" then return false, "invalid_action", 0 end
    local entity_id = select(1, spell_factory.create(action_id))
    if entity_id == nil or entity_id == 0 then return false, "create_failed", 0 end
    local item_component = select(1, configure_action_entity(entity_id, action_id, nil))
    if item_component == nil then return false, "components_missing", 0 end
    pcall(ComponentSetValue2, item_component, "has_been_picked_by_player", false)
    pcall(ComponentSetValue2, item_component, "inventory_slot", -1, -1)
    local ok, reason = spell_service.launch_world_entity(player_entity_id, entity_id, target_x, target_y, true)
    if not ok then pcall(EntityKill, entity_id); return false, reason, 0 end
    return true, "thrown", entity_id
end

function spell_service.give(player_entity_id, action_id)
    if type(action_id) ~= "string" or action_id == "" then return false, "invalid_action", 0, false end
    local entity_id = select(1, spell_factory.create(action_id))
    if entity_id == nil or entity_id == 0 then return false, "create_failed", 0, false end
    local item_component = select(1, configure_action_entity(entity_id, action_id, nil))
    if item_component == nil then return false, "components_missing", 0, false end
    pcall(ComponentSetValue2, item_component, "inventory_slot", -1, -1)
    local picked, reason = inventory_slots.pickup(player_entity_id, entity_id, false)
    if picked then
        pcall(ComponentSetValue2, item_component, "has_been_picked_by_player", true)
        ew_runtime.force_inventory_sync()
        return true, "picked", entity_id, false
    end
    if alive(entity_id) then
        local x, y = EntityGetTransform(player_entity_id)
        if x ~= nil then EntitySetTransform(entity_id, x + 12, y - 8) end
        enable_world(entity_id)
        ew_world_items.notify_world_item(entity_id)
        return false, reason or "inventory_full", entity_id, true
    end
    return false, reason or "pickup_failed", 0, false
end

function spell_service.move(player_entity_id, wand_entity_id, existing_entry, target_slot, target_entry, entries)
    if existing_entry == nil or not alive(existing_entry.entity) then return false, "missing_action" end
    target_slot = math.max(0, math.floor(tonumber(target_slot) or 0))
    if existing_entry.slot == target_slot then return true, "unchanged" end

    -- Normalize all pre-existing logical slots under one rollback journal, then change only
    -- the source/target coordinates. Moving onto an occupied slot swaps the two cards.
    local normalized, changes, reason = normalize_slots(entries)
    if not normalized then return false, reason end
    local function fail(message)
        rollback_slot_changes(changes)
        return false, message
    end
    if target_entry ~= nil and target_entry.entity ~= existing_entry.entity then
        if not set_slot(target_entry.item_component, existing_entry.slot, 0) then return fail("target_slot_failed") end
    end
    if not set_slot(existing_entry.item_component, target_slot, 0) then return fail("source_slot_failed") end
    refresh_wand_and_inventory(player_entity_id, wand_entity_id)
    return true, target_entry ~= nil and "swapped" or "moved"
end

local function restore_wand_entry(wand_entity_id, entry)
    if entry == nil or not alive(entry.entity) then return end
    local parent = type(EntityGetParent) == "function" and EntityGetParent(entry.entity) or 0
    if parent ~= nil and parent ~= 0 and parent ~= wand_entity_id then pcall(EntityRemoveFromParent, entry.entity) end
    if parent ~= wand_entity_id then pcall(EntityAddChild, wand_entity_id, entry.entity) end
    set_slot(entry.item_component, entry.actual_slot or entry.slot or 0, entry.actual_slot_y or 0)
    pcall(ComponentSetValue2, entry.item_component, "permanently_attached", false)
    EntitySetComponentsWithTagEnabled(entry.entity, "enabled_in_world", false)
    EntitySetComponentsWithTagEnabled(entry.entity, "enabled_in_inventory", false)
end

-- Directional drag-to-world is one source transaction: validate the world target first,
-- then detach/normalize, and restore the exact wand source if world activation fails.
function spell_service.drop_to_world(player_entity_id, wand_entity_id, existing_entry, entries, target_x, target_y)
    if existing_entry == nil or not alive(existing_entry.entity) then return false, "missing_action" end
    local plan, plan_reason = prepare_world_launch(player_entity_id, target_x, target_y)
    if plan == nil then return false, plan_reason end
    if not detach_verified(existing_entry.entity) then return false, "detach_failed" end
    local normalized, slot_changes, normalize_reason = normalize_slots(entries, existing_entry.entity)
    if not normalized then
        restore_wand_entry(wand_entity_id, existing_entry)
        return false, normalize_reason
    end
    local launched, launch_reason = spell_service.apply_world_launch(existing_entry.entity, plan, false)
    if not launched then
        rollback_slot_changes(slot_changes)
        restore_wand_entry(wand_entity_id, existing_entry)
        refresh_wand_and_inventory(player_entity_id, wand_entity_id)
        return false, launch_reason
    end
    pcall(ew_world_items.notify_world_item, existing_entry.entity)
    refresh_wand_and_inventory(player_entity_id, wand_entity_id)
    return true, "thrown"
end

-- Move a real inventory card into a wand slot. If the wand slot is occupied, the two
-- entities are exchanged instead of cloning either card, preserving modded/custom state.
function spell_service.adopt_inventory(player_entity_id, wand_entity_id, source_entry, target_slot, target_entry, entries)
    if type(source_entry) ~= "table" or not alive(source_entry.entity) then return false, "source_missing" end
    if not inventory_slots.is_inside_player_inventory(player_entity_id, source_entry.entity) then return false, "source_not_inventory" end
    target_slot = math.max(0, math.floor(tonumber(target_slot) or 0))
    local source_parent = EntityGetParent(source_entry.entity) or 0
    if source_parent == 0 or EntityGetName(source_parent) ~= "inventory_full" then return false, "source_not_spell_inventory" end
    local source_x = math.floor(tonumber(source_entry.x) or -1)
    local source_y = math.floor(tonumber(source_entry.y) or 0)
    if source_x < 0 then return false, "source_slot_missing" end

    local normalized, slot_changes, normalize_reason = normalize_slots(entries, target_entry and target_entry.entity or nil)
    if not normalized then return false, normalize_reason end

    if not detach_verified(source_entry.entity) then
        rollback_slot_changes(slot_changes)
        return false, "source_detach_failed"
    end
    pcall(ComponentSetValue2, source_entry.item_component, "permanently_attached", false)
    pcall(ComponentSetValue2, source_entry.item_component, "has_been_picked_by_player", true)
    if not set_slot(source_entry.item_component, target_slot, 0) or not attach_verified(wand_entity_id, source_entry.entity) then
        pcall(EntityRemoveFromParent, source_entry.entity)
        inventory_slots.place_exact(player_entity_id, source_entry.entity, "inventory_full", source_x, source_y)
        rollback_slot_changes(slot_changes)
        return false, "source_attach_failed"
    end
    EntitySetComponentsWithTagEnabled(source_entry.entity, "enabled_in_world", false)
    EntitySetComponentsWithTagEnabled(source_entry.entity, "enabled_in_inventory", false)

    if target_entry ~= nil and alive(target_entry.entity) then
        if not detach_verified(target_entry.entity) then
            pcall(EntityRemoveFromParent, source_entry.entity)
            inventory_slots.place_exact(player_entity_id, source_entry.entity, "inventory_full", source_x, source_y)
            rollback_slot_changes(slot_changes)
            return false, "target_detach_failed"
        end
        pcall(ComponentSetValue2, target_entry.item_component, "permanently_attached", false)
        pcall(ComponentSetValue2, target_entry.item_component, "has_been_picked_by_player", true)
        local placed, place_reason = inventory_slots.place_exact(player_entity_id, target_entry.entity, "inventory_full", source_x, source_y)
        if not placed then
            restore_wand_entry(wand_entity_id, target_entry)
            pcall(EntityRemoveFromParent, source_entry.entity)
            inventory_slots.place_exact(player_entity_id, source_entry.entity, "inventory_full", source_x, source_y)
            rollback_slot_changes(slot_changes)
            return false, place_reason or "target_inventory_failed"
        end
    end

    refresh_wand_and_inventory(player_entity_id, wand_entity_id)
    return true, target_entry ~= nil and "swapped_inventory" or "moved_from_inventory"
end

function spell_service.export_to_inventory_slot(player_entity_id, wand_entity_id, source_entry, entries, x, y)
    if source_entry == nil or not alive(source_entry.entity) then return false, "source_missing" end
    x, y = math.floor(tonumber(x) or -1), math.floor(tonumber(y) or -1)
    if x < 0 or y < 0 then return false, "slot_out_of_range" end
    local layout, layout_reason = inventory_slots.snapshot(player_entity_id, "inventory_full")
    if layout == nil then return false, layout_reason end
    local occupied = nil
    for _, record in ipairs(layout.entries) do
        if record.x == x and record.y == y and record.is_action == true then occupied = record; break end
    end
    if occupied ~= nil then return false, "occupied", occupied end

    local normalized, slot_changes, normalize_reason = normalize_slots(entries, source_entry.entity)
    if not normalized then return false, normalize_reason end
    if not detach_verified(source_entry.entity) then
        rollback_slot_changes(slot_changes)
        return false, "detach_failed"
    end
    pcall(ComponentSetValue2, source_entry.item_component, "permanently_attached", false)
    pcall(ComponentSetValue2, source_entry.item_component, "has_been_picked_by_player", true)
    local placed, place_reason = inventory_slots.place_exact(player_entity_id, source_entry.entity, "inventory_full", x, y)
    if not placed then
        restore_wand_entry(wand_entity_id, source_entry)
        rollback_slot_changes(slot_changes)
        return false, place_reason or "inventory_failed"
    end
    refresh_wand_and_inventory(player_entity_id, wand_entity_id)
    return true, "inventory_slot"
end

function spell_service.move_to_inventory(player_entity_id, wand_entity_id, existing_entry, entries)
    if existing_entry == nil or not alive(existing_entry.entity) then return false, "missing_action" end
    local plan, preflight_reason = inventory_slots.preflight(player_entity_id, existing_entry.entity)
    if plan == nil then return false, preflight_reason or "inventory_full" end
    if not detach_verified(existing_entry.entity) then return false, "detach_failed" end

    local normalized, slot_changes, normalize_reason = normalize_slots(entries, existing_entry.entity)
    if not normalized then
        pcall(EntityAddChild, wand_entity_id, existing_entry.entity)
        set_slot(existing_entry.item_component, existing_entry.actual_slot, existing_entry.actual_slot_y or 0)
        return false, normalize_reason
    end

    pcall(ComponentSetValue2, existing_entry.item_component, "inventory_slot", -1, -1)
    enable_world(existing_entry.entity)
    local picked, reason = inventory_slots.pickup(player_entity_id, existing_entry.entity, false)
    if not picked then
        if alive(existing_entry.entity) then
            local parent = type(EntityGetParent) == "function" and EntityGetParent(existing_entry.entity) or 0
            if parent ~= nil and parent ~= 0 then pcall(EntityRemoveFromParent, existing_entry.entity) end
            pcall(EntityAddChild, wand_entity_id, existing_entry.entity)
            set_slot(existing_entry.item_component, existing_entry.actual_slot, existing_entry.actual_slot_y or 0)
            EntitySetComponentsWithTagEnabled(existing_entry.entity, "enabled_in_world", false)
            EntitySetComponentsWithTagEnabled(existing_entry.entity, "enabled_in_inventory", false)
        end
        rollback_slot_changes(slot_changes)
        return false, reason or "pickup_failed"
    end
    refresh_wand_and_inventory(player_entity_id, wand_entity_id)
    return true, "inventory"
end

return spell_service
