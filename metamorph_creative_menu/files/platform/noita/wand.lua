if type(METAMORPH_CREATIVE_MENU_WAND_API) == "table" then return METAMORPH_CREATIVE_MENU_WAND_API end

local wand_api = {}

local function valid(component)
    return component ~= nil and component ~= 0
end

function wand_api.ability(entity)
    if entity == nil or entity == 0 or not EntityGetIsAlive(entity) then return 0 end
    local ability = EntityGetFirstComponentIncludingDisabled(entity, "AbilityComponent")
    if not valid(ability) then return 0 end
    local ok, use_gun_script = pcall(ComponentGetValue2, ability, "use_gun_script")
    return ok and use_gun_script == true and ability or 0
end

function wand_api.held(player)
    if player == nil or player == 0 or not EntityGetIsAlive(player) then return 0 end
    local inventory = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
    if not valid(inventory) then return 0 end
    local candidates = {}
    for _, field in ipairs({"mActualActiveItem", "mActiveItem"}) do
        local ok, value = pcall(ComponentGetValue2, inventory, field)
        value = ok and (tonumber(value) or 0) or 0
        if value ~= 0 then candidates[#candidates + 1] = value end
    end
    local seen = {}
    for _, entity in ipairs(candidates) do
        if not seen[entity] then
            seen[entity] = true
            if wand_api.ability(entity) ~= 0 then return entity end
        end
    end
    return 0
end

function wand_api.get_scalar(ability, field)
    if not valid(ability) then return nil, false end
    local ok, value = pcall(ComponentGetValue2, ability, field)
    return ok and value or nil, ok
end

function wand_api.set_scalar(ability, field, value)
    if not valid(ability) then return false end
    local ok = pcall(ComponentSetValue2, ability, field, value)
    if not ok then return false end
    local read_ok, actual = pcall(ComponentGetValue2, ability, field)
    if not read_ok then return false end
    if type(value) == "number" then return tonumber(actual) == tonumber(value) end
    if type(value) == "boolean" then return actual == value end
    return tostring(actual or "") == tostring(value or "")
end

function wand_api.get_object(ability, object_name, field)
    if not valid(ability) then return nil, false end
    local ok, value = pcall(ComponentObjectGetValue2, ability, object_name, field)
    return ok and value or nil, ok
end

function wand_api.set_object(ability, object_name, field, value)
    if not valid(ability) then return false end
    local ok = pcall(ComponentObjectSetValue2, ability, object_name, field, value)
    if not ok then return false end
    local read_ok, actual = pcall(ComponentObjectGetValue2, ability, object_name, field)
    if not read_ok then return false end
    if type(value) == "number" then return tonumber(actual) == tonumber(value) end
    if type(value) == "boolean" then return actual == value end
    return tostring(actual or "") == tostring(value or "")
end

METAMORPH_CREATIVE_MENU_WAND_API = wand_api
return wand_api
