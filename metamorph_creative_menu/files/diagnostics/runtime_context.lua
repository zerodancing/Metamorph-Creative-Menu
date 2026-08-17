if type(METAMORPH_CREATIVE_MENU_DIAGNOSTIC_RUNTIME_CONTEXT) == "table" then return METAMORPH_CREATIVE_MENU_DIAGNOSTIC_RUNTIME_CONTEXT end

local runtime_context = {}
local logger = dofile("mods/metamorph_creative_menu/files/diagnostics/logger.lua")

function runtime_context.qa()
    return "qa=" .. tostring(GlobalsGetValue("mcm_qa_active_v1", "0")) ..
        ":" .. logger.one_line(GlobalsGetValue("mcm_qa_phase_v1", "")) ..
        ":" .. logger.one_line(GlobalsGetValue("mcm_qa_step_v1", ""))
end

function runtime_context.world_sync()
    return "world_sent=" .. tostring(GlobalsGetValue("mcm_world_sync_sent_chunks_v1", "?")) ..
        "/" .. tostring(GlobalsGetValue("mcm_world_sync_sent_bytes_v1", "?")) ..
        " world_recv=" .. tostring(GlobalsGetValue("mcm_world_sync_recv_chunks_v1", "?")) ..
        "/" .. tostring(GlobalsGetValue("mcm_world_sync_recv_bytes_v1", "?")) ..
        " trail=" .. tostring(GlobalsGetValue("mcm_world_sync_trail_backlog_v1", "?")) ..
        " trail_sent=" .. tostring(GlobalsGetValue("mcm_world_sync_trail_sent_v1", "?")) ..
        " itemq=" .. tostring(GlobalsGetValue("mcm_world_item_outbox_ack_v1", "?")) ..
        "/" .. tostring(GlobalsGetValue("mcm_world_item_outbox_seq_v1", "?"))
end

METAMORPH_CREATIVE_MENU_DIAGNOSTIC_RUNTIME_CONTEXT = runtime_context
return runtime_context
