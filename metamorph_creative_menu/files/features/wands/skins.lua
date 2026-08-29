if type(METAMORPH_CREATIVE_MENU_WAND_SKINS) == "table" then return METAMORPH_CREATIVE_MENU_WAND_SKINS end

local skins = {}
local item_catalog = dofile("mods/metamorph_creative_menu/files/features/items/catalog.lua")
local cache = nil

local function attr(tag, name)
    local escaped = string.gsub(name, "([^%w])", "%%%1")
    return string.match(tag, escaped .. "%s*=%s*\"([^\"]*)\"")
        or string.match(tag, escaped .. "%s*=%s*'([^']*)'")
end

local function number_attr(tag, name)
    local value = attr(tag, name)
    return value ~= nil and tonumber(value) or nil
end

local function tagged(tag, wanted)
    local tags = tostring(attr(tag, "_tags") or attr(tag, "tags") or "")
    for value in string.gmatch(tags, "[^,%s]+") do if value == wanted then return true end end
    return false
end

local function merge(into, values)
    for key, value in pairs(values or {}) do if value ~= nil then into[key] = value end end
    return into
end

local function read_visual(path, visited, depth)
    if type(path) ~= "string" or path == "" or depth > 10 or visited[path] then return nil end
    if type(ModTextFileGetContent) ~= "function" then return nil end
    visited[path] = true
    local ok, content = pcall(ModTextFileGetContent, path)
    if not ok or type(content) ~= "string" or content == "" then visited[path] = nil; return nil end

    local result = {}
    for base in string.gmatch(content, "<Base[^>]*>") do
        local base_path = attr(base, "file")
        if base_path ~= nil and base_path ~= "" then merge(result, read_visual(base_path, visited, depth + 1)) end
    end

    for ability in string.gmatch(content, "<AbilityComponent[^>]*>") do
        local sprite = attr(ability, "sprite_file")
        if sprite ~= nil and sprite ~= "" then result.sprite_file = sprite end
    end
    for sprite in string.gmatch(content, "<SpriteComponent[^>]*>") do
        if tagged(sprite, "item") then
            local image = attr(sprite, "image_file")
            if image ~= nil and image ~= "" then result.image_file = image end
            local x, y = number_attr(sprite, "offset_x"), number_attr(sprite, "offset_y")
            if x ~= nil then result.offset_x = x end
            if y ~= nil then result.offset_y = y end
        end
    end
    for hotspot in string.gmatch(content, "<HotspotComponent[^>]*>") do
        if tagged(hotspot, "shoot_pos") then
            local x = number_attr(hotspot, "offset.x")
            local y = number_attr(hotspot, "offset.y")
            if x ~= nil then result.tip_x = x end
            if y ~= nil then result.tip_y = y end
        end
    end
    visited[path] = nil
    return next(result) ~= nil and result or nil
end

function skins.entries()
    if cache ~= nil then return cache end
    cache = {}
    local seen = {}
    for _, entry in ipairs(type(item_catalog) == "table" and item_catalog or {}) do
        if entry.category == "WANDS" and type(entry.path) == "string" then
            local visual = read_visual(entry.path, {}, 0)
            local sprite = visual and (visual.sprite_file or visual.image_file) or nil
            if type(sprite) == "string" and sprite ~= "" then
                local image = visual.image_file or sprite
                local signature = table.concat({sprite, image, tostring(visual.offset_x or ""), tostring(visual.offset_y or ""),
                    tostring(visual.tip_x or ""), tostring(visual.tip_y or "")}, "\31")
                if not seen[signature] then
                    seen[signature] = true
                    cache[#cache + 1] = {
                        sprite_file=sprite, image_file=image, source_path=entry.path,
                        name=entry.name, icon=entry.icon,
                        offset_x=visual.offset_x, offset_y=visual.offset_y,
                        tip_x=visual.tip_x, tip_y=visual.tip_y,
                    }
                end
            end
        end
    end
    table.sort(cache, function(a,b)
        local aa=tostring(a.name or a.source_path); local bb=tostring(b.name or b.source_path)
        if aa==bb then return a.sprite_file<b.sprite_file end
        return aa<bb
    end)
    return cache
end

function skins.reset() cache = nil end

METAMORPH_CREATIVE_MENU_WAND_SKINS = skins
return skins
