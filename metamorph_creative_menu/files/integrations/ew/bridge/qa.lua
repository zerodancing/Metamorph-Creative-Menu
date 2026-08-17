local qa_bridge = {}
local REMOTE_QA_SEQ = "mcm_remote_qa_seq_v1"
local REMOTE_QA_LAST = "mcm_remote_qa_last_v1"
local remote_receive_sequence = tonumber(GlobalsGetValue(REMOTE_QA_SEQ, "0")) or 0
local last_signature, last_send_frame = nil, -100000
local rpc, common

function qa_bridge.register(shared_rpc, shared_common)
    rpc, common = shared_rpc, shared_common
    rpc.opts_reliable()
    rpc.opts_everywhere()
    function rpc.sync_qa_state(active, run_id, phase, step)
        local sender = ctx.rpc_peer_id
        if sender == nil or sender == ctx.my_id then return end
        remote_receive_sequence = remote_receive_sequence + 1
        GlobalsSetValue(REMOTE_QA_LAST, common.clean(sender) .. "|" .. common.clean(active) .. "|" .. common.clean(run_id) .. "|" .. common.clean(phase) .. "|" .. common.clean(step))
        GlobalsSetValue(REMOTE_QA_SEQ, tostring(remote_receive_sequence))
    end
end

function qa_bridge.update(frame)
    local active = GlobalsGetValue("mcm_qa_active_v1", "0")
    local run_id = GlobalsGetValue("mcm_qa_run_v1", "")
    local phase = GlobalsGetValue("mcm_qa_phase_v1", "")
    local step = GlobalsGetValue("mcm_qa_step_v1", "")
    local signature = active .. "|" .. run_id .. "|" .. phase .. "|" .. step
    local changed = signature ~= last_signature
    local heartbeat = active == "1" and frame - last_send_frame >= 60
    if not changed and not heartbeat then return end
    if changed and last_signature ~= nil and active == "1" and frame - last_send_frame < 60 then return end
    local ok, failure = pcall(rpc.sync_qa_state, active, run_id, phase, step)
    if ok then last_signature, last_send_frame = signature, frame
    else common.report_error("qa_state_send", failure) end
end
return qa_bridge
