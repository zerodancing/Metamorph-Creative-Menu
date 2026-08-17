if type(METAMORPH_CREATIVE_MENU_FORM_ENTITY_TREE_CACHE) == "table" then return METAMORPH_CREATIVE_MENU_FORM_ENTITY_TREE_CACHE end

local cache = {}
local entity_tree = dofile("mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua")
local cached_frame = -1
local cached_root = 0
local cached_nodes = nil
local components_by_type = {}

function cache.reset()
    cached_frame = -1
    cached_root = 0
    cached_nodes = nil
    components_by_type = {}
end

local function nodes(root_entity)
    local frame = tonumber(GameGetFrameNum()) or -1
    if cached_frame ~= frame or cached_root ~= root_entity then
        cached_frame = frame
        cached_root = root_entity
        cached_nodes = nil
        components_by_type = {}
    end
    if cached_nodes == nil then
        cached_nodes = {}
        entity_tree.walk(root_entity, function(entity)
            cached_nodes[#cached_nodes + 1] = entity
        end)
    end
    return cached_nodes
end

function cache.components(root_entity, component_type)
    nodes(root_entity)
    local existing = components_by_type[component_type]
    if existing ~= nil then return existing end
    local result = {}
    for _, entity in ipairs(cached_nodes or {}) do
        for _, component in ipairs(EntityGetComponentIncludingDisabled(entity, component_type) or {}) do
            result[#result + 1] = component
        end
    end
    components_by_type[component_type] = result
    return result
end

METAMORPH_CREATIVE_MENU_FORM_ENTITY_TREE_CACHE = cache
return cache
