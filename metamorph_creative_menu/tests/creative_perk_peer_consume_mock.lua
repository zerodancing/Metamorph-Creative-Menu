local root=assert(arg[1],'root required')
local native_dofile=dofile
local globals={
 mcm_creative_perk_spawn_seq_v1='1',
 ['mcm_creative_perk_spawn_entity_v1:1']='77',
 ['mcm_creative_perk_spawn_id_v1:1']='TEST_PERK',
 ['mcm_creative_perk_spawn_x_v1:1']='100',
 ['mcm_creative_perk_spawn_y_v1:1']='200',
 ['mcm_creative_perk_spawn_frame_v1:1']='10',
}
GlobalsGetValue=function(k,d) return globals[k] or d end
GlobalsSetValue=function(k,v) globals[k]=tostring(v) end
local alive={[77]=true,[88]=true}
local positions={[77]={100,200},[88]={105,202}}
EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetTransform=function(e) return positions[e][1],positions[e][2] end
local killed={}
local network_deaths={}
local order={}
ewext={des_death_notify=function(e,wait,x,y,path,responsible)
 network_deaths[#network_deaths+1]={e=e,wait=wait,x=x,y=y,path=path,responsible=responsible}; order[#order+1]='notify'
end}
EntityGetFilename=function(e) return e==77 and 'data/entities/items/pickup/perk.xml' or '' end
EntityKill=function(e) killed[#killed+1]=e; order[#order+1]='kill'; alive[e]=false end
local frame=20
GameGetFrameNum=function() return frame end
local counts={TEST_PERK=0}
util={get_ent_variable=function(entity,key)
 assert(entity==88 and key=='ew_current_perks'); return counts
end}
ctx={my_id='me',players={friend={entity=88}}}
local bridge=assert(native_dofile(root..'/files/integrations/ew/bridge/creative_perks.lua'))
bridge.init({report_error=function(scope,detail) error(scope..':'..tostring(detail)) end})
-- Empty first observation establishes no pickup. A first non-empty observation would still
-- be proximity-gated instead of being silently accepted as an unverified baseline.
bridge.update()
assert(#killed==0 and globals.mcm_creative_perk_spawn_ack_v1=='1','creative perk registration/baseline failed')
-- A stock peer advertises perk counts every 120 frames. The owner correlates the
-- increment with the peer's recent path and kills the authoritative pickup locally.
frame=140; counts={TEST_PERK=1}; bridge.update()
assert(#network_deaths==1 and network_deaths[1].e==77 and network_deaths[1].wait==false,
 'remote stock-EW perk increment did not submit authoritative DES deletion')
assert(#killed==1 and killed[1]==77,'remote stock-EW perk increment did not consume owner authority')
assert(order[1]=='notify' and order[2]=='kill','creative perk authority was killed before DES deletion was submitted')
assert(string.find(globals.mcm_creative_perk_consume_status_v1 or '','consumed:TEST_PERK',1,true),
 'creative perk consume status not published')
print('creative_perk_peer_consume=PASS stock_peer_no_mcm=true owner_authority_killed=true des_delete_before_kill=true recent_position_correlation=true')
