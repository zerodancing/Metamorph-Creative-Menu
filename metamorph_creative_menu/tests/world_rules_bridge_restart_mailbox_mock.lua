local root=assert(arg[1],"root required")
local native_dofile=dofile
local globals={
 mcm_world_rules_outbox_seq_v1="12",
 mcm_world_rules_outbox_version_v1="2",
 mcm_world_rules_outbox_snapshot_v1="2,1,3",
 mcm_world_rules_remote_seq_v1="7",
}
local request_calls=0
local apply_calls=0
function GlobalsGetValue(key,fallback) local v=globals[key]; if v==nil then return fallback end; return v end
function GlobalsSetValue(key,value) globals[key]=tostring(value) end
ctx={my_id="client",host_id="host",rpc_peer_id="host"}
local rpc={
 opts_reliable=function() end,
 opts_everywhere=function() end,
}
local common={clean=function(value) return tostring(value or "") end,report_error=function(code,details) error(code..":"..tostring(details)) end}
local bridge=assert(native_dofile(root.."/files/integrations/ew/bridge/world_rules.lua"))
bridge.register(rpc,common)
local original_request=rpc.request_world_rules
rpc.request_world_rules=function(version,encoded) request_calls=request_calls+1 end
local original_apply=rpc.apply_world_rules
rpc.apply_world_rules=function(version,encoded,origin) apply_calls=apply_calls+1 end

-- Persisted outbox from the old EW Lua context must not be resent on module startup.
bridge.update()
assert(request_calls==0 and apply_calls==0,"EW bridge resent stale Rules outbox after restart")

-- A new UI edit advances sequence and must be delivered normally.
globals.mcm_world_rules_outbox_seq_v1="13"
globals.mcm_world_rules_outbox_snapshot_v1="1,1,1"
bridge.update()
assert(request_calls==1,"EW bridge ignored new Rules outbox after stale protection")

io.write("world_rules_bridge_restart_mailbox=PASS stale_ignored=true new_sent=true\n")
