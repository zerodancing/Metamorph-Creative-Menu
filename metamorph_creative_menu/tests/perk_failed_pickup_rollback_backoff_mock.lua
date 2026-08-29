local root=assert(arg[1], 'root required')
local native_dofile=dofile
local frame=0
local revert_calls=0
local revert_should_succeed=false

local transactions={}
function transactions.has() return false end
function transactions.begin(player,perk_id) return {player=player,perk_id=perk_id,transaction_id=99} end
function transactions.start_capture() return true end
function transactions.stop_capture() end
function transactions.commit() return true,'tracked' end
function transactions.revert_transaction()
    revert_calls=revert_calls+1
    return revert_should_succeed,'stuck'
end
function transactions.update() end
function transactions.active_count() return 0 end

local stubs={
 ['mods/metamorph_creative_menu/files/features/perks/inverse_registry.lua']={has=function() return false end,capture_pre_pickup=function() end},
 ['mods/metamorph_creative_menu/files/features/perks/transactions.lua']=transactions,
 ['mods/metamorph_creative_menu/files/features/perks/root_companions.lua']={supports=function() return false end,abort_pickup=function() end,update=function() end,debug=function() return {} end},
 ['mods/metamorph_creative_menu/files/features/perks/nested_pickups.lua']={update=function() end,state_snapshot=function() return {scopes=0,children=0} end},
 ['mods/metamorph_creative_menu/files/features/perks/locomotion_guard.lua']={capture_if_idle=function() end,repair_if_idle=function() end,baseline_count=function() return 0 end},
 ['mods/metamorph_creative_menu/files/features/perks/presentation.lua']={update=function() end},
 ['mods/metamorph_creative_menu/files/integrations/ew/world_items.lua']={notify_world_item=function() return true,'singleplayer' end},
 ['mods/metamorph_creative_menu/files/integrations/ew/perk_visibility.lua']={refresh=function() return true,'singleplayer' end},
 ['mods/metamorph_creative_menu/files/integrations/ew/runtime.lua']={force_inventory_sync=function() return true end},
}
dofile=function(path) if stubs[path]~=nil then return stubs[path] end return native_dofile(path) end

local alive={[1]=true,[77]=true}
function EntityGetIsAlive(id) return alive[id]==true end
function EntityHasTag() return false end
function EntityGetTransform(id) if id==1 then return 10,20 end end
function GameGetFrameNum() return frame end
function GlobalsGetValue(_,default) return default or '0' end
function GlobalsSetValue() end
function GameRemoveFlagRun() end
function GameAddFlagRun() end
function EntityGetRootEntity(id) return id end
function EntityGetComponentIncludingDisabled() return {} end
function EntitySetComponentIsEnabled() end
function EntityKill(id) alive[id]=false end
function EntityGetName() return 'perk' end
function perk_spawn() alive[77]=true; return 77 end
function perk_pickup() error('intentional pickup failure') end

METAMORPH_CREATIVE_MENU_PERK_SERVICE=nil
local service=assert(native_dofile(root..'/files/features/perks/service.lua'))
local ok,reason=service.apply(1,{id='TEST_PERK'},{ignore_debounce=true})
assert(ok==false and string.find(reason,'pickup_failed_partial',1,true),'test did not enter failed rollback path')
assert(revert_calls==1,'initial rollback attempt count changed')
for _=1,29 do frame=frame+1; service.update(0) end
assert(revert_calls==1,'failed pickup rollback retried every frame')
frame=30; service.update(0)
assert(revert_calls==2,'failed pickup rollback did not retry after initial backoff')
for f=31,89 do frame=f; service.update(0) end
assert(revert_calls==2,'failed pickup rollback ignored doubled backoff')
revert_should_succeed=true
frame=90; service.update(0)
assert(revert_calls==3,'failed pickup rollback did not retry after doubled backoff')
frame=91; service.update(0)
assert(revert_calls==3,'successful rollback remained queued')
print('perk_failed_pickup_rollback_backoff=PASS bounded_retry=true clears_on_success=true')
