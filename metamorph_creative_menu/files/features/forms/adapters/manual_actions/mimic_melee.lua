local mimic_melee = {}

local entity_tree = dofile("mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua")
local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local gameplay_input = dofile("mods/metamorph_creative_menu/files/platform/noita/gameplay_input.lua")

local valid = component_ops.valid
local get_value = component_ops.get
local boolean_value = component_ops.boolean

local MIMIC_PATHS = {
    ["data/entities/animals/chest_mimic.xml"] = true,
    ["data/entities/animals/chest_leggy.xml"] = true,
    ["data/entities/animals/illusions/dark_alchemist.xml"] = true,
    ["data/entities/animals/illusions/shaman_wind.xml"] = true,
}

local state = nil
local animation_cache = {}

local function component_enabled(component)
    if not valid(component) or type(ComponentGetIsEnabled) ~= "function" then return true end
    local ok, enabled = pcall(ComponentGetIsEnabled, component)
    return not ok or enabled == true
end

local function restore_animators()
    if state == nil then return end
    for _, record in ipairs(state.animators or {}) do
        if valid(record.component) and record.owner ~= nil and record.owner ~= 0 and EntityGetIsAlive(record.owner) then
            pcall(EntitySetComponentIsEnabled, record.owner, record.component, record.enabled == true)
        end
    end
    state.animators = {}
    state.animation_end_frame = -1
end

local function suppress_animators(entity)
    if state == nil or #(state.animators or {}) > 0 then return end
    entity_tree.walk(entity, function(current)
        for _, animator in ipairs(EntityGetComponentIncludingDisabled(current, "SpriteAnimatorComponent") or {}) do
            state.animators[#state.animators + 1] = {
                owner=current, component=animator, enabled=component_enabled(animator),
            }
            pcall(EntitySetComponentIsEnabled, current, animator, false)
        end
    end)
end

local function descriptor(entity)
    local found = nil
    entity_tree.walk(entity, function(current)
        for _, ai in ipairs(EntityGetComponentIncludingDisabled(current, "AnimalAIComponent") or {}) do
            if boolean_value(get_value(ai, "attack_melee_enabled", false)) == true then
                found = ai
                return false
            end
        end
    end)
    return found
end

local function same_herd(a, b)
    local ga = EntityGetFirstComponentIncludingDisabled(a, "GenomeDataComponent")
    local gb = EntityGetFirstComponentIncludingDisabled(b, "GenomeDataComponent")
    if not valid(ga) or not valid(gb) then return false end
    return get_value(ga, "herd_id", -100000) == get_value(gb, "herd_id", -100001)
end

local function damage_amount()
    if state == nil or state.damage_max <= state.damage_min or type(Random) ~= "function" then
        return state and state.damage_min or 0
    end
    local scale = 10000
    local ok, value = pcall(Random, math.floor(state.damage_min * scale), math.floor(state.damage_max * scale))
    return ok and (tonumber(value) or state.damage_min * scale) / scale or state.damage_min
end

local function bite(entity)
    if state == nil then return false end
    local x, y = EntityGetTransform(entity)
    if x == nil then return false end
    local root = EntityGetRootEntity(entity)
    local best, best_d2 = 0, nil
    for _, candidate in ipairs(EntityGetInRadiusWithTag(x, y, state.radius, "hittable") or {}) do
        local target = EntityGetRootEntity(candidate)
        if target ~= 0 and target ~= root and EntityGetIsAlive(target) and not same_herd(root, target) then
            local tx, ty = EntityGetTransform(target)
            if tx ~= nil then
                local dx, dy = tx - x, ty - y
                local d2 = dx * dx + dy * dy
                if best_d2 == nil or d2 < best_d2 then best, best_d2 = target, d2 end
            end
        end
    end
    if best == 0 then return false end
    return pcall(EntityInflictDamage, best, damage_amount(), "DAMAGE_MELEE", "metamorph mimic bite", "NONE", 0, 0, root, x, y, 0)
end

local function attack_animation_timing(image_file)
    image_file = tostring(image_file or "")
    if image_file == "" then return nil end
    if animation_cache[image_file] ~= nil then return animation_cache[image_file] or nil end
    local ok, content = pcall(ModTextFileGetContent, image_file)
    if not ok or type(content) ~= "string" then
        animation_cache[image_file] = false
        return nil
    end
    local block = string.match(content, '<RectAnimation[^>]-name%s*=%s*["\']attack["\'][^>]*>')
        or string.match(content, '<RectAnimation.-name%s*=%s*["\']attack["\'].-%>')
    if block == nil then
        animation_cache[image_file] = false
        return nil
    end
    local frame_wait = tonumber(string.match(block, 'frame_wait%s*=%s*["\']([^"\']+)["\']')) or 0.07
    local frame_count = tonumber(string.match(block, 'frame_count%s*=%s*["\']([^"\']+)["\']')) or 7
    local timing = {
        frame_ticks = math.max(1, math.floor(frame_wait * 60 + 0.5)),
        total_ticks = math.max(1, math.ceil(frame_wait * 60 * frame_count)),
    }
    animation_cache[image_file] = timing
    return timing
end

local function play_bite_animation(entity)
    local best_timing = nil
    -- chest_leggy's SpriteAnimatorComponent can rewrite the root SpriteComponent back to
    -- locomotion on the very next engine update.  Temporarily suspend only that
    -- presentation driver while the authored non-looping bite animation plays; restore
    -- its exact previous enabled state afterwards.
    suppress_animators(entity)
    entity_tree.walk(entity, function(current)
        for _, sprite in ipairs(EntityGetComponentIncludingDisabled(current, "SpriteComponent") or {}) do
            local image = tostring(get_value(sprite, "image_file", "") or "")
            local timing = attack_animation_timing(image)
            if timing ~= nil then
                -- Physics/IK forms such as chest_leggy do not always react to
                -- GamePlayAnimation after their AI has been playerized.  Drive the
                -- authored SpriteComponent directly and ask it to return to stand when
                -- the non-looping attack animation completes.
                pcall(ComponentSetValue2, sprite, "rect_animation", "attack")
                pcall(ComponentSetValue2, sprite, "next_rect_animation", "stand")
                pcall(EntitySetComponentIsEnabled, current, sprite, true)
                if type(EntityRefreshSprite) == "function" then pcall(EntityRefreshSprite, current, sprite) end
                if best_timing == nil or timing.total_ticks > best_timing.total_ticks then best_timing = timing end
            end
        end
    end)
    pcall(GamePlayAnimation, entity, "attack", 45, "", 0)
    return best_timing
end

function mimic_melee.reset()
    restore_animators()
    state = nil
end

function mimic_melee.configure(entity, path)
    mimic_melee.reset()
    if MIMIC_PATHS[tostring(path or "")] ~= true then return false end
    local ai = descriptor(entity)
    if not valid(ai) then return false end
    local damage_min = math.max(0, tonumber(get_value(ai, "attack_melee_damage_min", 0.4)) or 0.4)
    local damage_max = math.max(0, tonumber(get_value(ai, "attack_melee_damage_max", 0.6)) or 0.6)
    if damage_max < damage_min then damage_min, damage_max = damage_max, damage_min end
    state = {
        damage_min = damage_min,
        damage_max = damage_max,
        radius = math.max(1, tonumber(get_value(ai, "attack_melee_max_distance", 20)) or 20),
        action_frame = math.max(0, math.floor(tonumber(get_value(ai, "attack_melee_action_frame", 2)) or 2)),
        cooldown = math.max(1, math.floor(tonumber(get_value(ai, "attack_melee_frames_between", 10)) or 10)),
        next_frame = 0,
        pending_frame = -1,
        animation_end_frame = -1,
        animators = {},
    }
    gameplay_input.require_release("primary")
    return true
end

function mimic_melee.update(entity, controls)
    if state == nil then return false end
    local frame = tonumber(GameGetFrameNum()) or 0
    if state.animation_end_frame >= 0 and frame >= state.animation_end_frame then
        restore_animators()
    end
    if state.pending_frame >= 0 and frame >= state.pending_frame then
        state.pending_frame = -1
        bite(entity)
    end
    if gameplay_input.down(controls, "primary") and state.pending_frame < 0 and frame >= state.next_frame then
        local timing = play_bite_animation(entity)
        local frame_ticks = timing and timing.frame_ticks or 4
        local total_ticks = timing and timing.total_ticks or (state.action_frame * 4 + 8)
        state.pending_frame = frame + state.action_frame * frame_ticks
        state.animation_end_frame = frame + total_ticks
        state.next_frame = frame + math.max(state.cooldown, total_ticks)
        if state.action_frame <= 0 then
            state.pending_frame = -1
            bite(entity)
        end
    end
    return true
end

function mimic_melee.owns_primary()
    return state ~= nil
end

return mimic_melee
