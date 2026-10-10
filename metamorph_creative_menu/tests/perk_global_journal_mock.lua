local root=assert(arg[1])
local globals={TEMPLE_PERK_COUNT='3',PERK_PICKED_TEST_PICKUP_COUNT='0'}
local flags={}
local env={}
env.GlobalsGetValue=function(name,default) local value=globals[name]; if value==nil then return default end; return value end
env.GlobalsSetValue=function(name,value) globals[name]=tostring(value) end
env.GameHasFlagRun=function(name) return flags[name]==true end
env.GameAddFlagRun=function(name) flags[name]=true end
env.GameRemoveFlagRun=function(name) flags[name]=nil end
-- Revert operates through the real globals of the test VM.
GlobalsGetValue=env.GlobalsGetValue
GlobalsSetValue=env.GlobalsSetValue
GameHasFlagRun=env.GameHasFlagRun
GameAddFlagRun=env.GameAddFlagRun
GameRemoveFlagRun=env.GameRemoveFlagRun

local journal=assert(loadfile(root..'/files/features/perks/transactions/global_journal.lua'))()
local token={perk_id='TEST'}
assert(journal.start_capture(token,env))
assert(env.GlobalsGetValue('TEMPLE_PERK_COUNT','0')=='3')
env.GlobalsSetValue('TEMPLE_PERK_COUNT','4')
env.GlobalsSetValue('PERK_PICKED_TEST_PICKUP_COUNT','1') -- standard count belongs to perk service, not journal
env.GameAddFlagRun('CUSTOM_SIDE_EFFECT')
journal.stop_capture(token)
local delta={}
journal.attach_delta(delta,token)
assert(#delta.global_changes==1 and delta.global_changes[1].name=='TEMPLE_PERK_COUNT','unexpected global capture')
assert(#delta.run_flag_changes==1 and delta.run_flag_changes[1].name=='CUSTOM_SIDE_EFFECT','run flag not captured')
local preflight,reason=journal.preflight_delta(delta); assert(preflight,reason)
-- A later independent numeric change composes with the inverse: 6 - pickup delta 1 = 5.
globals.TEMPLE_PERK_COUNT='6'
journal.revert_delta(delta)
assert(globals.TEMPLE_PERK_COUNT=='5','numeric delta rollback stomped later edit')
assert(flags.CUSTOM_SIDE_EFFECT~=true,'run flag baseline not restored')
assert(globals.PERK_PICKED_TEST_PICKUP_COUNT=='1','standard perk count must not be journal-owned')

-- Two tracked pickups may touch the same non-numeric Global/run flag. Removing the
-- older one first must not clobber the newer owner, while removing the final owner
-- restores the original baseline.
globals.MODE='base'
flags.SHARED_FLAG=nil
local token1={perk_id='A',transaction_id=101}
assert(journal.start_capture(token1,env)); env.GlobalsSetValue('MODE','one'); env.GameAddFlagRun('SHARED_FLAG'); journal.stop_capture(token1)
local delta1={}; journal.attach_delta(delta1,token1)
local token2={perk_id='B',transaction_id=102}
assert(journal.start_capture(token2,env)); env.GlobalsSetValue('MODE','two'); env.GameAddFlagRun('SHARED_FLAG'); journal.stop_capture(token2)
local delta2={}; journal.attach_delta(delta2,token2)
assert(select(1,journal.preflight_delta(delta1)),'older layered global should remain removable')
journal.revert_delta(delta1)
assert(globals.MODE=='two' and flags.SHARED_FLAG==true,'removing older layer clobbered newer perk state')
assert(select(1,journal.preflight_delta(delta2)),'newer layered global should remain removable')
journal.revert_delta(delta2)
assert(globals.MODE=='base' and flags.SHARED_FLAG~=true,'final layer did not restore baseline')

print('perk_global_journal=PASS numeric_composition=true layered_ownership=true standard_count_excluded=true')
