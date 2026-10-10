local player_authority = {}

local function valid_entity(entity)
    return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity)
end

local function verify_player_switch(bridge, expected_entity)
    if not valid_entity(expected_entity) then return false end
    if bridge == nil or type(bridge.GetPlayerEntity) ~= "function" then return false end
    local read_succeeded, active_entity = pcall(bridge.GetPlayerEntity)
    return read_succeeded and active_entity == expected_entity and EntityGetIsAlive(active_entity)
end

local function current_player_pointer(bridge)
    if bridge == nil or type(bridge.GetPlayerEntity) ~= "function" then return nil end
    local read_succeeded, active_entity = pcall(bridge.GetPlayerEntity)
    return read_succeeded and active_entity or nil
end

-- SetPlayerEntity is treated as a transaction. Unknown is intentionally different from
-- failure: if readback cannot prove which entity is authoritative, callers must not
-- destroy either candidate and turn a recoverable bridge race into a no-player state.
function player_authority.switch(bridge, previous_entity, replacement_entity)
    if bridge == nil or type(bridge.SetPlayerEntity) ~= "function" or type(bridge.GetPlayerEntity) ~= "function"
        or not valid_entity(replacement_entity)
    then
        return false, "invalid"
    end

    pcall(bridge.SetPlayerEntity, replacement_entity)
    if verify_player_switch(bridge, replacement_entity) then
        if type(bridge.RegisterPlayerEntityId) == "function" then pcall(bridge.RegisterPlayerEntityId, replacement_entity) end
        return true, "committed"
    end

    if valid_entity(previous_entity) then
        pcall(bridge.SetPlayerEntity, previous_entity)
        if verify_player_switch(bridge, previous_entity) then
            if type(bridge.RegisterPlayerEntityId) == "function" then pcall(bridge.RegisterPlayerEntityId, previous_entity) end
            return false, "rolled_back"
        end
    end

    local active_entity = current_player_pointer(bridge)
    if active_entity == replacement_entity and valid_entity(replacement_entity) then
        if type(bridge.RegisterPlayerEntityId) == "function" then pcall(bridge.RegisterPlayerEntityId, replacement_entity) end
        return true, "committed_late"
    end
    if active_entity == previous_entity and valid_entity(previous_entity) then
        return false, "rolled_back_late"
    end
    return false, "unknown"
end

return player_authority
