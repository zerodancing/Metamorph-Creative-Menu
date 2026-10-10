local root = assert(arg[1], "root required")
local native_dofile = dofile
local quick_inventory = 2
local player = 1
local item_components = {}
local slots = {}
local wand_entities = {}
local children = {}

for index = 0, 3 do
    local wand = 100 + index
    local item = 200 + index
    item_components[wand] = 1000 + wand
    item_components[item] = 1000 + item
    slots[wand] = {index, 0}
    slots[item] = {index, 0}
    wand_entities[wand] = true
    children[#children + 1] = wand
    children[#children + 1] = item
end
local target_wand = 300
local target_item = 301
item_components[target_wand] = 1300
item_components[target_item] = 1301
slots[target_wand] = {-1, 0}
slots[target_item] = {-1, 0}
wand_entities[target_wand] = true

function EntityGetIsAlive(entity) return entity ~= 0 end
function EntityGetAllChildren(entity)
    if entity == player then return {quick_inventory} end
    if entity == quick_inventory then return children end
    return {}
end
function EntityGetName(entity)
    if entity == quick_inventory then return "inventory_quick" end
    return ""
end
function EntityGetFirstComponentIncludingDisabled(entity, component_type)
    if component_type == "Inventory2Component" and entity == player then return 10 end
    if component_type == "ItemComponent" then return item_components[entity] or 0 end
    if component_type == "ItemActionComponent" then return 0 end
    if component_type == "AbilityComponent" then return 0 end
    return 0
end
function ComponentGetValue2(component, field)
    if component == 10 and field == "quick_inventory_slots" then return 10 end
    if component == 10 and field == "full_inventory_slots_x" then return 16 end
    if component == 10 and field == "full_inventory_slots_y" then return 1 end
    if field == "inventory_slot" then
        for entity, item_component in pairs(item_components) do
            if item_component == component then return slots[entity][1], slots[entity][2] end
        end
    end
    if field == "is_pickable" then return true end
    if field == "auto_pickup" then return false end
    return nil
end
function EntityHasTag(entity, tag) return tag == "wand" and wand_entities[entity] == true end

dofile = function(path)
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path, 1, #prefix) == prefix then
        return native_dofile(root .. "/" .. string.sub(path, #prefix + 1))
    end
    return native_dofile(path)
end

local inventory_slots = assert(native_dofile(root .. "/files/platform/noita/inventory_slots.lua"))

local wand_plan, wand_reason = inventory_slots.preflight(player, target_wand)
assert(wand_plan == nil and wand_reason == "full", "fifth wand must overflow instead of replacing a visible wand")
local item_plan, item_reason = inventory_slots.preflight(player, target_item)
assert(item_plan == nil and item_reason == "full", "fifth regular item must overflow instead of replacing a visible item")

-- Wand and regular-item rows intentionally share numeric slot coordinates. Freeing a
-- wand slot must not free the corresponding regular-item slot.
table.remove(children, 7) -- removes wand 103 while item 203 remains
local free_wand_plan = assert(inventory_slots.preflight(player, target_wand))
assert(free_wand_plan.x == 3 and free_wand_plan.y == 0, "wand did not reuse the freed fourth wand slot")
local still_full_item, still_full_reason = inventory_slots.preflight(player, target_item)
assert(still_full_item == nil and still_full_reason == "full", "wand-row vacancy incorrectly leaked into item row")

print("inventory_capacity=PASS four_wands=true four_items=true overflow_safe=true")
