local hash = {}

-- Deterministic 64-bit-looking identifier built from two independent 32-bit
-- accumulators. Lua numbers are exact for every intermediate multiplication used here.
function hash.hex64(value)
    local text = tostring(value or "")
    local h1, h2 = 5381, 52711
    for i = 1, #text do
        local byte = string.byte(text, i)
        h1 = (h1 * 33 + byte) % 4294967296
        h2 = (h2 * 65599 + byte) % 4294967296
    end
    return string.format("%08x%08x", h1, h2)
end

return hash
