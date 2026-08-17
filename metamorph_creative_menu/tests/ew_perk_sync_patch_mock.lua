local root=assert(arg[1])
local patches=assert(dofile(root..'/files/integrations/ew/resilience_patches.lua'))
local fixture=[[
local perks_to_ignore = {
    HOMUNCULUS = true,
}
local global_perks = {
    GOLD_IS_FOREVER = true,
    PEACE_WITH_GODS = true,
}
function perk_fns.update_perks(perk_data, player_data)
    local entity = player_data.entity
    local current_counts = util.get_ent_variable(entity, "ew_current_perks") or {}
    for perk_id, count in pairs(perk_data) do
        local current = (current_counts[perk_id] or 0)
        local diff = count - current
        if diff < 0 then EntityKill(entity) end
    end
    util.set_ent_variable(entity, "ew_current_perks", perk_data)
end
]]
local patched,count=patches.patch_peer_perk_isolation_source(fixture)
assert(count==1,'peer perk patch did not apply atomically')
assert(string.find(patched,'local global_perks = {}',1,true),'global ownership table was not isolated')
assert(string.find(patched,'mcm_peer_perk_sync_v3',1,true),'critical peer-perk marker missing')
assert(string.find(patched,'mcm_peer_perk_removal_v1',1,true),'removal normalization missing')
assert(string.find(patched,'mcm_peer_perk_remote_safety_v1',1,true),'remote safety policy missing')
for _,perk_id in ipairs({'CORDYCEPS','ABILITY_ACTIONS_MATERIALIZED','RESPAWN','SAVING_GRACE'}) do
    assert(string.find(patched,perk_id..' = true',1,true),'unsafe remote mechanic not isolated: '..perk_id)
end

-- Execute the relevant patched update function in a tiny EW-like environment: omitting
-- TEST from the next packet must become TEST=0 and enter EW's existing negative-diff path.
local current={TEST=1,KEEP=1}
local killed=0
util={
 get_ent_variable=function() return current end,
 set_ent_variable=function(_,_,value) current=value end,
}
EntityKill=function() killed=killed+1 end
perk_fns={}
local update_source=string.match(patched,'function perk_fns%.update_perks.-\nend')
assert(type(update_source)=='string','patched update function not found')
assert(load(update_source))()
perk_fns.update_perks({KEEP=1},{entity=77})
assert(current.TEST==0,'removed perk id was not preserved as explicit zero')
assert(killed==1,'EW negative-diff cleanup path did not run for removal')
local patched_again,count_again=patches.patch_peer_perk_isolation_source(patched)
assert(count_again==0 and patched_again==patched,'peer perk patch is not idempotent')
print('ew_perk_sync_patch=PASS peer_local=true removals_propagate_via_existing_ew_path=true')
