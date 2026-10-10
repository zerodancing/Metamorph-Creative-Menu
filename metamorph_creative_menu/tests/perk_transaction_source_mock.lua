local root=assert(arg[1], 'root required')
local native_dofile=dofile
local next_id=0
local stubs={}
stubs['mods/metamorph_creative_menu/files/features/perks/transactions/global_journal.lua']={
 start_capture=function() return false end,stop_capture=function() end,attach_delta=function(delta,token) delta.transaction_id=token.transaction_id end,
 preflight_delta=function() return true end,revert_delta=function() end,discard_delta=function() end,active_owner_counts=function() return 0,0 end,
}
stubs['mods/metamorph_creative_menu/files/features/perks/transactions/mutation_journal.lua']={
 prepare=function(token) next_id=next_id+1; token.transaction_id=next_id end,start_capture=function() return false end,stop_capture=function() end,
 attach_delta=function(delta,token) delta.transaction_id=token.transaction_id end,cleanup_owned_objects=function() return true end,revert_properties=function() return true end,
 discard_delta=function() end,rebind_delta=function() end,rebuild_ownership=function() end,active_property_count=function() return 0 end,
}
stubs['mods/metamorph_creative_menu/files/features/perks/transactions/player_rebind.lua']={capture=function() return {} end,resolve=function() return {} end,remap_delta=function() end}
stubs['mods/metamorph_creative_menu/files/features/perks/transactions/pending_cleanup.lua']={update=function() end,state_snapshot=function() return {pending=0,failed=0} end}
stubs['mods/metamorph_creative_menu/files/features/perks/transactions/structural_snapshot.lua']={
 valid_entity=function(id) return id==1 end,parent_of=function() return 0 end,snapshot=function() return {} end,
 build_delta=function() return {reversible=true,fields={},enabled={},reparents={},added_entities={},added_components={}} end,
 component_alive=function() return false end,preflight_reparents=function() return true end,cleanup_structural_additions=function() return true end,
}
stubs['mods/metamorph_creative_menu/files/features/perks/transactions/wand_special_states.lua']={
 object_get=function() end,object_set=function() return true end,extra_mana_state=function() return nil end,same_scalar=function(a,b) return a==b end,
 no_more_shuffle_state=function() return nil end,no_more_shuffle_delta=function() return {} end,
}
dofile=function(path) if stubs[path]~=nil then return stubs[path] end return native_dofile(path) end
METAMORPH_CREATIVE_MENU_PERK_TRANSACTIONS=nil
local tx=assert(native_dofile(root..'/files/features/perks/transactions.lua'))
local a=assert(tx.begin(1,'TEST')); a.source='mcm_creative'; assert(tx.commit(a))
local b=assert(tx.begin(1,'TEST')); assert(tx.commit(b))
local c=assert(tx.begin(1,'TEST')); c.source='mcm_creative'; assert(tx.commit(c))
assert(tx.source_count('TEST','mcm_creative',1)==2,'creative transaction source count incorrect')
assert(tx.source_count('TEST','',1)==1,'ordinary transaction source count incorrect')
assert(tx.revert('TEST',1)==true,'top creative transaction did not revert')
assert(tx.source_count('TEST','mcm_creative',1)==1,'creative source count did not follow rollback stack')
print('perk_transaction_source=PASS source_preserved=true rollback_count=true')
