local world_rules_bridge = {}
local REMOTE_SEQ = "mcm_world_rules_remote_seq_v1"
local REMOTE_VERSION = "mcm_world_rules_remote_version_v1"
local REMOTE_SNAPSHOT = "mcm_world_rules_remote_snapshot_v1"
local REMOTE_ORIGIN = "mcm_world_rules_remote_origin_v1"
local OUTBOX_SEQ = "mcm_world_rules_outbox_seq_v1"
local OUTBOX_VERSION = "mcm_world_rules_outbox_version_v1"
local OUTBOX_SNAPSHOT = "mcm_world_rules_outbox_snapshot_v1"
local WORLD_RULES_PROTOCOL = 2
local receive_sequence = tonumber(GlobalsGetValue(REMOTE_SEQ, "0")) or 0
-- Do not resend an outbox snapshot left in the save by a previous EW Lua context.
-- A real edit in this session increments OUTBOX_SEQ and will be observed normally.
local last_outbox_sequence = GlobalsGetValue(OUTBOX_SEQ, "")
local rpc, common

function world_rules_bridge.register(shared_rpc, shared_common)
    rpc, common = shared_rpc, shared_common
    rpc.opts_reliable()
    rpc.opts_everywhere()
    function rpc.apply_world_rules(version, encoded, origin_peer)
        if ctx.rpc_peer_id == nil or ctx.host_id == nil or ctx.rpc_peer_id ~= ctx.host_id then
            common.report_error("unauthorized_snapshot", "sender=" .. common.clean(ctx.rpc_peer_id) .. ";host=" .. common.clean(ctx.host_id))
            return
        end
        if tonumber(version) ~= WORLD_RULES_PROTOCOL or type(encoded) ~= "string" or encoded == "" then
            common.report_error("invalid_snapshot", "version=" .. common.clean(version) .. ";type=" .. type(encoded))
            return
        end
        receive_sequence = receive_sequence + 1
        GlobalsSetValue(REMOTE_VERSION, tostring(version))
        GlobalsSetValue(REMOTE_SNAPSHOT, encoded)
        GlobalsSetValue(REMOTE_ORIGIN, common.clean(origin_peer or ctx.rpc_peer_id))
        GlobalsSetValue(REMOTE_SEQ, tostring(receive_sequence))
    end

    rpc.opts_reliable()
    function rpc.request_world_rules(version, encoded)
        if ctx.my_id == nil or ctx.host_id == nil or ctx.my_id ~= ctx.host_id or ctx.rpc_peer_id == nil then return end
        if tonumber(version) ~= WORLD_RULES_PROTOCOL or type(encoded) ~= "string" or encoded == "" or #encoded > 8192 then
            common.report_error("invalid_rule_request", "sender=" .. common.clean(ctx.rpc_peer_id))
            return
        end
        rpc.apply_world_rules(version, encoded, ctx.rpc_peer_id)
    end
end

function world_rules_bridge.update()
    local sequence = GlobalsGetValue(OUTBOX_SEQ, "")
    if sequence == "" or sequence == last_outbox_sequence then return end
    local version = GlobalsGetValue(OUTBOX_VERSION, "0")
    local encoded = GlobalsGetValue(OUTBOX_SNAPSHOT, "")
    if tonumber(version) ~= WORLD_RULES_PROTOCOL or type(encoded) ~= "string" or encoded == "" or #encoded > 8192 then
        common.report_error("invalid_submit", "version=" .. common.clean(version) .. ";type=" .. type(encoded))
        last_outbox_sequence = sequence
        return
    end
    local is_host = ctx.my_id ~= nil and ctx.host_id ~= nil and ctx.my_id == ctx.host_id
    local ok, failure
    if is_host then ok, failure = pcall(rpc.apply_world_rules, version, encoded, ctx.my_id)
    else ok, failure = pcall(rpc.request_world_rules, version, encoded) end
    if not ok then common.report_error("send", failure); return end
    last_outbox_sequence = sequence
end

return world_rules_bridge
