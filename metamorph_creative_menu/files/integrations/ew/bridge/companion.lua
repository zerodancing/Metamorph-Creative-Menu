local companion_bridge = {}
local OUTBOX_SEQ = "mcm_companion_request_seq_v1"
local OUTBOX_X = "mcm_companion_request_x_v1"
local OUTBOX_Y = "mcm_companion_request_y_v1"
local last_sequence = ""
local request_frame = {}
local rpc, common

function companion_bridge.register(shared_rpc, shared_common)
    rpc, common = shared_rpc, shared_common
    rpc.opts_reliable()
    function rpc.request_player_companion(offset_x, offset_y)
        if ctx.my_id == nil or ctx.host_id == nil or ctx.my_id ~= ctx.host_id then return end
        local sender = ctx.rpc_peer_id
        local data = sender ~= nil and ctx.players[sender] or nil
        local source = data ~= nil and data.entity or 0
        if source == nil or source == 0 or not EntityGetIsAlive(source) then
            common.report_error("companion_source", "sender=" .. common.clean(sender)); return
        end
        local frame = GameGetFrameNum()
        if frame - (request_frame[sender] or -1000) < 10 then return end
        request_frame[sender] = frame
        local x = math.max(-128, math.min(128, tonumber(offset_x) or 32))
        local y = math.max(-128, math.min(128, tonumber(offset_y) or -4))
        local ok_module, avatar = pcall(dofile, "mods/metamorph_creative_menu/files/features/companion/player_avatar.lua")
        if not ok_module or type(avatar) ~= "table" or type(avatar.spawn_visual_copy) ~= "function" then
            common.report_error("companion_module", avatar); return
        end
        local ok, clone = pcall(avatar.spawn_visual_copy, source, x, y)
        if not ok or clone == nil or clone == 0 then common.report_error("companion_spawn", clone) end
    end
end

function companion_bridge.update()
    local sequence = GlobalsGetValue(OUTBOX_SEQ, "")
    if sequence == "" or sequence == last_sequence then return end
    last_sequence = sequence
    if ctx.my_id == nil or ctx.host_id == nil or ctx.my_id == ctx.host_id then return end
    local x = tonumber(GlobalsGetValue(OUTBOX_X, "32")) or 32
    local y = tonumber(GlobalsGetValue(OUTBOX_Y, "-4")) or -4
    local ok, failure = pcall(rpc.request_player_companion, x, y)
    if not ok then common.report_error("companion_send", failure) end
end
return companion_bridge
