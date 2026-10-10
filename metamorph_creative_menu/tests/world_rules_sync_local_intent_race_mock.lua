local root=assert(arg[1],"root required")
local native_dofile=dofile
local globals={
 mcm_world_rules_rpc_ready_v1="1", mcm_world_rules_rpc_my_id_v1="client-a", mcm_world_rules_rpc_host_id_v1="host",
 mcm_world_rules_remote_seq_v1="0", mcm_world_rules_outbox_seq_v1="0",
}
local current="NEW"
function GlobalsGetValue(k,d) local v=globals[k]; if v==nil then return d end return v end
function GlobalsSetValue(k,v) globals[k]=tostring(v) end
function ModIsEnabled(n) return n=="quant.ew" end
function GameHasFlagRun() return false end
function GameGetFrameNum() return 100 end
function print() end
METAMORPH_CREATIVE_MENU_WORLD_RULE_SYNC=nil
local sync=assert(native_dofile(root.."/files/integrations/ew/world_rules_sync.lua"))
local callbacks={
 encode_snapshot=function() return current end,
 decode_snapshot=function(s) return {s} end,
 apply_snapshot=function(values) current=values[1] end,
 set_remote_authoritative=function() end,
}
-- Capture the user's exact NEW intent, then race an older remote OLD state ahead of update.
sync.mark_dirty("NEW")
globals.mcm_world_rules_remote_seq_v1="1"
globals.mcm_world_rules_remote_version_v1="2"
globals.mcm_world_rules_remote_snapshot_v1="OLD"
globals.mcm_world_rules_remote_origin_v1="host"
sync.update(100,callbacks)
assert(current=="OLD","fixture did not apply racing remote snapshot")
assert(globals.mcm_world_rules_outbox_snapshot_v1=="NEW","racing remote snapshot rewrote pending local user intent")
io.write("world_rules_sync_local_intent_race=PASS immutable_pending=true\n")
