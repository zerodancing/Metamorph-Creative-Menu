if type(METAMORPH_CREATIVE_MENU_PERK_NESTED_PICKUPS) == "table" then return METAMORPH_CREATIVE_MENU_PERK_NESTED_PICKUPS end

-- GAMBLE grants its two rewards from a LuaComponent on a later frame. Those nested
-- perk_pickup calls are therefore outside the synchronous transaction that created the
-- spawner. This registry joins those real later pickups back to the exact GAMBLE
-- transaction that caused them, without changing how vanilla chooses or applies rewards.
local nested_pickups = {}

local scopes_by_player = {}
local children_by_parent_transaction = {}
local FALLBACK_TICK = 0
local CLAIM_WINDOW_FRAMES = 90

local function frame_now()
    if type(GameGetFrameNum) == "function" then
        local ok, value = pcall(GameGetFrameNum)
        if ok and tonumber(value) ~= nil then return tonumber(value) end
    end
    FALLBACK_TICK = FALLBACK_TICK + 1
    return FALLBACK_TICK
end

function nested_pickups.open_gamble_scope(player_entity_id, parent_transaction_id)
    player_entity_id = tonumber(player_entity_id) or 0
    parent_transaction_id = tonumber(parent_transaction_id)
    if player_entity_id == 0 or parent_transaction_id == nil then return false end
    local now = frame_now()
    scopes_by_player[player_entity_id] = {
        parent_transaction_id=parent_transaction_id,
        parent_perk_id="GAMBLE",
        remaining=2,
        opened_frame=now,
        expires_frame=now + CLAIM_WINDOW_FRAMES,
    }
    return true
end

function nested_pickups.scope_open(player_entity_id, parent_transaction_id)
    local scope = scopes_by_player[tonumber(player_entity_id) or 0]
    if type(scope) ~= "table" then return false end
    if tonumber(parent_transaction_id) ~= nil and tonumber(scope.parent_transaction_id) ~= tonumber(parent_transaction_id) then
        return false
    end
    local now = frame_now()
    if now > (tonumber(scope.expires_frame) or now) or (tonumber(scope.remaining) or 0) <= 0 then
        scopes_by_player[tonumber(player_entity_id) or 0] = nil
        return false
    end
    return true
end

function nested_pickups.claim_parent(player_entity_id)
    player_entity_id = tonumber(player_entity_id) or 0
    local scope = scopes_by_player[player_entity_id]
    if type(scope) ~= "table" then return nil end
    local now = frame_now()
    if now > (tonumber(scope.expires_frame) or now) or (tonumber(scope.remaining) or 0) <= 0 then
        scopes_by_player[player_entity_id] = nil
        return nil
    end
    scope.remaining = scope.remaining - 1
    if scope.remaining <= 0 then scopes_by_player[player_entity_id] = nil end
    return {
        parent_transaction_id=scope.parent_transaction_id,
        parent_perk_id=scope.parent_perk_id,
    }
end

function nested_pickups.register_child(parent_transaction_id, perk_id, transaction_id)
    parent_transaction_id = tonumber(parent_transaction_id)
    transaction_id = tonumber(transaction_id)
    perk_id = tostring(perk_id or "")
    if parent_transaction_id == nil or transaction_id == nil or perk_id == "" then return false end
    local children = children_by_parent_transaction[parent_transaction_id]
    if children == nil then
        children = {}
        children_by_parent_transaction[parent_transaction_id] = children
    end
    children[#children + 1] = {perk_id=perk_id, transaction_id=transaction_id}
    return true
end

function nested_pickups.children(parent_transaction_id)
    local source = children_by_parent_transaction[tonumber(parent_transaction_id)] or {}
    local result = {}
    for index, child in ipairs(source) do
        result[index] = {perk_id=child.perk_id, transaction_id=child.transaction_id}
    end
    return result
end

function nested_pickups.clear_parent(parent_transaction_id)
    children_by_parent_transaction[tonumber(parent_transaction_id)] = nil
end

function nested_pickups.rebind_player(old_player_entity_id, new_player_entity_id)
    if tonumber(old_player_entity_id) == tonumber(new_player_entity_id) then return true end
    local scope = scopes_by_player[tonumber(old_player_entity_id)]
    if scope ~= nil then
        scopes_by_player[tonumber(new_player_entity_id)] = scope
        scopes_by_player[tonumber(old_player_entity_id)] = nil
    end
    return true
end

function nested_pickups.update()
    local now = frame_now()
    for player_entity_id, scope in pairs(scopes_by_player) do
        if now > (tonumber(scope.expires_frame) or now) then scopes_by_player[player_entity_id] = nil end
    end
end

function nested_pickups.state_snapshot()
    local scopes, children = 0, 0
    for _ in pairs(scopes_by_player) do scopes = scopes + 1 end
    for _, rows in pairs(children_by_parent_transaction) do children = children + #(rows or {}) end
    return {scopes=scopes, children=children}
end

METAMORPH_CREATIVE_MENU_PERK_NESTED_PICKUPS = nested_pickups
return nested_pickups
