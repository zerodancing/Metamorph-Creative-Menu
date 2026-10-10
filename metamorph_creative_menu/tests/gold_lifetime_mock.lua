local root = assert(arg[1], "root required")
local service = dofile(root .. "/files/features/world_rules/gold_lifetime.lua")
local entities = {1,2,3,4}
local paths = {
    [1]="data/entities/items/pickup/goldnugget.xml",
    [2]="data/entities/items/pickup/goldnugget_200.xml",
    [3]="data/entities/items/pickup/bloodmoney_50.xml",
    [4]="data/entities/items/pickup/goldnugget_200000.xml_extra",
}
local lifetimes = {[2]=99}
local next_component = 100
function EntityGetWithTag(tag) assert(tag=="gold_nugget"); return entities end
function EntityGetIsAlive(_) return true end
function EntityGetFilename(entity) return paths[entity] end
function EntityGetFirstComponentIncludingDisabled(entity, component_type)
    assert(component_type=="LifetimeComponent")
    return lifetimes[entity]
end
function EntityAddComponent2(entity, component_type, values)
    assert(component_type=="LifetimeComponent")
    assert(values.lifetime==900)
    next_component = next_component + 1
    lifetimes[entity] = next_component
    return next_component
end
local restored = service.restore_missing_lifetimes()
assert(restored == 2, "unexpected restored count: " .. tostring(restored))
assert(lifetimes[1] ~= nil and lifetimes[3] ~= nil, "ordinary gold was not restored")
assert(lifetimes[4] == nil, "special/nonmatching gold path was modified")
print("gold_lifetime_service=PASS restored=" .. tostring(restored))
