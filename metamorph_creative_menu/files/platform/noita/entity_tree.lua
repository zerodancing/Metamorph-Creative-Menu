if type(METAMORPH_CREATIVE_MENU_ENTITY_TREE) == "table" then return METAMORPH_CREATIVE_MENU_ENTITY_TREE end

local entity_tree = {}

function entity_tree.walk(root_entity, visitor)
    if root_entity == nil or root_entity == 0 or type(visitor) ~= "function" then return end
    local queue = { root_entity }
    local seen = {}
    local index = 1
    while index <= #queue do
        local entity = queue[index]
        index = index + 1
        if entity ~= nil and entity ~= 0 and not seen[entity] then
            seen[entity] = true
            if visitor(entity) == false then return end
            for _, child in ipairs(EntityGetAllChildren(entity) or {}) do
                queue[#queue + 1] = child
            end
        end
    end
end

function entity_tree.root(entity)
    if entity == nil or entity == 0 then return 0 end
    local current = entity
    local seen = {}
    while current ~= nil and current ~= 0 and not seen[current] do
        seen[current] = true
        local parent = EntityGetParent(current)
        if parent == nil or parent == 0 then return current end
        current = parent
    end
    return entity
end

METAMORPH_CREATIVE_MENU_ENTITY_TREE = entity_tree
return entity_tree
