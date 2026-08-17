if type(METAMORPH_CREATIVE_MENU_CREATURE_METADATA) == "table" then return METAMORPH_CREATIVE_MENU_CREATURE_METADATA end

local metadata = {}
local xml_cache = {}
local name_cache = {}

function metadata.basename(path)
    return string.match(path or "", "([^/]+)%.xml$") or path or ""
end

function metadata.read_text(path)
    if type(path) ~= "string" or path == "" then return nil end
    if xml_cache[path] ~= nil then return xml_cache[path] ~= false and xml_cache[path] or nil end
    local ok, content = pcall(ModTextFileGetContent, path)
    if not ok or type(content) ~= "string" or content == "" then
        -- Mod-owned files can appear later through VFS composition; do not permanently
        -- negative-cache them. Vanilla data files are immutable for this process.
        if string.sub(path, 1, 5) ~= "mods/" then xml_cache[path] = false end
        return nil
    end
    xml_cache[path] = content
    return content
end

function metadata.attribute(tag, name)
    return string.match(tag or "", name .. '%s*=%s*"([^"]+)"')
        or string.match(tag or "", name .. "%s*=%s*'([^']+)'")
end

function metadata.base_files(content)
    local result = {}
    for tag in string.gmatch(content or "", "<Base[^>]*>") do
        local file = metadata.attribute(tag, "file")
        if file ~= nil and file ~= "" then result[#result + 1] = file end
    end
    return result
end

function metadata.translated(value)
    if type(value) ~= "string" or value == "" then return "" end
    local text = GameTextGetTranslatedOrNot(value)
    if text == nil or text == "" then return value end
    return text
end

local function entity_name(path, visited, depth)
    if name_cache[path] ~= nil then return name_cache[path] ~= false and name_cache[path] or nil end
    if type(path) ~= "string" or path == "" or depth > 10 then return nil end
    visited = visited or {}
    if visited[path] then return nil end
    visited[path] = true

    local content = metadata.read_text(path)
    if content == nil then
        name_cache[path] = false
        return nil
    end
    local entity_tag = string.match(content, "<Entity[^>]*>")
    if entity_tag ~= nil then
        local name = metadata.attribute(entity_tag, "name")
        if name ~= nil and name ~= "" and not string.find(name, "DEBUG_NAME", 1, true) then
            name_cache[path] = name
            return name
        end
    end
    for _, base in ipairs(metadata.base_files(content)) do
        local name = entity_name(base, visited, depth + 1)
        if name ~= nil then
            name_cache[path] = name
            return name
        end
    end
    name_cache[path] = false
    return nil
end

function metadata.entity_name(path)
    return entity_name(path, {}, 0)
end

METAMORPH_CREATIVE_MENU_CREATURE_METADATA = metadata
return metadata
