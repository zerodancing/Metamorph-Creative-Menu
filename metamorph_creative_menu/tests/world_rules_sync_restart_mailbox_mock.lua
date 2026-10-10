local root=assert(arg[1],"root required")
local native_dofile=dofile
local globals={
    mcm_world_rules_rpc_ready_v1="1",
    mcm_world_rules_rpc_my_id_v1="client-a",
    mcm_world_rules_rpc_host_id_v1="host",
    -- These values are leftovers serialized by the previous Lua VM/session.
    mcm_world_rules_remote_seq_v1="41",
    mcm_world_rules_remote_version_v1="2",
    mcm_world_rules_remote_snapshot_v1="2,2",
    mcm_world_rules_remote_origin_v1="host",
    mcm_world_rules_outbox_seq_v1="17",
}
local applied=0
function GlobalsGetValue(key,fallback) local v=globals[key]; if v==nil then return fallback end; return v end
function GlobalsSetValue(key,value) globals[key]=tostring(value) end
function ModIsEnabled(name) return name=="quant.ew" end
function GameHasFlagRun() return false end
function GameGetFrameNum() return 100 end
function print() end
METAMORPH_CREATIVE_MENU_WORLD_RULE_SYNC=nil
local sync=assert(native_dofile(root.."/files/integrations/ew/world_rules_sync.lua"))
local callbacks={
    encode_snapshot=function() return "1,1" end,
    decode_snapshot=function(encoded)
        if encoded=="2,2" then return {2,2} end
        if encoded=="1,2" then return {1,2} end
        return nil
    end,
    apply_snapshot=function() applied=applied+1 end,
    set_remote_authoritative=function() end,
}

sync.update(100,callbacks)
assert(applied==0,"stale remote Rules mailbox was replayed after restart")

-- A genuinely new bridge publication advances the sequence and must still apply.
globals.mcm_world_rules_remote_seq_v1="42"
globals.mcm_world_rules_remote_snapshot_v1="1,2"
globals.mcm_world_rules_remote_origin_v1="peer-b"
sync.update(101,callbacks)
assert(applied==1,"new remote Rules snapshot was ignored after stale-mailbox protection")

-- A new local edit must continue from the persisted outbox sequence, never reuse it.
sync.mark_dirty("1,1")
sync.update(102,callbacks)
assert(tonumber(globals.mcm_world_rules_outbox_seq_v1)==18,"local outbox sequence did not advance from persisted value")
assert(globals.mcm_world_rules_outbox_snapshot_v1=="1,1","new local Rules snapshot was not published")

io.write("world_rules_sync_restart_mailbox=PASS stale_ignored=true new_applied=true seq=18\n")
