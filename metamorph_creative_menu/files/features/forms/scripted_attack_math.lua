if type(METAMORPH_CREATIVE_MENU_SCRIPTED_ATTACK_MATH) == "table" then
    return METAMORPH_CREATIVE_MENU_SCRIPTED_ATTACK_MATH
end

local mathx = {}

local function finite(v, fallback)
    v = tonumber(v)
    if v == nil or v ~= v or v == math.huge or v == -math.huge then return fallback end
    return v
end

function mathx.radial(count, speed, start_angle, invert_y)
    count = math.max(1, math.floor(finite(count, 1) or 1))
    speed = finite(speed, 0) or 0
    start_angle = finite(start_angle, 0) or 0
    local out = {}
    local step = (math.pi * 2) / count
    for i = 0, count - 1 do
        local a = start_angle + step * i
        out[#out + 1] = {
            x = math.cos(a) * speed,
            y = math.sin(a) * speed * (invert_y == true and -1 or 1),
        }
    end
    return out
end

function mathx.radial_degrees(count, speed, start_degrees)
    count = math.max(1, math.floor(finite(count, 1) or 1))
    speed = finite(speed, 0) or 0
    local angle = finite(start_degrees, 0) or 0
    local step = math.floor(360 / count)
    local out = {}
    for _ = 1, count do
        local rad = math.rad(angle)
        out[#out + 1] = {x=math.cos(rad) * speed, y=math.sin(rad) * speed}
        angle = angle + step
    end
    return out
end

function mathx.firepillar(amount)
    amount = math.max(1, math.floor(finite(amount, 1) or 1))
    local space = math.floor(180 / amount)
    local angle = space * 0.5
    local out = {}
    for _ = 1, amount do
        local rad = math.rad(angle)
        out[#out + 1] = {x=math.cos(rad) * 150, y=math.sin(rad) * 150 - 200}
        angle = angle + space
    end
    return out
end

function mathx.aimed(sx, sy, tx, ty, speed)
    sx, sy = finite(sx, 0) or 0, finite(sy, 0) or 0
    tx, ty = finite(tx, sx) or sx, finite(ty, sy - 1) or (sy - 1)
    speed = finite(speed, 0) or 0
    local dx, dy = tx - sx, ty - sy
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= 0.000001 then return 0, -speed end
    return dx / len * speed, dy / len * speed
end

function mathx.rotate(x, y, angle)
    local c, s = math.cos(angle), math.sin(angle)
    return x * c - y * s, x * s + y * c
end

METAMORPH_CREATIVE_MENU_SCRIPTED_ATTACK_MATH = mathx
return mathx
