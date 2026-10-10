local localization = {}
local TRANSLATIONS = "mods/metamorph_creative_menu/translations.csv"
local catalog = nil
local detected_language_column = nil
local english_catalog = nil

local function parse_csv_line(line)
    local fields, field, quoted = {}, "", false
    local index, length = 1, #tostring(line or "")
    while index <= length do
        local char = string.sub(line, index, index)
        if char == '"' then
            if quoted and string.sub(line, index + 1, index + 1) == '"' then
                field = field .. '"'
                index = index + 1
            else
                quoted = not quoted
            end
        elseif char == "," and not quoted then
            fields[#fields + 1], field = field, ""
        else
            field = field .. char
        end
        index = index + 1
    end
    fields[#fields + 1] = field
    return fields
end

local function read_file(path)
    if type(ModTextFileGetContent) ~= "function" then return nil end
    local ok, value = pcall(ModTextFileGetContent, path)
    return ok and type(value) == "string" and value or nil
end

local function load_catalog()
    if catalog ~= nil then return catalog end
    catalog = { rows={}, header={} }
    local content = read_file(TRANSLATIONS)
    if content == nil or content == "" then return catalog end
    local first = true
    for line in string.gmatch(content .. "\n", "([^\r\n]*)[\r]?\n") do
        local fields = parse_csv_line(line)
        if first then
            catalog.header = fields
            first = false
        elseif fields[1] ~= nil and fields[1] ~= "" then
            catalog.rows["$" .. fields[1]] = fields
        end
    end
    return catalog
end


local function load_english_catalog()
    if english_catalog ~= nil then return english_catalog end
    english_catalog = {}
    local content = read_file("data/translations/common.csv")
    if content == nil or content == "" then return english_catalog end
    local first = true
    for line in string.gmatch(content .. "\n", "([^\r\n]*)[\r]?\n") do
        local fields = parse_csv_line(line)
        if first then
            first = false
        elseif fields[1] ~= nil and fields[1] ~= "" and fields[2] ~= nil and fields[2] ~= "" then
            english_catalog["$" .. fields[1]] = fields[2]
        end
    end
    return english_catalog
end

local function engine_translation(key)
    if type(GameTextGetTranslatedOrNot) ~= "function" then return nil end
    local ok, value = pcall(GameTextGetTranslatedOrNot, key)
    return ok and type(value) == "string" and value or nil
end

local function language_column()
    if detected_language_column ~= nil then return detected_language_column end
    local data = load_catalog()
    -- These long-standing rows are already known to Noita before settings.lua runs,
    -- and their values differ across the shipped languages. They let the separate
    -- settings VM select the correct column for newly appended rows immediately.
    for _, anchor in ipairs({ "$mcm_tab_spells", "$mcm_tab_items", "$mcm_tab_perks" }) do
        local translated, row = engine_translation(anchor), data.rows[anchor]
        if translated ~= nil and translated ~= anchor and row ~= nil then
            for column = 2, #row do
                if row[column] == translated then
                    detected_language_column = column
                    return column
                end
            end
        end
    end
    detected_language_column = 2 -- CSV's English column is the safe final fallback.
    return detected_language_column
end

function localization.register()
    if not ModDoesFileExist(TRANSLATIONS) then return false end
    local ok_base, base = pcall(ModTextFileGetContent, "data/translations/common.csv")
    local ok_append, append = pcall(ModTextFileGetContent, TRANSLATIONS)
    if not ok_base or not ok_append or type(base) ~= "string" or type(append) ~= "string" then return false end
    local body = string.match(append, "^[^\n]*\n(.*)$") or ""
    if body == "" then return false end

    -- settings.lua and init.lua execute in different Lua contexts. Registering from
    -- both must therefore be idempotent, and an older partially appended table must
    -- be upgraded instead of leaving every newly introduced label untranslated.
    local existing = {}
    for line in string.gmatch(base .. "\n", "([^\r\n]*)[\r]?\n") do
        local key = string.match(line, "^([^,]+),")
        if key ~= nil and key ~= "" then existing[key] = true end
    end
    local missing = {}
    for line in string.gmatch(body .. "\n", "([^\r\n]*)[\r]?\n") do
        local key = string.match(line, "^([^,]+),")
        if key ~= nil and key ~= "" and not existing[key] then
            missing[#missing + 1] = line
            existing[key] = true
        end
    end
    if #missing == 0 then return true end
    if not string.match(base, "\n$") then base = base .. "\n" end
    ModTextFileSetContent("data/translations/common.csv", base .. table.concat(missing, "\n") .. "\n")
    return true
end

function localization.translate(key, fallback)
    if key == nil or key == "" then return "" end
    key = tostring(key)
    local translated = engine_translation(key)
    if translated ~= nil and translated ~= "" and translated ~= key then return translated end
    local row = load_catalog().rows[key]
    if row ~= nil then
        local local_value = row[language_column()]
        if type(local_value) == "string" and local_value ~= "" then return local_value end
    end
    return fallback or key
end

function localization.english(key, fallback)
    if key == nil or key == "" then return "" end
    key = tostring(key)
    local own_row = load_catalog().rows[key]
    if own_row ~= nil and type(own_row[2]) == "string" and own_row[2] ~= "" then
        return own_row[2]
    end
    local vanilla = load_english_catalog()[key]
    if type(vanilla) == "string" and vanilla ~= "" then return vanilla end
    return fallback or key
end

function localization.search_aliases(key, fallback)
    key = tostring(key or "")
    local values, seen = {}, {}
    local function add(value)
        value = tostring(value or "")
        if value ~= "" and not seen[value] then seen[value] = true; values[#values + 1] = value end
    end
    add(localization.translate(key, fallback))
    add(localization.english(key, fallback))
    add(fallback)
    add(key)
    if string.sub(key, 1, 1) == "$" then add(string.sub(key, 2)) end
    return values
end

return localization
