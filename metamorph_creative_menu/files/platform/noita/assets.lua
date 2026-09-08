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

local GENERATED_DIR = "mods/metamorph_creative_menu/files/generated/"
local PLACEHOLDER_PATH = "data/ui_gfx/progress_menu/icon_unknown.png"
-- Public GuiImage playback enum from data/scripts/lib/utilities.lua. A one-frame
-- proxy can safely use PlayToEndAndPause; original multi-frame Sprite XML uses the
-- same mode as a bounded fallback because the public API has no "pause on frame 0".
local PLAY_TO_END_AND_PAUSE = 1

local function static_path(path)
    return string.sub(tostring(path or ""), 1, 5) ~= "mods/"
end

local function read_text(path)
    if type(path) ~= "string" or path == "" then return nil end
    if static_path(path) and text_cache[path] ~= nil then
        return text_cache[path] ~= false and text_cache[path] or nil
    end
    local ok, content = pcall(ModTextFileGetContent, path)
    if not ok or type(content) ~= "string" or content == "" then
        -- Vanilla data is immutable during a run. Mod/VFS resources can appear after
        -- pre-init, so neither misses nor successful reads are frozen for mods/* paths.
        if static_path(path) then text_cache[path] = false end
        return nil
    end
    if static_path(path) then text_cache[path] = content end
    return content
end

local function attr(tag, name)
    return string.match(tag, name .. '%s*=%s*"([^"]+)"')
        or string.match(tag, name .. "%s*=%s*'([^']+)'")
end

local function first_animation(content, preferred)
    local first = nil
    for tag in string.gmatch(content, "<RectAnimation[^>]*>") do
        if first == nil then first = tag end
        if preferred ~= nil and preferred ~= "" and attr(tag, "name") == preferred then
            return tag
        end
    end
    return first
end

local function parse_sprite(path, content)
    if type(content) ~= "string" or content == "" then return nil, "sprite_xml_unreadable" end
    local sprite_tag = string.match(content, "<Sprite[^>]*>")
    if sprite_tag == nil then return nil, "sprite_xml_missing_sprite" end
    local filename = attr(sprite_tag, "filename")
    if filename == nil or filename == "" then return nil, "sprite_xml_missing_filename" end
    local preferred = attr(sprite_tag, "default_animation")
    local animation = first_animation(content, preferred)
    if animation == nil then return nil, "sprite_xml_missing_animation" end
    local frame_width = tonumber(attr(animation, "frame_width"))
    local frame_height = tonumber(attr(animation, "frame_height"))
    if frame_width == nil or frame_height == nil or frame_width <= 0 or frame_height <= 0 then
        return nil, "sprite_xml_invalid_frame_size"
    end
    local animation_name = attr(animation, "name") or preferred or ""
    local frame_count = math.max(1, tonumber(attr(animation, "frame_count")) or 1)
    local frames_per_row = math.max(1, tonumber(attr(animation, "frames_per_row")) or 1)
    local rect = {
        name = animation_name,
        pos_x = tonumber(attr(animation, "pos_x")) or 0,
        pos_y = tonumber(attr(animation, "pos_y")) or 0,
        frame_count = frame_count,
        frame_width = frame_width,
        frame_height = frame_height,
        frame_wait = tonumber(attr(animation, "frame_wait")),
        frames_per_row = frames_per_row,
        loop = tonumber(attr(animation, "loop")) or 0,
    }
    return {
        kind = "sprite_xml",
        path = path,
        source_path = path,
        source_png = filename,
        width = frame_width,
        height = frame_height,
        animation_name = animation_name,
        playback_mode = PLAY_TO_END_AND_PAUSE,
        rect_animation = rect,
        single_frame = frame_count == 1,
        source_is_atlas = frame_count > 1 or frames_per_row > 1,
        proxy = false,
    }
end

local function placeholder(reason, source_path)
    return {
        kind = "placeholder",
        path = PLACEHOLDER_PATH,
        source_path = source_path,
        reason = reason or "asset_unavailable",
        animation_name = "",
        single_frame = true,
        source_is_atlas = false,
        proxy = false,
    }
end

local function raster_dimensions(path)
    if dimension_cache[path] ~= nil then
        local cached = dimension_cache[path]
        if cached == false then return nil, nil end
        return cached[1], cached[2]
    end
    if gui == nil then return nil, nil end
    local ok, w, h = pcall(GuiGetImageDimensions, gui, path, 1)
    w, h = tonumber(w), tonumber(h)
    if not ok or w == nil or h == nil or w <= 0 or h <= 0 then
        -- Resource availability can be frame-dependent; never poison the cache here.
        return nil, nil
    end
    dimension_cache[path] = { w, h }
    return w, h
end

local function sibling_sprite_xml(path)
    if type(path) ~= "string" or string.sub(string.lower(path), -4) ~= ".png" then return nil end
    local candidate = string.sub(path, 1, #path - 4) .. ".xml"
    if ModDoesFileExist(candidate) then return candidate end
    return nil
end

local function parse_sprite_path(sprite_path)
    local content = read_text(sprite_path)
    if content == nil then return nil, "sprite_xml_unreadable" end
    return parse_sprite(sprite_path, content)
end

local function prepare_first_frame_proxy(sprite_path)
    local cached = proxy_cache[sprite_path]
    if cached ~= nil then return cached ~= false and cached or nil, cached == false and "proxy_unavailable" or nil end

    local source, reason = parse_sprite_path(sprite_path)
    if source == nil then
        if static_path(sprite_path) then proxy_cache[sprite_path] = false end
        return nil, reason
    end

    local rect = source.rect_animation
    local proxy_animation_name = source.animation_name ~= "" and source.animation_name or "default"
    local generated_path = GENERATED_DIR .. "asset_first_frame_" .. hash.hex64(sprite_path) .. ".xml"
    local generated = string.format(
        '<Sprite filename="%s" default_animation="%s"><RectAnimation name="%s" pos_x="%d" pos_y="%d" frame_count="1" frame_width="%d" frame_height="%d" frame_wait="999999" frames_per_row="1" loop="0"></RectAnimation></Sprite>',
        xml_utils.escape_attribute(source.source_png),
        xml_utils.escape_attribute(proxy_animation_name),
        xml_utils.escape_attribute(proxy_animation_name),
        rect.pos_x,
        rect.pos_y,
        rect.frame_width,
        rect.frame_height
    )
    local ok = pcall(ModTextFileSetContent, generated_path, generated)
    if not ok then
        -- Never permanently cache a failed mods/* publication; load order can make a
        -- resource temporarily unavailable during pre-init.
        if static_path(sprite_path) then proxy_cache[sprite_path] = false end
        return nil, "proxy_write_failed"
    end

    local descriptor = {
        kind = "sprite_proxy",
        path = generated_path,
        source_path = sprite_path,
        source_png = source.source_png,
        width = source.width,
        height = source.height,
        animation_name = proxy_animation_name,
        playback_mode = PLAY_TO_END_AND_PAUSE,
        rect_animation = {
            name = proxy_animation_name,
            pos_x = rect.pos_x,
            pos_y = rect.pos_y,
            frame_count = 1,
            frame_width = rect.frame_width,
            frame_height = rect.frame_height,
            frame_wait = 999999,
            frames_per_row = 1,
            loop = 0,
        },
        single_frame = true,
        source_is_atlas = false,
        proxy = true,
    }
    proxy_cache[sprite_path] = descriptor
    asset_cache[sprite_path] = descriptor
    asset_cache[generated_path] = descriptor
    dimension_cache[generated_path] = { descriptor.width, descriptor.height }
    return descriptor
end

local function raster_descriptor(path)
    if not ModDoesFileExist(path) then return nil end
    local w, h = raster_dimensions(path)
    return {
        kind = "raster",
        path = path,
        source_path = path,
        width = w,
        height = h,
        animation_name = "",
        single_frame = true,
        source_is_atlas = false,
        proxy = false,
    }
end

local function resolve_asset(path, visited, depth)
    if type(path) == "table" and type(path.path) == "string" then return path end
    if type(path) ~= "string" or path == "" or depth > 10 then return nil end
    local cached = asset_cache[path]
    if cached ~= nil then return cached ~= false and cached or nil end
    visited = visited or {}
    if visited[path] then return nil end
    visited[path] = true

    if string.sub(string.lower(path), -4) ~= ".xml" then
        -- A PNG is safe only when it is a genuine raster icon. If a sibling Sprite XML
        -- proves that this exact PNG is an animation atlas, route through the XML
        -- descriptor/proxy instead of ever handing the atlas to GuiImage as an icon.
        local sibling = sibling_sprite_xml(path)
        if sibling ~= nil and not visited[sibling] then
            local sibling_info = parse_sprite_path(sibling)
            if sibling_info ~= nil and sibling_info.source_png == path and sibling_info.source_is_atlas then
                local framed = resolve_asset(sibling, visited, depth + 1)
                if framed ~= nil then
                    asset_cache[path] = framed
                    return framed
                end
                return placeholder("animated_raster_without_sprite", path)
            end
        end
        local result = raster_descriptor(path)
        if result ~= nil and static_path(path) then asset_cache[path] = result end
        return result
    end

    local source, reason = parse_sprite_path(path)
    if source == nil then
        local result = placeholder(reason, path)
        if static_path(path) then asset_cache[path] = result end
        return result
    end

    -- Prewarmed known icons are guaranteed one-frame proxies. Runtime-discovered mod
    -- objects may not exist during OnModPreInit; for them keep the original Sprite XML
    -- and pass its explicit RectAnimation metadata to GuiImage. This never exposes the
    -- source PNG atlas as a successful icon descriptor.
    local proxy = proxy_cache[path]
    local result = type(proxy) == "table" and proxy or source
    if static_path(path) then asset_cache[path] = result end
    return result
end

local function score_sprite(image_path, tag, kind)
    local lower = string.lower((image_path or "") .. " " .. (tag or ""))
    local score = 0
    local bad = { "particle", "glow", "light", "effect", "shadow", "mask", "emissive", "laser", "projectile", "status", "hurt", "damage", "spark", "muzzle", "ragdoll" }
    for _, word in ipairs(bad) do if string.find(lower, word, 1, true) then score = score - 25 end end
    local good = { "character", "body", "enemy", "animal", "main", "sprite" }
    for _, word in ipairs(good) do if string.find(lower, word, 1, true) then score = score + 4 end end
    if kind == "item" and string.find(lower, "item", 1, true) then score = score + 6 end
    if kind == "form" then score = score + 1200 end
    if string.sub(string.lower(image_path or ""), -4) == ".xml" then
        score = score + 20
    elseif kind == "creature" and string.sub(string.lower(image_path or ""), -4) == ".png" then
        score = score - 4
    end
    return score
end

local function collect_entity_candidates(path, kind, visited, depth, out)
    if type(path) ~= "string" or path == "" or depth > 10 or visited[path] then return end
    visited[path] = true
    local content = read_text(path)
    if content == nil then return end
    if kind ~= "form" and kind ~= "creature" then
        for tag in string.gmatch(content, "<UIIconComponent[^>]*>") do
            local icon = attr(tag, "icon_sprite_file")
            if icon ~= nil and icon ~= "" then out[#out + 1] = { path = icon, score = (kind == "effect" and 1600 or 1150) } end
        end
    end
    if kind == "item" then
        for tag in string.gmatch(content, "<ItemComponent[^>]*>") do
            local ui = attr(tag, "ui_sprite")
            if ui ~= nil and ui ~= "" then out[#out + 1] = { path = ui, score = 1500 } end
        end
    end
    if kind == "item" or kind == "form" then
        for tag in string.gmatch(content, "<PhysicsImageShapeComponent[^>]*>") do
            local image = attr(tag, "image_file")
            if image ~= nil and image ~= "" then out[#out + 1] = { path = image, score = kind == "form" and 700 or 900 } end
        end
    end
    for tag in string.gmatch(content, "<SpriteComponent[^>]*>") do
        local image = attr(tag, "image_file")
        if image ~= nil and image ~= "" then out[#out + 1] = { path = image, score = score_sprite(image, tag, kind) } end
    end
    for tag in string.gmatch(content, "<Base[^>]*>") do
        local base = attr(tag, "file")
        if base ~= nil and base ~= "" then collect_entity_candidates(base, kind, visited, depth + 1, out) end
    end
end

local function ordered_entity_candidates(path, kind)
    local candidates = {}
    collect_entity_candidates(path, kind or "generic", {}, 0, candidates)
    table.sort(candidates, function(a, b) return a.score > b.score end)
    if kind ~= "item" then return candidates end

    local ordered = {}
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
    return ordered
end

local function prewarm_path(path)
    if type(path) ~= "string" or path == "" then return false, "invalid_path" end
    local lower = string.lower(path)
    if string.sub(lower, -4) == ".xml" then
        local descriptor, reason = prepare_first_frame_proxy(path)
        return descriptor ~= nil, reason
    end
    if string.sub(lower, -4) == ".png" then
        local sibling = sibling_sprite_xml(path)
        if sibling ~= nil then
            local info = parse_sprite_path(sibling)
            if info ~= nil and info.source_png == path and info.source_is_atlas then
                local descriptor, reason = prepare_first_frame_proxy(sibling)
                return descriptor ~= nil, reason
            end
        end
        return true, nil
    end
    return false, "unsupported_asset"
end

function asset_service.bind_gui(value)
    gui = value
end

function asset_service.resolve(path)
    return resolve_asset(path, {}, 0)
end

function asset_service.prewarm(paths)
    if type(paths) ~= "table" then return 0, 0 end
    local seen = {}
    local prepared, failed = 0, 0
    for _, path in ipairs(paths) do
        path = tostring(path or "")
        if path ~= "" and not seen[path] then
            seen[path] = true
            local ok = prewarm_path(path)
            if ok then prepared = prepared + 1 else failed = failed + 1 end
        end
    end
    return prepared, failed
end

function asset_service.prewarm_entity(path, kind)
    local seen = {}
    for _, candidate in ipairs(ordered_entity_candidates(path, kind or "generic")) do
        local candidate_path = tostring(candidate.path or "")
        if candidate_path ~= "" and not seen[candidate_path] then
            seen[candidate_path] = true
            local ok = prewarm_path(candidate_path)
            if ok then return true end
        end
    end
    return false
end

-- Runtime forms must keep the source sprite animation. UI descriptors/proxies are never
-- used for player-form world sprites.
function asset_service.resolve_entity_live(path, kind)
    local candidates = {}
    collect_entity_candidates(path, kind or "form", {}, 0, candidates)
    table.sort(candidates, function(a, b) return a.score > b.score end)
    for _, candidate in ipairs(candidates) do
        local candidate_path = tostring(candidate.path or "")
        if candidate_path ~= "" and ModDoesFileExist(candidate_path) then return candidate_path end
    end
    return nil
end

function asset_service.resolve_entity(path, kind)
    local key = tostring(kind or "generic") .. "|" .. tostring(path or "")
    if entity_icon_cache[key] ~= nil then return entity_icon_cache[key] end
    for _, candidate in ipairs(ordered_entity_candidates(path, kind or "generic")) do
        local resolved = resolve_asset(candidate.path, {}, 0)
        if resolved ~= nil and resolved.kind ~= "placeholder" then
            entity_icon_cache[key] = resolved
            return resolved
        end
    end
    -- Do not negative-cache entity presentation: mod/VFS resources can appear later.
    return nil
end

function asset_service.dimensions(asset_or_path)
    if type(asset_or_path) == "table" then
        local w, h = tonumber(asset_or_path.width), tonumber(asset_or_path.height)
        if w ~= nil and h ~= nil and w > 0 and h > 0 then return w, h end
        return raster_dimensions(asset_or_path.path)
    end
    if type(asset_or_path) ~= "string" or asset_or_path == "" then return nil, nil end
    return raster_dimensions(asset_or_path)
end

function asset_service.path(asset_or_path)
    if type(asset_or_path) == "table" then return asset_or_path.path end
    return asset_or_path
end

function asset_service.placeholder(reason, source_path)
    return placeholder(reason, source_path)
end

function asset_service.invalidate_entity(path)
    for key in pairs(entity_icon_cache) do
        if string.find(key, "|" .. tostring(path), 1, true) ~= nil then entity_icon_cache[key] = nil end
    end
end

METAMORPH_CREATIVE_MENU_ASSETS = asset_service
return asset_service
