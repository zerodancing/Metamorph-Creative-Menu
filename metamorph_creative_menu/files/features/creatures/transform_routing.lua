local transform_routing = {}

local metadata = dofile("mods/metamorph_creative_menu/files/features/creatures/metadata.lua")

local CRASH_PRONE_WRAPPER_PREFIXES = {
    "data/entities/animals/rainforest/",
    "data/entities/animals/vault/",
    "data/entities/animals/crypt/",
    "data/entities/animals/the_end/",
    "data/entities/animals/robobase/",
}

local function is_confirmed_wrapper_group(path)
    path = tostring(path or "")
    for _, prefix in ipairs(CRASH_PRONE_WRAPPER_PREFIXES) do
        if path:sub(1, #prefix) == prefix then
            local remainder = path:sub(#prefix + 1)
            if remainder:match("^[^/]+%.xml$") then return true end
        end
    end
    return false
end

local function read_text(path)
    local ok, content = pcall(ModTextFileGetContent, path)
    if not ok or type(content) ~= "string" or content == "" then return nil end
    return content
end

local function attribute(tag, name)
    local escaped = tostring(name):gsub("([%%%-%+%*%?%[%]%^%$%(%)%.])", "%%%1")
    return tag:match(escaped .. '%s*=%s*"([^"]*)"')
        or tag:match(escaped .. "%s*=%s*'([^']*)'")
end

local function tag_name(tag)
    if tostring(tag):match("^<%s*/") then
        return tostring(tag):match("^<%s*/%s*([%w_]+)")
    end
    return tostring(tag):match("^<%s*([%w_]+)")
end

local function is_self_closing(tag)
    return tostring(tag):match("/%s*>$") ~= nil
end

-- Rainforest, Vault, Crypt, The End, and Robobase contain placement/depth variants which EntityLoad handles as
-- normal authored enemies, but which have repeatedly hard-crashed Noita when used as
-- direct POLYMORPH targets.  Only route a path away from itself when the file proves it
-- is a thin same-species wrapper: a direct root Base with the same XML basename.
-- This keeps unrelated authored variants on their existing exact-transform route.
local function direct_same_species_base(path)
    if not is_confirmed_wrapper_group(path) then return nil, "not_crash_prone_group" end
    local content = read_text(path)
    if content == nil then return nil, "read_failed" end

    local entity_depth = 0
    for tag in content:gmatch("<[^>]+>") do
        if not tag:match("^<%s*!") and not tag:match("^<%s*%?") then
            local name = tag_name(tag)
            if name == "Entity" then
                if tag:match("^<%s*/") then
                    entity_depth = math.max(0, entity_depth - 1)
                elseif not is_self_closing(tag) then
                    entity_depth = entity_depth + 1
                end
            elseif name == "Base" and entity_depth == 1 and not tag:match("^<%s*/") then
                local base_path = attribute(tag, "file")
                if type(base_path) ~= "string" or base_path == "" or base_path == path then
                    return nil, "direct_base_missing"
                end
                if metadata.basename(base_path) ~= metadata.basename(path) then
                    return nil, "different_species_base"
                end
                if not ModDoesFileExist(base_path) then return nil, "base_missing" end
                return base_path, "same_species_placement_wrapper"
            end
        end
    end
    return nil, "direct_base_missing"
end

function transform_routing.plan(path, exact_canonical_target)
    path = tostring(path or "")
    if path == "" or not ModDoesFileExist(path) then
        return { requested_path = path, target_path = path, mode = "invalid", reason = "missing_target" }
    end

    if type(exact_canonical_target) == "string" and exact_canonical_target ~= ""
        and exact_canonical_target ~= path and ModDoesFileExist(exact_canonical_target)
    then
        return {
            requested_path = path,
            target_path = exact_canonical_target,
            mode = "exact_canonical_alias",
            reason = "exact_path_compatibility_alias",
        }
    end

    local base_path, reason = direct_same_species_base(path)
    if type(base_path) == "string" and base_path ~= "" then
        return {
            requested_path = path,
            target_path = base_path,
            mode = "placement_wrapper_fallback",
            reason = reason,
        }
    end

    return {
        requested_path = path,
        target_path = path,
        mode = "direct",
        reason = reason or "direct",
    }
end

function transform_routing.direct_same_species_base(path)
    return direct_same_species_base(path)
end

return transform_routing
