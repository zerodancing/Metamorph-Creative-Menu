local items_bridge = {}
local OUTBOX_SEQ = "mcm_world_item_outbox_seq_v1"
local OUTBOX_ENTITY = "mcm_world_item_outbox_entity_v1"
local OUTBOX_ACK = "mcm_world_item_outbox_ack_v1"
local OUTBOX_RESULT = "mcm_world_item_outbox_result_v1"
local last_sequence = tonumber(GlobalsGetValue(OUTBOX_ACK, "0")) or 0
local common

function items_bridge.init(shared_common) common = shared_common end

function items_bridge.update()
    local sequence = tonumber(GlobalsGetValue(OUTBOX_SEQ, "0")) or 0
    if sequence <= last_sequence then return end
    local processed, budget = last_sequence, 16
    while processed < sequence and budget > 0 do
        local next_seq = processed + 1
        local suffix = ":" .. tostring(next_seq)
        local entity = tonumber(GlobalsGetValue(OUTBOX_ENTITY .. suffix, "0")) or 0
        local result = "invalid"
        if entity ~= 0 and EntityGetIsAlive(entity) then
            if type(CrossCall) == "function" then
                local ok, err = pcall(CrossCall, "ew_thrown", entity)
                result = ok and "submitted" or ("error:" .. common.clean(err))
                if not ok then common.report_error("world_item", "seq=" .. tostring(next_seq) .. ";" .. common.clean(err)) end
            else
                result = "crosscall_unavailable"
                common.report_error("world_item", "seq=" .. tostring(next_seq) .. ";CrossCall unavailable")
            end
        end
        GlobalsSetValue(OUTBOX_RESULT, tostring(next_seq) .. ":" .. result)
        GlobalsSetValue(OUTBOX_ENTITY .. suffix, "")
        processed, budget = next_seq, budget - 1
    end
    last_sequence = processed
    GlobalsSetValue(OUTBOX_ACK, tostring(processed))
end
return items_bridge
