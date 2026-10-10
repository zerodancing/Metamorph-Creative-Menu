local root=assert(arg[1])
local globals={mcm_world_item_outbox_seq_v1='1',mcm_world_item_outbox_entity_v1_legacy=''}
globals['mcm_world_item_outbox_entity_v1:1']='42'
local attempts,errors=0,{}
function GlobalsGetValue(k,f) local v=globals[k]; if v==nil then return f end; return v end
function GlobalsSetValue(k,v) globals[k]=tostring(v) end
function EntityGetIsAlive(e) return e==42 end
function CrossCall(name,e) attempts=attempts+1; assert(name=='ew_thrown' and e==42); if attempts==1 then error('temporary failure') end end
local common={clean=function(v) return tostring(v) end,report_error=function(k,v) errors[#errors+1]=k..':'..v end}
local bridge=assert(loadfile(root..'/files/integrations/ew/bridge/items.lua'))()
bridge.init(common)
bridge.update()
assert((globals.mcm_world_item_outbox_ack_v1==nil or globals.mcm_world_item_outbox_ack_v1=='0'),'failed ew_thrown was acknowledged')
assert(globals['mcm_world_item_outbox_entity_v1:1']=='42','failed ew_thrown payload was consumed')
assert(attempts==1 and #errors==1,'temporary failure diagnostics wrong')
bridge.update()
assert(globals.mcm_world_item_outbox_ack_v1=='1','retried ew_thrown success was not acknowledged')
assert(globals['mcm_world_item_outbox_entity_v1:1']=='','successful retry did not clear payload')
assert(attempts==2,'queued event was not retried exactly once')
print('item_outbox_failure=PASS failure_not_consumed=true retry=true')
