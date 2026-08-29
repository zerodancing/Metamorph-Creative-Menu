local root=assert(arg[1])
local patches=assert(dofile(root..'/files/integrations/ew/resilience_patches.lua'))
local fixture=[[
local perk_fns = {}
local perks_to_ignore = {
    HOMUNCULUS = true,
}
local global_perks = {
    GOLD_IS_FOREVER = true,
    PEACE_WITH_GODS = true,
}
local perk_list = {
    { id = "GOLD_IS_FOREVER" },
    { id = "TEST" },
}
function perk_fns.get_my_perks()
    local perks = {}
    for i = 1, #perk_list do
        local perk_id = perk_list[i].id
        local perk_flag_name = get_perk_picked_flag_name(perk_id)
        local perk_count = tonumber(GlobalsGetValue(perk_flag_name .. "_PICKUP_COUNT", "0"))
        if perk_count > 0 then
            perks[perk_id] = perk_count
        end
    end
    return perks
end
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
return perk_fns
]]
local patched,count=patches.patch_peer_perk_isolation_source(fixture)
assert(count==1,'peer perk patch did not apply atomically')
assert(string.find(patched,'GOLD_IS_FOREVER = true',1,true),'upstream global-perk policy was destroyed')
assert(not string.find(patched,'local global_perks = {}',1,true),'MCM still replaces EW global-perk policy')
assert(string.find(patched,'mcm_peer_perk_sync_v4',1,true),'critical peer-perk marker missing')
assert(string.find(patched,'mcm_peer_perk_sender_filter_v1',1,true),'sender-side creative filter missing')
assert(string.find(patched,'mcm_peer_perk_removal_v1',1,true),'removal normalization missing')
assert(string.find(patched,'mcm_peer_perk_remote_safety_v1',1,true),'remote safety policy missing')
for _,perk_id in ipairs({'CORDYCEPS','ABILITY_ACTIONS_MATERIALIZED','RESPAWN','SAVING_GRACE'}) do
    assert(string.find(patched,perk_id..' = true',1,true),'unsafe remote mechanic not isolated: '..perk_id)
end

local globals={
    PERK_PICKED_GOLD_IS_FOREVER_PICKUP_COUNT='2',
    PERK_PICKED_TEST_PICKUP_COUNT='2',
    ['mcm_creative_perk_hidden_count_v1:GOLD_IS_FOREVER']='1',
    ['mcm_creative_perk_hidden_count_v1:TEST']='1',
}
function GlobalsGetValue(name,default) return globals[name] or default end
function get_perk_picked_flag_name(id) return 'PERK_PICKED_'..id end
local current={TEST=1,KEEP=1}
local killed=0
util={
 get_ent_variable=function() return current end,
 set_ent_variable=function(_,_,value) current=value end,
}
EntityKill=function() killed=killed+1 end
local module=assert(load(patched))()
local advertised=module.get_my_perks()
assert(advertised.GOLD_IS_FOREVER==1,'tracked creative global perk was still advertised to stock EW peer')
assert(advertised.TEST==2,'non-global creative perk was incorrectly hidden from remote replica')
module.update_perks({KEEP=1},{entity=77})
assert(current.TEST==0,'removed perk id was not preserved as explicit zero')
assert(killed==1,'EW negative-diff cleanup path did not run for removal')
local patched_again,count_again=patches.patch_peer_perk_isolation_source(patched)
assert(count_again==0 and patched_again==patched,'peer perk patch is not idempotent')
print('ew_perk_sync_patch=PASS upstream_globals_preserved=true sender_filter=true stock_peer_safe=true removals_existing_path=true')
