-- Pure slot planning shared by the runtime and the offline regression suite.
-- Coordinates are zero based, matching ItemComponent.inventory_slot.
local inventory_policy = {}

function inventory_policy.slot_key(x, y)
    return tostring(math.floor(tonumber(x) or -1)) .. ":" .. tostring(math.floor(tonumber(y) or -1))
end

function inventory_policy.first_free(width, height, occupied)
    width = math.max(0, math.floor(tonumber(width) or 0))
    height = math.max(0, math.floor(tonumber(height) or 0))
    occupied = type(occupied) == "table" and occupied or {}
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            if not occupied[inventory_policy.slot_key(x, y)] then return x, y end
        end
    end
    return nil
end

function inventory_policy.first_free_range(first_x, count, occupied)
    first_x = math.max(0, math.floor(tonumber(first_x) or 0))
    count = math.max(0, math.floor(tonumber(count) or 0))
    occupied = type(occupied) == "table" and occupied or {}
    for x = first_x, first_x + count - 1 do
        if not occupied[inventory_policy.slot_key(x, 0)] then return x, 0 end
    end
    return nil
end

function inventory_policy.destination(is_action)
    -- Action cards are the only entities allowed in inventory_full. Wands,
    -- potions, tablets and every other held item belong to inventory_quick.
    return is_action == true and "inventory_full" or "inventory_quick"
end

function inventory_policy.plan(width, height, occupied)
    local x, y = inventory_policy.first_free(width, height, occupied)
    if x == nil then return { kind="world", reason="full" } end
    return { kind="inventory", x=x, y=y }
end


function inventory_policy.plan_range(first_x, count, occupied)
    local x, y = inventory_policy.first_free_range(first_x, count, occupied)
    if x == nil then return { kind="world", reason="full" } end
    return { kind="inventory", x=x, y=y }
end

return inventory_policy
