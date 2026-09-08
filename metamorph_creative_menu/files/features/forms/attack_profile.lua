if type(METAMORPH_CREATIVE_MENU_FORM_ATTACK_PROFILE) == "table" then
    return METAMORPH_CREATIVE_MENU_FORM_ATTACK_PROFILE
end

local attack_profile = {}

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value or value == math.huge or value == -math.huge then return fallback end
    return value
end

local function nonnegative(value, fallback)
    return math.max(0, finite(value, fallback or 0) or 0)
end

local function integer_nonnegative(value, fallback)
    return math.floor(nonnegative(value, fallback) + 0.0000001)
end

local function bool(value)
    if type(value) == "string" then
        local lower = string.lower(value)
        if lower == "true" then return true end
        if lower == "false" then return false end
        value = tonumber(value)
    end
    if type(value) == "number" then return value ~= 0 end
    return value == true
end

function attack_profile.normalize(spec)
    spec = type(spec) == "table" and spec or {}
    local low = math.max(1, integer_nonnegative(spec.count_min, 1))
    local high = math.max(low, integer_nonnegative(spec.count_max, low))
    local min_distance = nonnegative(spec.min_distance, 0)
    local max_distance = nonnegative(spec.max_distance, 10000)
    if max_distance < min_distance then min_distance, max_distance = max_distance, min_distance end
    return {
        source_kind = tostring(spec.source_kind or ""),
        component = spec.component,
        path = tostring(spec.path or ""),
        frames = integer_nonnegative(spec.frames, 30),
        global_frames = integer_nonnegative(spec.global_frames, 0),
        count_min = low,
        count_max = high,
        action_frame = integer_nonnegative(spec.action_frame, 0),
        animation = tostring(spec.animation or "attack_ranged"),
        min_distance = min_distance,
        max_distance = max_distance,
        use_probability = math.max(0, math.min(100, integer_nonnegative(spec.use_probability, 100))),
        state_duration_frames = integer_nonnegative(spec.state_duration_frames, 45),
        angular_range_deg = math.max(0, math.min(90, finite(spec.angular_range_deg, 90) or 90)),
        offset_x = finite(spec.offset_x, 0) or 0,
        offset_y = finite(spec.offset_y, 0) or 0,
        root_offset_x = finite(spec.root_offset_x, 0) or 0,
        root_offset_y = finite(spec.root_offset_y, 0) or 0,
        use_message = bool(spec.use_message),
        landing_required = bool(spec.landing_required),
        predict = bool(spec.predict),
        aim_rotation_enabled = bool(spec.aim_rotation_enabled),
        aim_rotation_speed = finite(spec.aim_rotation_speed, 3) or 3,
        aim_ok_angle_deg = finite(spec.aim_ok_angle_deg, 10) or 10,
        use_laser_sight = bool(spec.use_laser_sight),
        next_frame = integer_nonnegative(spec.next_frame, 0),
    }
end

function attack_profile.projectile_count(profile, random_fn)
    profile = type(profile) == "table" and profile or {}
    local low = math.max(1, integer_nonnegative(profile.count_min, 1))
    local high = math.max(low, integer_nonnegative(profile.count_max, low))
    if low == high then return low end
    if type(random_fn) == "function" then
        local ok, value = pcall(random_fn, low, high)
        value = ok and tonumber(value) or nil
        if value ~= nil then return math.max(low, math.min(high, math.floor(value))) end
    end
    return low
end

function attack_profile.animation_delay_frames(profile, frame_wait, fps)
    profile = type(profile) == "table" and profile or {}
    local action_frame = integer_nonnegative(profile.action_frame, 0)
    if action_frame <= 0 then return 0 end
    frame_wait = finite(frame_wait, nil)
    fps = finite(fps, 60) or 60
    if frame_wait == nil or frame_wait <= 0 or fps <= 0 then return action_frame end
    return math.max(0, math.floor(action_frame * frame_wait * fps + 0.5))
end

local function interval_distance(profile, distance)
    if distance < profile.min_distance then return profile.min_distance - distance end
    if distance > profile.max_distance then return distance - profile.max_distance end
    return 0
end

local function random_integer(random_fn, low, high)
    if low >= high then return low end
    if type(random_fn) ~= "function" then return low end
    local ok, value = pcall(random_fn, low, high)
    value = ok and tonumber(value) or low
    return math.max(low, math.min(high, math.floor(value or low)))
end

local function pick_with_authored_probability(candidates, random_fn)
    if #candidates == 0 then return nil end
    -- `use_probability` belongs to each attack descriptor independently. Gate every
    -- otherwise-eligible profile first, then choose among those that actually passed.
    -- This matters for real vanilla overlaps such as necromancer_super: a 70% close
    -- attack must not create an artificial no-shot outcome while a 100% attack is also
    -- valid at the same target distance.
    local passed = {}
    for _, candidate in ipairs(candidates) do
        local probability = math.max(0, math.min(100, tonumber(candidate.use_probability) or 100))
        if probability >= 100 or (probability > 0 and random_integer(random_fn, 1, 100) <= probability) then
            passed[#passed + 1] = candidate
        end
    end
    if #passed == 0 then return nil end
    if #passed == 1 then return passed[1] end
    return passed[random_integer(random_fn, 1, #passed)]
end

function attack_profile.select_primary(profiles, distance, random_fn)
    distance = math.max(0, finite(distance, 0) or 0)
    local usable = {}
    for _, profile in ipairs(type(profiles) == "table" and profiles or {}) do
        if type(profile) == "table" and tostring(profile.path or "") ~= ""
            and profile.use_message ~= true and (tonumber(profile.use_probability) or 0) > 0
        then
            usable[#usable + 1] = profile
        end
    end
    if #usable == 0 then return nil end
    local in_range = {}
    for _, profile in ipairs(usable) do
        if interval_distance(profile, distance) == 0 then in_range[#in_range + 1] = profile end
    end
    if #in_range > 0 then return pick_with_authored_probability(in_range, random_fn) end

    -- These distances are hard target-acquisition limits for the creature AI, but MCM
    -- is driving the attack from explicit player input. Treat the authored intervals as
    -- an attack-selection policy, not as a reason to discard the click. This keeps
    -- close/far multi-attack creatures behaving like their originals while allowing the
    -- selected projectile to be aimed at any cursor position on screen.
    local nearest = {}
    local nearest_distance = math.huge
    for _, profile in ipairs(usable) do
        local gap = interval_distance(profile, distance)
        if gap < nearest_distance then
            nearest_distance = gap
            nearest = {profile}
        elseif gap == nearest_distance then
            nearest[#nearest + 1] = profile
        end
    end
    return pick_with_authored_probability(nearest, random_fn)
end

METAMORPH_CREATIVE_MENU_FORM_ATTACK_PROFILE = attack_profile
return attack_profile
