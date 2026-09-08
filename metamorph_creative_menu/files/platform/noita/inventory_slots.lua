if type(METAMORPH_CREATIVE_MENU_INVENTORY_SLOTS) == "table" then return METAMORPH_CREATIVE_MENU_INVENTORY_SLOTS end

local inventory_slots = {}
local policy = dofile("mods/metamorph_creative_menu/files/core/inventory_policy.lua")
local patcher_bridge = dofile("mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua")
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
        local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
        -- Inventory containers snapshot an item's preferred slot while processing child
        -- attachment. Restore the coordinate before reattaching, then confirm it again
        -- afterwards so both ItemComponent and the native inventory view agree.
        if valid(item) and old_x ~= nil then pcall(ComponentSetValue2, item, "inventory_slot", old_x, old_y or 0) end
        pcall(EntityAddChild, old_parent, entity)
        if valid(item) and old_x ~= nil then pcall(ComponentSetValue2, item, "inventory_slot", old_x, old_y or 0) end
        if EntityGetName(old_parent) == "inventory_quick" or EntityGetName(old_parent) == "inventory_full" then enable_inventory(entity) end
    else
        enable_world(entity)
    end
end

local function force_refresh(player)
    local inv2 = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
    if valid(inv2) then pcall(ComponentSetValue2, inv2, "mForceRefresh", true) end
end

-- Existing action cards that have lived inside a wand are registered by Noita's native
-- inventory system, not only by ItemComponent.inventory_slot. Direct child re-parenting can
-- therefore be visually/readback-correct in Lua while InventoryGui later packs the card into
-- another cell. Fresh catalogue cards do not suffer from this because they enter through the
-- engine pickup path for the first time.
--
-- Exact full-inventory moves below deliberately use GamePickUpInventoryItem as the authority.
-- Before each pickup MCM temporarily occupies every other free spell cell with fresh action
-- sentinels, so the requested cell is literally the only cell the engine can choose. The
-- sentinels exist only inside this synchronous transaction and are removed before returning.
-- This preserves the original spell entity and all of its runtime/modded components while
-- letting Noita rebuild its private InventoryComponent.items registration itself.
local SENTINEL_ACTION = "LIGHT_BULLET"
local SENTINEL_TAG = "metamorph_creative_menu_inventory_sentinel"

local function detach_verified(entity)
    local parent = EntityGetParent(entity) or 0
    if parent == 0 then return true end
    local removed = pcall(EntityRemoveFromParent, entity)
    return removed and (EntityGetParent(entity) or 0) == 0
end

local function nested_parent_mode(entity, parent)
    if parent == nil or parent == 0 then
        enable_world(entity)
        return
    end
    local name = EntityGetName(parent)
    if name == "inventory_quick" or name == "inventory_full" then
        enable_inventory(entity)
        return
    end
    -- Action cards stored inside a wand are neither world nor player-inventory items.
    EntitySetComponentsWithTagEnabled(entity, "enabled_in_hand", false)
    EntitySetComponentsWithTagEnabled(entity, "enabled_in_world", false)
    EntitySetComponentsWithTagEnabled(entity, "enabled_in_inventory", false)
end

local function assignment_map(assignments)
    local result = {}
    for _, spec in ipairs(type(assignments) == "table" and assignments or {}) do
        local entity = math.floor(tonumber(spec.entity) or 0)
        local x, y = tonumber(spec.x), tonumber(spec.y)
        if entity ~= 0 and x ~= nil and y ~= nil then
            result[entity] = {x=math.floor(x), y=math.floor(y)}
        end
    end
    return result
end

local function destroy_sentinel(player, entity)
    if entity == nil or entity == 0 or not EntityGetIsAlive(entity) then return end
    -- GameKillInventoryItem is important here: the sentinel must leave the same private
    -- InventoryComponent.items registration that GamePickUpInventoryItem created for it.
    -- A bare EntityKill/RemoveFromParent would only clean the ECS hierarchy on some builds.
    if type(GameKillInventoryItem) == "function" and parent_is_player_inventory(player, entity) then
        pcall(GameKillInventoryItem, player, entity)
    end
    if EntityGetIsAlive(entity) then
        if (EntityGetParent(entity) or 0) ~= 0 then pcall(EntityRemoveFromParent, entity) end
        pcall(EntityKill, entity)
    end
end

local function destroy_sentinels(player, sentinels)
    for index=#(sentinels or {}),1,-1 do destroy_sentinel(player, sentinels[index]) end
end

-- Register a temporary action through the *same engine pickup path* as the real card. This
-- is intentionally not EntityAddChild: direct parenting updates the ECS tree but does not
-- guarantee that Noita's private InventoryComponent.items vector knows about the child.
-- The caller supplies the slot that should currently be the engine's first free cell and we
-- verify that assumption after pickup. If a future Noita build orders free cells differently,
-- the transaction fails safely instead of silently moving the user's spell.
local function create_registered_sentinel(player, inventory, expected_x, expected_y)
    if type(CreateItemActionEntity) ~= "function" or type(GamePickUpInventoryItem) ~= "function" then
        return 0, "sentinel_factory_missing"
    end
    local ok, entity = pcall(CreateItemActionEntity, SENTINEL_ACTION, 0, 0)
    entity = ok and tonumber(entity) or 0
    if entity == nil or entity == 0 or not EntityGetIsAlive(entity) then return 0, "sentinel_create_failed" end
    local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
    if not valid(item) then pcall(EntityKill, entity); return 0, "sentinel_item_missing" end
    if type(EntityAddTag) == "function" then pcall(EntityAddTag, entity, SENTINEL_TAG) end
    pcall(ComponentSetValue2, item, "inventory_slot", expected_x, expected_y)
    pcall(ComponentSetValue2, item, "permanently_attached", false)
    pcall(ComponentSetValue2, item, "has_been_picked_by_player", true)
    enable_world(entity)

    local picked = pcall(GamePickUpInventoryItem, player, entity, false)
    local parent_ok = picked and EntityGetIsAlive(entity)
        and tonumber(EntityGetParent(entity) or 0) == tonumber(inventory)
    local read_ok, actual_x, actual_y = pcall(ComponentGetValue2, item, "inventory_slot")
    local slot_ok = read_ok and tonumber(actual_x) == expected_x and (tonumber(actual_y) or 0) == expected_y
    if not parent_ok or not slot_ok then
        destroy_sentinel(player, entity)
        return 0, not parent_ok and "sentinel_pickup_failed" or "sentinel_order_changed"
    end
    enable_inventory(entity)
    return entity, "ok"
end

local function linear_slot(x, y, width)
    return (tonumber(y) or 0) * width + (tonumber(x) or 0)
end

-- Make the requested cell the first free native spell slot. Noita packs an existing card
-- taken from a wand into its first free InventoryComponent.items position even when
-- ItemComponent.inventory_slot already names a later cell. To beat that native packing rule
-- without cloning the user's card, register short-lived action sentinels in every free cell
-- *before* the target. They are picked up by Noita itself, so they really occupy its private
-- vector. Once the target is first-free, the real card is picked up, then the sentinels are
-- removed synchronously. Later holes are irrelevant and therefore never touched.
local function isolate_target_cell(player, inventory, width, height, target_x, target_y)
    local current, reason = inventory_slots.snapshot(player, "inventory_full")
    if current == nil or tonumber(current.inventory) ~= tonumber(inventory) then return nil, reason or "inventory_changed" end
    local target_key = policy.slot_key(target_x, target_y)
    if current.by_slot[target_key] ~= nil then return nil, "occupied" end

    local target_linear = linear_slot(target_x, target_y, width)
    local sentinels = {}
    for index=0,target_linear-1 do
        local x = index % width
        local y = math.floor(index / width)
        if y < height then
            local key = policy.slot_key(x, y)
            if current.by_slot[key] == nil then
                local sentinel, sentinel_reason = create_registered_sentinel(player, inventory, x, y)
                if sentinel == 0 then
                    destroy_sentinels(player, sentinels)
                    return nil, sentinel_reason
                end
                sentinels[#sentinels+1] = sentinel
                -- Keep the local occupancy model in sync so the expected first-free slot for
                -- the next sentinel advances exactly as the engine did.
                current.by_slot[key] = {entity=sentinel,x=x,y=y,is_action=true}
            end
        end
    end
    return sentinels, "ok"
end

local function engine_pickup_exact(player, entity, inventory, width, height, x, y)
    if not EntityGetIsAlive(entity) then return false, "invalid" end
    local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
    if not valid(item) then return false, "not_item" end
    if (EntityGetParent(entity) or 0) ~= 0 and not detach_verified(entity) then return false, "detach_failed" end

    local sentinels, isolate_reason = isolate_target_cell(player, inventory, width, height, x, y)
    if sentinels == nil then return false, isolate_reason end

    -- Publish the preferred cell too, but do not manually touch mItemUid/mFramePickedUp:
    -- GamePickUpInventoryItem owns those native registration fields and is the operation
    -- whose result we need InventoryGui to trust.
    pcall(ComponentSetValue2, item, "inventory_slot", x, y)
    pcall(ComponentSetValue2, item, "permanently_attached", false)
    pcall(ComponentSetValue2, item, "has_been_picked_by_player", true)
    enable_world(entity)
    local picked = pcall(GamePickUpInventoryItem, player, entity, false)
    local parent_ok = picked and EntityGetIsAlive(entity) and tonumber(EntityGetParent(entity) or 0) == tonumber(inventory)
    local read_ok, actual_x, actual_y = pcall(ComponentGetValue2, item, "inventory_slot")
    local slot_ok = read_ok and tonumber(actual_x) == x and (tonumber(actual_y) or 0) == y

    destroy_sentinels(player, sentinels)
    if not parent_ok or not slot_ok then
        if (EntityGetParent(entity) or 0) ~= 0 then pcall(EntityRemoveFromParent, entity) end
        enable_world(entity)
        return false, not parent_ok and "pickup_wrong_inventory" or "pickup_wrong_slot"
    end
    enable_inventory(entity)
    return true, "ok"
end

-- Move one or more existing spell entities to exact inventory_full cells. Every requested
-- entity is detached before the first pickup so swaps are collision-free. Each insertion is
-- then performed by Noita itself with all non-target holes temporarily blocked.
local function rebuild_full_exact_legacy(player, assignments)
    local snapshot, reason = inventory_slots.snapshot(player, "inventory_full")
    if snapshot == nil then return false, reason end
    local requested = assignment_map(assignments)
    if next(requested) == nil then return false, "no_assignments" end

    local records = {}
    local requested_entities = {}
    for entity, desired in pairs(requested) do
        if not EntityGetIsAlive(entity) or not is_action(entity) then return false, "invalid_action" end
        local old_x, old_y, item = item_slot(entity)
        if not valid(item) then return false, "not_item" end
        if desired.x < 0 or desired.y < 0 or desired.x >= snapshot.width or desired.y >= snapshot.height then
            return false, "slot_out_of_range"
        end
        records[#records+1] = {
            entity=entity, item=item, old_parent=EntityGetParent(entity) or 0,
            old_x=old_x, old_y=old_y or 0, x=desired.x, y=desired.y,
        }
        requested_entities[entity] = true
    end

    -- Requested cells may be occupied by another requested entity (swap), but never by an
    -- untouched spell. Also reject duplicate destination cells before mutating anything.
    local destinations = {}
    for _, record in ipairs(records) do
        local key = policy.slot_key(record.x, record.y)
        if destinations[key] ~= nil and destinations[key] ~= record.entity then return false, "occupied", destinations[key] end
        destinations[key] = record.entity
        local occupied = snapshot.by_slot[key]
        if occupied ~= nil and occupied.entity ~= record.entity and requested_entities[occupied.entity] ~= true then
            return false, "occupied", occupied.entity
        end
    end

    table.sort(records, function(a,b)
        if a.y ~= b.y then return a.y < b.y end
        if a.x ~= b.x then return a.x < b.x end
        return tonumber(a.entity) < tonumber(b.entity)
    end)

    local function direct_restore(record)
        if not EntityGetIsAlive(record.entity) then return false end
        if (EntityGetParent(record.entity) or 0) ~= 0 then pcall(EntityRemoveFromParent, record.entity) end
        local item = EntityGetFirstComponentIncludingDisabled(record.entity, "ItemComponent")
        if not valid(item) then return false end
        record.item = item
        if record.old_parent ~= 0 and EntityGetName(record.old_parent) == "inventory_full"
            and EntityGetRootEntity(record.old_parent) == player and record.old_x ~= nil
        then
            local ok = engine_pickup_exact(player, record.entity, record.old_parent, snapshot.width, snapshot.height, record.old_x, record.old_y or 0)
            if ok then return true end
        end
        if record.old_x ~= nil then pcall(ComponentSetValue2, item, "inventory_slot", record.old_x, record.old_y or 0) end
        if record.old_parent ~= nil and record.old_parent ~= 0 then
            pcall(EntityAddChild, record.old_parent, record.entity)
            if record.old_x ~= nil then pcall(ComponentSetValue2, item, "inventory_slot", record.old_x, record.old_y or 0) end
        end
        nested_parent_mode(record.entity, record.old_parent)
        return tonumber(EntityGetParent(record.entity) or 0) == tonumber(record.old_parent or 0)
    end

    local function rollback()
        for _, record in ipairs(records) do
            if EntityGetIsAlive(record.entity) and (EntityGetParent(record.entity) or 0) ~= 0 then pcall(EntityRemoveFromParent, record.entity) end
        end
        -- Restore inventory cells first in original cell order; wand/other parents follow.
        table.sort(records, function(a,b)
            local ai = a.old_parent ~= 0 and EntityGetName(a.old_parent) == "inventory_full" and 0 or 1
            local bi = b.old_parent ~= 0 and EntityGetName(b.old_parent) == "inventory_full" and 0 or 1
            if ai ~= bi then return ai < bi end
            if (a.old_y or 0) ~= (b.old_y or 0) then return (a.old_y or 0) < (b.old_y or 0) end
            return (a.old_x or -1) < (b.old_x or -1)
        end)
        for _, record in ipairs(records) do direct_restore(record) end
        force_refresh(player)
    end

    for _, record in ipairs(records) do
        if not detach_verified(record.entity) then rollback(); return false, "detach_failed" end
    end

    local expected = {}
    for _, record in ipairs(records) do
        local placed, place_reason = engine_pickup_exact(player, record.entity, snapshot.inventory, snapshot.width, snapshot.height, record.x, record.y)
        if not placed then rollback(); return false, place_reason end
        expected[#expected+1] = {entity=record.entity,parent=snapshot.inventory,x=record.x,y=record.y}
        -- Catch any immediate engine packing before inserting the next member of a swap.
        for _, spec in ipairs(expected) do
            local sx, sy = item_slot(spec.entity)
            if tonumber(EntityGetParent(spec.entity) or 0) ~= tonumber(spec.parent)
                or tonumber(sx) ~= tonumber(spec.x) or tonumber(sy or 0) ~= tonumber(spec.y)
            then
                rollback(); return false, "pickup_drift"
            end
        end
    end
    force_refresh(player)
    return true, "ok", expected
end

local function exact_rehydrate_bridge()
    if type(patcher_bridge) ~= "table" or type(patcher_bridge.get) ~= "function" then return nil end
    local bridge = patcher_bridge.get({bootstrap_if_installed=true,capability="SerializeEntity"})
    if type(bridge) ~= "table" or type(bridge.SerializeEntity) ~= "function"
        or type(bridge.DeserializeEntity) ~= "function" or type(EntityCreateNew) ~= "function"
    then return nil end
    return bridge
end

local function rehydrate_create(bridge, serialized, parent, x, y, inventory_parent)
    local ok_new, entity = pcall(EntityCreateNew)
    entity = ok_new and tonumber(entity) or 0
    if entity == nil or entity == 0 then return 0, "rehydrate_create_failed" end
    local ok_deserialize = pcall(bridge.DeserializeEntity, entity, serialized)
    if not ok_deserialize or not EntityGetIsAlive(entity) then
        if EntityGetIsAlive(entity) then pcall(EntityKill, entity) end
        return 0, "rehydrate_deserialize_failed"
    end
    local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
    if not valid(item) or not is_action(entity) then pcall(EntityKill, entity); return 0, "rehydrate_components_missing" end

    -- Serialized cards deliberately keep gameplay/modded component state, but these two
    -- fields are native inventory registration history and must belong to the new entity.
    pcall(ComponentSetValue2, item, "mItemUid", 0)
    pcall(ComponentSetValue2, item, "mFramePickedUp", 0)
    if x ~= nil then pcall(ComponentSetValue2, item, "inventory_slot", x, y or 0) end
    if inventory_parent then
        pcall(ComponentSetValue2, item, "permanently_attached", false)
        pcall(ComponentSetValue2, item, "has_been_picked_by_player", true)
    end
    local added = parent ~= nil and parent ~= 0 and pcall(EntityAddChild, parent, entity)
    if parent ~= nil and parent ~= 0 and (not added or tonumber(EntityGetParent(entity) or 0) ~= tonumber(parent)) then
        pcall(EntityKill, entity)
        return 0, "rehydrate_attach_failed"
    end
    if x ~= nil then
        pcall(ComponentSetValue2, item, "inventory_slot", x, y or 0)
        local ok_slot, actual_x, actual_y = pcall(ComponentGetValue2, item, "inventory_slot")
        if not ok_slot or tonumber(actual_x) ~= tonumber(x) or tonumber(actual_y or 0) ~= tonumber(y or 0) then
            pcall(EntityKill, entity)
            return 0, "rehydrate_slot_failed"
        end
    end
    nested_parent_mode(entity, parent)
    return entity, "ok"
end

-- Full/unsafe builds can sidestep the stale native Item/Inventory registration entirely.
-- We serialize the real spell, recreate it as a fresh entity with the same complete ECS
-- state, and attach that fresh entity at the requested inventory cell. This is the same
-- class of entity that catalogue-created cards use, which is the path Noita already honors
-- exactly. Old entities are retired through GameKillInventoryItem when applicable so the
-- private InventoryComponent.items vector cannot keep a stale registration behind.
local function rebuild_full_exact_rehydrated(player, assignments)
    local bridge = exact_rehydrate_bridge()
    if bridge == nil then return nil, "rehydrate_unavailable" end
    local snapshot, reason = inventory_slots.snapshot(player, "inventory_full")
    if snapshot == nil then return false, reason end
    local requested = assignment_map(assignments)
    if next(requested) == nil then return false, "no_assignments" end

    local records, requested_entities, destinations = {}, {}, {}
    local needs_rehydrate = false
    for entity, desired in pairs(requested) do
        if not EntityGetIsAlive(entity) or not is_action(entity) then return false, "invalid_action" end
        local old_x, old_y, item = item_slot(entity)
        if not valid(item) then return false, "not_item" end
        if desired.x < 0 or desired.y < 0 or desired.x >= snapshot.width or desired.y >= snapshot.height then
            return false, "slot_out_of_range"
        end
        local ok_uid, uid = pcall(ComponentGetValue2, item, "mItemUid")
        local ok_frame, picked_frame = pcall(ComponentGetValue2, item, "mFramePickedUp")
        if (ok_uid and (tonumber(uid) or 0) ~= 0) or (ok_frame and (tonumber(picked_frame) or 0) ~= 0)
            or (EntityGetParent(entity) or 0) ~= 0
        then needs_rehydrate = true end
        local ok_data, serialized = pcall(bridge.SerializeEntity, entity)
        if not ok_data or serialized == nil then return false, "rehydrate_serialize_failed" end
        local key = policy.slot_key(desired.x, desired.y)
        if destinations[key] ~= nil and destinations[key] ~= entity then return false, "occupied", destinations[key] end
        destinations[key] = entity
        records[#records+1] = {
            entity=entity, serialized=serialized, old_parent=EntityGetParent(entity) or 0,
            old_x=old_x, old_y=old_y or 0, x=desired.x, y=desired.y,
        }
        requested_entities[entity]=true
    end
    if not needs_rehydrate then return nil, "fresh_entity" end
    for _, record in ipairs(records) do
        local occupied = snapshot.by_slot[policy.slot_key(record.x,record.y)]
        if occupied ~= nil and occupied.entity ~= record.entity and requested_entities[occupied.entity] ~= true then
            return false, "occupied", occupied.entity
        end
    end
    table.sort(records,function(a,b)
        if a.y ~= b.y then return a.y < b.y end
        if a.x ~= b.x then return a.x < b.x end
        return tonumber(a.entity) < tonumber(b.entity)
    end)

    -- Retire every old registration only after every entity serialized successfully.
    for _, record in ipairs(records) do
        local old_parent_name = record.old_parent ~= 0 and EntityGetName(record.old_parent) or ""
        if old_parent_name == "inventory_full" and EntityGetRootEntity(record.old_parent) == player
            and type(GameKillInventoryItem) == "function"
        then
            pcall(GameKillInventoryItem, player, record.entity)
        end
        if EntityGetIsAlive(record.entity) then
            if (EntityGetParent(record.entity) or 0) ~= 0 then pcall(EntityRemoveFromParent, record.entity) end
            pcall(EntityKill, record.entity)
        end
    end

    local created = {}

    -- A fresh catalog card is the one path the real game demonstrably accepts into an exact
    -- full-inventory cell. Rehydration therefore only creates the fresh ECS entity; the
    -- final registration still goes through the exact same GamePickUpInventoryItem +
    -- sentinel transaction as a catalog-created card. Direct EntityAddChild here would
    -- recreate the original bug by bypassing InventoryComponent.items again.
    local function create_into_inventory(serialized, x, y)
        local entity, create_reason = rehydrate_create(bridge, serialized, 0, x, y, false)
        if entity == 0 then return 0, create_reason end
        local placed, place_reason = engine_pickup_exact(player, entity, snapshot.inventory, snapshot.width, snapshot.height, x, y)
        if not placed then
            if EntityGetIsAlive(entity) then pcall(EntityKill, entity) end
            return 0, place_reason
        end
        return entity, "ok"
    end

    local function rollback()
        for _, entity in ipairs(created) do if EntityGetIsAlive(entity) then pcall(EntityKill,entity) end end
        created = {}
        -- Entity ids cannot be restored after rehydration, but the complete serialized
        -- spell state and its original parent/slot are restored transactionally. Inventory
        -- parents are restored through native pickup so their private item vector is rebuilt.
        for _, record in ipairs(records) do
            local inv_parent = record.old_parent ~= 0 and EntityGetName(record.old_parent) == "inventory_full"
                and EntityGetRootEntity(record.old_parent) == player
            local restored = 0
            if inv_parent then
                restored = select(1, create_into_inventory(record.serialized, record.old_x, record.old_y))
            else
                restored = select(1, rehydrate_create(bridge,record.serialized,record.old_parent,record.old_x,record.old_y,false))
            end
            if restored ~= 0 then created[#created+1]=restored end
        end
        force_refresh(player)
    end

    local expected, replacements = {}, {}
    for _, record in ipairs(records) do
        local entity, create_reason = create_into_inventory(record.serialized, record.x, record.y)
        if entity == 0 then rollback(); return false, create_reason end
        created[#created+1]=entity
        replacements[record.entity]=entity
        expected[#expected+1]={entity=entity,parent=snapshot.inventory,x=record.x,y=record.y,replaces=record.entity}
    end
    force_refresh(player)
    return true, "rehydrated", expected, replacements
end

local function rebuild_full_exact(player, assignments)
    local ok, reason, expected, replacements = rebuild_full_exact_rehydrated(player, assignments)
    if ok ~= nil then return ok, reason, expected, replacements end
    return rebuild_full_exact_legacy(player, assignments)
end

function inventory_slots.rebuild_full_exact(player, assignments)
    return rebuild_full_exact(player, assignments)
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

    if inventory_name == "inventory_full" then
        return rebuild_full_exact(player, {{entity=entity,x=x,y=y}})
    end

    local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
    if not valid(item) then return false, "not_item" end
    local old_parent = EntityGetParent(entity) or 0
    local old_x, old_y = item_slot(entity)
    if not detach_verified(entity) then return false, "detach_failed" end
    local prepared = pcall(ComponentSetValue2, item, "inventory_slot", x, y)
    if not prepared then
        restore_parent(entity, old_parent, old_x, old_y)
        return false, "slot_write_failed"
    end
    local added = pcall(EntityAddChild, snapshot.inventory, entity)
    if not added or EntityGetParent(entity) ~= snapshot.inventory then
        restore_parent(entity, old_parent, old_x, old_y)
        return false, "attach_failed"
    end
    local wrote = pcall(ComponentSetValue2, item, "inventory_slot", x, y)
    local read_ok, actual_x, actual_y = pcall(ComponentGetValue2, item, "inventory_slot")
    if not wrote or not read_ok or tonumber(actual_x) ~= x or (tonumber(actual_y) or 0) ~= y then
        restore_parent(entity, old_parent, old_x, old_y)
        return false, "slot_write_failed"
    end
    enable_inventory(entity)
    force_refresh(player)
    return true, "ok", {{entity=entity,parent=snapshot.inventory,x=x,y=y}}
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

    if name == "inventory_full" then
        return rebuild_full_exact(player, {
            {entity=left_entity,x=rx,y=ry},
            {entity=right_entity,x=lx,y=ly},
        })
    end

    local function restore_swap()
        if (EntityGetParent(left_entity) or 0) ~= 0 then pcall(EntityRemoveFromParent, left_entity) end
        if (EntityGetParent(right_entity) or 0) ~= 0 then pcall(EntityRemoveFromParent, right_entity) end
        pcall(ComponentSetValue2, li, "inventory_slot", lx, ly)
        pcall(ComponentSetValue2, ri, "inventory_slot", rx, ry)
        pcall(EntityAddChild, left_parent, left_entity)
        pcall(EntityAddChild, left_parent, right_entity)
        pcall(ComponentSetValue2, li, "inventory_slot", lx, ly)
        pcall(ComponentSetValue2, ri, "inventory_slot", rx, ry)
        enable_inventory(left_entity)
        enable_inventory(right_entity)
        force_refresh(player)
    end

    if not detach_verified(left_entity) or not detach_verified(right_entity) then
        restore_swap()
        return false, "swap_detach_failed"
    end
    local left_prepared = pcall(ComponentSetValue2, li, "inventory_slot", rx, ry)
    local right_prepared = left_prepared and pcall(ComponentSetValue2, ri, "inventory_slot", lx, ly)
    local left_added = right_prepared and pcall(EntityAddChild, left_parent, left_entity)
    local right_added = left_added and pcall(EntityAddChild, left_parent, right_entity)
    local left_ok = right_added and pcall(ComponentSetValue2, li, "inventory_slot", rx, ry)
    local right_ok = left_ok and pcall(ComponentSetValue2, ri, "inventory_slot", lx, ly)
    local verify_left, actual_lx, actual_ly = pcall(ComponentGetValue2, li, "inventory_slot")
    local verify_right, actual_rx, actual_ry = pcall(ComponentGetValue2, ri, "inventory_slot")
    if not right_ok or EntityGetParent(left_entity) ~= left_parent or EntityGetParent(right_entity) ~= left_parent
        or not verify_left or not verify_right
        or tonumber(actual_lx) ~= rx or (tonumber(actual_ly) or 0) ~= (tonumber(ry) or 0)
        or tonumber(actual_rx) ~= lx or (tonumber(actual_ry) or 0) ~= (tonumber(ly) or 0)
    then
        restore_swap()
        return false, "swap_failed"
    end
    enable_inventory(left_entity)
    enable_inventory(right_entity)
    force_refresh(player)
    return true, "ok", {
        {entity=left_entity,parent=left_parent,x=rx,y=ry},
        {entity=right_entity,parent=left_parent,x=lx,y=ly},
    }
end

METAMORPH_CREATIVE_MENU_INVENTORY_SLOTS = inventory_slots
return inventory_slots
