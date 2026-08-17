local inventory_slots = {}
local policy = dofile("mods/metamorph_creative_menu/files/core/inventory_policy.lua")
-- Noita represents both visible rows with coordinates 0..3. A wand and a potion
-- may therefore legitimately share inventory_slot=0:0; their class selects the row.
-- quick_inventory_slots=10 is an engine capacity, not a flat coordinate range.
local QUICK_SLOT_COUNT = 4

local function valid(component)
    return component ~= nil and component ~= 0
end

local function item_slot(entity)
    local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
    if not valid(item) then
        return nil
    end
    local x, y = ComponentGetValue2(item, "inventory_slot")
    return tonumber(x), tonumber(y) or 0, item
end

local function inventory_limits(player, inventory)
    local name = EntityGetName(inventory)
    local inv2 = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
    if not valid(inv2) then
        return nil
    end
    if name == "inventory_quick" then
        return math.min(QUICK_SLOT_COUNT,
            math.max(1, tonumber(ComponentGetValue2(inv2, "quick_inventory_slots")) or QUICK_SLOT_COUNT)), 1, "quick"
    end
    if name == "inventory_full" then
        return math.max(1, tonumber(ComponentGetValue2(inv2, "full_inventory_slots_x")) or 16), math.max(1, tonumber(ComponentGetValue2(inv2, "full_inventory_slots_y")) or 1), "full"
    end
    return nil
end


local function is_action(entity)
    return valid(EntityGetFirstComponentIncludingDisabled(entity, "ItemActionComponent"))
end

local function is_wand(entity)
    if type(EntityHasTag) == "function" and EntityHasTag(entity, "wand") then return true end
    local ability = EntityGetFirstComponentIncludingDisabled(entity, "AbilityComponent")
    if not valid(ability) then return false end
    local ok, use_gun_script = pcall(ComponentGetValue2, ability, "use_gun_script")
    return ok and use_gun_script == true
end

local function slot_range(entity, inventory_name, width)
    if inventory_name ~= "inventory_quick" then return 0, width end
    return 0, math.min(QUICK_SLOT_COUNT, width)
end

local function occupied_map(inventory, exclude, target_is_wand)
    local occupied = {}
    local quick = EntityGetName(inventory) == "inventory_quick"
    for _, child in ipairs(EntityGetAllChildren(inventory) or {}) do
        -- Equal numeric coordinates collide only within the same quick row/class.
        if child ~= exclude and (not quick or is_wand(child) == target_is_wand) then
            local x, y = item_slot(child)
            if x ~= nil then
                occupied[policy.slot_key(x, y)] = true
            end
        end
    end
    return occupied
end

local function enable_world(entity)
    EntitySetComponentsWithTagEnabled(entity, "enabled_in_hand", false)
    EntitySetComponentsWithTagEnabled(entity, "enabled_in_inventory", false)
    EntitySetComponentsWithTagEnabled(entity, "enabled_in_world", true)
end

local function enable_inventory(entity)
    EntitySetComponentsWithTagEnabled(entity, "enabled_in_hand", false)
    EntitySetComponentsWithTagEnabled(entity, "enabled_in_world", false)
    EntitySetComponentsWithTagEnabled(entity, "enabled_in_inventory", true)
end

function inventory_slots.enable_world(entity)
    enable_world(entity)
end

function inventory_slots.is_inside_player_inventory(player, entity)
    if player == nil or player == 0 or entity == nil or entity == 0 or not EntityGetIsAlive(entity) then
        return false
    end
    local current = entity
    for _ = 1, 6 do
        local parent = EntityGetParent(current)
        if parent == nil or parent == 0 then return false end
        local name = EntityGetName(parent)
        if (name == "inventory_quick" or name == "inventory_full") and EntityGetRootEntity(parent) == player then
            return true
        end
        if parent == player then return false end
        current = parent
    end
    return false
end

function inventory_slots.ensure_unique(player, entity)
    if player == nil or player == 0 or entity == nil or entity == 0 or not EntityGetIsAlive(entity) then
        return false, "invalid"
    end
    local parent = EntityGetParent(entity)
    if parent == nil or parent == 0 then
        return false, "not_picked"
    end
    local width, height = inventory_limits(player, parent)
    if width == nil then
        return true
    end
    local x, y, item = item_slot(entity)
    if not valid(item) then
        return true
    end
    local occupied = occupied_map(parent, entity, is_wand(entity))
    local first_x, count = slot_range(entity, EntityGetName(parent), width)
    local key = x ~= nil and policy.slot_key(x, y) or nil
    local invalid = x == nil or x < first_x or x >= first_x + count or y < 0 or y >= height
    if not invalid and not occupied[key] then
        return true
    end
    local free_x, free_y = policy.first_free_range(first_x, count, occupied)
    if free_x == nil then
        local px, py = EntityGetTransform(player)
        EntityRemoveFromParent(entity)
        if px ~= nil then
            EntitySetTransform(entity, px + 12, py - 8)
        end
        enable_world(entity)
        return false, "full"
    end
    ComponentSetValue2(item, "inventory_slot", free_x, free_y)
    local inv2 = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
    if valid(inv2) then
        ComponentSetValue2(inv2, "mForceRefresh", true)
    end
    return true
end

local function named_inventory(player, name)
    for _, child in ipairs(EntityGetAllChildren(player) or {}) do
        if EntityGetName(child) == name then return child end
    end
    return 0
end

local function preflight(player, entity)
    local destination = policy.destination(is_action(entity))
    local inventory = named_inventory(player, destination)
    if inventory == 0 then return nil, "inventory_missing" end
    local width, height = inventory_limits(player, inventory)
    if width == nil then return nil, "inventory_shape" end
    local first_x, count = slot_range(entity, destination, width)
    local plan = policy.plan_range(first_x, count, occupied_map(inventory, entity, is_wand(entity)))
    if plan.kind ~= "inventory" then return nil, plan.reason end
    plan.inventory = inventory
    plan.name = destination
    return plan, "ok"
end

local function parent_is_player_inventory(player, entity)
    local parent = EntityGetParent(entity)
    if parent == nil or parent == 0 then return false end
    if EntityGetName(parent) == "inventory_quick" or EntityGetName(parent) == "inventory_full" then
        return EntityGetRootEntity(parent) == player
    end
    return false
end

function inventory_slots.pickup(player, entity, play_sound)
    if player == nil or player == 0 or entity == nil or entity == 0 or not EntityGetIsAlive(entity) then
        return false, "invalid"
    end
    local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
    if not valid(item) then return false, "not_item" end
    local ok_pickable, pickable = pcall(ComponentGetValue2, item, "is_pickable")
    if ok_pickable and pickable == false then return false, "not_pickable" end
    local ok_auto, auto_pickup = pcall(ComponentGetValue2, item, "auto_pickup")
    if ok_auto and auto_pickup == true then return false, "auto_pickup" end

    -- Preflight before GamePickUpInventoryItem. Once the engine has parented an item,
    -- a later rejection can already have displaced an action card or hidden the held
    -- wand for a frame.
    local plan, reason = preflight(player, entity)
    if plan == nil then return false, reason end
    pcall(ComponentSetValue2, item, "inventory_slot", plan.x, plan.y)

    local ok = pcall(GamePickUpInventoryItem, player, entity, play_sound == true)
    if not ok or not EntityGetIsAlive(entity) then
        return false, "pickup_failed"
    end
    if EntityGetParent(entity) ~= plan.inventory then
        -- Some entities carry a preferred-inventory hint and GamePickUp may put them
        -- in an engine-only holder even after a successful four-slot preflight.
        -- Finish the already-approved transaction in the exact planned inventory;
        -- this does not run when the four visible cells are full.
        if EntityGetParent(entity) ~= nil and EntityGetParent(entity) ~= 0 then
            EntityRemoveFromParent(entity)
        end
        EntityAddChild(plan.inventory, entity)
        ComponentSetValue2(item, "inventory_slot", plan.x, plan.y)
        enable_inventory(entity)
        if EntityGetParent(entity) ~= plan.inventory then
            if parent_is_player_inventory(player, entity) then EntityRemoveFromParent(entity) end
            return false, "wrong_inventory"
        end
    end
    return inventory_slots.ensure_unique(player, entity)
end

function inventory_slots.preflight(player, entity)
    return preflight(player, entity)
end

return inventory_slots
