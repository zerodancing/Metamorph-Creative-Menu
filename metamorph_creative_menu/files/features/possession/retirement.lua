local retirement = {}
local entity_tree = dofile("mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua")

local function valid_entity(entity)
    return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity)
end

function retirement.retire_without_death_side_effects(entity)
    if not valid_entity(entity) then return false end

    -- Possession is replacement, not murder. Normal EntityKill may run arbitrary
    -- death/explosion/drop scripts on the copied mob. Disable the whole tree first so
    -- retiring the replaced entity cannot create gameplay side effects.
    local entities = {}
    entity_tree.walk(entity, function(current_entity)
        if valid_entity(current_entity) then entities[#entities + 1] = current_entity end
    end)
    pcall(EntitySetTransform, entity, 10000000, 10000000)
    for _, current_entity in ipairs(entities) do
        for _, component in ipairs(EntityGetAllComponents(current_entity) or {}) do
            local type_read, component_type = pcall(ComponentGetTypeName, component)
            if type_read and component_type == "LuaComponent" then
                pcall(EntityRemoveComponent, current_entity, component)
            else
                pcall(EntitySetComponentIsEnabled, current_entity, component, false)
            end
        end
    end
    if valid_entity(entity) then pcall(EntityKill, entity) end
    return true
end

return retirement
