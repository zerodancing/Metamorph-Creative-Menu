if type(METAMORPH_CREATIVE_MENU_FORM_COMBAT) == "table" then return METAMORPH_CREATIVE_MENU_FORM_COMBAT end

local form_combat = {}

local entity_tree = dofile("mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua")
local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local tree_cache = dofile("mods/metamorph_creative_menu/files/features/forms/entity_tree_cache.lua")

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
local secondary_attack_cache = nil
local secondary_attack_cursor = 1
local secondary_attack_global_next = 0
local pending_secondary_attack = nil
local sprite_animation_cache = {}

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
            if looks_barrel or (current ~= entity and looks_turret) then
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

local function configure_non_ai_player(entity)
    local controls = ensure_controls(entity)

    set_component_type_enabled_tree(entity, "PathFindingComponent", false)
    ensure_native_polymorph_attack_carrier(entity)

    walk_entity_tree(entity, function(current)
        for _, animal in ipairs(EntityGetComponentIncludingDisabled(current, "AnimalAIComponent") or {}) do
            local static_turret = get_value(animal, "is_static_turret", false) == true
            local ranged_path = tostring(get_value(animal, "attack_ranged_entity_file", "") or "")
            pcall(ComponentSetValue2, animal, "sense_creatures", false)
            pcall(ComponentSetValue2, animal, "attack_melee_enabled", false)
            pcall(ComponentSetValue2, animal, "attack_dash_enabled", false)
            -- polymorph_hax requires both the projectile path and the authored enable
            -- bit. giantshooter deliberately ships with this bit off for autonomous AI,
            -- which made both variants unable to fire as player forms. Autonomous AI
            -- remains component-disabled, so enabling the metadata cannot create NPC fire.
            pcall(ComponentSetValue2, animal, "attack_ranged_enabled", ranged_path ~= "")
            -- Never blank attack_ranged_entity_file. Static turrets keep only their
            -- presentation loop so the barrel/laser sight can animate toward our cursor.
            pcall(EntitySetComponentIsEnabled, current, animal, static_turret)
        end
        for _, attack in ipairs(EntityGetComponentIncludingDisabled(current, "AIAttackComponent") or {}) do
            -- AIAttackComponent is attack metadata consumed by polymorph firing. Keep it
            -- enabled; autonomous target selection is already disabled at AnimalAI.
            pcall(EntitySetComponentIsEnabled, current, attack, true)
        end
    end)

    if valid(controls) then
        -- Primary fire belongs to Noita's native polymorph controller. Manual replay of
        -- the same attack animation/projectile can trigger authored attack callbacks a
        -- second time, producing the observed double-shot/double-melee regression.
        pcall(ComponentSetValue2, controls, "polymorph_hax", true)
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
    local x, y, _, scale_x = EntityGetTransform(owner)
    if x == nil then
        owner = entity
        x, y, _, scale_x = EntityGetTransform(entity)
    end
    if x == nil then return nil end
    local ox = tonumber(get_value(comp, "attack_ranged_offset_x", 0)) or 0
    local oy = tonumber(get_value(comp, "attack_ranged_offset_y", 0)) or 0
    ox = ox + (tonumber(get_value(comp, "attack_ranged_root_offset_x", 0)) or 0)
    oy = oy + (tonumber(get_value(comp, "attack_ranged_root_offset_y", 0)) or 0)
    if (tonumber(scale_x) or 1) < 0 then ox = -ox end
    return owner, x + ox, y + oy
end

local function sprite_animation_names(path)
    path = tostring(path or "")
    if path == "" then return nil end
    if sprite_animation_cache[path] ~= nil then return sprite_animation_cache[path] end
    local names = {}
    local ok, content = pcall(ModTextFileGetContent, path)
    if not ok or type(content) ~= "string" then
        sprite_animation_cache[path] = false
        return false
    end
    for tag in string.gmatch(content, "<RectAnimation.-%>") do
        local name = string.match(tag, "name%s*=%s*['\"]([^'\"]+)['\"]")
        if name ~= nil and name ~= "" then names[name] = true end
    end
    sprite_animation_cache[path] = names
    return names
end

local function play_attack_animation(entity, name, priority)
    name = tostring(name or "")
    if entity == nil or entity == 0 or name == "" then return end
    priority = tonumber(priority) or 30
    -- Many creatures keep visible sprites on child entities. Route the authored attack
    -- to every entity that actually exposes it; do not force CharacterPlatforming's
    -- animation_to_play field, since that can pin a form in a missing animation and
    -- suppress its native jump, landing, hurt and idle transitions.
    walk_entity_tree(entity, function(current)
        if not valid(component(current, "SpriteAnimatorComponent")) then return end
        local supported = false
        local unknown = false
        for _, sprite in ipairs(EntityGetComponentIncludingDisabled(current, "SpriteComponent") or {}) do
            local path = tostring(get_value(sprite, "image_file", "") or "")
            local names = sprite_animation_names(path)
            if type(names) == "table" and names[name] == true then supported = true break end
            if path == "" or names == false then unknown = true end
        end
        if supported or unknown then pcall(GamePlayAnimation, current, name, priority, "", 0) end
    end)
end

-- LMB remains Noita's native polymorph primary attack. Every distinct authored
-- AIAttack beyond that primary becomes an RMB attack. When several exist, repeated RMB
-- shots rotate through the ready attacks while preserving each component's cooldown,
-- projectile count, muzzle offset, action frame and animation.
local function detect_secondary_attacks(entity)
    local primary = ""
    for _, animal in ipairs(tree_components(entity, "AnimalAIComponent")) do
        local path = tostring(get_value(animal, "attack_ranged_entity_file", "") or "")
        if path ~= "" then primary = path; break end
    end
    if primary == "" then return {} end

    local unique = {}
    local extras = {}
    for _, attack in ipairs(tree_components(entity, "AIAttackComponent")) do
        local path = tostring(get_value(attack, "attack_ranged_entity_file", "") or "")
        if path ~= "" and not unique[path]
            and boolean_value(get_value(attack, "attack_ranged_use_message", false)) ~= true
            and ModDoesFileExist(path)
        then
            unique[path] = true
            if path ~= primary then
                extras[#extras + 1] = {
                    component = attack,
                    path = path,
                    frames = math.max(1, tonumber(get_value(attack, "frames_between", 30)) or 30),
                    global_frames = math.max(1, tonumber(get_value(attack, "frames_between_global", 1)) or 1),
                    count_min = math.max(1, tonumber(get_value(attack, "attack_ranged_entity_count_min", 1)) or 1),
                    count_max = math.max(1, tonumber(get_value(attack, "attack_ranged_entity_count_max", 1)) or 1),
                    action_frame = math.max(0, tonumber(get_value(attack, "attack_ranged_action_frame", 0)) or 0),
                    animation = tostring(get_value(attack, "animation_name", "attack_ranged") or "attack_ranged"),
                    next_frame = 0,
                }
            end
        end
    end
    return extras
end

local function projectile_count(attack)
    local low = math.max(1, math.floor(tonumber(attack.count_min) or 1))
    local high = math.max(low, math.floor(tonumber(attack.count_max) or low))
    if high == low then return low end
    if type(Random) == "function" then
        local ok, value = pcall(Random, low, high)
        if ok and tonumber(value) ~= nil then return math.max(low, math.min(high, tonumber(value))) end
    end
    return low
end

local function fire_projectile_attack(entity, attack)
    if type(attack) ~= "table" or not valid(attack.component) then return false end
    local owner, sx, sy = ranged_origin(entity, attack.component)
    if owner == nil then return false end
    local tx, ty = mouse_target(sx, sy)
    local fired = false
    for _ = 1, projectile_count(attack) do
        local projectile = EntityLoad(attack.path, sx, sy)
        if projectile ~= nil and projectile ~= 0 then
            local shot_ok = pcall(GameShootProjectile, entity, sx, sy, tx, ty, projectile, true)
            if shot_ok then
                fired = true
            else
                -- EntityLoad succeeded but the engine rejected the shoot call. Do not
                -- leave a live projectile at the muzzle or start a false cooldown.
                pcall(EntityKill, projectile)
            end
        end
    end
    return fired
end

local function update_secondary_attacks(entity)
    local controls = ensure_controls(entity)
    if not valid(controls) then return false end
    local frame = tonumber(GameGetFrameNum()) or 0

    if pending_secondary_attack ~= nil and frame >= pending_secondary_attack.fire_at then
        local pending = pending_secondary_attack
        pending_secondary_attack = nil
        if not fire_projectile_attack(entity, pending.attack) then
            -- The attack was reserved before its authored action frame. A native shoot
            -- failure must not consume the creature's cooldown: restore the exact state
            -- observed before reservation so the player may retry immediately.
            pending.attack.next_frame = pending.previous_next_frame
            secondary_attack_global_next = pending.previous_global_next
            pcall(ComponentSetValue2, pending.attack.component, "mNextFrameUsable", pending.previous_component_next)
        end
    end

    if get_value(controls, "mButtonDownFire2", false) ~= true
        or pending_secondary_attack ~= nil
        or frame < secondary_attack_global_next
    then
        return false
    end
    if secondary_attack_cache == nil then secondary_attack_cache = detect_secondary_attacks(entity) end
    local attacks = secondary_attack_cache
    if type(attacks) ~= "table" or #attacks == 0 then return false end

    local selected = nil
    local selected_index = nil
    for offset = 0, #attacks - 1 do
        local index = ((secondary_attack_cursor - 1 + offset) % #attacks) + 1
        local attack = attacks[index]
        if valid(attack.component) then
            local native_next = tonumber(get_value(attack.component, "mNextFrameUsable", 0)) or 0
            if frame >= math.max(native_next, tonumber(attack.next_frame) or 0) then
                selected, selected_index = attack, index
                break
            end
        end
    end
    if selected == nil then return false end

    if selected.animation ~= "" then play_attack_animation(entity, selected.animation, 40) end
    local previous_next_frame = tonumber(selected.next_frame) or 0
    local previous_component_next = tonumber(get_value(selected.component, "mNextFrameUsable", 0)) or 0
    local previous_global_next = secondary_attack_global_next
    selected.next_frame = frame + selected.frames
    secondary_attack_global_next = frame + selected.global_frames
    pcall(ComponentSetValue2, selected.component, "mNextFrameUsable", selected.next_frame)
    pending_secondary_attack = {
        attack = selected,
        fire_at = frame + selected.action_frame,
        previous_next_frame = previous_next_frame,
        previous_component_next = previous_component_next,
        previous_global_next = previous_global_next,
    }
    secondary_attack_cursor = (selected_index % #attacks) + 1
    if selected.action_frame == 0 then
        local pending = pending_secondary_attack
        pending_secondary_attack = nil
        if not fire_projectile_attack(entity, selected) then
            selected.next_frame = pending.previous_next_frame
            secondary_attack_global_next = pending.previous_global_next
            pcall(ComponentSetValue2, selected.component, "mNextFrameUsable", pending.previous_component_next)
            return false
        end
    end
    return true
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
        local authored_arc = tonumber(get_value(comp, "creature_detection_angular_range_deg", 170)) or 170
        local full_arc = math.max(20, math.min(170, authored_arc > 0 and authored_arc or 170))
        local relative = shortest_angle_delta(aim_state.base, desired)
        local half_arc = math.rad(full_arc * 0.5)
        relative = math.max(-half_arc, math.min(half_arc, relative))
        desired = aim_state.base + relative
    end
    local raw_speed = math.abs(tonumber(get_value(comp, "attack_ranged_aim_rotation_speed", 3)) or 3)
    -- The field is not consistently authored in one unit across vanilla entities:
    -- small values behave like radians/frame while larger values are effectively
    -- degree-like tuning. Convert both to radians and apply a responsive player floor.
    -- A player-controlled turret should track intent, not spend seconds catching up.
    local native_step = raw_speed <= 1 and raw_speed or math.rad(raw_speed)
    local step = math.max(math.rad(12), native_step)
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
        local owner, sx, sy = ranged_origin(entity, attack)
        if owner ~= nil then step_manual_aim(attack, owner, sx, sy) end
    end

    for _, animal in ipairs(tree_components(entity, "AnimalAIComponent")) do
        if get_value(animal, "attack_ranged_aim_rotation_enabled", false) == true then
            local owner = ComponentGetEntity(animal)
            if owner == nil or owner == 0 then owner = entity end
            local x, y = EntityGetTransform(owner)
            if x ~= nil then
                local ox = tonumber(get_value(animal, "attack_ranged_offset_x", 0)) or 0
                local oy = tonumber(get_value(animal, "attack_ranged_offset_y", 0)) or 0
                local aim_angle = step_manual_aim(animal, owner, x + ox, y + oy)

                if get_value(animal, "is_static_turret", false) == true then
                    local target = ensure_turret_target()
                    if target ~= 0 then
                        local a = tonumber(aim_angle)
                        local tx, ty
                        if a ~= nil then
                            tx, ty = x + ox + math.cos(a) * 800, y + oy + math.sin(a) * 800
                        else
                            tx, ty = mouse_target(x + ox, y + oy)
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

local function update_manual_lasers(entity)
    local lasers = tree_components(entity, "LaserEmitterComponent")
    if #lasers == 0 then return end
    local controls = ensure_controls(entity)
    if not valid(controls) then return end
    local has_ranged = #tree_components(entity, "AIAttackComponent") > 0
    local fire
    if has_ranged then
        fire = get_value(controls, "mButtonDownFire2", false) == true
    else
        fire = get_value(controls, "mButtonDownFire", false) == true
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
    if turret_aim_target ~= 0 and EntityGetIsAlive(turret_aim_target) then EntityKill(turret_aim_target) end
    turret_aim_target = 0
    turret_aim_state = {}
    secondary_attack_cache = nil
    secondary_attack_cursor = 1
    secondary_attack_global_next = 0
    pending_secondary_attack = nil
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
form_combat.setup_manual_barrels = setup_manual_barrels
form_combat.play_attack_animation = play_attack_animation
form_combat.update_secondary_attacks = update_secondary_attacks
form_combat.update_manual_aim = update_manual_aim
form_combat.update_manual_lasers = update_manual_lasers
form_combat.tree_has_laser = function(entity) return #tree_components(entity, "LaserEmitterComponent") > 0 end

METAMORPH_CREATIVE_MENU_FORM_COMBAT = form_combat
return form_combat
