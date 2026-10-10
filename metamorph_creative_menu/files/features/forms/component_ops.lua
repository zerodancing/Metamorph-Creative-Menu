if type(METAMORPH_CREATIVE_MENU_FORM_COMPONENT_OPS) == "table" then return METAMORPH_CREATIVE_MENU_FORM_COMPONENT_OPS end

local component_ops = {}
local entity_tree = dofile("mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua")
local DEATH_GUARD_SCRIPT = "mods/metamorph_creative_menu/files/features/forms/death_guard.lua"

function component_ops.valid(value)
    return value ~= nil and value ~= 0
end

function component_ops.first(entity, component_type)
    if entity == nil or entity == 0 then return nil end
    local value = EntityGetFirstComponentIncludingDisabled(entity, component_type)
    return component_ops.valid(value) and value or nil
end

function component_ops.get(component, field, fallback)
    if not component_ops.valid(component) then return fallback end
    local ok, first, second = pcall(ComponentGetValue2, component, field)
    if not ok then return fallback end
    if second ~= nil then return first, second end
    if first == nil then return fallback end
    return first
end

function component_ops.boolean(value)
    if value == nil then return nil end
    if type(value) == "string" then
        local lower = string.lower(value)
        if lower == "true" then return true end
        if lower == "false" then return false end
        value = tonumber(value)
    end
    if type(value) == "number" then return value ~= 0 end
    return value == true
end

local function typed_scalar_value(current, value)
    local wanted_type = type(current)
    if wanted_type == "number" then
        if type(value) == "boolean" then return value and 1 or 0 end
        return tonumber(value)
    end
    if wanted_type == "boolean" then return component_ops.boolean(value) end
    if wanted_type == "string" then return tostring(value) end
    return value
end

function component_ops.set_typed_scalar(component, field, value)
    if not component_ops.valid(component) or value == nil then return false end
    local read_ok, current, extra = pcall(ComponentGetValue2, component, field)
    if not read_ok or current == nil or extra ~= nil then return false end
    local coerced = typed_scalar_value(current, value)
    if coerced == nil then return false end
    if not pcall(ComponentSetValue2, component, field, coerced) then return false end
    local verify_ok, after, after_extra = pcall(ComponentGetValue2, component, field)
    if not verify_ok or after_extra ~= nil then return false end
    if type(coerced) == "number" and type(after) == "number" then
        return math.abs(after - coerced) <= 0.000001
    end
    return after == coerced
end

function component_ops.set_fields_if_present(component, source, fields)
    if not component_ops.valid(component) then return end
    for _, field in ipairs(fields or {}) do
        local value = source ~= nil and source[field] or nil
        if value ~= nil then component_ops.set_typed_scalar(component, field, value) end
    end
end

function component_ops.ensure_controls(entity)
    local controls = component_ops.first(entity, "ControlsComponent")
    if component_ops.valid(controls) then
        pcall(ComponentSetValue2, controls, "enabled", true)
        pcall(ComponentSetValue2, controls, "polymorph_hax", true)
        pcall(EntitySetComponentIsEnabled, entity, controls, true)
        return controls
    end
    local ok, created = pcall(EntityAddComponent2, entity, "ControlsComponent", { enabled=true, polymorph_hax=true })
    if ok and component_ops.valid(created) then
        pcall(EntitySetComponentIsEnabled, entity, created, true)
        return created
    end
    return nil
end

function component_ops.set_type_enabled(entity, component_type, enabled)
    for _, component in ipairs(EntityGetComponentIncludingDisabled(entity, component_type) or {}) do
        pcall(EntitySetComponentIsEnabled, entity, component, enabled == true)
    end
end

function component_ops.set_type_enabled_tree(entity, component_type, enabled)
    entity_tree.walk(entity, function(current)
        component_ops.set_type_enabled(current, component_type, enabled)
    end)
end

function component_ops.add_death_guard(entity)
    for _, component in ipairs(EntityGetComponentIncludingDisabled(entity, "LuaComponent", "metamorph_creative_menu_form_death_guard") or {}) do
        if component_ops.valid(component) then return component end
    end
    local ok, created = pcall(EntityAddComponent2, entity, "LuaComponent", {
        _tags="metamorph_creative_menu_form_death_guard",
        script_damage_received=DEATH_GUARD_SCRIPT,
        script_death=DEATH_GUARD_SCRIPT,
        execute_every_n_frame=-1,
        remove_after_executed=false,
    })
    return ok and created or nil
end

METAMORPH_CREATIVE_MENU_FORM_COMPONENT_OPS = component_ops
return component_ops
