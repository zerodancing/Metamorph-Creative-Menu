local root=assert(arg[1])
local native_dofile=dofile
local globals={}
local local_player=1
local begin_calls, generic_begin_calls, start_calls, stop_calls, commit_calls, set_id_calls=0,0,0,0,0,0
local all_root_capture_calls, all_root_commit_calls=0,0
local service={
 begin_pickup=function(player,perk) begin_calls=begin_calls+1; return {player=player,perk_id=perk.id} end,
 start_pickup_capture=function(token,env) start_calls=start_calls+1; return true end,
 stop_pickup_capture=function(token) stop_calls=stop_calls+1 end,
 commit_pickup=function(token) commit_calls=commit_calls+1; return true,'tracked' end,
 remove_one=function() return true end,
}
local transactions={
 begin=function(player,id) generic_begin_calls=generic_begin_calls+1; return {player=player,perk_id=id,global_changes={},global_reads={},run_flag_changes={}} end,
 set_perk_id=function(token,id) set_id_calls=set_id_calls+1; token.perk_id=id; return true end,
}
local roots={
 capture_all_before=function() all_root_capture_calls=all_root_capture_calls+1; return {TEST={}} end,
 commit_from_all=function(id,player,before) all_root_commit_calls=all_root_commit_calls+1 end,
}
local catalog={all=function() return {{id='TEST',ui_name='$perk_test'}} end}
local locator={get=function() return local_player end}
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/features/perks/service.lua' then return service end
 if path=='mods/metamorph_creative_menu/files/features/perks/transactions.lua' then return transactions end
 if path=='mods/metamorph_creative_menu/files/features/perks/root_companions.lua' then return roots end
 if path=='mods/metamorph_creative_menu/files/features/perks/catalog.lua' then return catalog end
 if path=='mods/metamorph_creative_menu/files/platform/noita/player_locator.lua' then return locator end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
get_perk_picked_flag_name=function(id) return 'PERK_PICKED_'..id end
GlobalsGetValue=function(k,d) return globals[k] or d end
EntityGetIsAlive=function(e) return e==55 end
EntityGetName=function(e) return '$perk_test' end
EntityGetComponentIncludingDisabled=function() return {} end
ComponentGetValue2=function() return '' end

local observer=assert(native_dofile(root..'/files/features/perks/external_observer.lua'))
local context=assert(observer.before_pickup(55,1,'TEST',{}),'local vanilla pickup was not observed')
globals.PERK_PICKED_TEST_PICKUP_COUNT='1'
local tracked,reason,id=observer.after_pickup(context,true)
assert(tracked and reason=='tracked' and id=='TEST','known pickup did not commit')
assert(begin_calls==1 and start_calls==1 and stop_calls==1 and commit_calls==1,'known pickup lifecycle diverged')
assert(observer.before_pickup(55,2,'TEST',{})==nil,'remote replica pickup must never become local ownership')

-- Unknown presentation metadata still resolves safely from exactly one pickup-count delta.
globals.PERK_PICKED_TEST_PICKUP_COUNT='1'
EntityGetName=function() return '$unknown' end
local unknown=assert(observer.before_pickup(55,1,'$unknown',{}),'unknown local pickup was not provisionally captured')
globals.PERK_PICKED_TEST_PICKUP_COUNT='2'
local tracked2,reason2,id2=observer.after_pickup(unknown,true)
assert(tracked2 and id2=='TEST',tostring(reason2))
assert(generic_begin_calls==1 and set_id_calls==2,'post-pickup id resolution did not use generic transaction')
assert(all_root_capture_calls==1 and all_root_commit_calls==1,'unknown pickup did not preserve detached-root baseline')
print('perk_external_pickup=PASS local_only=true count_delta_resolution=true')
