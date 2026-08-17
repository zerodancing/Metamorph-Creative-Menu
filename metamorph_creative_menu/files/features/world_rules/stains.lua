if type(METAMORPH_CREATIVE_MENU_WORLD_RULE_STAINS) == "table" then return METAMORPH_CREATIVE_MENU_WORLD_RULE_STAINS end

local stain_adapter = {}
local rule_math = dofile("mods/metamorph_creative_menu/files/core/rule_math.lua")
local SCAN_RADIUS = 1024
local stain_state = {}

local function same_value(left_value, right_value)
    if type(left_value) == "number" or type(right_value) == "number" then
        return rule_math.same(left_value, right_value)
    end
    return left_value == right_value
end

local function stain_record(component_id, frame_number)
    local record_key = tostring(component_id)
    local existing_record = stain_state[record_key]
    if existing_record ~= nil then
        existing_record.last_seen_frame = frame_number
        return existing_record, record_key
    end

    local read_succeeded, original_multiplier = pcall(
        ComponentGetValue2, component_id, "stain_shaken_drop_chance_multiplier"
    )
    original_multiplier = read_succeeded and tonumber(original_multiplier) or nil
    if original_multiplier == nil then return nil, record_key end

    local type_read_succeeded, component_type = pcall(ComponentGetTypeName, component_id)
    local owner_read_succeeded, owner_entity_id = pcall(ComponentGetEntity, component_id)
    local new_record = {
        component_id = component_id,
        component_type = type_read_succeeded and component_type or "",
        owner_entity_id = owner_read_succeeded and owner_entity_id or 0,
        original_multiplier = original_multiplier,
        last_seen_frame = frame_number,
        last_written_multiplier = nil,
    }
    stain_state[record_key] = new_record
    return new_record, record_key
end

local function set_stain_drop(component_id, target_multiplier, frame_number)
    local ownership_record = stain_record(component_id, frame_number)
    if ownership_record == nil then return false end

    target_multiplier = tonumber(target_multiplier)
    if target_multiplier == nil then return false end

    local read_succeeded, current_multiplier = pcall(
        ComponentGetValue2, component_id, "stain_shaken_drop_chance_multiplier"
    )
    current_multiplier = read_succeeded and tonumber(current_multiplier) or nil
    if current_multiplier ~= nil and same_value(current_multiplier, target_multiplier) then
        ownership_record.last_written_multiplier = current_multiplier
        return true
    end

    local write_succeeded = pcall(
        ComponentSetValue2, component_id, "stain_shaken_drop_chance_multiplier", target_multiplier
    )
    local verify_succeeded, written_multiplier = pcall(
        ComponentGetValue2, component_id, "stain_shaken_drop_chance_multiplier"
    )
    written_multiplier = verify_succeeded and tonumber(written_multiplier) or nil
    if write_succeeded and written_multiplier ~= nil and same_value(written_multiplier, target_multiplier) then
        ownership_record.last_written_multiplier = written_multiplier
        return true
    end
    return false
end

local function restore_stain_record(record_key, ownership_record)
    if ownership_record == nil or ownership_record.component_id == nil then
        stain_state[record_key] = nil
        return true, "gone"
    end

    local type_read_succeeded, current_type = pcall(ComponentGetTypeName, ownership_record.component_id)
    local owner_read_succeeded, current_owner_entity_id = pcall(ComponentGetEntity, ownership_record.component_id)
    if not type_read_succeeded or current_type ~= ownership_record.component_type
        or not owner_read_succeeded or current_owner_entity_id ~= ownership_record.owner_entity_id
    then
        stain_state[record_key] = nil
        return true, "gone"
    end

    -- We only own a field after a verified successful write. If application failed
    -- before that point, there is nothing to roll back and no right to overwrite a
    -- newer value from the game or another mod.
    if ownership_record.last_written_multiplier == nil then
        stain_state[record_key] = nil
        return true, "unowned"
    end
    local read_succeeded, current_multiplier = pcall(
        ComponentGetValue2, ownership_record.component_id, "stain_shaken_drop_chance_multiplier"
    )
    current_multiplier = read_succeeded and tonumber(current_multiplier) or nil
    if current_multiplier == nil then return false, "read" end
    if not same_value(current_multiplier, ownership_record.last_written_multiplier) then
        -- Compare-and-swap ownership: a newer writer wins. Relinquish our stale record
        -- instead of restoring an old baseline over somebody else's change.
        stain_state[record_key] = nil
        return true, "external"
    end
    if same_value(current_multiplier, ownership_record.original_multiplier) then
        stain_state[record_key] = nil
        return true, "ok"
    end

    local write_succeeded = pcall(
        ComponentSetValue2,
        ownership_record.component_id,
        "stain_shaken_drop_chance_multiplier",
        ownership_record.original_multiplier
    )
    local verify_succeeded, restored_multiplier = pcall(
        ComponentGetValue2, ownership_record.component_id, "stain_shaken_drop_chance_multiplier"
    )
    restored_multiplier = verify_succeeded and tonumber(restored_multiplier) or nil
    if not write_succeeded or restored_multiplier == nil
        or not same_value(restored_multiplier, ownership_record.original_multiplier)
    then
        return false, "readback"
    end

    stain_state[record_key] = nil
    return true, "ok"
end

local function scan_stain_drop(target_multiplier, frame_number, player_entity_id)
    if type(EntityGetInRadius) ~= "function" then return end
    if player_entity_id == nil or player_entity_id == 0 or not EntityGetIsAlive(player_entity_id) then return end

    local player_x, player_y = EntityGetTransform(player_entity_id)
    if player_x == nil then return end

    local scan_succeeded, nearby_entities = pcall(EntityGetInRadius, player_x, player_y, SCAN_RADIUS)
    local entities_to_scan = { player_entity_id }
    local seen_entity_ids = { [player_entity_id] = true }
    if scan_succeeded and type(nearby_entities) == "table" then
        for _, nearby_entity_id in ipairs(nearby_entities) do
            if not seen_entity_ids[nearby_entity_id] then
                seen_entity_ids[nearby_entity_id] = true
                entities_to_scan[#entities_to_scan + 1] = nearby_entity_id
            end
        end
    end

    for _, entity_id in ipairs(entities_to_scan) do
        for _, component_id in ipairs(EntityGetComponentIncludingDisabled(entity_id, "SpriteStainsComponent") or {}) do
            set_stain_drop(component_id, target_multiplier, frame_number)
        end
    end
end

function stain_adapter.supported()
    return type(EntityGetInRadius) == "function"
end

function stain_adapter.apply(target_multiplier, frame_number, player_entity_id)
    scan_stain_drop(target_multiplier, frame_number, player_entity_id)
    return true
end

function stain_adapter.cleanup_stale(frame_number)
    local record_keys = {}
    for record_key in pairs(stain_state) do record_keys[#record_keys + 1] = record_key end
    for _, record_key in ipairs(record_keys) do
        local ownership_record = stain_state[record_key]
        if ownership_record ~= nil and ownership_record.last_seen_frame ~= frame_number then
            restore_stain_record(record_key, ownership_record)
        end
    end
end

function stain_adapter.restore_all()
    local all_restored = true
    local record_keys = {}
    for record_key in pairs(stain_state) do record_keys[#record_keys + 1] = record_key end
    for _, record_key in ipairs(record_keys) do
        local restored, reason = restore_stain_record(record_key, stain_state[record_key])
        if not restored and reason ~= "gone" then all_restored = false end
    end
    return all_restored
end

function stain_adapter.has_overrides()
    return next(stain_state) ~= nil
end

METAMORPH_CREATIVE_MENU_WORLD_RULE_STAINS = stain_adapter
return stain_adapter
