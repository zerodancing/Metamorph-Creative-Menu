local root=assert(arg[1])
local original_dofile=dofile
local spawned=0
local picked=0
local received=nil
local stored={OLD=2,KEEP=1}
local globals={}
local cord_func=function() return 'cord' end
local safe_func=function() return 'safe' end
perk_list={
    {id='CORDYCEPS',func=cord_func,particle_effect='cord_particles'},
    {id='RESPAWN',game_effect='RESPAWN'},
    {id='SAVING_GRACE',game_effect='SAVING_GRACE'},
    {id='ABILITY_ACTIONS_MATERIALIZED',func=function() return 'materialized' end,game_effect='ABILITY_ACTIONS_MATERIALIZED'},
    {id='SAFE',func=safe_func,game_effect='SAFE_EFFECT'},
}
local suppression_seen=false
local fake_perk_fns={}
fake_perk_fns.update_perks=function(perk_data,player_data)
    received=perk_data
    local by_id={} for _,perk in ipairs(perk_list) do by_id[perk.id]=perk end
    suppression_seen = by_id.CORDYCEPS.func==nil and by_id.CORDYCEPS.particle_effect==nil
        and by_id.RESPAWN.game_effect==nil and by_id.SAVING_GRACE.game_effect==nil
        and by_id.ABILITY_ACTIONS_MATERIALIZED.func==nil and by_id.ABILITY_ACTIONS_MATERIALIZED.game_effect==nil
        and by_id.SAFE.func==safe_func and by_id.SAFE.game_effect=='SAFE_EFFECT'
    return true
end
fake_perk_fns.on_world_update=function()
    -- Model upstream's historical global-perk to_spawn auto-pickup.
    local ent=perk_spawn(1,2,'GLOBAL')
    perk_pickup(ent,99,'',true,false)
    return 'world-ok'
end
util={get_ent_variable=function(entity,name) assert(entity==77 and name=='ew_current_perks'); return stored end}
perk_spawn=function() spawned=spawned+1; return 123 end
perk_pickup=function() picked=picked+1 end
GlobalsSetValue=function(k,v) globals[k]=tostring(v) end
dofile_once=function(path)
    assert(path=='mods/quant.ew/files/core/perk_fns.lua',path)
    return fake_perk_fns
end
local guard=assert(original_dofile(root..'/files/integrations/ew/perk_runtime_guard.lua'))
local ok,reason=guard.install()
assert(ok,tostring(reason))
fake_perk_fns.update_perks({KEEP=1,NEW=3,CORDYCEPS=1,RESPAWN=1,SAVING_GRACE=1,ABILITY_ACTIONS_MATERIALIZED=1,SAFE=1},{entity=77})
assert(received.KEEP==1 and received.NEW==3 and received.OLD==0,'removed peer perk was not normalized to explicit zero')
assert(suppression_seen,'unsafe remote perk mechanics were executed on the synthetic peer replica')
local restored={} for _,perk in ipairs(perk_list) do restored[perk.id]=perk end
assert(restored.CORDYCEPS.func==cord_func and restored.CORDYCEPS.particle_effect=='cord_particles','CORDYCEPS definition not restored')
assert(restored.RESPAWN.game_effect=='RESPAWN' and restored.SAVING_GRACE.game_effect=='SAVING_GRACE','survival perk definitions not restored')
assert(restored.SAFE.func==safe_func and restored.SAFE.game_effect=='SAFE_EFFECT','safe perk definition changed')
local result=fake_perk_fns.on_world_update()
assert(result=='world-ok','wrapped EW world update result changed')
assert(spawned==0 and picked==0,'historical global auto-pickup reached the teammate')
-- The guard must restore global functions after the EW call.
perk_spawn(); perk_pickup()
assert(spawned==1 and picked==1,'runtime guard leaked temporary API overrides')
assert(globals.mcm_peer_perk_runtime_guard_v1=='installed','runtime status not published')
print('ew_perk_runtime_guard=PASS removals=true peer_ownership=true remote_safety=true existing_transport=true')
