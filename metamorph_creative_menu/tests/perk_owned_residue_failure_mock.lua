local root=assert(arg[1])
local native_dofile = dofile
dofile = function(path)
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end
local entity=1
local component=10
local values={[component]={pixel_gravity=350}}
local alive={[entity]=true}
local pending_kill={}
local next_entity=100
local frame=0
function GameGetFrameNum() return frame end
function ComponentGetTypeName(id) return values[id] and "CharacterPlatformingComponent" or "" end
function ComponentGetValue2(id,field) return values[id] and values[id][field] end
function ComponentSetValue2(id,field,value) values[id][field]=value end
function EntityGetIsAlive(id) return alive[id]==true end
function EntityGetComponentIncludingDisabled() return {} end
function EntitySetComponentIsEnabled() end
function EntityLoad() next_entity=next_entity+1; alive[next_entity]=true; return next_entity end
function EntityKill(id) pending_kill[id]=true end
local journal=assert(dofile(root..'/files/features/perks/transactions/mutation_journal.lua'))
local pending=assert(dofile(root..'/files/features/perks/transactions/pending_cleanup.lua'))
local token={}
assert(journal.prepare(token)); assert(journal.start_capture(token,_G))
ComponentSetValue2(component,'pixel_gravity',0)
local created=EntityLoad('owned_deferred.xml',0,0)
journal.stop_capture(token)
local delta={transaction_id=token.transaction_id}; journal.attach_delta(delta,token)
local ok,reason=journal.revert_delta(delta)
assert(ok==true,'deferred EntityKill blocked rollback: '..tostring(reason))
assert(values[component].pixel_gravity==350,'scalar rollback did not commit on first removal')
local state=pending.state_snapshot(); assert(state.pending==1 and state.failed==0,'deferred object not queued')
frame=frame+1; for id in pairs(pending_kill) do alive[id]=false end; pending.update()
state=pending.state_snapshot(); assert(state.pending==0 and state.failed==0,'completed deletion remained residue')
print('perk_owned_residue_failure=PASS deferred_delete_requires_one_user_action=true')
