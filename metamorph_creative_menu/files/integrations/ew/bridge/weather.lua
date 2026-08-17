local weather_bridge = {}
local OUTBOX_SEQ = "mcm_weather_outbox_seq_v1"
local OUTBOX_VERSION = "mcm_weather_outbox_version_v1"
local OUTBOX_SNAPSHOT = "mcm_weather_outbox_snapshot_v1"
local REMOTE_SEQ = "mcm_weather_remote_seq_v1"
local REMOTE_VERSION = "mcm_weather_remote_version_v1"
local REMOTE_SNAPSHOT = "mcm_weather_remote_snapshot_v1"
local receive_sequence = tonumber(GlobalsGetValue(REMOTE_SEQ, "0")) or 0
local last_outbox_sequence = ""
local rpc, common

function weather_bridge.register(shared_rpc, shared_common)
    rpc, common = shared_rpc, shared_common
    rpc.opts_reliable()
    rpc.opts_everywhere()
    function rpc.apply_weather_state(version, encoded)
        if ctx.rpc_peer_id == nil or ctx.host_id == nil or ctx.rpc_peer_id ~= ctx.host_id then
            common.report_error("weather_unauthorized", "sender=" .. common.clean(ctx.rpc_peer_id) .. ";host=" .. common.clean(ctx.host_id)); return
        end
        if tonumber(version) ~= 1 or type(encoded) ~= "string" or encoded == "" or #encoded > 1024 then
            common.report_error("weather_invalid", "version=" .. common.clean(version) .. ";len=" .. tostring(type(encoded) == "string" and #encoded or -1)); return
        end
        receive_sequence = receive_sequence + 1
        GlobalsSetValue(REMOTE_VERSION, tostring(version))
        GlobalsSetValue(REMOTE_SNAPSHOT, encoded)
        GlobalsSetValue(REMOTE_SEQ, tostring(receive_sequence))
    end

    rpc.opts_reliable()
    function rpc.request_weather_state(version, encoded)
        if ctx.my_id == nil or ctx.host_id == nil or ctx.my_id ~= ctx.host_id or ctx.rpc_peer_id == nil then return end
        if tonumber(version) ~= 1 or type(encoded) ~= "string" or encoded == "" or #encoded > 1024 then
            common.report_error("weather_request_invalid", "sender=" .. common.clean(ctx.rpc_peer_id)); return
        end
        rpc.apply_weather_state(version, encoded)
    end
end

function weather_bridge.update()
    local sequence = GlobalsGetValue(OUTBOX_SEQ, "")
    if sequence == "" or sequence == last_outbox_sequence then return end
    local version = tonumber(GlobalsGetValue(OUTBOX_VERSION, "0")) or 0
    local encoded = GlobalsGetValue(OUTBOX_SNAPSHOT, "")
    if version ~= 1 or type(encoded) ~= "string" or encoded == "" or #encoded > 1024 then
        common.report_error("weather_submit", "version=" .. common.clean(version)); last_outbox_sequence = sequence; return
    end
    local sender = (ctx.my_id ~= nil and ctx.host_id ~= nil and ctx.my_id == ctx.host_id) and rpc.apply_weather_state or rpc.request_weather_state
    local ok, failure = pcall(sender, version, encoded)
    if not ok then common.report_error("weather_send", failure); return end
    last_outbox_sequence = sequence
end
return weather_bridge
