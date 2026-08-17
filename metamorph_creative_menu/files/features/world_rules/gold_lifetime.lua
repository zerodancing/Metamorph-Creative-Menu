local gold_lifetime_service = {}

function gold_lifetime_service.is_ordinary_timed_gold_path(entity_path)
    local normalized_path = string.lower(tostring(entity_path or ""))
    return normalized_path == "data/entities/items/pickup/goldnugget.xml"
        or string.match(normalized_path, "data/entities/items/pickup/goldnugget_%d+%.xml$") ~= nil
        or string.match(normalized_path, "data/entities/items/pickup/bloodmoney_%d+%.xml$") ~= nil
end

function gold_lifetime_service.restore_missing_lifetimes()
    if type(EntityGetWithTag) ~= "function" or type(EntityAddComponent2) ~= "function" then return 0 end
    local query_succeeded, gold_entities = pcall(EntityGetWithTag, "gold_nugget")
    if not query_succeeded or type(gold_entities) ~= "table" then return 0 end

    local restored_count = 0
    for _, gold_entity_id in ipairs(gold_entities) do
        if gold_entity_id ~= nil and gold_entity_id ~= 0 and EntityGetIsAlive(gold_entity_id) then
            local entity_path = EntityGetFilename(gold_entity_id)
            if gold_lifetime_service.is_ordinary_timed_gold_path(entity_path) then
                local lifetime_component = EntityGetFirstComponentIncludingDisabled(gold_entity_id, "LifetimeComponent")
                if lifetime_component == nil or lifetime_component == 0 then
                    local add_succeeded, added_component = pcall(EntityAddComponent2, gold_entity_id, "LifetimeComponent", {
                        _tags="enabled_in_world", lifetime=900,
                    })
                    if add_succeeded and added_component ~= nil and added_component ~= 0 then
                        restored_count = restored_count + 1
                    end
                end
            end
        end
    end
    return restored_count
end

return gold_lifetime_service
