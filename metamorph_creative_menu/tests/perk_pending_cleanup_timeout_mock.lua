local root=assert(arg[1]); local frame=0; local alive={[101]=true}
function GameGetFrameNum() return frame end
function EntityGetIsAlive(id) return alive[id]==true end
function EntityGetComponentIncludingDisabled() return {} end
function EntitySetComponentIsEnabled() end
function EntityKill(_) end
local pending=assert(dofile(root..'/files/features/perks/transactions/pending_cleanup.lua'))
assert(select(1,pending.retire_entity(101,'stuck-test'))==true)
for _=1,31 do frame=frame+1; pending.update() end
local state=pending.debug_state(); assert(state.pending==0 and state.failed==1,'true residue not detected')
assert(string.find(table.concat(state.failed_items,','),'entity:101',1,true),'exact id missing')
print('perk_pending_cleanup_timeout=PASS persistent_residue_detected_async=true')
