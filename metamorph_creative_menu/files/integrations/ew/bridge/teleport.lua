local teleport_bridge = {}

local NAMESPACE = "metamorph_creative_menu:teleport:v1:"
local OUTBOX_SEQ = "mcm_teleport_bring_outbox_seq_v1"
local OUTBOX_PEER = "mcm_teleport_bring_outbox_peer_v1"
local OUTBOX_TARGET_X = "mcm_teleport_bring_outbox_target_x_v1"
local OUTBOX_TARGET_Y = "mcm_teleport_bring_outbox_target_y_v1"
local OUTBOX_DEST_X = "mcm_teleport_bring_outbox_dest_x_v1"
local OUTBOX_DEST_Y = "mcm_teleport_bring_outbox_dest_y_v1"
local OUTBOX_ACK = "mcm_teleport_bring_outbox_ack_v1"
local MAX_STREAM_FRAMES = 300

local rpc, common
local last_sequence = tonumber(GlobalsGetValue(OUTBOX_ACK, "0")) or 0
local pending = nil

local function frame_number()
    local ok, frame = pcall(GameGetFrameNum)
    return ok and (tonumber(frame) or 0) or 0
end

local function world_loaded(x, y)
    if type(DoesWorldExistAt) ~= "function" then return true end
    local ok, loaded = pcall(DoesWorldExistAt, x - 24, y - 32, x + 24, y + 20)
    return ok and loaded == true
end

local function safe_position(x, y)
    if type(FindFreePositionForBody) == "function" then
        local ok, px, py = pcall(FindFreePositionForBody, x, y, 0, 0, 9)
        if ok and common.finite_number(px) and common.finite_number(py) and world_loaded(px, py) then
            return px, py
        end
    end
    return nil, nil
end

local function apply_pending()
    if pending == nil then return end
    local player = type(ctx) == "table" and type(ctx.my_player) == "table" and ctx.my_player.entity or 0
    if player == nil or player == 0 or not EntityGetIsAlive(player) then pending = nil; return end
    if frame_number() - pending.started > MAX_STREAM_FRAMES then pending = nil; return end
    if not world_loaded(pending.x, pending.y) then
        if type(GameSetCameraPos) == "function" then pcall(GameSetCameraPos, pending.x, pending.y) end
        return
    end
    local x, y = safe_position(pending.x, pending.y)
    if x == nil then pending = nil; return end
    local component = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
    if component ~= nil and component ~= 0 then pcall(ComponentSetValue2, component, "mVelocity", 0, 0) end
    pcall(EntitySetTransform, player, x, y)
    pending = nil
end

local function peer_by_name(peer_id)
    peer_id = tostring(peer_id or "")
    for candidate in pairs(ctx.players or {}) do
        if tostring(candidate) == peer_id then return candidate end
    end
    return nil
end

local function closest_peer(x, y)
    local best, best_distance = nil, 96 * 96
    for candidate, data in pairs(ctx.players or {}) do
        local entity = type(data) == "table" and data.entity or 0
        if entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity) then
            local px, py = EntityGetTransform(entity)
            if common.finite_number(px) and common.finite_number(py) then
                local dx, dy = px - x, py - y
                local distance = dx * dx + dy * dy
                if distance <= best_distance then best, best_distance = candidate, distance end
            end
        end
    end
    return best
end

local function read_value(base, sequence, fallback)
    local value = GlobalsGetValue(base .. "_" .. tostring(sequence), "")
    if value == "" and sequence == tonumber(GlobalsGetValue(OUTBOX_SEQ, "0")) then
        value = GlobalsGetValue(base, fallback or "")
    end
    return value
end

local function drain_outbox()
    local sequence = tonumber(GlobalsGetValue(OUTBOX_SEQ, "0")) or 0
    while last_sequence < sequence do
        local current = last_sequence + 1
        local peer_id = read_value(OUTBOX_PEER, current, "")
        local target_x = tonumber(read_value(OUTBOX_TARGET_X, current, ""))
        local target_y = tonumber(read_value(OUTBOX_TARGET_Y, current, ""))
        local dest_x = tonumber(read_value(OUTBOX_DEST_X, current, ""))
        local dest_y = tonumber(read_value(OUTBOX_DEST_Y, current, ""))
        if not common.finite_number(target_x) or not common.finite_number(target_y)
            or not common.finite_number(dest_x) or not common.finite_number(dest_y)
        then
            common.report_error("teleport_bring_submit", "seq=" .. tostring(current))
        else
            local target = peer_by_name(peer_id) or closest_peer(target_x, target_y)
            if target ~= nil then
                local ok, failure = pcall(rpc.request_bring, tostring(target), dest_x, dest_y)
                if not ok then common.report_error("teleport_bring_send", failure); break end
            end
        end
        GlobalsSetValue(OUTBOX_PEER .. "_" .. tostring(current), "")
        GlobalsSetValue(OUTBOX_TARGET_X .. "_" .. tostring(current), "")
        GlobalsSetValue(OUTBOX_TARGET_Y .. "_" .. tostring(current), "")
        GlobalsSetValue(OUTBOX_DEST_X .. "_" .. tostring(current), "")
        GlobalsSetValue(OUTBOX_DEST_Y .. "_" .. tostring(current), "")
        last_sequence = current
        GlobalsSetValue(OUTBOX_ACK, tostring(last_sequence))
    end
end

function teleport_bridge.register(ew_api, shared_common)
    common = shared_common
    rpc = ew_api.new_rpc_namespace(NAMESPACE)
    rpc.opts_reliable()
    rpc.opts_everywhere()
    function rpc.request_bring(target_peer_id, x, y)
        x, y = tonumber(x), tonumber(y)
        if not common.finite_number(x) or not common.finite_number(y) then return end
        -- A sender may only request a point beside its own authoritative player.
        local sender = ctx.rpc_player_data and ctx.rpc_player_data.entity or 0
        if sender == nil or sender == 0 or not EntityGetIsAlive(sender) then return end
        local sx, sy = EntityGetTransform(sender)
        if not common.finite_number(sx) or not common.finite_number(sy)
            or (sx - x) * (sx - x) + (sy - y) * (sy - y) > 96 * 96
        then
            return
        end
        if tostring(ctx.my_id) ~= tostring(target_peer_id or "") then return end
        pending = { x=x, y=y, started=frame_number() }
        if type(GameSetCameraPos) == "function" then pcall(GameSetCameraPos, x, y) end
    end
end

function teleport_bridge.update()
    drain_outbox()
    apply_pending()
end

return teleport_bridge
