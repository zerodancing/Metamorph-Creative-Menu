local rule_math = {}

function rule_math.scaled(original, factor)
    original, factor = tonumber(original), tonumber(factor)
    if original == nil or factor == nil then return nil end
    return original * factor
end

function rule_math.same(a, b, epsilon)
    a, b = tonumber(a), tonumber(b)
    if a == nil or b == nil then return a == b end
    return math.abs(a - b) < (tonumber(epsilon) or 0.0001)
end

return rule_math
