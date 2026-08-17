local root=assert(arg[1])
local native_dofile=dofile
local sync_calls=0
local capture_started=0
local capture_stopped=0
local commits=0
local next_transaction_id=0
local reverted_transaction=nil
local inverses={
 capture_pre_pickup=function() return true end,
 has=function() return false end,
 zero_cleanup=function() return true end,
 maintenance_cleanup=function() return true end,
 post_tracked_cleanup=function() return true end,
}
local transactions={
 begin=function(player,perk_id) next_transaction_id=next_transaction_id+1; return {player=player,perk_id=perk_id,transaction_id=next_transaction_id} end,
 start_capture=function(token,env) capture_started=capture_started+1 return true end,
 stop_capture=function(token) capture_stopped=capture_stopped+1 end,
 commit=function(token) commits=commits+1 return true,'tracked' end,
 revert_transaction=function(perk_id,player,transaction_id) reverted_transaction={perk_id=perk_id,player=player,transaction_id=transaction_id}; return true,'reverted' end,
 has=function() return false end,
 clear=function() end,
}
local root_companions={supports=function() return false end,commit=function() end,update=function() end,on_count_zero=function() end,debug=function() return {} end}
local presentation={expire_one_game_effect=function() end,on_count_zero=function() end,update=function() end}
local ew_runtime={force_inventory_sync=function() sync_calls=sync_calls+1 end}
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/features/perks/inverse_registry.lua' then return inverses end
 if path=='mods/metamorph_creative_menu/files/features/perks/transactions.lua' then return transactions end
 if path=='mods/metamorph_creative_menu/files/features/perks/root_companions.lua' then return root_companions end
 if path=='mods/metamorph_creative_menu/files/features/perks/presentation.lua' then return presentation end
 if path=='mods/metamorph_creative_menu/files/integrations/ew/runtime.lua' then return ew_runtime end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
local globals={}
local alive={[1]=true}
local next_pickup=54
EntityGetIsAlive=function(entity) return alive[entity]==true end
EntityGetTransform=function() return 10,20 end
EntityGetName=function(entity) assert(entity>=55); return "$mock_perk" end
EntityGetRootEntity=function(entity) return entity end
EntityGetComponentIncludingDisabled=function() return {} end
EntitySetComponentIsEnabled=function() end
EntityKill=function(entity) alive[entity]=false end
GameGetFrameNum=function() return 100 end
GlobalsGetValue=function(name,default) return globals[name] or default end
GlobalsSetValue=function(name,value) globals[name]=tostring(value) end
GameRemoveFlagRun=function() end
GameAddFlagRun=function() end
local pickup_args=nil
local spawn_dont_remove=nil
perk_pickup=function(...)
 pickup_args={...}
 local current=tonumber(GlobalsGetValue('PERK_PICKED_TEST_PICKUP_COUNT','0')) or 0
 GlobalsSetValue('PERK_PICKED_TEST_PICKUP_COUNT',tostring(current+1))
end
perk_spawn=function(_,_,_,dont_remove) spawn_dont_remove=dont_remove; next_pickup=next_pickup+1; alive[next_pickup]=true; return next_pickup end

local service=assert(native_dofile(root..'/files/features/perks/service.lua'))
local perk={id='TEST',stackable=false,func=function() end}
local ok,reason=service.apply(1,perk,{ignore_debounce=true})
assert(ok and reason=='applied',tostring(reason))
assert(pickup_args and pickup_args[1]==55 and pickup_args[2]==1 and pickup_args[3]=='$mock_perk','canonical pickup must use a real perk entity')
assert(pickup_args[4]==true and pickup_args[5]==false,'canonical path must use physical-pickup-equivalent vanilla flags')
assert(spawn_dont_remove==true,'creative perk entity must carry perk_dont_remove_others')
assert(capture_started==1 and capture_stopped>=1 and commits==1,'transaction capture not committed')
assert(sync_calls==1,'inventory sync not requested after direct apply')
local second_ok,second_reason=service.apply(1,perk,{ignore_debounce=true})
assert(second_ok and second_reason=='applied','non-stackable perk was artificially blocked')
assert(tonumber(globals.PERK_PICKED_TEST_PICKUP_COUNT)==2,'second real pickup did not execute')
assert(commits==2 and sync_calls==2,'second pickup did not use canonical transaction/sync path')

-- If vanilla throws before public pickup count changes, rollback must target the exact
-- just-created transaction instead of remove_one(), which would see count==0/unchanged.
perk_pickup=function() error("partial vanilla pickup") end
local failed,failed_reason=service.apply(1,perk,{ignore_debounce=true})
assert(failed==false and failed_reason=="pickup_failed","failed vanilla pickup did not report atomic failure")
assert(reverted_transaction and reverted_transaction.perk_id=="TEST" and reverted_transaction.player==1 and reverted_transaction.transaction_id==3,"failed pickup did not rollback exact transaction id")
assert(tonumber(globals.PERK_PICKED_TEST_PICKUP_COUNT)==2,"failed pickup changed public perk count")
assert(sync_calls==2,"failed pickup published successful inventory sync")
local removal_attempts=0
service.count=function() return 1 end
service.remove_one=function() removal_attempts=removal_attempts+1; return true,'removed' end
local removed,limit_reason=service.remove_all(1,perk)
assert(removed==1000 and removal_attempts==1000 and limit_reason=='limit_reached','remove_all safety cap falsely reported complete success')
print('perk_direct_apply=PASS real_perk_entity=true physical_pickup_equivalent=true cosmetic_fx=true transaction=true sync=true repeat_nonstackable=true exception_atomic=true limit_reached=true')
