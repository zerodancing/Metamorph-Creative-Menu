local utf8_text = {}

local function continuation(byte)
    return byte ~= nil and byte >= 0x80 and byte <= 0xBF
end

local function sequence_length(value, index)
    local b1 = string.byte(value, index)
    if b1 == nil then return nil end
    if b1 <= 0x7F then return 1 end

    local b2 = string.byte(value, index + 1)
    if b1 >= 0xC2 and b1 <= 0xDF then
        if continuation(b2) then return 2 end
        return nil
    end

    local b3 = string.byte(value, index + 2)
    if b1 == 0xE0 then
        if b2 ~= nil and b2 >= 0xA0 and b2 <= 0xBF and continuation(b3) then return 3 end
        return nil
    end
    if (b1 >= 0xE1 and b1 <= 0xEC) or (b1 >= 0xEE and b1 <= 0xEF) then
        if continuation(b2) and continuation(b3) then return 3 end
        return nil
    end
    if b1 == 0xED then
        if b2 ~= nil and b2 >= 0x80 and b2 <= 0x9F and continuation(b3) then return 3 end
        return nil
    end

    local b3_4 = string.byte(value, index + 2)
    local b4 = string.byte(value, index + 3)
    if b1 == 0xF0 then
        if b2 ~= nil and b2 >= 0x90 and b2 <= 0xBF and continuation(b3_4) and continuation(b4) then return 4 end
        return nil
    end
    if b1 >= 0xF1 and b1 <= 0xF3 then
        if continuation(b2) and continuation(b3_4) and continuation(b4) then return 4 end
        return nil
    end
    if b1 == 0xF4 then
        if b2 ~= nil and b2 >= 0x80 and b2 <= 0x8F and continuation(b3_4) and continuation(b4) then return 4 end
        return nil
    end

    return nil
end

function utf8_text.truncate_bytes(value, max_bytes)
    value = tostring(value or "")
    local limit = tonumber(max_bytes)
    if limit == nil or limit ~= limit or limit <= 0 then return "" end
    if limit == math.huge then limit = #value else limit = math.floor(limit) end

    local index = 1
    local safe_end = 0
    local length = #value
    while index <= length and index <= limit do
        local size = sequence_length(value, index)
        if size == nil then break end
        local sequence_end = index + size - 1
        if sequence_end > limit then break end
        safe_end = sequence_end
        index = sequence_end + 1
    end

    if safe_end == length then return value end
    if safe_end == 0 then return "" end
    return string.sub(value, 1, safe_end)
end

return utf8_text
