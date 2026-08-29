if type(METAMORPH_CREATIVE_MENU_SEARCH_ENGINE) == "table" then return METAMORPH_CREATIVE_MENU_SEARCH_ENGINE end

local search_engine = {}

-- Search normalization is intentionally engine-agnostic: UI/catalog layers may feed it
-- translated labels, English aliases, technical ids and paths without coupling core to
-- Noita's localization APIs.
local QUERY_CACHE_LIMIT = 64
local query_cache, query_cache_order = {}, {}

local function utf8_decode(value)
    value = tostring(value or "")
    local out, index, length = {}, 1, #value
    while index <= length do
        local first = string.byte(value, index)
        local codepoint, width
        if first == nil then break end
        if first < 0x80 then
            codepoint, width = first, 1
        elseif first >= 0xC2 and first < 0xE0 and index + 1 <= length then
            local b2 = string.byte(value, index + 1)
            if b2 ~= nil and b2 >= 0x80 and b2 < 0xC0 then
                codepoint = (first - 0xC0) * 0x40 + (b2 - 0x80)
                width = 2
            end
        elseif first >= 0xE0 and first < 0xF0 and index + 2 <= length then
            local b2, b3 = string.byte(value, index + 1), string.byte(value, index + 2)
            if b2 ~= nil and b3 ~= nil and b2 >= 0x80 and b2 < 0xC0 and b3 >= 0x80 and b3 < 0xC0 then
                codepoint = (first - 0xE0) * 0x1000 + (b2 - 0x80) * 0x40 + (b3 - 0x80)
                width = 3
            end
        elseif first >= 0xF0 and first < 0xF5 and index + 3 <= length then
            local b2, b3, b4 = string.byte(value, index + 1), string.byte(value, index + 2), string.byte(value, index + 3)
            if b2 ~= nil and b3 ~= nil and b4 ~= nil
                and b2 >= 0x80 and b2 < 0xC0 and b3 >= 0x80 and b3 < 0xC0 and b4 >= 0x80 and b4 < 0xC0
            then
                codepoint = (first - 0xF0) * 0x40000 + (b2 - 0x80) * 0x1000 + (b3 - 0x80) * 0x40 + (b4 - 0x80)
                width = 4
            end
        end
        if codepoint == nil then
            out[#out + 1] = first
            index = index + 1
        else
            out[#out + 1] = codepoint
            index = index + width
        end
    end
    return out
end

local function utf8_encode(codepoint)
    if codepoint < 0x80 then return string.char(codepoint) end
    if codepoint < 0x800 then
        return string.char(0xC0 + math.floor(codepoint / 0x40), 0x80 + codepoint % 0x40)
    end
    if codepoint < 0x10000 then
        return string.char(0xE0 + math.floor(codepoint / 0x1000),
            0x80 + math.floor(codepoint / 0x40) % 0x40, 0x80 + codepoint % 0x40)
    end
    return string.char(0xF0 + math.floor(codepoint / 0x40000),
        0x80 + math.floor(codepoint / 0x1000) % 0x40,
        0x80 + math.floor(codepoint / 0x40) % 0x40, 0x80 + codepoint % 0x40)
end

local LATIN_FOLD = {
    [0x00C0]="a",[0x00C1]="a",[0x00C2]="a",[0x00C3]="a",[0x00C4]="a",[0x00C5]="a",
    [0x00E0]="a",[0x00E1]="a",[0x00E2]="a",[0x00E3]="a",[0x00E4]="a",[0x00E5]="a",
    [0x0100]="a",[0x0101]="a",[0x0102]="a",[0x0103]="a",[0x0104]="a",[0x0105]="a",
    [0x00C6]="ae",[0x00E6]="ae",
    [0x00C7]="c",[0x00E7]="c",[0x0106]="c",[0x0107]="c",[0x010C]="c",[0x010D]="c",
    [0x010E]="d",[0x010F]="d",[0x0110]="d",[0x0111]="d",
    [0x00C8]="e",[0x00C9]="e",[0x00CA]="e",[0x00CB]="e",[0x00E8]="e",[0x00E9]="e",[0x00EA]="e",[0x00EB]="e",
    [0x0112]="e",[0x0113]="e",[0x0116]="e",[0x0117]="e",[0x0118]="e",[0x0119]="e",[0x011A]="e",[0x011B]="e",
    [0x011E]="g",[0x011F]="g",
    [0x00CC]="i",[0x00CD]="i",[0x00CE]="i",[0x00CF]="i",[0x00EC]="i",[0x00ED]="i",[0x00EE]="i",[0x00EF]="i",
    [0x012A]="i",[0x012B]="i",[0x012E]="i",[0x012F]="i",
    [0x0139]="l",[0x013A]="l",[0x013D]="l",[0x013E]="l",[0x0141]="l",[0x0142]="l",
    [0x00D1]="n",[0x00F1]="n",[0x0143]="n",[0x0144]="n",[0x0147]="n",[0x0148]="n",
    [0x00D2]="o",[0x00D3]="o",[0x00D4]="o",[0x00D5]="o",[0x00D6]="o",[0x00D8]="o",
    [0x00F2]="o",[0x00F3]="o",[0x00F4]="o",[0x00F5]="o",[0x00F6]="o",[0x00F8]="o",
    [0x014C]="o",[0x014D]="o",[0x0150]="o",[0x0151]="o",[0x0152]="oe",[0x0153]="oe",
    [0x0154]="r",[0x0155]="r",[0x0158]="r",[0x0159]="r",
    [0x015A]="s",[0x015B]="s",[0x0160]="s",[0x0161]="s",[0x015E]="s",[0x015F]="s",[0x00DF]="ss",
    [0x0164]="t",[0x0165]="t",
    [0x00D9]="u",[0x00DA]="u",[0x00DB]="u",[0x00DC]="u",[0x00F9]="u",[0x00FA]="u",[0x00FB]="u",[0x00FC]="u",
    [0x016A]="u",[0x016B]="u",[0x016E]="u",[0x016F]="u",[0x0170]="u",[0x0171]="u",
    [0x00DD]="y",[0x00FD]="y",[0x00FF]="y",
    [0x0179]="z",[0x017A]="z",[0x017B]="z",[0x017C]="z",[0x017D]="z",[0x017E]="z",
}

local function fold_codepoint(codepoint)
    local mapped = LATIN_FOLD[codepoint]
    if mapped ~= nil then return mapped end
    if codepoint >= 0x41 and codepoint <= 0x5A then return string.char(codepoint + 0x20) end
    -- Cyrillic uppercase + Yo. Yo is folded to e/е so common user spelling variants match.
    if codepoint >= 0x0410 and codepoint <= 0x042F then codepoint = codepoint + 0x20 end
    if codepoint == 0x0401 or codepoint == 0x0451 then codepoint = 0x0435 end
    -- Full-width ASCII used by some CJK input methods.
    if codepoint >= 0xFF01 and codepoint <= 0xFF5E then codepoint = codepoint - 0xFEE0 end
    if codepoint >= 0x41 and codepoint <= 0x5A then codepoint = codepoint + 0x20 end
    return utf8_encode(codepoint)
end

function search_engine.normalize(value)
    local parts = {}
    for _, codepoint in ipairs(utf8_decode(value)) do parts[#parts + 1] = fold_codepoint(codepoint) end
    local normalized = table.concat(parts)
    -- Treat punctuation/path/id separators as word boundaries. Keep all non-ASCII UTF-8
    -- bytes intact so Chinese/Japanese/Korean text remains searchable verbatim.
    normalized = string.gsub(normalized, "[%c%s_%-%.%/%\\:;,%(%)%[%]{}<>|]+", " ")
    normalized = string.gsub(normalized, "[%+]+", " ")
    normalized = string.gsub(normalized, "%s+", " ")
    normalized = string.gsub(normalized, "^%s+", "")
    normalized = string.gsub(normalized, "%s+$", "")
    return normalized
end

local function words(value)
    local result = {}
    for token in string.gmatch(value, "%S+") do result[#result + 1] = token end
    return result
end

local function cache_query(key, compiled)
    if query_cache[key] ~= nil then return end
    query_cache[key] = compiled
    query_cache_order[#query_cache_order + 1] = key
    if #query_cache_order > QUERY_CACHE_LIMIT then
        local oldest = table.remove(query_cache_order, 1)
        query_cache[oldest] = nil
    end
end

function search_engine.compile_query(query)
    local key = tostring(query or "")
    local cached = query_cache[key]
    if cached ~= nil then return cached end
    local positive, negative = {}, {}
    -- Operator detection happens before punctuation normalization, otherwise -foo loses
    -- its exclusion meaning.
    for raw in string.gmatch(key, "%S+") do
        local first = string.sub(raw, 1, 1)
        local excluded = (first == "-" or first == "!") and #raw > 1
        local body = excluded and string.sub(raw, 2) or raw
        body = search_engine.normalize(body)
        for token in string.gmatch(body, "%S+") do
            (excluded and negative or positive)[#(excluded and negative or positive) + 1] = token
        end
    end
    local compiled = {
        raw=key,
        normalized=search_engine.normalize(key),
        positive=positive,
        negative=negative,
        positive_phrase=table.concat(positive, " "),
    }
    cache_query(key, compiled)
    return compiled
end

local function edit_distance_at_most(left, right, limit)
    if left == right then return 0 end
    local a, b = utf8_decode(left), utf8_decode(right)
    if math.abs(#a - #b) > limit then return nil end
    if #a == 0 or #b == 0 then return math.max(#a, #b) <= limit and math.max(#a, #b) or nil end
    local previous = {}
    for j = 0, #b do previous[j] = j end
    for i = 1, #a do
        local current = {[0]=i}
        local row_min = current[0]
        for j = 1, #b do
            local cost = a[i] == b[j] and 0 or 1
            local value = math.min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
            current[j] = value
            if value < row_min then row_min = value end
        end
        if row_min > limit then return nil end
        previous = current
    end
    return previous[#b] <= limit and previous[#b] or nil
end

local function token_score(token, normalized_fields, joined, joined_compact, field_words)
    local best = nil
    for _, field in ipairs(normalized_fields) do
        if field == token then best = math.max(best or 0, 220) end
        if string.sub(field, 1, #token) == token then best = math.max(best or 0, 170) end
    end
    if string.find(joined, token, 1, true) ~= nil then best = math.max(best or 0, 130) end
    local compact = string.gsub(token, " ", "")
    if compact ~= "" and string.find(joined_compact, compact, 1, true) ~= nil then best = math.max(best or 0, 110) end
    if best ~= nil then return best end

    -- Typo tolerance is deliberately conservative. Short tokens and CJK single-glyph
    -- searches stay exact; longer human-readable names tolerate one or two edits.
    local token_len = #utf8_decode(token)
    local limit = token_len >= 8 and 2 or (token_len >= 4 and 1 or 0)
    if limit == 0 then return nil end
    for _, word in ipairs(field_words) do
        local distance = edit_distance_at_most(token, word, limit)
        if distance ~= nil then
            local score = distance == 0 and 120 or (distance == 1 and 72 or 48)
            best = math.max(best or 0, score)
        end
    end
    return best
end

function search_engine.score(query, fields)
    local compiled = type(query) == "table" and query or search_engine.compile_query(query)
    fields = type(fields) == "table" and fields or {fields}
    local normalized_fields, field_words = {}, {}
    for _, value in ipairs(fields) do
        local normalized = search_engine.normalize(value)
        if normalized ~= "" then
            normalized_fields[#normalized_fields + 1] = normalized
            for _, word in ipairs(words(normalized)) do field_words[#field_words + 1] = word end
        end
    end
    if #compiled.positive == 0 and #compiled.negative == 0 then return 0 end
    local joined = table.concat(normalized_fields, " ")
    local joined_compact = string.gsub(joined, "%s+", "")
    for _, token in ipairs(compiled.negative) do
        if token ~= "" and (string.find(joined, token, 1, true) ~= nil
            or string.find(joined_compact, string.gsub(token, "%s+", ""), 1, true) ~= nil)
        then
            return nil
        end
    end
    local score = 0
    for _, token in ipairs(compiled.positive) do
        local matched = token_score(token, normalized_fields, joined, joined_compact, field_words)
        if matched == nil then return nil end
        score = score + matched
    end
    if compiled.positive_phrase ~= "" then
        if joined == compiled.positive_phrase then score = score + 700
        elseif string.find(joined, compiled.positive_phrase, 1, true) ~= nil then score = score + 300 end
    end
    return score
end

function search_engine.matches(query, fields)
    return search_engine.score(query, fields) ~= nil
end

METAMORPH_CREATIVE_MENU_SEARCH_ENGINE = search_engine
return search_engine
