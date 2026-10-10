local root=assert(arg[1])
local frame=10
local alive={[1]=true,[2]=true,[60]=true,[61]=true}
local positions={[1]={0,0},[2]={100,0},[60]={8,0},[61]={92,0}}
local tags={[1]={player_unit=true},[2]={ew_peer=true},[60]={death_ghost=true},[61]={death_ghost=true}}
EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetRootEntity=function(e) return e end
EntityGetTransform=function(e) local p=positions[e]; return p[1],p[2] end
EntityGetInRadius=function() return {60,61} end
EntityGetWithTag=function(tag)
 local result={}; for e,ts in pairs(tags) do if alive[e] and ts[tag] then result[#result+1]=e end end; return result
end
EntityHasTag=function(e,t) return tags[e] and tags[e][t] or false end
EntityGetFilename=function(e) return (e==60 or e==61) and 'data/entities/misc/perks/death_ghost.xml' or '' end
EntityGetComponentIncludingDisabled=function() return {} end
EntitySetComponentIsEnabled=function() end
EntityKill=function(e) alive[e]=false end
GameGetFrameNum=function() return frame end
local roots=assert(dofile(root..'/files/features/perks/root_companions.lua'))
local before=roots.capture_before(1,'DEATH_GHOST')
-- Make local ghost appear after baseline while remote ghost remains near peer 2.
alive[60]=false
before=roots.capture_before(1,'DEATH_GHOST')
alive[60]=true
roots.commit('DEATH_GHOST',1,before)
roots.on_count_zero('DEATH_GHOST')
assert(alive[60]==false,'local owned root survived cleanup')
assert(alive[61]==true,'remote peer companion was claimed by local cleanup')
print('perk_peer_root_isolation=PASS local_removed=true remote_preserved=true')
