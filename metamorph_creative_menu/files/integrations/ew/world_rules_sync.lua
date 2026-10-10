if type(METAMORPH_CREATIVE_MENU_WORLD_RULE_SYNC) == "table" then return METAMORPH_CREATIVE_MENU_WORLD_RULE_SYNC end

local world_rule_sync = {}

local BRIDGE_READY = "mcm_world_rules_rpc_ready_v1"
local BRIDGE_MY_ID = "mcm_world_rules_rpc_my_id_v1"
local BRIDGE_HOST_ID = "mcm_world_rules_rpc_host_id_v1"
local REMOTE_SEQ = "mcm_world_rules_remote_seq_v1"
local REMOTE_VERSION = "mcm_world_rules_remote_version_v1"
local REMOTE_SNAPSHOT = "mcm_world_rules_remote_snapshot_v1"
local REMOTE_ORIGIN = "mcm_world_rules_remote_origin_v1"
local BRIDGE_ERROR_SEQ = "mcm_world_rules_rpc_error_seq_v1"
local BRIDGE_ERROR = "mcm_world_rules_rpc_error_v1"
local OUTBOX_SEQ = "mcm_world_rules_outbox_seq_v1"
local OUTBOX_VERSION = "mcm_world_rules_outbox_version_v1"
local OUTBOX_SNAPSHOT = "mcm_world_rules_outbox_snapshot_v1"
local WORLD_RULES_PROTOCOL = 2

local last_network_send_frame = -100000
local pending_local_snapshot = nil
local outbox_sequence = 0
-- Ignore mailbox entries serialized by a previous Lua VM/save session. New bridge
-- publications always advance these sequence values after the current module loads.
local last_remote_sequence = ""
local last_bridge_error_sequence = ""
local mailbox_initialized = false
local last_network_error = { signature=nil, frame=-100000 }

local function ew_enabled()
    local read_succeeded, enabled = pcall(ModIsEnabled, "quant.ew")
    return read_succeeded and enabled == true
end

local function log_network_error(code, details)
    local frame = type(GameGetFrameNum) == "function" and GameGetFrameNum() or -1
    local signature = tostring(code) .. "\31" .. tostring(details or "")
    if last_network_error.signature == signature and frame - last_network_error.frame < 600 then return end
    last_network_error.signature, last_network_error.frame = signature, frame
    if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE) == "function" then
        pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE, "world_rules." .. tostring(code), tostring(details or ""))
    end
    print("[Metamorph: Creative Menu] EW world-rules: " .. tostring(code) .. " - " .. tostring(details or ""))
end

function world_rule_sync.can_edit()
    if not ew_enabled() then return true, "singleplayer" end
    if GameHasFlagRun("ew_flag_this_is_host") then return true, "ew_host" end
    -- Host and client have equal creative-menu rights. The host is only a transport
    -- authority used by EW for rebroadcast/convergence, never an user permission gate.
    return true, "ew_peer"
end

function world_rule_sync.mark_dirty(encoded_snapshot)
    if type(encoded_snapshot) ~= "string" or encoded_snapshot == "" then return false end
    -- Freeze the user's exact intent at click/reset time. A remote mailbox update that
    -- arrives before update() may change local presentation, but cannot rewrite what
    -- this peer already asked EW to publish.
    pending_local_snapshot = encoded_snapshot
    return true
end

local function consume_bridge_error()
    local sequence = GlobalsGetValue(BRIDGE_ERROR_SEQ, "")
    if sequence == "" or sequence == last_bridge_error_sequence then return end
    last_bridge_error_sequence = sequence
    log_network_error("ew_module", GlobalsGetValue(BRIDGE_ERROR, "unknown"))
end

local function consume_remote_snapshot(callbacks)
    local sequence = GlobalsGetValue(REMOTE_SEQ, "")
    if sequence == "" or sequence == last_remote_sequence then return end
    last_remote_sequence = sequence
    local origin = GlobalsGetValue(REMOTE_ORIGIN, "")
    local my_id = GlobalsGetValue(BRIDGE_MY_ID, "")
    local host_id = GlobalsGetValue(BRIDGE_HOST_ID, "")
    -- Ignore only the host's own delayed echo. Client-originated edits are authoritative
    -- after the EW host has accepted and rebroadcast the complete snapshot.
    if my_id ~= "" and my_id == host_id and origin == my_id then return end

    local encoded = GlobalsGetValue(REMOTE_SNAPSHOT, "")
    local choices = callbacks.decode_snapshot(encoded)
    if choices == nil then
        log_network_error("snapshot_decode", encoded)
        return
    end
    local version = tonumber(GlobalsGetValue(REMOTE_VERSION, "0")) or 0
    if version ~= WORLD_RULES_PROTOCOL then
        log_network_error("invalid_snapshot", "version=" .. tostring(version) .. ";choices=" .. type(choices))
        return
    end
    callbacks.apply_snapshot(choices)
end

function world_rule_sync.update(frame, callbacks)
    if type(callbacks) ~= "table" then return end
    if not ew_enabled() then
        if type(callbacks.set_remote_authoritative) == "function" then callbacks.set_remote_authoritative(false) end
        return
    end

    if not mailbox_initialized then
        -- Globals are unavailable while modules load, but are stable by the first
        -- world update. Snapshot old sequences here so a resumed save is not mistaken
        -- for a new remote edit.
        outbox_sequence = tonumber(GlobalsGetValue(OUTBOX_SEQ, "0")) or 0
        -- A local click can race the first bridge publication in isolated/reloaded
        -- Lua contexts. In that case consume the remote state for presentation while
        -- retaining pending_local_snapshot as the user's exact outbound intent.
        if pending_local_snapshot == nil then
            last_remote_sequence = GlobalsGetValue(REMOTE_SEQ, "")
        end
        last_bridge_error_sequence = GlobalsGetValue(BRIDGE_ERROR_SEQ, "")
        mailbox_initialized = true
    end

    consume_bridge_error()
    consume_remote_snapshot(callbacks)

    if GlobalsGetValue(BRIDGE_READY, "0") ~= "1" then
        if frame >= 600 then log_network_error("bridge_not_ready", "EW extra module was not loaded") end
        return
    end

    local is_host = GameHasFlagRun("ew_flag_this_is_host")
    if pending_local_snapshot ~= nil or (is_host and frame - last_network_send_frame >= 120) then
        local encoded = pending_local_snapshot or callbacks.encode_snapshot()
        outbox_sequence = outbox_sequence + 1
        -- Latest-state mailbox: payload/version first and sequence last. Missing one
        -- publication is harmless because the next complete snapshot supersedes it.
        GlobalsSetValue(OUTBOX_VERSION, tostring(WORLD_RULES_PROTOCOL))
        GlobalsSetValue(OUTBOX_SNAPSHOT, encoded)
        GlobalsSetValue(OUTBOX_SEQ, tostring(outbox_sequence))
        pending_local_snapshot = nil
        last_network_send_frame = frame
    end
end

METAMORPH_CREATIVE_MENU_WORLD_RULE_SYNC = world_rule_sync
return world_rule_sync
