if type(METAMORPH_CREATIVE_MENU_FORM_COMBAT) == "table" then return METAMORPH_CREATIVE_MENU_FORM_COMBAT end

local form_combat = {}

local entity_tree = dofile("mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua")
local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local tree_cache = dofile("mods/metamorph_creative_menu/files/features/forms/entity_tree_cache.lua")
local attack_profile = dofile("mods/metamorph_creative_menu/files/features/forms/attack_profile.lua")
local aim_policy = dofile("mods/metamorph_creative_menu/files/features/forms/aim_policy.lua")

local valid = component_ops.valid
local component = component_ops.first
local get_value = component_ops.get
local boolean_value = component_ops.boolean
local ensure_controls = component_ops.ensure_controls
local set_component_type_enabled = component_ops.set_type_enabled
local set_component_type_enabled_tree = component_ops.set_type_enabled_tree
local walk_entity_tree = entity_tree.walk
local tree_components = tree_cache.components

local turret_aim_target = 0
local manual_barrel_pivots = {}
local turret_aim_state = {}
local ranged_attack_cache = nil
local ranged_attack_cursor = 1
local ranged_attack_global_next = 0
local ranged_attack_state_attack = nil
local ranged_attack_state_started = 0
local ranged_attack_state_until = 0
local pending_ranged_attack = nil
local manual_ranged_owned = false
local manual_ranged_entity = 0
local sprite_animation_cache = {}
local ranged_animation_override = nil
local restore_ranged_animation_override = nil
local detect_ranged_attacks = nil

local function component_is_enabled(comp)
    if not valid(comp) or type(ComponentGetIsEnabled) ~= "function" then return false end
    local ok, enabled = pcall(ComponentGetIsEnabled, comp)
    return ok and enabled == true
end

local function setup_manual_barrels(entity)
    manual_barrel_pivots = {}
    local seen_direct = {}
    walk_entity_tree(entity, function(current)
        for _, sprite in ipairs(EntityGetComponentIncludingDisabled(current, "SpriteComponent") or {}) do
            local image = string.lower(tostring(get_value(sprite, "image_file", "") or ""))
            local base = string.match(image, "([^/]+)%.xml$") or image
            -- Match weapon-layer *tokens*, never arbitrary substrings. v22 treated
            -- `shotgunner.xml` as a gun sprite because its creature filename contains
            -- the letters "gun"; that disabled the whole body sprite and left our
            -- presentation pivot frozen at the transformation point.
            local looks_barrel = base == "gun" or base == "shotgun" or base == "barrel" or base == "cannon"
                or string.find(base, "^gun_", 1) ~= nil or string.find(base, "_gun$", 1) ~= nil
                or string.find(base, "_gun_", 1, true) ~= nil
                or string.find(base, "^barrel_", 1) ~= nil or string.find(base, "_barrel$", 1) ~= nil
                or string.find(base, "_barrel_", 1, true) ~= nil
                or string.find(base, "^cannon_", 1) ~= nil or string.find(base, "_cannon$", 1) ~= nil
                or string.find(base, "_cannon_", 1, true) ~= nil
            local looks_turret = string.find(base, "turret", 1, true) ~= nil
            local static_weapon_layer = aim_policy.sprite_is_static_weapon_layer(sprite)
            if (looks_barrel or (current ~= entity and looks_turret)) and not static_weapon_layer then
                if current ~= entity and not seen_direct[current] then
                    -- Child gun entities are already natural rotation pivots in many
                    -- vanilla machines. Preserve their sprites/animations and rotate the
                    -- child itself instead of replacing it with a static picture.
                    seen_direct[current] = true
                    manual_barrel_pivots[#manual_barrel_pivots + 1] = { entity=current, direct=true, aim_offset=nil }
                elseif current == entity then
                    -- Only split an actual gun/barrel/cannon layer. A root image named
                    -- `turret.xml` is usually the *whole machine*; rotating a copy of it
                    -- made the tracks orbit around the body. Root-only monolithic turret
                    -- sprites therefore stay native while child barrels still rotate.
                    local pivot = EntityCreateNew("metamorph_creative_menu_manual_barrel") or 0
                    if pivot ~= 0 then
                        EntityAddTag(pivot, "metamorph_creative_menu_runtime")
                        local ok_sprite, created = pcall(EntityAddComponent2, pivot, "SpriteComponent", {
                            image_file = tostring(get_value(sprite, "image_file", "") or ""),
                            rect_animation = tostring(get_value(sprite, "rect_animation", "") or ""),
                            offset_x = tonumber(get_value(sprite, "offset_x", 0)) or 0,
                            offset_y = tonumber(get_value(sprite, "offset_y", 0)) or 0,
                            z_index = tonumber(get_value(sprite, "z_index", 0)) or 0,
                            alpha = tonumber(get_value(sprite, "alpha", 1)) or 1,
                            emissive = get_value(sprite, "emissive", false) == true,
                            additive = get_value(sprite, "additive", false) == true,
                            has_special_scale = get_value(sprite, "has_special_scale", false) == true,
                            special_scale_x = tonumber(get_value(sprite, "special_scale_x", 1)) or 1,
                            special_scale_y = tonumber(get_value(sprite, "special_scale_y", 1)) or 1,
                        })
                        if ok_sprite and created ~= nil and created ~= 0 then
                            local x, y = EntityGetTransform(entity)
                            if x ~= nil then EntitySetTransform(pivot, x, y) end
                            pcall(EntitySetComponentIsEnabled, entity, sprite, false)
                            manual_barrel_pivots[#manual_barrel_pivots + 1] = { entity=pivot, direct=false, aim_offset=nil }
                        else
                            EntityKill(pivot)
                        end
                    end
                end
            end
        end
    end)
end

local function rotate_manual_barrels(entity, angle, previous_aim, aim_x, aim_y)
    if entity == nil or entity == 0 or #manual_barrel_pivots == 0 then return end
    local _, _, _, root_sx, root_sy = EntityGetTransform(entity)
    root_sx, root_sy = tonumber(root_sx) or 1, tonumber(root_sy) or 1
    previous_aim = tonumber(previous_aim) or tonumber(angle) or 0
    for _, record in ipairs(manual_barrel_pivots) do
        local pivot = type(record) == "table" and record.entity or record
        local direct = type(record) == "table" and record.direct == true
        if pivot ~= nil and pivot ~= 0 and EntityGetIsAlive(pivot) then
            local x, y, rotation, sx, sy = EntityGetTransform(pivot)
            if x ~= nil then
                rotation = tonumber(rotation) or 0
                sx, sy = tonumber(sx) or 1, tonumber(sy) or 1
                if type(record) == "table" and record.aim_offset == nil then
                    -- Calibrate against the entity's native aim angle instead of assuming
                    -- every vanilla barrel sprite is authored pointing right. This keeps
                    -- left-facing/mirrored and pre-rotated barrels aligned with the same
                    -- physical angle reported by mRangedAttackCurrentAimAngle.
                    record.aim_offset = rotation - previous_aim
                end
                local visual_rotation = (tonumber(angle) or 0) + (type(record) == "table" and tonumber(record.aim_offset) or 0)
                if not direct then
                    -- Standalone presentation pivots are positioned on the entity's
                    -- actual ranged-attack origin, not at the body's track/feet origin.
                    -- This keeps the visible hinge aligned with the muzzle height.
                    if aim_x ~= nil and aim_y ~= nil then x, y = aim_x, aim_y end
                    sx, sy = root_sx, root_sy
                end
                pcall(EntitySetTransform, pivot, x, y, visual_rotation, sx, sy)
            end
        end
    end
end

local function first_ranged_attack_metadata(entity)
    local first = nil
    walk_entity_tree(entity, function(current)
        for _, attack in ipairs(EntityGetComponentIncludingDisabled(current, "AIAttackComponent") or {}) do
            local path = tostring(get_value(attack, "attack_ranged_entity_file", "") or "")
            if path ~= "" then
                first = {
                    path = path,
                    frames = tonumber(get_value(attack, "frames_between", 30)) or 30,
                    offset_x = tonumber(get_value(attack, "attack_ranged_offset_x", 0)) or 0,
                    offset_y = tonumber(get_value(attack, "attack_ranged_offset_y", 0)) or 0,
                    use_message = boolean_value(get_value(attack, "attack_ranged_use_message", false)) == true,
                }
                return false
            end
        end
    end)
    return first
end

local function ensure_native_polymorph_attack_carrier(entity)
    local animal = component(entity, "AnimalAIComponent")
    local metadata = first_ranged_attack_metadata(entity)
    if not valid(animal) and metadata ~= nil then
        local ok, created = pcall(EntityAddComponent2, entity, "AnimalAIComponent", {
            attack_ranged_enabled = true,
            attack_ranged_entity_file = metadata.path,
            attack_ranged_frames_between = metadata.frames,
            attack_ranged_offset_x = metadata.offset_x,
            attack_ranged_offset_y = metadata.offset_y,
            attack_ranged_use_message = metadata.use_message == true,
            sense_creatures = false,
        })
        if ok and valid(created) then
            animal = created
            pcall(EntitySetComponentIsEnabled, entity, animal, false)
        end
    elseif valid(animal) then
        local path = tostring(get_value(animal, "attack_ranged_entity_file", "") or "")
        if path == "" and metadata ~= nil then
            pcall(ComponentSetValue2, animal, "attack_ranged_entity_file", metadata.path)
            pcall(ComponentSetValue2, animal, "attack_ranged_frames_between", metadata.frames)
            pcall(ComponentSetValue2, animal, "attack_ranged_offset_x", metadata.offset_x)
            pcall(ComponentSetValue2, animal, "attack_ranged_offset_y", metadata.offset_y)
        end
    end
    return animal
end

local function ranged_ownership_capability(entity)
    local direct = 0
    local contextual = 0
    walk_entity_tree(entity, function(current)
        for _, animal in ipairs(EntityGetComponentIncludingDisabled(current, "AnimalAIComponent") or {}) do
            local path = tostring(get_value(animal, "attack_ranged_entity_file", "") or "")
            -- A non-empty direct descriptor is an authored attack capability even when
            -- attack_ranged_enabled is currently false. Vanilla Lua can toggle that flag
            -- later (coward/limit_projectiles) without recreating the component. Claim the
            -- descriptor now, but attack_logically_enabled() still gates every actual shot.
            if path ~= "" then
                if boolean_value(get_value(animal, "attack_ranged_use_message", false)) == true then
                    contextual = contextual + 1
                else
                    direct = direct + 1
                end
            end
        end
        for _, attack in ipairs(EntityGetComponentIncludingDisabled(current, "AIAttackComponent") or {}) do
            local path = tostring(get_value(attack, "attack_ranged_entity_file", "") or "")
            if path ~= "" then
                if boolean_value(get_value(attack, "attack_ranged_use_message", false)) == true then
                    contextual = contextual + 1
                else
                    direct = direct + 1
                end
            end
        end
    end)
    -- Message-based attacks depend on an item/use-message context that the public Lua
    -- API cannot faithfully replay. In mixed/direct+message creatures we deliberately
    -- leave Noita's native polymorph path in charge rather than double-fire one half.
    return direct > 0 and contextual == 0
end

local function configure_ranged_player(entity)
    if manual_ranged_owned and manual_ranged_entity == entity and ranged_attack_cache ~= nil then return true end
    restore_ranged_animation_override()
    manual_ranged_owned = ranged_ownership_capability(entity)
    ranged_attack_cache = nil
    ranged_attack_cursor = 1
    ranged_attack_global_next = 0
    ranged_attack_state_attack = nil
    ranged_attack_state_started = 0
    ranged_attack_state_until = 0
    pending_ranged_attack = nil
    manual_ranged_entity = manual_ranged_owned and entity or 0
    if not manual_ranged_owned then return false end

    -- Keep authored attack descriptors untouched. Manual ownership is isolated by
    -- disabling ControlsComponent.polymorph_hax instead of blanking projectile paths or
    -- forcing AIAttackComponent enabled state. This makes external component disables and
    -- an intentional empty attack_ranged_entity_file observable on the very next update.
    if type(detect_ranged_attacks) == "function" then detect_ranged_attacks(entity) end
    return true
end

local function configure_non_ai_player(entity)
    local controls = ensure_controls(entity)

    set_component_type_enabled_tree(entity, "PathFindingComponent", false)
    local manual_ranged = configure_ranged_player(entity)
    if not manual_ranged then ensure_native_polymorph_attack_carrier(entity) end

    walk_entity_tree(entity, function(current)
        for _, animal in ipairs(EntityGetComponentIncludingDisabled(current, "AnimalAIComponent") or {}) do
            local static_turret = get_value(animal, "is_static_turret", false) == true
            local ranged_path = tostring(get_value(animal, "attack_ranged_entity_file", "") or "")
            pcall(ComponentSetValue2, animal, "sense_creatures", false)
            pcall(ComponentSetValue2, animal, "attack_melee_enabled", false)
            pcall(ComponentSetValue2, animal, "attack_dash_enabled", false)
            if not manual_ranged then
                -- Compatibility fallback for contextual/message attacks: retain the old
                -- native polymorph carrier exactly as before.
                pcall(ComponentSetValue2, animal, "attack_ranged_enabled", ranged_path ~= "")
            end
            -- When MCM owns direct ranged attacks, AnimalAI must not execute them. Keep
            -- AIAttackComponent itself untouched so external phase/mod enable state stays
            -- observable through ComponentGetIsEnabled(). Contextual native fallback keeps
            -- the old static-turret presentation loop.
            pcall(EntitySetComponentIsEnabled, current, animal, (not manual_ranged) and static_turret)
        end
    end)

    if valid(controls) then
        pcall(ComponentSetValue2, controls, "polymorph_hax", not manual_ranged)
    end

    if not valid(component(entity, "Inventory2Component")) then
        set_component_type_enabled(entity, "ItemPickUpperComponent", false)
    end
end


local function mouse_target(x, y)
    local tx, ty = x + 48, y
    local ok, mx, my = pcall(DEBUG_GetMouseWorld)
    if ok and mx ~= nil and my ~= nil then return mx, my end
    return tx, ty
end

local function target_angle(sx, sy, tx, ty)
    if type(math.atan2) == "function" then return math.atan2(ty - sy, tx - sx) end
    if tx ~= sx then
        local angle = math.atan((ty - sy) / (tx - sx))
        if tx < sx then angle = angle + math.pi end
        return angle
    end
    return ty < sy and (-math.pi * 0.5) or (math.pi * 0.5)
end

local function shortest_angle_delta(current, target)
    local two_pi = math.pi * 2
    return ((target - current + math.pi) % two_pi) - math.pi
end

local function ranged_origin(entity, comp)
    local owner = ComponentGetEntity(comp)
    if owner == nil or owner == 0 then owner = entity end
    local x, y, rotation, scale_x = EntityGetTransform(owner)
    if x == nil then
        owner = entity
        x, y, rotation, scale_x = EntityGetTransform(entity)
    end
    if x == nil then return nil end
    rotation = tonumber(rotation) or 0
    scale_x = tonumber(scale_x) or 1

    -- AIAttackComponent's root offset is the physical rotation pivot. Vanilla tank
    -- data makes this explicit: the gun SpriteComponent has transform_offset.y=-5 and
    -- both AIAttacks use attack_ranged_root_offset_y=-5. The ranged offset is the
    -- muzzle vector relative to that pivot, so aimed weapons must rotate that vector
    -- with mRangedAttackCurrentAimAngle instead of adding both offsets in world space.
    local root_x = tonumber(get_value(comp, "attack_ranged_root_offset_x", 0)) or 0
    local root_y = tonumber(get_value(comp, "attack_ranged_root_offset_y", 0)) or 0
    if scale_x < 0 then root_x = -root_x end
    local pivot_x, pivot_y = x + root_x, y + root_y

    local ox = tonumber(get_value(comp, "attack_ranged_offset_x", 0)) or 0
    local oy = tonumber(get_value(comp, "attack_ranged_offset_y", 0)) or 0
    local aimed = boolean_value(get_value(comp, "attack_ranged_aim_rotation_enabled", false)) == true
    local static_weapon = aimed and aim_policy.static_weapon_attack(entity, comp)
    if aimed and not static_weapon then
        local angle = tonumber(get_value(comp, "mRangedAttackCurrentAimAngle", rotation)) or rotation
        local ca, sa = math.cos(angle), math.sin(angle)
        local rx = ox * ca - oy * sa
        local ry = ox * sa + oy * ca
        return owner, pivot_x + rx, pivot_y + ry, pivot_x, pivot_y
    end

    if scale_x < 0 then ox = -ox end
    return owner, pivot_x + ox, pivot_y + oy, pivot_x, pivot_y
end

local function sprite_animation_metadata(path)
    path = tostring(path or "")
    if path == "" then return nil end
    if sprite_animation_cache[path] ~= nil then
        return sprite_animation_cache[path] ~= false and sprite_animation_cache[path] or nil
    end
    local ok, content = pcall(ModTextFileGetContent, path)
    if not ok or type(content) ~= "string" then
        sprite_animation_cache[path] = false
        return nil
    end
    local animations = {}
    for tag in string.gmatch(content, "<RectAnimation.-%>") do
        local name = string.match(tag, "name%s*=%s*['\"]([^'\"]+)['\"]")
        if name ~= nil and name ~= "" then
            local loop_value = string.match(tag, "loop%s*=%s*['\"]([^'\"]+)['\"]")
            animations[name] = {
                frame_wait = tonumber(string.match(tag, "frame_wait%s*=%s*['\"]([^'\"]+)['\"]")),
                frame_count = tonumber(string.match(tag, "frame_count%s*=%s*['\"]([^'\"]+)['\"]")),
                loop = loop_value == "1" or loop_value == "true",
            }
        end
    end
    sprite_animation_cache[path] = animations
    return animations
end

local function play_attack_animation(entity, name, priority)
    name = tostring(name or "")
    if entity == nil or entity == 0 or name == "" then return end
    priority = tonumber(priority) or 30
    walk_entity_tree(entity, function(current)
        if not valid(component(current, "SpriteAnimatorComponent")) then return end
        local supported = false
        local unknown = false
        for _, sprite in ipairs(EntityGetComponentIncludingDisabled(current, "SpriteComponent") or {}) do
            local path = tostring(get_value(sprite, "image_file", "") or "")
            local animations = sprite_animation_metadata(path)
            if type(animations) == "table" and animations[name] ~= nil then supported = true break end
            if path == "" or animations == nil then unknown = true end
        end
        if supported or unknown then pcall(GamePlayAnimation, current, name, priority, "", 0) end
    end)
end

restore_ranged_animation_override = function()
    local state = ranged_animation_override
    ranged_animation_override = nil
    if type(state) ~= "table" then return end
    for _, record in ipairs(state.sprites or {}) do
        if valid(record.component) and record.owner ~= nil and record.owner ~= 0 and EntityGetIsAlive(record.owner) then
            pcall(ComponentSetValue2, record.component, "rect_animation", record.rect_animation or "")
            pcall(ComponentSetValue2, record.component, "next_rect_animation", record.next_rect_animation or "")
            if type(EntityRefreshSprite) == "function" then pcall(EntityRefreshSprite, record.owner, record.component) end
        end
    end
    for _, record in ipairs(state.animators or {}) do
        if valid(record.component) and record.owner ~= nil and record.owner ~= 0 and EntityGetIsAlive(record.owner) then
            pcall(EntitySetComponentIsEnabled, record.owner, record.component, record.enabled == true)
        end
    end
end

local function start_ranged_animation_override(entity, animation_name, frame, authored_state_frames)
    animation_name = tostring(animation_name or "")
    if entity == nil or entity == 0 or animation_name == "" then return false end
    restore_ranged_animation_override()

    local state = { entity=entity, sprites={}, animators={}, end_frame=frame + math.max(1, tonumber(authored_state_frames) or 1) }
    local animator_seen = {}
    local longest = 0
    local has_loop = false

    walk_entity_tree(entity, function(current)
        local supported_sprites = {}
        for _, sprite in ipairs(EntityGetComponentIncludingDisabled(current, "SpriteComponent") or {}) do
            local image = tostring(get_value(sprite, "image_file", "") or "")
            local animations = sprite_animation_metadata(image)
            local metadata = type(animations) == "table" and animations[animation_name] or nil
            if type(metadata) == "table" then
                supported_sprites[#supported_sprites + 1] = { component=sprite, metadata=metadata }
                local wait = tonumber(metadata.frame_wait) or 0.07
                local count = math.max(1, tonumber(metadata.frame_count) or 1)
                longest = math.max(longest, math.ceil(wait * 60 * count))
                if metadata.loop == true then has_loop = true end
            end
        end
        if #supported_sprites == 0 then return end

        -- SpriteAnimatorComponent is the system that races our manual attack animation
        -- with walk/fly/landing. Suspend only that visual state switcher for the short
        -- authored attack window. SpriteComponent itself continues advancing rect frames.
        for _, animator in ipairs(EntityGetComponentIncludingDisabled(current, "SpriteAnimatorComponent") or {}) do
            if not animator_seen[animator] then
                animator_seen[animator] = true
                local enabled = true
                if type(ComponentGetIsEnabled) == "function" then
                    local ok_enabled, value = pcall(ComponentGetIsEnabled, animator)
                    if ok_enabled then enabled = value == true end
                end
                state.animators[#state.animators + 1] = {owner=current,component=animator,enabled=enabled}
                pcall(EntitySetComponentIsEnabled, current, animator, false)
            end
        end
        for _, data in ipairs(supported_sprites) do
            local sprite = data.component
            state.sprites[#state.sprites + 1] = {
                owner=current, component=sprite,
                rect_animation=tostring(get_value(sprite, "rect_animation", "") or ""),
                next_rect_animation=tostring(get_value(sprite, "next_rect_animation", "") or ""),
            }
            pcall(ComponentSetValue2, sprite, "rect_animation", animation_name)
            -- Do not force `stand` as a follow-up. The saved/native locomotion state is
            -- restored when the short override ends, so an airborne shot can land safely.
            pcall(ComponentSetValue2, sprite, "next_rect_animation", "")
            pcall(EntitySetComponentIsEnabled, current, sprite, true)
            if type(EntityRefreshSprite) == "function" then pcall(EntityRefreshSprite, current, sprite) end
        end
    end)

    if #state.sprites == 0 then
        -- Unknown sprite setup: retain the old public API fallback, but never use this
        -- path for normal authored creature sprites where we can release ownership cleanly.
        play_attack_animation(entity, animation_name, 30)
        return false
    end

    local authored = math.max(1, math.floor(tonumber(authored_state_frames) or longest or 1))
    if has_loop then
        state.end_frame = frame + authored
    else
        state.end_frame = frame + math.max(1, longest > 0 and math.min(authored, longest) or authored)
    end
    ranged_animation_override = state
    return true
end

local function animation_frame_wait(entity, animation_name)
    animation_name = tostring(animation_name or "")
    if animation_name == "" then return nil end
    local found = nil
    walk_entity_tree(entity, function(current)
        for _, sprite in ipairs(EntityGetComponentIncludingDisabled(current, "SpriteComponent") or {}) do
            local path = tostring(get_value(sprite, "image_file", "") or "")
            local animations = sprite_animation_metadata(path)
            local metadata = type(animations) == "table" and animations[animation_name] or nil
            if type(metadata) == "table" and tonumber(metadata.frame_wait) ~= nil then
                found = tonumber(metadata.frame_wait)
                return false
            end
        end
    end)
    return found
end

local function normalize_attack_component(comp, source_kind)
    if not valid(comp) then return nil end
    local is_multi = source_kind == "ai_attack"
    local prefix = is_multi and "" or "attack_ranged_"
    local path = tostring(get_value(comp, "attack_ranged_entity_file", "") or "")
    if path == "" then return nil end
    local use_message = boolean_value(get_value(comp, "attack_ranged_use_message", false)) == true
    if use_message then return nil end
    return attack_profile.normalize({
        source_kind = source_kind,
        component = comp,
        path = path,
        frames = get_value(comp, is_multi and "frames_between" or "attack_ranged_frames_between", 30),
        global_frames = is_multi and get_value(comp, "frames_between_global", 0) or 0,
        count_min = get_value(comp, "attack_ranged_entity_count_min", 1),
        count_max = get_value(comp, "attack_ranged_entity_count_max", 1),
        action_frame = get_value(comp, "attack_ranged_action_frame", 0),
        animation = is_multi and get_value(comp, "animation_name", "attack_ranged") or "attack_ranged",
        min_distance = get_value(comp, is_multi and "min_distance" or "attack_ranged_min_distance", 0),
        max_distance = get_value(comp, is_multi and "max_distance" or "attack_ranged_max_distance", 10000),
        use_probability = is_multi and get_value(comp, "use_probability", 100) or 100,
        state_duration_frames = get_value(comp, is_multi and "state_duration_frames" or "attack_ranged_state_duration_frames", 45),
        angular_range_deg = is_multi and get_value(comp, "angular_range_deg", 90) or 90,
        offset_x = get_value(comp, "attack_ranged_offset_x", 0),
        offset_y = get_value(comp, "attack_ranged_offset_y", 0),
        root_offset_x = is_multi and get_value(comp, "attack_ranged_root_offset_x", 0) or 0,
        root_offset_y = is_multi and get_value(comp, "attack_ranged_root_offset_y", 0) or 0,
        use_message = false,
        landing_required = get_value(comp, "attack_landing_ranged_enabled", false),
        predict = get_value(comp, "attack_ranged_predict", false),
        aim_rotation_enabled = get_value(comp, "attack_ranged_aim_rotation_enabled", false),
        aim_rotation_speed = get_value(comp, "attack_ranged_aim_rotation_speed", 3),
        aim_ok_angle_deg = get_value(comp, "attack_ranged_aim_rotation_shooting_ok_angle_deg", 10),
        use_laser_sight = get_value(comp, "attack_ranged_use_laser_sight", false),
        next_frame = 0,
    })
end

detect_ranged_attacks = function(entity)
    if ranged_attack_cache ~= nil then return ranged_attack_cache end
    local attacks = {}
    -- AIAttackComponent is a real multi-attack descriptor. Never deduplicate by
    -- projectile path: vanilla can author two attacks with the same projectile but
    -- different range/count/cooldown/origin semantics.
    for _, comp in ipairs(tree_components(entity, "AIAttackComponent")) do
        local attack = normalize_attack_component(comp, "ai_attack")
        if attack ~= nil then attacks[#attacks + 1] = attack end
    end
    for _, comp in ipairs(tree_components(entity, "AnimalAIComponent")) do
        local attack = normalize_attack_component(comp, "animal")
        if attack ~= nil then attacks[#attacks + 1] = attack end
    end
    ranged_attack_cache = attacks
    return attacks
end

local function projectile_count(attack)
    local random_fn = type(Random) == "function" and Random or nil
    return attack_profile.projectile_count(attack, random_fn)
end

local function ranged_target(attack, sx, sy)
    if type(attack) == "table" and attack.aim_rotation_enabled == true and valid(attack.component) then
        local owner = ComponentGetEntity(attack.component)
        local root = owner ~= nil and owner ~= 0 and EntityGetRootEntity(owner) or 0
        if not aim_policy.static_weapon_attack(root, attack.component) then
            local angle = tonumber(get_value(attack.component, "mRangedAttackCurrentAimAngle", nil))
            if angle ~= nil then return sx + math.cos(angle) * 1000, sy + math.sin(angle) * 1000 end
        end
    end
    return mouse_target(sx, sy)
end

local function refresh_attack_from_component(attack, suppress_native_path)
    if type(attack) ~= "table" or not valid(attack.component) then return end
    local comp = attack.component
    local is_multi = attack.source_kind == "ai_attack"
    local changed_path = tostring(get_value(comp, "attack_ranged_entity_file", "") or "")
    -- The live component is authoritative, including an intentional empty string. MCM no
    -- longer hides its own carrier blank in this field, so a phase script or another mod
    -- can disable/rewrite the attack without stale shadow projectile state surviving.
    attack.path = changed_path
    attack.frames = math.max(0, tonumber(get_value(comp, is_multi and "frames_between" or "attack_ranged_frames_between", attack.frames)) or attack.frames or 0)
    attack.global_frames = is_multi and math.max(0, tonumber(get_value(comp, "frames_between_global", attack.global_frames)) or attack.global_frames or 0) or 0
    attack.count_min = math.max(1, math.floor(tonumber(get_value(comp, "attack_ranged_entity_count_min", attack.count_min)) or attack.count_min or 1))
    attack.count_max = math.max(attack.count_min, math.floor(tonumber(get_value(comp, "attack_ranged_entity_count_max", attack.count_max)) or attack.count_max or attack.count_min))
    attack.action_frame = math.max(0, math.floor(tonumber(get_value(comp, "attack_ranged_action_frame", attack.action_frame)) or attack.action_frame or 0))
    local min_distance = math.max(0, tonumber(get_value(comp, is_multi and "min_distance" or "attack_ranged_min_distance", attack.min_distance)) or attack.min_distance or 0)
    local max_distance = math.max(0, tonumber(get_value(comp, is_multi and "max_distance" or "attack_ranged_max_distance", attack.max_distance)) or attack.max_distance or 10000)
    if max_distance < min_distance then min_distance, max_distance = max_distance, min_distance end
    attack.min_distance, attack.max_distance = min_distance, max_distance
    attack.offset_x = tonumber(get_value(comp, "attack_ranged_offset_x", attack.offset_x)) or attack.offset_x or 0
    attack.offset_y = tonumber(get_value(comp, "attack_ranged_offset_y", attack.offset_y)) or attack.offset_y or 0
    attack.use_message = boolean_value(get_value(comp, "attack_ranged_use_message", attack.use_message)) == true
    attack.landing_required = boolean_value(get_value(comp, "attack_landing_ranged_enabled", attack.landing_required)) == true
    attack.predict = boolean_value(get_value(comp, "attack_ranged_predict", attack.predict)) == true
    attack.aim_rotation_enabled = boolean_value(get_value(comp, "attack_ranged_aim_rotation_enabled", attack.aim_rotation_enabled)) == true
    attack.aim_rotation_speed = tonumber(get_value(comp, "attack_ranged_aim_rotation_speed", attack.aim_rotation_speed)) or attack.aim_rotation_speed or 3
    attack.aim_ok_angle_deg = tonumber(get_value(comp, "attack_ranged_aim_rotation_shooting_ok_angle_deg", attack.aim_ok_angle_deg)) or attack.aim_ok_angle_deg or 10
    attack.use_laser_sight = boolean_value(get_value(comp, "attack_ranged_use_laser_sight", attack.use_laser_sight)) == true
    if is_multi then
        attack.animation = tostring(get_value(comp, "animation_name", attack.animation) or attack.animation or "attack_ranged")
        attack.root_offset_x = tonumber(get_value(comp, "attack_ranged_root_offset_x", attack.root_offset_x)) or attack.root_offset_x or 0
        attack.root_offset_y = tonumber(get_value(comp, "attack_ranged_root_offset_y", attack.root_offset_y)) or attack.root_offset_y or 0
        attack.state_duration_frames = math.max(0, math.floor(tonumber(get_value(comp, "state_duration_frames", attack.state_duration_frames)) or attack.state_duration_frames or 45))
        attack.angular_range_deg = math.max(0, math.min(90, tonumber(get_value(comp, "angular_range_deg", attack.angular_range_deg)) or attack.angular_range_deg or 90))
        attack.use_probability = math.max(0, math.min(100, math.floor(tonumber(get_value(comp, "use_probability", attack.use_probability)) or attack.use_probability or 100)))
    else
        attack.state_duration_frames = math.max(0, math.floor(tonumber(get_value(comp, "attack_ranged_state_duration_frames", attack.state_duration_frames)) or attack.state_duration_frames or 45))
    end
end

local function refresh_attack_after_shot(attack)
    refresh_attack_from_component(attack)
end

local function sync_dynamic_attack_metadata(entity)
    if not manual_ranged_owned then return end
    local attacks = detect_ranged_attacks(entity)
    local known = {}
    for _, attack in ipairs(attacks) do
        if type(attack) == "table" and valid(attack.component) then known[attack.component] = attack end
    end

    -- Entity LuaComponents (and external mods) may add a new direct attack descriptor
    -- after the form has already been configured. Discover those components every frame
    -- instead of treating the initial snapshot as the complete lifetime attack set.
    -- Contextual Message_UseItem descriptors remain native because they cannot be
    -- faithfully replayed by this layer.
    local function claim_new(comp, source_kind)
        if known[comp] ~= nil or not valid(comp) then return end
        local use_message = boolean_value(get_value(comp, "attack_ranged_use_message", false)) == true
        local path = tostring(get_value(comp, "attack_ranged_entity_file", "") or "")
        if use_message or path == "" then return end
        local attack = normalize_attack_component(comp, source_kind)
        if attack == nil then return end
        attacks[#attacks + 1] = attack
        known[comp] = attack
    end

    for _, comp in ipairs(tree_components(entity, "AIAttackComponent")) do claim_new(comp, "ai_attack") end
    for _, comp in ipairs(tree_components(entity, "AnimalAIComponent")) do claim_new(comp, "animal") end

    for _, attack in ipairs(attacks) do refresh_attack_from_component(attack) end
end

local function attack_logically_enabled(attack)
    if type(attack) ~= "table" or not valid(attack.component) or tostring(attack.path or "") == "" then return false end
    if attack.source_kind == "animal" then
        return boolean_value(get_value(attack.component, "attack_ranged_enabled", true)) == true
    end
    if attack.source_kind == "ai_attack" then
        return component_is_enabled(attack.component)
    end
    return true
end

local function fire_projectile_attack(entity, attack)
    if type(attack) ~= "table" or not valid(attack.component) or tostring(attack.path or "") == "" then return false end
    local owner, sx, sy = ranged_origin(entity, attack.component)
    if owner == nil then return false end
    local tx, ty = ranged_target(attack, sx, sy)
    local fired = false
    local volley_path = attack.path
    for _ = 1, projectile_count(attack) do
        -- Load the exact authored entity. The projectile's own ProjectileComponent then
        -- owns speed/lob/direction_random_rad/muzzle flash/callbacks just as in vanilla.
        -- Keep one immutable path for this whole volley: Message_Shot may author the
        -- *next* attack, but it must not change later projectiles in the current volley.
        local projectile = EntityLoad(volley_path, sx, sy)
        if projectile ~= nil and projectile ~= 0 then
            local shot_ok = pcall(GameShootProjectile, entity, sx, sy, tx, ty, projectile, true)
            if shot_ok then
                fired = true
            else
                pcall(EntityKill, projectile)
            end
        end
    end
    if fired then refresh_attack_after_shot(attack) end
    return fired
end

local function component_next_frame(attack)
    if type(attack) ~= "table" or not valid(attack.component) then return 0 end
    if attack.source_kind == "ai_attack" then
        return tonumber(get_value(attack.component, "mNextFrameUsable", 0)) or 0
    end
    if attack.source_kind == "animal" then
        return tonumber(get_value(attack.component, "mRangedAttackNextFrame", 0)) or 0
    end
    return 0
end

local function set_component_next_frame(attack, value)
    if type(attack) ~= "table" or not valid(attack.component) then return end
    if attack.source_kind == "ai_attack" then
        pcall(ComponentSetValue2, attack.component, "mNextFrameUsable", tonumber(value) or 0)
    elseif attack.source_kind == "animal" then
        pcall(ComponentSetValue2, attack.component, "mRangedAttackNextFrame", tonumber(value) or 0)
    end
end

local function attack_is_aimed(entity, attack)
    if type(attack) ~= "table" or attack.aim_rotation_enabled ~= true then return true end
    if aim_policy.static_weapon_attack(entity, attack.component) then return true end
    local owner, _, _, pivot_x, pivot_y = ranged_origin(entity, attack.component)
    if owner == nil then return false end
    local current = tonumber(get_value(attack.component, "mRangedAttackCurrentAimAngle", nil))
    if current == nil then return true end
    local tx, ty = mouse_target(pivot_x, pivot_y)
    local desired = target_angle(pivot_x, pivot_y, tx, ty)
    local tolerance = math.rad(math.max(0, tonumber(attack.aim_ok_angle_deg) or 10))
    return math.abs(shortest_angle_delta(current, desired)) <= tolerance
end

local function landing_ready(entity, attack)
    if type(attack) ~= "table" or attack.landing_required ~= true then return true end
    -- This authored flag is a hard attack precondition. CharacterDataComponent is the
    -- engine's own collision-ground state and avoids inventing raycast thresholds.
    for _, comp in ipairs(tree_components(entity, "CharacterDataComponent")) do
        if boolean_value(get_value(comp, "is_on_ground", false)) == true then return true end
    end
    return false
end

local function ready_attacks(entity, frame)
    local ready = {}
    for _, attack in ipairs(detect_ranged_attacks(entity)) do
        if valid(attack.component)
            and attack_logically_enabled(attack)
            and frame >= math.max(tonumber(attack.next_frame) or 0, component_next_frame(attack))
            and landing_ready(entity, attack)
            and attack_is_aimed(entity, attack)
        then
            ready[#ready + 1] = attack
        end
    end
    return ready
end

local function cursor_distance(entity)
    local x, y = EntityGetTransform(entity)
    if x == nil then return 0 end
    local tx, ty = mouse_target(x, y)
    local dx, dy = tx - x, ty - y
    return math.sqrt(dx * dx + dy * dy)
end

local function attack_ready_now(entity, attack, frame)
    if type(attack) ~= "table" or not valid(attack.component) or not attack_logically_enabled(attack) then return false end
    if frame < math.max(tonumber(attack.next_frame) or 0, component_next_frame(attack)) then return false end
    if not landing_ready(entity, attack) or not attack_is_aimed(entity, attack) then return false end
    -- Player authority must not inherit the AI's target-acquisition radius. Range still
    -- participates in primary attack selection (attack_profile.select_primary), but once
    -- a profile is selected its authored state/cooldown remains usable wherever the
    -- cursor moves. The projectile itself is still fired toward the real cursor target.
    return true
end

local function select_primary_attack(entity, frame)
    -- AIAttackComponent.state_duration_frames is an authored state lock: once the AI
    -- selects an attack, other attack states are not allowed until this window expires.
    -- Keep the same profile selected while it is locked; if its own local cooldown has
    -- not elapsed, holding fire simply waits instead of randomly switching weapons.
    if ranged_attack_state_attack ~= nil and frame < ranged_attack_state_until then
        if attack_ready_now(entity, ranged_attack_state_attack, frame) then return ranged_attack_state_attack end
        return nil
    end
    ranged_attack_state_attack = nil
    ranged_attack_state_started = 0
    ranged_attack_state_until = 0
    local ready = ready_attacks(entity, frame)
    if #ready == 0 then return nil end
    local random_fn = type(Random) == "function" and Random or nil
    return attack_profile.select_primary(ready, cursor_distance(entity), random_fn)
end

local function select_secondary_attack(entity, frame)
    local attacks = detect_ranged_attacks(entity)
    if #attacks == 0 then return nil end
    -- A creature may author its entire ranged behavior in one AIAttackComponent while
    -- keeping AnimalAI.attack_ranged_enabled=0. That sole real descriptor must remain
    -- usable from the secondary fire surface; requiring two profiles resurrected the
    -- old false assumption that a dormant AnimalAI projectile path was a real attack.
    if #attacks == 1 then
        local attack = attacks[1]
        return attack_ready_now(entity, attack, frame) and attack or nil
    end
    for offset = 0, #attacks - 1 do
        local index = ((ranged_attack_cursor - 1 + offset) % #attacks) + 1
        local attack = attacks[index]
        if attack_ready_now(entity, attack, frame) then
            ranged_attack_cursor = (index % #attacks) + 1
            return attack
        end
    end
    return nil
end

local function restore_attack_reservation(pending)
    if type(pending) ~= "table" or type(pending.attack) ~= "table" then return end
    pending.attack.next_frame = pending.previous_next_frame
    ranged_attack_global_next = pending.previous_global_next
    set_component_next_frame(pending.attack, pending.previous_component_next)
end

local function flush_pending_attack(entity)
    if pending_ranged_attack == nil then return false end
    local pending = pending_ranged_attack
    pending_ranged_attack = nil
    if fire_projectile_attack(entity, pending.attack) then
        -- Message_Shot may rewrite the next projectile/cooldown (Boss Wizard is a
        -- vanilla example). The reservation starts at attack entry, but must use the
        -- post-callback authored intervals for the *next* attack.
        local started = tonumber(pending.started_at) or 0
        pending.attack.next_frame = started + math.max(0, tonumber(pending.attack.frames) or 0)
        ranged_attack_global_next = started + math.max(0, tonumber(pending.attack.global_frames) or 0)
        set_component_next_frame(pending.attack, pending.attack.next_frame)
        if ranged_attack_state_attack == pending.attack then
            -- Message_Shot may also change state_duration_frames. Rebase the end of the
            -- authored attack state on the frame where that state was first entered,
            -- never on every projectile fired from within it; otherwise rapid-fire
            -- attacks would extend their state indefinitely.
            ranged_attack_state_until = ranged_attack_state_started + math.max(0, tonumber(pending.attack.state_duration_frames) or 45)
        end
        return true
    end
    restore_attack_reservation(pending)
    return false
end

local function begin_ranged_attack(entity, attack, frame)
    if type(attack) ~= "table" then return false end
    if ranged_attack_state_attack ~= attack or frame >= ranged_attack_state_until then
        ranged_attack_state_attack = attack
        ranged_attack_state_started = frame
        ranged_attack_state_until = frame + math.max(0, tonumber(attack.state_duration_frames) or 45)
    end
    if attack.animation ~= "" then
        start_ranged_animation_override(entity, attack.animation, frame, attack.state_duration_frames)
    end
    local previous_next_frame = tonumber(attack.next_frame) or 0
    local previous_component_next = component_next_frame(attack)
    local previous_global_next = ranged_attack_global_next
    attack.next_frame = frame + math.max(0, tonumber(attack.frames) or 0)
    ranged_attack_global_next = frame + math.max(0, tonumber(attack.global_frames) or 0)
    set_component_next_frame(attack, attack.next_frame)
    local frame_wait = animation_frame_wait(entity, attack.animation)
    local delay = attack_profile.animation_delay_frames(attack, frame_wait, 60)
    pending_ranged_attack = {
        attack = attack,
        fire_at = frame + delay,
        previous_next_frame = previous_next_frame,
        previous_component_next = previous_component_next,
        previous_global_next = previous_global_next,
        started_at = frame,
    }
    if delay == 0 then return flush_pending_attack(entity) end
    return true
end

local function update_ranged_attacks(entity, allow_secondary, allow_primary)
    if allow_secondary == nil then allow_secondary = true end
    if allow_primary == nil then allow_primary = true end
    if not manual_ranged_owned then
        -- A form can acquire its first direct ranged descriptor after transformation
        -- (Lua init, delayed component creation, or another mod). Retry ownership here
        -- rather than permanently falling back to polymorph_hax based on frame-zero state.
        -- Contextual Message_UseItem-only forms still fail capability detection and stay native.
        if not configure_ranged_player(entity) then return false end
    end
    -- Vanilla LuaComponents and external mods can mutate an existing AnimalAI/AIAttack
    -- descriptor while the form is alive. Refresh from the live component before input;
    -- polymorph_hax is disabled while MCM owns the direct ranged path, so descriptors can
    -- remain untouched and continue serving as the compatibility source of truth.
    sync_dynamic_attack_metadata(entity)
    local controls = ensure_controls(entity)
    if not valid(controls) then return false end
    -- ensure_controls() enables the generic polymorph helper by default. Manual ranged
    -- ownership replaces only its attack path, so keep that native helper off here.
    pcall(ComponentSetValue2, controls, "polymorph_hax", false)
    local frame = tonumber(GameGetFrameNum()) or 0
    local completed = false

    if ranged_animation_override ~= nil and frame >= (tonumber(ranged_animation_override.end_frame) or frame) then
        restore_ranged_animation_override()
    end

    -- Release only MCM's logical attack reservation. Do not inject a synthetic `stand`
    -- animation here: landing/walking/flying are owned by Noita's locomotion controller,
    -- and a forced stand after an airborne shot was racing that controller every landing.
    -- Priority-0 attack playback above lets the native state machine replace even looped
    -- attack animations naturally as soon as locomotion changes.
    if ranged_attack_state_attack ~= nil and frame >= ranged_attack_state_until then
        ranged_attack_state_attack = nil
        ranged_attack_state_started = 0
        ranged_attack_state_until = 0
    end

    if pending_ranged_attack ~= nil then
        if frame < pending_ranged_attack.fire_at then return false end
        completed = flush_pending_attack(entity)
        if pending_ranged_attack ~= nil then return completed end
    end
    if frame < ranged_attack_global_next then return completed end

    local fire_primary = allow_primary and get_value(controls, "mButtonDownFire", false) == true
    local fire_secondary = allow_secondary and get_value(controls, "mButtonDownFire2", false) == true
    if not fire_primary and not fire_secondary then return completed end

    local selected = nil
    if fire_primary then selected = select_primary_attack(entity, frame) end
    if selected == nil and fire_secondary then selected = select_secondary_attack(entity, frame) end
    if selected == nil then return completed end
    return begin_ranged_attack(entity, selected, frame) or completed
end

local function update_secondary_attacks(entity)
    -- Stable compatibility hook for older adapters/tests that invoked the secondary
    -- driver directly. Runtime configuration normally acquires ownership first.
    if not manual_ranged_owned then configure_ranged_player(entity) end
    return update_ranged_attacks(entity)
end


local function step_manual_aim(comp, owner, sx, sy)
    if not valid(comp) then return nil end
    if get_value(comp, "attack_ranged_aim_rotation_enabled", false) ~= true then return nil end
    local tx, ty = mouse_target(sx, sy)
    local current = tonumber(get_value(comp, "mRangedAttackCurrentAimAngle", 0)) or 0
    local desired = target_angle(sx, sy, tx, ty)
    if get_value(comp, "is_static_turret", false) == true then
        local aim_state = turret_aim_state[comp]
        if aim_state == nil then
            aim_state = { base=current }
            turret_aim_state[comp] = aim_state
        end
        local authored_half_arc = tonumber(get_value(comp, "creature_detection_angular_range_deg", 90)) or 90
        -- Noita documents this value as the half-angle around the entity's X axis:
        -- 90 means the complete 180 degree forward sector (90 left + 90 right).
        -- Do not divide it a second time when translating target detection to player aim.
        authored_half_arc = math.max(0, math.min(90, authored_half_arc))
        local relative = shortest_angle_delta(aim_state.base, desired)
        local half_arc = math.rad(authored_half_arc)
        relative = math.max(-half_arc, math.min(half_arc, relative))
        desired = aim_state.base + relative
    end
    -- Preserve the engine-authored value verbatim. All vanilla ranged rotation speeds
    -- are authored as small per-frame angular steps (0.01/0.05/0.1 in current data).
    -- Converting values heuristically would reintroduce the very attack guessing this
    -- driver is meant to remove.
    local step = math.max(0.0001, math.abs(tonumber(get_value(comp, "attack_ranged_aim_rotation_speed", 3)) or 3))
    local delta = shortest_angle_delta(current, desired)
    if math.abs(delta) > step then delta = delta < 0 and -step or step end
    local next_angle = current + delta
    pcall(ComponentSetValue2, comp, "mRangedAttackCurrentAimAngle", next_angle)
    local root = owner ~= nil and owner ~= 0 and EntityGetRootEntity(owner) or 0
    rotate_manual_barrels(root, next_angle, current, sx, sy)

    -- For child-owned attack components the transform is the actual barrel in many
    -- entities. Rotate that child as well; root entities are never rotated here.
    if owner ~= nil and owner ~= 0 then
        local root = EntityGetRootEntity(owner)
        if owner ~= root then
            local x, y, _, sx_scale, sy_scale = EntityGetTransform(owner)
            if x ~= nil then pcall(EntitySetTransform, owner, x, y, next_angle, sx_scale, sy_scale) end
        end
    end
    return next_angle
end

local function ensure_turret_target()
    if turret_aim_target ~= 0 and EntityGetIsAlive(turret_aim_target) then return turret_aim_target end
    turret_aim_target = EntityCreateNew("metamorph_creative_menu_aim_target") or 0
    if turret_aim_target ~= 0 then
        EntityAddTag(turret_aim_target, "ew_no_enemy_sync")
        EntityAddTag(turret_aim_target, "metamorph_creative_menu_runtime")
    end
    return turret_aim_target
end

local function update_manual_aim(entity)
    for _, attack in ipairs(tree_components(entity, "AIAttackComponent")) do
        if component_is_enabled(attack) and tostring(get_value(attack, "attack_ranged_entity_file", "") or "") ~= ""
            and not aim_policy.static_weapon_attack(entity, attack)
        then
            local owner, _, _, pivot_x, pivot_y = ranged_origin(entity, attack)
            if owner ~= nil then step_manual_aim(attack, owner, pivot_x, pivot_y) end
        end
    end

    for _, animal in ipairs(tree_components(entity, "AnimalAIComponent")) do
        if get_value(animal, "attack_ranged_aim_rotation_enabled", false) == true then
            local owner = ComponentGetEntity(animal)
            if owner == nil or owner == 0 then owner = entity end
            local x, y = EntityGetTransform(owner)
            if x ~= nil then
                local aim_angle = step_manual_aim(animal, owner, x, y)

                if get_value(animal, "is_static_turret", false) == true then
                    local target = ensure_turret_target()
                    if target ~= 0 then
                        local a = tonumber(aim_angle)
                        local tx, ty
                        if a ~= nil then
                            tx, ty = x + math.cos(a) * 800, y + math.sin(a) * 800
                        else
                            tx, ty = mouse_target(x, y)
                        end
                        EntitySetTransform(target, tx, ty)
                        pcall(ComponentSetValue2, animal, "mGreatestPrey", target)
                        pcall(ComponentSetValue2, animal, "mGreatestThreat", target)
                        pcall(ComponentSetValue2, animal, "mHasFoundPrey", true)
                    end
                end
            end
        end
    end
end

local function update_manual_lasers(entity, allow_secondary, allow_primary)
    if allow_secondary == nil then allow_secondary = true end
    if allow_primary == nil then allow_primary = true end
    local lasers = tree_components(entity, "LaserEmitterComponent")
    if #lasers == 0 then return end
    local controls = ensure_controls(entity)
    if not valid(controls) then return end
    local fire_primary = allow_primary and get_value(controls, "mButtonDownFire", false) == true
    local fire_secondary = allow_secondary and get_value(controls, "mButtonDownFire2", false) == true
    local fire
    if manual_ranged_owned then
        fire = fire_primary or fire_secondary
    elseif #tree_components(entity, "AIAttackComponent") > 0 then
        fire = fire_secondary
    else
        fire = fire_primary
    end
    local frame = GameGetFrameNum()
    for _, laser in ipairs(lasers) do
        local owner = ComponentGetEntity(laser)
        if owner == nil or owner == 0 or not EntityGetIsAlive(owner) then owner = entity end
        local x, y, rotation = EntityGetTransform(owner)
        if x ~= nil then
            local tx, ty = mouse_target(x, y)
            local desired = target_angle(x, y, tx, ty)
            pcall(ComponentSetValue2, laser, "is_emitting", false)
            pcall(ComponentSetValue2, laser, "laser_angle_add_rad", shortest_angle_delta(tonumber(rotation) or 0, desired))
            if fire then pcall(ComponentSetValue2, laser, "emit_until_frame", frame + 2) end
        end
    end
end


function form_combat.reset()
    restore_ranged_animation_override()
    if turret_aim_target ~= 0 and EntityGetIsAlive(turret_aim_target) then EntityKill(turret_aim_target) end
    turret_aim_target = 0
    turret_aim_state = {}
    ranged_attack_cache = nil
    ranged_attack_cursor = 1
    ranged_attack_global_next = 0
    ranged_attack_state_attack = nil
    ranged_attack_state_started = 0
    ranged_attack_state_until = 0
    pending_ranged_attack = nil
    manual_ranged_owned = false
    manual_ranged_entity = 0
    for _, barrel_record in ipairs(manual_barrel_pivots) do
        local pivot_entity = type(barrel_record) == "table" and barrel_record.entity or barrel_record
        local uses_native_child = type(barrel_record) == "table" and barrel_record.direct == true
        if not uses_native_child and pivot_entity ~= nil and pivot_entity ~= 0 and EntityGetIsAlive(pivot_entity) then
            EntityKill(pivot_entity)
        end
    end
    manual_barrel_pivots = {}
end

form_combat.configure_non_ai_player = configure_non_ai_player
form_combat.configure_ranged_player = configure_ranged_player
form_combat.manual_ranged_owned = function() return manual_ranged_owned end
form_combat.setup_manual_barrels = setup_manual_barrels
form_combat.play_attack_animation = play_attack_animation
form_combat.update_ranged_attacks = update_ranged_attacks
form_combat.update_secondary_attacks = update_secondary_attacks
form_combat.update_manual_aim = update_manual_aim
form_combat.update_manual_lasers = update_manual_lasers
form_combat.tree_has_laser = function(entity) return #tree_components(entity, "LaserEmitterComponent") > 0 end

METAMORPH_CREATIVE_MENU_FORM_COMBAT = form_combat
return form_combat
