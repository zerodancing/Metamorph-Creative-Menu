local perk_bridge = {}
local OUTBOX_SEQ = "mcm_global_perk_remove_outbox_seq_v1"
local OUTBOX_ACK = "mcm_global_perk_remove_outbox_ack_v1"
local last_sequence = tonumber(GlobalsGetValue(OUTBOX_ACK, "0")) or 0
local rpc

function perk_bridge.register(shared_rpc)
    rpc = shared_rpc
    rpc.opts_reliable()
    rpc.opts_everywhere()
    function rpc.remove_global_perk(perk_id, amount)
        -- Reserved protocol slot. Perks are peer-local; never mutate another peer here.
        return
    end
end

function perk_bridge.update()
    local sequence = tonumber(GlobalsGetValue(OUTBOX_SEQ, "0")) or 0
    if sequence <= last_sequence then return end
    last_sequence = sequence
    GlobalsSetValue(OUTBOX_ACK, tostring(sequence))
end
return perk_bridge
