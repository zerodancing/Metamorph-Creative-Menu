if type(METAMORPH_CREATIVE_MENU_DIAGNOSTIC_ENTITY_INSPECTION) == "table" then return METAMORPH_CREATIVE_MENU_DIAGNOSTIC_ENTITY_INSPECTION end

local entity_inspection = {}

function entity_inspection.summary(entity)
    if entity == nil or entity == 0 or not EntityGetIsAlive(entity) then return "entity=0/dead" end
    local filename = tostring(EntityGetFilename(entity) or "")
    local x, y = EntityGetTransform(entity)
    local children = EntityGetAllChildren(entity) or {}
    local components = EntityGetAllComponents(entity) or {}
    return string.format("entity=%d file=%s pos=%.1f,%.1f children=%d components=%d poly=%s ew_client=%s",
        entity, filename, tonumber(x) or 0, tonumber(y) or 0, #children, #components,
        tostring(EntityHasTag(entity, "polymorphed_player")), tostring(EntityHasTag(entity, "ew_client")))
end

function entity_inspection.variable_string(entity, wanted_name)
    if entity == nil or entity == 0 or not EntityGetIsAlive(entity) then return "" end
    for _, component in ipairs(EntityGetComponentIncludingDisabled(entity, "VariableStorageComponent") or {}) do
        local name_read, component_name = pcall(ComponentGetValue2, component, "name")
        if name_read and tostring(component_name or "") == tostring(wanted_name or "") then
            local value_read, value = pcall(ComponentGetValue2, component, "value_string")
            return value_read and tostring(value or "") or ""
        end
    end
    return ""
end

METAMORPH_CREATIVE_MENU_DIAGNOSTIC_ENTITY_INSPECTION = entity_inspection
return entity_inspection
