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

local function magic_number(name, fallback)
    if type(MagicNumbersGetValue) ~= "function" then return fallback end
    local ok, value = pcall(MagicNumbersGetValue, name)
    value = ok and tonumber(value) or nil
    return value ~= nil and value or fallback
end

-- Returns the on-screen rectangle occupied by a vanilla inventory surface. Prefer live
-- InventoryComponent geometry; the fallback derives the same top-right quick/full grids
-- from the player's actual dimensions and Noita UI magic numbers.
function inventory_slots.native_drop_bounds(player, inventory_name, screen_width, screen_height)
    inventory_name = tostring(inventory_name or "inventory_full")
    if inventory_name ~= "inventory_full" and inventory_name ~= "inventory_quick" then return nil end
    if inventory_name == "inventory_full" and type(GameIsInventoryOpen) == "function" then
        local ok, opened = pcall(GameIsInventoryOpen)
        if not ok or opened ~= true then return nil end
    end
    local inventory = named_inventory(player, inventory_name)
    if inventory == 0 then return nil end
    local width, height = inventory_limits(player, inventory)
    if width == nil then return nil end

    local geometry = EntityGetFirstComponentIncludingDisabled(inventory, "InventoryComponent")
    if valid(geometry) then
        local ok_pos, x, y = pcall(ComponentGetValue2, geometry, "ui_position_on_screen")
        local ok_item, item_w, item_h = pcall(ComponentGetValue2, geometry, "ui_element_size")
        local ok_container, cells_x, cells_y = pcall(ComponentGetValue2, geometry, "ui_container_size")
        x, y, item_w, item_h, cells_x, cells_y = tonumber(x), tonumber(y), tonumber(item_w), tonumber(item_h), tonumber(cells_x), tonumber(cells_y)
        if ok_pos and ok_item and ok_container and x ~= nil and y ~= nil and item_w ~= nil and item_h ~= nil
            and cells_x ~= nil and cells_y ~= nil and item_w > 0 and item_h > 0 and cells_x > 0 and cells_y > 0
        then
            return {x=x, y=y, width=item_w * cells_x, height=item_h * cells_y, source="component"}
        end
    end

    screen_width, screen_height = tonumber(screen_width) or 427, tonumber(screen_height) or 242
    local icon_size = math.max(8, magic_number("INVENTORY_ICON_SIZE", 20))
    local margin_x = math.max(0, magic_number("UI_BARS_POS_X", 20))
    local top = math.max(0, magic_number("UI_BARS_POS_Y", 20) - 4)
    local grid_width = math.min(screen_width, math.max(icon_size, width * icon_size))
    -- inventory_quick has two visible rows (wands and ordinary held items) sharing the
    -- same numeric slot coordinates. Cover both rows so a catalog item can be dropped on
    -- the vanilla quick inventory without inventing a second coordinate system.
    local visible_rows = inventory_name == "inventory_quick" and 2 or height
    local grid_height = math.min(screen_height - top, math.max(icon_size, visible_rows * icon_size + 8))
    local left = math.max(0, screen_width - grid_width - margin_x)
    return {x=left, y=top, width=grid_width, height=grid_height, source="native_grid"}
end

function inventory_slots.snapshot(player, inventory_name)
    inventory_name = tostring(inventory_name or "")
    local inventory = named_inventory(player, inventory_name)
    if inventory == 0 then return nil, "inventory_missing" end
    local width, height, kind = inventory_limits(player, inventory)
    if width == nil then return nil, "inventory_shape" end
    local result = {
        inventory=inventory, name=inventory_name, kind=kind, width=width, height=height,
        entries={}, by_slot={},
    }
    for _, child in ipairs(EntityGetAllChildren(inventory) or {}) do
        local x, y, item = item_slot(child)
        if x ~= nil and valid(item) then
            local record = {
                entity=child, item_component=item, x=x, y=y,
                is_action=is_action(child), is_wand=is_wand(child),
            }
            result.entries[#result.entries + 1] = record
            local collides = inventory_name ~= "inventory_quick" or record.is_wand == true
            local key = policy.slot_key(x, y)
            if result.by_slot[key] == nil or collides then result.by_slot[key] = record end
        end
    end
    table.sort(result.entries, function(a,b)
        if a.y ~= b.y then return a.y < b.y end
        if a.x ~= b.x then return a.x < b.x end
        return tonumber(a.entity) < tonumber(b.entity)
    end)
    return result, "ok"
end

local function restore_parent(entity, old_parent, old_x, old_y)
    if EntityGetParent(entity) ~= nil and EntityGetParent(entity) ~= 0 then pcall(EntityRemoveFromParent, entity) end
    if old_parent ~= nil and old_parent ~= 0 then
        pcall(EntityAddChild, old_parent, entity)
        local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
        if valid(item) and old_x ~= nil then pcall(ComponentSetValue2, item, "inventory_slot", old_x, old_y or 0) end
        if EntityGetName(old_parent) == "inventory_quick" or EntityGetName(old_parent) == "inventory_full" then enable_inventory(entity) end
    else
        enable_world(entity)
    end
end

function inventory_slots.place_exact(player, entity, inventory_name, x, y)
    if player == nil or player == 0 or entity == nil or entity == 0 or not EntityGetIsAlive(entity) then
        return false, "invalid"
    end
    inventory_name = tostring(inventory_name or "")
    if policy.destination(is_action(entity)) ~= inventory_name then return false, "wrong_inventory" end
    local snapshot, reason = inventory_slots.snapshot(player, inventory_name)
    if snapshot == nil then return false, reason end
    x, y = math.floor(tonumber(x) or -1), math.floor(tonumber(y) or -1)
    if x < 0 or y < 0 or x >= snapshot.width or y >= snapshot.height then return false, "slot_out_of_range" end
    local occupied = snapshot.by_slot[policy.slot_key(x, y)]
    if occupied ~= nil and occupied.entity ~= entity then return false, "occupied", occupied end

    local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
    if not valid(item) then return false, "not_item" end
    local old_parent = EntityGetParent(entity) or 0
    local old_x, old_y = item_slot(entity)
    if old_parent ~= snapshot.inventory then
        if old_parent ~= 0 then pcall(EntityRemoveFromParent, entity) end
        local added = pcall(EntityAddChild, snapshot.inventory, entity)
        if not added or EntityGetParent(entity) ~= snapshot.inventory then
            restore_parent(entity, old_parent, old_x, old_y)
            return false, "attach_failed"
        end
    end
    local wrote = pcall(ComponentSetValue2, item, "inventory_slot", x, y)
    local read_ok, actual_x, actual_y = pcall(ComponentGetValue2, item, "inventory_slot")
    if not wrote or not read_ok or tonumber(actual_x) ~= x or (tonumber(actual_y) or 0) ~= y then
        restore_parent(entity, old_parent, old_x, old_y)
        return false, "slot_write_failed"
    end
    enable_inventory(entity)
    local inv2 = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
    if valid(inv2) then pcall(ComponentSetValue2, inv2, "mForceRefresh", true) end
    return true, "ok"
end

function inventory_slots.swap_exact(player, left_entity, right_entity)
    if left_entity == nil or right_entity == nil or left_entity == right_entity then return false, "invalid" end
    if not EntityGetIsAlive(left_entity) or not EntityGetIsAlive(right_entity) then return false, "invalid" end
    local left_parent, right_parent = EntityGetParent(left_entity), EntityGetParent(right_entity)
    if left_parent == nil or left_parent == 0 or left_parent ~= right_parent then return false, "different_inventory" end
    local name = EntityGetName(left_parent)
    if name ~= "inventory_quick" and name ~= "inventory_full" then return false, "not_inventory" end
    if EntityGetRootEntity(left_parent) ~= player then return false, "foreign_inventory" end
    local lx, ly, li = item_slot(left_entity)
    local rx, ry, ri = item_slot(right_entity)
    if not valid(li) or not valid(ri) or lx == nil or rx == nil then return false, "slot_missing" end
    local left_ok = pcall(ComponentSetValue2, li, "inventory_slot", rx, ry)
    local right_ok = left_ok and pcall(ComponentSetValue2, ri, "inventory_slot", lx, ly)
    if not right_ok then
        pcall(ComponentSetValue2, li, "inventory_slot", lx, ly)
        pcall(ComponentSetValue2, ri, "inventory_slot", rx, ry)
        return false, "swap_failed"
    end
    local inv2 = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
    if valid(inv2) then pcall(ComponentSetValue2, inv2, "mForceRefresh", true) end
    return true, "ok"
end

return inventory_slots
