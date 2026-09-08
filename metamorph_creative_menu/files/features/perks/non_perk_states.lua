-- Removable player states that belong next to perks in the UI but are not perks.
-- Keep them out of perk_list/perk transactions: these are vanilla essence/curse mechanics
-- with their own counters, run flags and child entities.
local states = {}

local ESSENCES = {
    { id="laser",   name_key="$item_essence_laser",   count_key="ESSENCE_LASER_PICKUP_COUNT" },
    { id="fire",    name_key="$item_essence_fire",    count_key="ESSENCE_FIRE_PICKUP_COUNT" },
    { id="water",   name_key="$item_essence_water",   count_key="ESSENCE_WATER_PICKUP_COUNT" },
    { id="air",     name_key="$item_essence_air",     count_key="ESSENCE_AIR_PICKUP_COUNT" },
    { id="alcohol", name_key="$item_essence_alcohol", count_key="ESSENCE_ALCOHOL_PICKUP_COUNT" },
}
local BY_ID = {}
for _, entry in ipairs(ESSENCES) do BY_ID[entry.id] = entry end

local function valid(entity)
    if entity == nil or entity == 0 or type(EntityGetIsAlive) ~= "function" then return false end
    local ok, alive = pcall(EntityGetIsAlive, entity)
    return ok and alive == true
end

local function children(player)
    if not valid(player) or type(EntityGetAllChildren) ~= "function" then return {} end
    local ok, result = pcall(EntityGetAllChildren, player)
    return ok and type(result) == "table" and result or {}
end

local function has_tag(entity, tag)
    if type(EntityHasTag) ~= "function" then return false end
    local ok, value = pcall(EntityHasTag, entity, tag)
    return ok and value == true
end

local function filename(entity)
    if type(EntityGetFilename) ~= "function" then return "" end
    local ok, value = pcall(EntityGetFilename, entity)
    return ok and tostring(value or "") or ""
end

local function component_value(component, field)
    if component == nil or component == 0 then return nil end
    if type(ComponentGetValue2) == "function" then
        local ok, value = pcall(ComponentGetValue2, component, field)
        if ok then return value end
    end
    if type(ComponentGetValue) == "function" then
        local ok, value = pcall(ComponentGetValue, component, field)
        if ok then return value end
    end
    return nil
end

local function icon_name(entity)
    if type(EntityGetFirstComponentIncludingDisabled) ~= "function" then return nil end
    local ok, component = pcall(EntityGetFirstComponentIncludingDisabled, entity, "UIIconComponent")
    if not ok then return nil end
    return component_value(component, "name")
end

local function essence_child_kind(child, id)
    if not has_tag(child, "essence_effect") then return nil end
    if filename(child) == "data/entities/misc/essences/" .. id .. ".xml" then return "effect" end
    if tostring(icon_name(child) or "") == "$item_essence_" .. id then return "icon" end
    return nil
end

local function essence_child_count(player, id)
    local count = 0
    for _, child in ipairs(children(player)) do
        if essence_child_kind(child, id) == "effect" then count = count + 1 end
    end
    return count
end

local function run_flag(flag)
    if type(GameHasFlagRun) ~= "function" then return false end
    local ok, value = pcall(GameHasFlagRun, flag)
    return ok and value == true
end

local function global_count(key)
    if type(GlobalsGetValue) ~= "function" then return 0 end
    local ok, value = pcall(GlobalsGetValue, key, "0")
    return ok and math.max(0, math.floor(tonumber(value) or 0)) or 0
end

local function retire_child(child)
    if not valid(child) then return true end
    if type(EntityRemoveFromParent) == "function" then pcall(EntityRemoveFromParent, child) end
    if type(EntityKill) ~= "function" then return false end
    return pcall(EntityKill, child)
end

local function reverse_fire_multiplier(player, copies)
    copies = math.max(0, math.floor(tonumber(copies) or 0))
    if copies == 0 or type(EntityGetComponent) ~= "function" then return true end
    local factor = 1.3 ^ copies
    local ok_components, components = pcall(EntityGetComponent, player, "DamageModelComponent")
    if not ok_components or type(components) ~= "table" then return true end
    for _, component in ipairs(components) do
        for _, field in ipairs({"projectile", "explosion"}) do
            local ok_read, raw = pcall(ComponentObjectGetValue, component, "damage_multipliers", field)
            local value = ok_read and tonumber(raw) or nil
            if value ~= nil and type(ComponentObjectSetValue) == "function" then
                local target = value / factor
                local ok_write = pcall(ComponentObjectSetValue, component, "damage_multipliers", field, tostring(target))
                if not ok_write then return false end
            end
        end
    end
    return true
end

local function remove_essence(player, entry, remove_all)
    if not valid(player) then return false, "player" end
    local count = global_count(entry.count_key)
    local effects, icons = {}, {}
    for _, child in ipairs(children(player)) do
        local kind = essence_child_kind(child, entry.id)
        if kind == "effect" then effects[#effects + 1] = child
        elseif kind == "icon" then icons[#icons + 1] = child end
    end
    local copies = math.max(count, #effects, #icons)
    if copies == 0 and run_flag("essence_" .. entry.id) then copies = 1 end
    if copies == 0 then return false, "not_active" end
    local removed = remove_all and copies or 1
    -- Vanilla fire pickup scales both fields once per copy. Use its counter for the
    -- inverse; entity/flag-only recovery cannot prove an unrecorded multiplier exists.
    local fire_copies = remove_all and count or math.min(count, 1)
    if entry.id == "fire" and not reverse_fire_multiplier(player, fire_copies) then
        return false, "fire_multiplier"
    end
    for _, group in ipairs({effects, icons}) do
        local limit = remove_all and #group or math.min(#group, 1)
        for index = 1, limit do
            if not retire_child(group[index]) then return false, "child_cleanup" end
        end
    end
    local remaining = math.max(0, copies - removed)
    if type(GlobalsSetValue) == "function" then pcall(GlobalsSetValue, entry.count_key, tostring(remaining)) end
    if remaining == 0 and type(GameRemoveFlagRun) == "function" then
        pcall(GameRemoveFlagRun, "essence_" .. entry.id)
    end
    -- Persistent discovery flags belong to progression, not the active effect.
    return true, "essence_removed"
end

local function greed_active(player)
    if run_flag("greed_curse") and not run_flag("greed_curse_gone") then return true end
    for _, child in ipairs(children(player)) do if has_tag(child, "greed_curse") then return true end end
    return false
end

local function remove_greed(player)
    if not valid(player) then return false, "player" end
    for _, child in ipairs(children(player)) do
        if has_tag(child, "greed_curse") and not retire_child(child) then return false, "child_cleanup" end
    end
    if type(GameRemoveFlagRun) == "function" then pcall(GameRemoveFlagRun, "greed_curse") end
    -- This is the same runtime terminal marker used by the vanilla Greed Crystal. It
    -- prevents biome/chest scripts from reactivating curse behaviour after the child dies.
    if type(GameAddFlagRun) == "function" then pcall(GameAddFlagRun, "greed_curse_gone") end
    return true, "greed_removed"
end

function states.list(player)
    local result = {}
    for _, entry in ipairs(ESSENCES) do
        local count = global_count(entry.count_key)
        local child_count = essence_child_count(player, entry.id)
        if count > 0 or child_count > 0 or run_flag("essence_" .. entry.id) then
            result[#result + 1] = {
                id="essence_" .. entry.id, kind="essence", essence_id=entry.id,
                name_key=entry.name_key, count=math.max(count, child_count, 1),
                description_key="$itemdesc_essence_" .. entry.id,
                icon="data/ui_gfx/essence_icons/" .. entry.id .. ".png",
            }
        end
    end
    if greed_active(player) then
        result[#result + 1] = { id="greed_curse", kind="curse", name_key="$item_essence_greed", count=1,
            description_key="$itemdesc_essence_greed", icon="data/items_gfx/greed_curse.png" }
    end
    return result
end

function states.remove(player, state_id)
    local id = tostring(state_id or "")
    local essence_id = string.match(id, "^essence_(.+)$")
    if essence_id ~= nil and BY_ID[essence_id] ~= nil then return remove_essence(player, BY_ID[essence_id], true) end
    if id == "greed_curse" then return remove_greed(player) end
    return false, "unknown_state"
end

function states.remove_one(player, state_id)
    local id = tostring(state_id or "")
    local essence_id = string.match(id, "^essence_(.+)$")
    if essence_id ~= nil and BY_ID[essence_id] ~= nil then return remove_essence(player, BY_ID[essence_id], false) end
    if id == "greed_curse" then return remove_greed(player) end
    return false, "unknown_state"
end

return states
