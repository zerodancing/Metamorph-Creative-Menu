if type(METAMORPH_CREATIVE_MENU_ASSETS) == "table" then return METAMORPH_CREATIVE_MENU_ASSETS end

local asset_service = {}
local hash = dofile("mods/metamorph_creative_menu/files/core/hash.lua")
local xml_utils = dofile("mods/metamorph_creative_menu/files/core/xml_utils.lua")

local gui = nil
local text_cache = {}
local asset_cache = {}
local dimension_cache = {}
local entity_icon_cache = {}
local proxy_cache = {}
local proxy_meta = {}

local GENERATED_DIR = "mods/metamorph_creative_menu/files/generated/"
local function static_path(path) return string.sub(tostring(path or ""), 1, 5) ~= "mods/" end

local function read_text(path)
    if type(path) ~= "string" or path == "" then
        return nil
    end
    if text_cache[path] ~= nil then
        return text_cache[path] ~= false and text_cache[path] or nil
    end
    local ok, content = pcall(ModTextFileGetContent, path)
    if not ok or type(content) ~= "string" or content == "" then
        -- Vanilla data is immutable during a run; mod/VFS paths may legitimately be
        -- generated after our first probe, so never permanently cache those misses.
        if static_path(path) then text_cache[path] = false end
        return nil
    end
    text_cache[path] = content
    return content
end

local function attr(tag, name)
    return string.match(tag, name .. '%s*=%s*"([^"]+)"')
        or string.match(tag, name .. "%s*=%s*'([^']+)'")
end


local function first_animation(content, preferred)
    local first = nil
    for tag in string.gmatch(content, "<RectAnimation[^>]*>") do
        if first == nil then
            first = tag
        end
        if preferred ~= nil and preferred ~= "" and attr(tag, "name") == preferred then
            return tag
        end
    end
    return first
end

local function raster_dimensions(path)
    if dimension_cache[path] ~= nil then
        local cached = dimension_cache[path]
        if cached == false then
            return nil, nil
        end
        return cached[1], cached[2]
    end
    if gui == nil then
        return nil, nil
    end
    local ok, w, h = pcall(GuiGetImageDimensions, gui, path, 1)
    w, h = tonumber(w), tonumber(h)
    if not ok or w == nil or h == nil or w <= 0 or h <= 0 then
        -- Do not permanently poison an icon because its first dimensions query ran
        -- before the GUI/image resource was ready. Status icons can become available
        -- on a later frame.
        return nil, nil
    end
    dimension_cache[path] = { w, h }
    return w, h
end

local function prepare_first_frame_proxy(sprite_path)
    if proxy_cache[sprite_path] ~= nil then
        local cached = proxy_cache[sprite_path]
        return cached ~= false and cached or nil
    end
    local content = read_text(sprite_path)
    if content == nil then
        if static_path(sprite_path) then proxy_cache[sprite_path] = false end
        return nil
    end
    local sprite_tag = string.match(content, "<Sprite[^>]*>")
    if sprite_tag == nil then
        if static_path(sprite_path) then proxy_cache[sprite_path] = false end
        return nil
    end
    local filename = attr(sprite_tag, "filename")
    local animation = first_animation(content, attr(sprite_tag, "default_animation"))
    if filename == nil or filename == "" or animation == nil then
        if static_path(sprite_path) then proxy_cache[sprite_path] = false end
        return nil
    end
    local fw = tonumber(attr(animation, "frame_width"))
    local fh = tonumber(attr(animation, "frame_height"))
    if fw == nil or fh == nil or fw <= 0 or fh <= 0 then
        if static_path(sprite_path) then proxy_cache[sprite_path] = false end
        return nil
    end
    local generated_path = GENERATED_DIR .. "asset_first_frame_" .. hash.hex64(sprite_path) .. ".xml"
    local generated = string.format(
        '<Sprite filename="%s" default_animation="default"><RectAnimation name="default" pos_x="%d" pos_y="%d" frame_count="1" frame_width="%d" frame_height="%d" frame_wait="999999" frames_per_row="%d" loop="0"></RectAnimation></Sprite>',
        xml_utils.escape_attribute(filename),
        tonumber(attr(animation, "pos_x")) or 0,
        tonumber(attr(animation, "pos_y")) or 0,
        fw,
        fh,
        tonumber(attr(animation, "frames_per_row")) or 1
    )
    local ok = pcall(ModTextFileSetContent, generated_path, generated)
    if not ok then
        if static_path(sprite_path) then proxy_cache[sprite_path] = false end
        return nil
    end
    proxy_cache[sprite_path] = generated_path
    proxy_meta[generated_path] = { fw, fh }
    return generated_path
end

local function sibling_sprite_xml(path)
    if type(path) ~= "string" then
        return nil
    end
    local lower = string.lower(path)
    if string.sub(lower, -4) ~= ".png" then
        return nil
    end
    local candidate = string.sub(path, 1, #path - 4) .. ".xml"
    if ModDoesFileExist(candidate) then
        return candidate
    end
    return nil
end

local function resolve_asset(path, visited, depth)
    if type(path) ~= "string" or path == "" or depth > 10 then
        return nil
    end
    local cached = asset_cache[path]
    if cached ~= nil then
        return cached ~= false and cached or nil
    end
    visited = visited or {}
    if visited[path] then
        return nil
    end
    visited[path] = true

    if string.sub(string.lower(path), -4) ~= ".xml" then
        -- UI/status PNGs are already valid GuiImage assets. Prefer them directly; the
        -- old sibling-XML-first rule needlessly generated animation proxies and could
        -- leave effect slots blank when a sibling sprite failed to resolve once.
        local w, h = raster_dimensions(path)
        if w ~= nil then
            local result = { path = path, width = w, height = h }
            asset_cache[path] = result
            return result
        end
        local sibling = sibling_sprite_xml(path)
        if sibling ~= nil and not visited[sibling] then
            local framed = resolve_asset(sibling, visited, depth + 1)
            if framed ~= nil then
                asset_cache[path] = framed
                return framed
            end
        end
        -- Missing/transient raster assets are retried rather than cached as failure.
        return nil
    end

    local content = read_text(path)
    if content == nil then
        if static_path(path) then asset_cache[path] = false end
        return nil
    end

    if string.find(content, "<Sprite", 1, true) ~= nil then
        local proxy = prepare_first_frame_proxy(path)
        if proxy ~= nil then
            local meta = proxy_meta[proxy]
            local result = { path = proxy, width = meta[1], height = meta[2] }
            asset_cache[path] = result
            asset_cache[proxy] = result
            dimension_cache[proxy] = { meta[1], meta[2] }
            return result
        end
        local sprite_tag = string.match(content, "<Sprite[^>]*>")
        local filename = sprite_tag ~= nil and attr(sprite_tag, "filename") or nil
        if filename ~= nil and filename ~= "" then
            local result = resolve_asset(filename, visited, depth + 1)
            if result ~= nil then asset_cache[path] = result elseif static_path(path) then asset_cache[path] = false end
            return result
        end
    end

    if static_path(path) then asset_cache[path] = false end
    return nil
end

local function score_sprite(image_path, tag, kind)
    local lower = string.lower((image_path or "") .. " " .. (tag or ""))
    local score = 0
    local bad = { "particle", "glow", "light", "effect", "shadow", "mask", "emissive", "laser", "projectile", "status", "hurt", "damage", "spark", "muzzle", "ragdoll" }
    for _, word in ipairs(bad) do
        if string.find(lower, word, 1, true) then
            score = score - 25
        end
    end
    local good = { "character", "body", "enemy", "animal", "main", "sprite" }
    for _, word in ipairs(good) do
        if string.find(lower, word, 1, true) then
            score = score + 4
        end
    end
    if kind == "item" and string.find(lower, "item", 1, true) then
        score = score + 6
    end
    if kind == "form" then score = score + 1200 end
    if string.sub(string.lower(image_path or ""), -4) == ".xml" then
        score = score + 20
    elseif kind == "creature" and string.sub(string.lower(image_path or ""), -4) == ".png" then
        score = score - 4
    end
    return score
end

local function collect_entity_candidates(path, kind, visited, depth, out)
    if type(path) ~= "string" or path == "" or depth > 10 or visited[path] then
        return
    end
    visited[path] = true
    local content = read_text(path)
    if content == nil then
        return
    end
    -- UIIconComponent is the authoritative presentation for perks/status effects and
    -- is also used by several pickups. Prefer it over guessing from decorative sprites.
    if kind ~= "form" and kind ~= "creature" then
        for tag in string.gmatch(content, "<UIIconComponent[^>]*>") do
            local icon = attr(tag, "icon_sprite_file")
            if icon ~= nil and icon ~= "" then
                out[#out + 1] = { path = icon, score = (kind == "effect" and 1600 or 1150) }
            end
        end
    end
    if kind == "item" then
        for tag in string.gmatch(content, "<ItemComponent[^>]*>") do
            local ui = attr(tag, "ui_sprite")
            if ui ~= nil and ui ~= "" then
                out[#out + 1] = { path = ui, score = 1500 }
            end
        end
    end
    if kind == "item" or kind == "form" then
        -- Many physics pickups (chests, utility boxes, quest props) have no Item UI
        -- sprite at all; their PhysicsImageShape is the closest canonical visual.
        for tag in string.gmatch(content, "<PhysicsImageShapeComponent[^>]*>") do
            local image = attr(tag, "image_file")
            if image ~= nil and image ~= "" then
                out[#out + 1] = { path = image, score = kind == "form" and 700 or 900 }
            end
        end
    end
    for tag in string.gmatch(content, "<SpriteComponent[^>]*>") do
        local image = attr(tag, "image_file")
        if image ~= nil and image ~= "" then
            out[#out + 1] = { path = image, score = score_sprite(image, tag, kind) }
        end
    end
    for tag in string.gmatch(content, "<Base[^>]*>") do
        local base = attr(tag, "file")
        if base ~= nil and base ~= "" then
            collect_entity_candidates(base, kind, visited, depth + 1, out)
        end
    end
end

function asset_service.bind_gui(value)
    gui = value
end

function asset_service.resolve(path)
    return resolve_asset(path, {}, 0)
end

-- Runtime forms must keep the source sprite animation. The normal UI resolver turns
-- Sprite XML into a generated one-frame proxy on purpose so icons stay readable; using
-- that same asset for a player form made animated items/spells look frozen. This resolver
-- returns the best original world sprite/physics image without generating an icon proxy.
function asset_service.resolve_entity_live(path, kind)
    local candidates = {}
    collect_entity_candidates(path, kind or "form", {}, 0, candidates)
    table.sort(candidates, function(a, b) return a.score > b.score end)
    for _, candidate in ipairs(candidates) do
        local candidate_path = tostring(candidate.path or "")
        if candidate_path ~= "" and ModDoesFileExist(candidate_path) then
            return candidate_path
        end
    end
    return nil
end

function asset_service.resolve_entity(path, kind)
    local key = tostring(kind or "generic") .. "|" .. tostring(path or "")
    if entity_icon_cache[key] ~= nil then
        local cached = entity_icon_cache[key]
        return cached ~= false and cached or nil
    end
    local candidates = {}
    collect_entity_candidates(path, kind or "generic", {}, 0, candidates)
    table.sort(candidates, function(a, b) return a.score > b.score end)

    -- Item ui_sprite frequently points at an animation atlas rather than a single icon.
    -- If there is any Sprite XML for the entity, prefer that XML (or the PNG's sibling
    -- XML) before ever accepting a raw PNG. The XML resolver generates a one-frame
    -- proxy, so animated hearts/orbs remain one readable picture instead of a strip of
    -- tiny frames. Physics-only props still fall back to their raw shape image.
    local ordered = {}
    if kind == "item" then
        for _, candidate in ipairs(candidates) do
            local sibling = sibling_sprite_xml(candidate.path)
            if sibling ~= nil then
                ordered[#ordered + 1] = { path = sibling, score = candidate.score + 2000 }
            elseif string.sub(string.lower(candidate.path or ""), -4) == ".xml" then
                ordered[#ordered + 1] = { path = candidate.path, score = candidate.score + 1000 }
            end
        end
        for _, candidate in ipairs(candidates) do ordered[#ordered + 1] = candidate end
        table.sort(ordered, function(a, b) return a.score > b.score end)
    else
        ordered = candidates
    end

    for _, candidate in ipairs(ordered) do
        local resolved = resolve_asset(candidate.path, {}, 0)
        if resolved ~= nil then
            entity_icon_cache[key] = resolved
            return resolved
        end
    end
    -- Do not negative-cache entity presentation. Some UI/status resources become
    -- queryable only after the owning script has initialized; a permanent miss made
    -- previously visible effect icons turn into empty cells for the rest of the run.
    return nil
end

function asset_service.dimensions(asset_or_path)
    if type(asset_or_path) == "table" then
        return asset_or_path.width, asset_or_path.height
    end
    if type(asset_or_path) ~= "string" or asset_or_path == "" then
        return nil, nil
    end
    local meta = proxy_meta[asset_or_path]
    if meta ~= nil then
        return meta[1], meta[2]
    end
    return raster_dimensions(asset_or_path)
end

function asset_service.path(asset_or_path)
    if type(asset_or_path) == "table" then
        return asset_or_path.path
    end
    return asset_or_path
end

function asset_service.invalidate_entity(path)
    for key in pairs(entity_icon_cache) do
        if string.find(key, "|" .. tostring(path), 1, true) ~= nil then
            entity_icon_cache[key] = nil
        end
    end
end

METAMORPH_CREATIVE_MENU_ASSETS = asset_service
return asset_service
