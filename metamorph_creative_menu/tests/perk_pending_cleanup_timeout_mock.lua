local root=assert(arg[1]); local frame=0; local alive={[101]=true}; local kill_calls=0
function GameGetFrameNum() return frame end
function EntityGetIsAlive(id) return alive[id]==true end
function EntityGetComponentIncludingDisabled() return {} end
function EntitySetComponentIsEnabled() end
function EntityKill(_) kill_calls=kill_calls+1 end
local pending=assert(dofile(root..'/files/features/perks/transactions/pending_cleanup.lua'))
assert(select(1,pending.retire_entity(101,'stuck-test'))==true)
for _=1,31 do frame=frame+1; pending.update() end
local state=pending.state_snapshot(); assert(state.pending==0 and state.failed==1,'true residue not detected')
assert(string.find(table.concat(state.failed_items,','),'entity:101',1,true),'exact id missing')
local calls_at_timeout=kill_calls
for _=1,28 do frame=frame+1; pending.update() end
assert(kill_calls==calls_at_timeout,'failed residue was retried every frame instead of backing off')
frame=frame+1; pending.update()
assert(kill_calls==calls_at_timeout+1,'failed residue was not retried after initial backoff')
local calls_after_retry=kill_calls
for _=1,59 do frame=frame+1; pending.update() end
assert(kill_calls==calls_after_retry,'failed residue ignored exponential retry delay')
frame=frame+1; pending.update()
assert(kill_calls==calls_after_retry+1,'second failed retry did not occur after doubled backoff')
print('perk_pending_cleanup_timeout=PASS persistent_residue_detected_async=true bounded_retry_backoff=true')
