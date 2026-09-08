local static_weapon_presentation = {}

local aim_policy = dofile("mods/metamorph_creative_menu/files/features/forms/aim_policy.lua")
local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")

local valid = component_ops.valid
local get_value = component_ops.get

local state = nil

local function root_facing(entity, current)
    -- The body/tracks are already mirrored by Noita.  Static gun layers with
    -- has_special_scale=1 opt out of that inherited scale, which is why a playerized
    -- tank could turn its tracks while leaving the upper gun facing the old side.
    -- Prefer the actual entity transform so presentation follows exactly what the body
    -- is rendering; ControlsComponent is only a fallback for unusual physics frames.
    local _, _, _, sx = EntityGetTransform(entity)
    sx = tonumber(sx)
    if sx ~= nil and math.abs(sx) > 0.0001 then return sx < 0 and -1 or 1 end
    local controls = EntityGetFirstComponentIncludingDisabled(entity, "ControlsComponent")
    if valid(controls) then
        local left = get_value(controls, "mButtonDownLeft", false) == true
        local right = get_value(controls, "mButtonDownRight", false) == true
        if left ~= right then return right and 1 or -1 end
    end
    return current or 1
end

local function restore()
    if state == nil then return end
    for _, record in ipairs(state.layers or {}) do
        if valid(record.component) and record.owner ~= nil and record.owner ~= 0 and EntityGetIsAlive(record.owner) then
            pcall(ComponentSetValue2, record.component, "has_special_scale", record.had_special_scale == true)
            pcall(ComponentSetValue2, record.component, "special_scale_x", record.base_scale_x)
            pcall(ComponentSetValue2, record.component, "special_scale_y", record.base_scale_y)
        end
    end
end

function static_weapon_presentation.reset()
    restore()
    state = nil
end

function static_weapon_presentation.configure(entity)
    static_weapon_presentation.reset()
    if entity == nil or entity == 0 then return false end
    local layers = {}
    for _, sprite in ipairs(EntityGetComponentIncludingDisabled(entity, "SpriteComponent") or {}) do
        if aim_policy.sprite_is_static_weapon_layer(sprite) then
            layers[#layers + 1] = {
                owner = entity,
                component = sprite,
                had_special_scale = get_value(sprite, "has_special_scale", false) == true,
                base_scale_x = tonumber(get_value(sprite, "special_scale_x", 1)) or 1,
                base_scale_y = tonumber(get_value(sprite, "special_scale_y", 1)) or 1,
            }
        end
    end
    if #layers == 0 then return false end
    state = { entity=entity, layers=layers, facing=root_facing(entity, 1) }
    return true
end

function static_weapon_presentation.update(entity)
    if state == nil or entity ~= state.entity then return false end
    state.facing = root_facing(entity, state.facing)
    for _, record in ipairs(state.layers) do
        if valid(record.component) and EntityGetIsAlive(record.owner) then
            -- Let this non-rotating authored layer inherit the same entity-scale flip as
            -- the tracks/body.  This is more faithful than inventing negative
            -- special_scale values (the engine treats special scale as a separate
            -- presentation channel) and is trivially reversible on reset.
            pcall(ComponentSetValue2, record.component, "has_special_scale", false)
        end
    end
    return true
end

return static_weapon_presentation
