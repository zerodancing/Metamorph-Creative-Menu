if type(METAMORPH_CREATIVE_MENU_FORM_PROFILE_SINGLETON) == "table" then
    return METAMORPH_CREATIVE_MENU_FORM_PROFILE_SINGLETON
end

local form_profile = {}
METAMORPH_CREATIVE_MENU_FORM_PROFILE_SINGLETON = form_profile

local profile_cache = {}
local text_cache = {}

local function read_text(path)
    if type(path) ~= "string" or path == "" then return nil end
    if text_cache[path] ~= nil then
        return text_cache[path] ~= false and text_cache[path] or nil
    end
    local ok, content = pcall(ModTextFileGetContent, path)
    if not ok or type(content) ~= "string" or content == "" then
        if string.sub(path, 1, 5) ~= "mods/" then text_cache[path] = false end
        return nil
    end
    text_cache[path] = content
    return content
end

local function attr(tag, name)
    local escaped = string.gsub(name, "([%%%-%+%*%?%[%]%^%$%(%)%.])", "%%%1")
    return string.match(tag, escaped .. '%s*=%s*"([^"]*)"')
        or string.match(tag, escaped .. "%s*=%s*'([^']*)'")
end

local function scalar(value)
    if value == nil then return nil end
    if value == "true" then return true end
    if value == "false" then return false end
    local number = tonumber(value)
    return number ~= nil and number or value
end

local function flag(value)
    if value == nil then return nil end
    if type(value) == "string" then
        value = string.lower(value)
        if value == "true" then return true end
        if value == "false" then return false end
        value = tonumber(value)
    end
    if type(value) == "number" then return value ~= 0 end
    return value == true
end

local function attributes(tag)
    local result = {}
    for key, value in string.gmatch(tag or "", '([%w_%.]+)%s*=%s*"([^"]*)"') do
        result[key] = scalar(value)
    end
    for key, value in string.gmatch(tag or "", "([%w_%.]+)%s*=%s*'([^']*)'") do
        if result[key] == nil then result[key] = scalar(value) end
    end
    return result
end

local function merge(dst, src)
    for key, value in pairs(src or {}) do dst[key] = value end
end

local function scan_root(path, wanted_components, visited, depth)
    if type(path) ~= "string" or path == "" or depth > 16 or visited[path] then
        return { components = {}, base_overrides = {}, tags = {} }
    end
    visited[path] = true
    local content = read_text(path)
    if content == nil then
        visited[path] = nil
        return { components = {}, base_overrides = {}, tags = {} }
    end

    local out = { components = {}, base_overrides = {}, tags = {} }
    for name, _ in pairs(wanted_components) do
        out.components[name] = {}
        out.base_overrides[name] = {}
    end

    local entity_depth = 0
    local root_base_depth = 0
    local root_seen = false

    for tag in string.gmatch(content, "<[^>]+>") do
        local lower = string.lower(tag)
        local closing = string.match(lower, "^<%s*/") ~= nil
        local self_closing = string.match(lower, "/%s*>$") ~= nil

        if closing then
            if string.match(lower, "^<%s*/%s*base%s*>") and entity_depth == 1 and root_base_depth > 0 then
                root_base_depth = root_base_depth - 1
            elseif string.match(lower, "^<%s*/%s*entity%s*>") then
                entity_depth = math.max(0, entity_depth - 1)
            end
        else
            if string.match(lower, "^<%s*entity[%s>]" ) then
                entity_depth = entity_depth + 1
                if not root_seen and entity_depth == 1 then
                    root_seen = true
                    local tags = attr(tag, "tags") or ""
                    for value in string.gmatch(tags, "[^,%s]+") do out.tags[value] = true end
                end
                -- `<Entity ... />` opens and closes at the same token. Leaving depth
                -- incremented makes every following root component look like a child.
                if self_closing then entity_depth = math.max(0, entity_depth - 1) end
            elseif string.match(lower, "^<%s*base[%s>]" ) and entity_depth == 1 then
                local base_path = attr(tag, "file")
                if type(base_path) == "string" and base_path ~= "" and base_path ~= path then
                    local inherited = scan_root(base_path, wanted_components, visited, depth + 1)
                    for name, _ in pairs(wanted_components) do
                        merge(out.components[name], inherited.components[name])
                    end
                    for tag_name, value in pairs(inherited.tags or {}) do out.tags[tag_name] = value end
                end
                if not self_closing then root_base_depth = root_base_depth + 1 end
            else
                local component_name = string.match(tag, "^<%s*([%w_]+Component)[%s/>]")
                if component_name ~= nil and wanted_components[component_name] and entity_depth == 1 then
                    local values = attributes(tag)
                    merge(out.components[component_name], values)
                    if root_base_depth > 0 then merge(out.base_overrides[component_name], values) end
                end
            end
        end
    end
    visited[path] = nil
    return out
end

local WANTED = {
    AnimalAIComponent = true,
    AIAttackComponent = true,
    GenomeDataComponent = true,
    CharacterDataComponent = true,
    CharacterPlatformingComponent = true,
    PathFindingComponent = true,
    DamageModelComponent = true,
    PhysicsAIComponent = true,
    BossDragonComponent = true,
    IKLimbsAnimatorComponent = true,
    LimbBossComponent = true,
    WormComponent = true,
}

function form_profile.get(path)
    if profile_cache[path] ~= nil then return profile_cache[path] end
    local scanned = scan_root(path, WANTED, {}, 0)
    local p = {
        path = path,
        animal_ai = scanned.components.AnimalAIComponent or {},
        ai_attack = scanned.components.AIAttackComponent or {},
        genome = scanned.components.GenomeDataComponent or {},
        character_data = scanned.components.CharacterDataComponent or {},
        platforming = scanned.components.CharacterPlatformingComponent or {},
        pathfinding = scanned.components.PathFindingComponent or {},
        damage = scanned.components.DamageModelComponent or {},
        damage_override = scanned.base_overrides.DamageModelComponent or {},
        physics_ai = scanned.components.PhysicsAIComponent or {},
        boss_dragon = scanned.components.BossDragonComponent or {},
        ik_animator = scanned.components.IKLimbsAnimatorComponent or {},
        limb_boss = scanned.components.LimbBossComponent or {},
        worm = scanned.components.WormComponent or {},
        tags = scanned.tags or {},
    }
    p.can_fly = flag(p.animal_ai.can_fly) == true
        or flag(p.pathfinding.can_fly) == true
        or p.tags.flying == true
    local can_walk = p.animal_ai.can_walk
    if can_walk == nil then can_walk = p.pathfinding.can_walk end
    p.pure_flyer = p.can_fly and can_walk ~= nil and flag(can_walk) == false
    p.has_boss_dragon = next(p.boss_dragon) ~= nil
    p.has_physics_ai = next(p.physics_ai) ~= nil
    p.has_limb_boss = next(p.limb_boss) ~= nil
    p.has_worm = next(p.worm) ~= nil
    profile_cache[path] = p
    return p
end

function form_profile.plan(info)
    info = info or {}
    local requested = tostring(info.path or "")
    local target = requested
    local mode = "direct"
    local canonical = tostring(info.canonical_target or "")
    local is_damage_wrapper = tostring(info.canonical_reason or "") == "direct_base_same_id"
        and tostring(info.risk_signature or "") == "canonical_wrapper_damage_override"
        and canonical ~= ""
        and ModDoesFileExist(canonical)

    if is_damage_wrapper then
        target = canonical
        mode = "canonical_damage_overlay"
    elseif (tostring(info.transform_policy or "") == "blocked_crash" or tostring(info.transform_policy or "") == "blocked_mixed")
        and canonical ~= "" and ModDoesFileExist(canonical)
    then
        target = canonical
        mode = "canonical_crash_fallback"
    end

    return {
        requested_path = requested,
        target_path = target,
        mode = mode,
        requested_profile = form_profile.get(requested),
        target_profile = form_profile.get(target),
    }
end

return form_profile
