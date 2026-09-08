local global_text = {}

local DEFAULT_MAX_BYTES = 512

local function safe_tostring(value)
    if value == nil then return "" end
    local ok, text = pcall(tostring, value)
    return ok and type(text) == "string" and text or ""
end

local function is_safe_ascii(byte)
    if byte < 32 or byte > 126 then return false end
    return byte ~= 34  -- "
        and byte ~= 37 -- %
        and byte ~= 38 -- &
        and byte ~= 60 -- <
        and byte ~= 62 -- >
        and byte ~= 92 -- backslash
end

function global_text.encode_diagnostic(value, max_bytes)
    local text = safe_tostring(value)
    local limit = tonumber(max_bytes)
    if limit == nil then limit = DEFAULT_MAX_BYTES end
    limit = math.floor(limit)
    if limit <= 0 or text == "" then return "" end

    local out, used = {}, 0
    for index = 1, #text do
        local byte = string.byte(text, index)
        if is_safe_ascii(byte) then
            if used + 1 > limit then break end
            out[#out + 1] = string.char(byte)
            used = used + 1
        else
            if used + 3 > limit then break end
            out[#out + 1] = string.format("%%%02X", byte)
            used = used + 3
        end
    end
    return table.concat(out)
end

return global_text
