local aim_policy = {}

local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local get_value = component_ops.get
local boolean_value = component_ops.boolean

local function weapon_sprite_name(sprite)
    local image = string.lower(tostring(get_value(sprite, "image_file", "") or ""))
    return string.match(image, "([^/]+)%.xml$") or image
end

local function looks_like_weapon_layer(name)
    return name == "gun" or name == "shotgun" or name == "barrel" or name == "cannon"
        or string.find(name, "^gun_", 1) ~= nil or string.find(name, "_gun$", 1) ~= nil
        or string.find(name, "_gun_", 1, true) ~= nil
        or string.find(name, "^barrel_", 1) ~= nil or string.find(name, "_barrel$", 1) ~= nil
        or string.find(name, "_barrel_", 1, true) ~= nil
        or string.find(name, "^cannon_", 1) ~= nil or string.find(name, "_cannon$", 1) ~= nil
        or string.find(name, "_cannon_", 1, true) ~= nil
end

function aim_policy.sprite_is_static_weapon_layer(sprite)
    if sprite == nil or sprite == 0 then return false end
    if not looks_like_weapon_layer(weapon_sprite_name(sprite)) then return false end
    local update_rotation = get_value(sprite, "update_transform_rotation", true)
    return boolean_value(update_rotation) ~= true
end

function aim_policy.static_weapon_attack(entity, attack_component)
    if attack_component == nil or attack_component == 0 then return false end
    local owner = type(ComponentGetEntity) == "function" and ComponentGetEntity(attack_component) or entity
    if owner == nil or owner == 0 then owner = entity end
    local root = type(EntityGetRootEntity) == "function" and EntityGetRootEntity(owner) or owner
    -- This policy is for authored root-level presentation layers such as vanilla tanks.
    -- Child-owned turrets are genuine transform pivots and keep the normal rotation path.
    if owner ~= root then return false end
    for _, sprite in ipairs(EntityGetComponentIncludingDisabled(owner, "SpriteComponent") or {}) do
        if aim_policy.sprite_is_static_weapon_layer(sprite) then return true end
    end
    return false
end

return aim_policy
