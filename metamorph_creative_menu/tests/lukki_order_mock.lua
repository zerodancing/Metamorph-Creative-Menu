local root=assert(arg[1])
local player=1
local comp=101
local values={[comp]={pixel_gravity=367.5,mFramesNotSwimming=0}}
local meta={[comp]={run_velocity=100,velocity_min_x=-100,velocity_max_x=100}}
local globals={PLAYER_LUKKINESS_LEVEL='0',LUKKI_PERK_TOTAL_COUNT='0',PERK_PICKED_ATTACK_FOOT_PICKUP_COUNT='0',PERK_PICKED_LEGGY_FEET_PICKUP_COUNT='0'}
GlobalsGetValue=function(k,d) local v=globals[k]; if v==nil then return d end; return v end
GlobalsSetValue=function(k,v) globals[k]=tostring(v) end
EntityGetIsAlive=function(e) return e==player end
EntityGetAllChildren=function() return {} end
EntityGetAllComponents=function() return {} end
EntityGetComponentIncludingDisabled=function(e,t,tag) if e==player and t=='CharacterPlatformingComponent' then return {comp} end return {} end
EntityGetFirstComponentIncludingDisabled=function(e,t) local x=EntityGetComponentIncludingDisabled(e,t); return x[1] end
ComponentGetValue2=function(c,f) return values[c] and values[c][f] end
ComponentSetValue2=function(c,f,v) values[c][f]=v end
ComponentGetMetaCustom=function(c,f) return meta[c] and meta[c][f] end
ComponentSetMetaCustom=function(c,f,v) meta[c][f]=v end
ComponentHasTag=function() return false end
EntitySetComponentsWithTagEnabled=function() end
EntityHasTag=function() return false end
EntityGetFilename=function() return '' end
EntityGetName=function() return '' end
EntityKill=function() end
EntityGetWithTag=function() return {} end
GameGetGameEffect=function() return 0 end
GameGetWorldStateEntity=function() return 0 end
GameRemoveFlagRun=function() end
RemoveFlagPersistent=function() end
local native=dofile
dofile=function(path)
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native(root..'/'..string.sub(path,#prefix+1)) end
 return native(path)
end
local inv=assert(native(root..'/files/features/perks/inverse_registry.lua'))
-- A previous movement perk has already raised platform gravity before Lukki is picked.
assert(inv.capture_pre_pickup(player,'ATTACK_FOOT'))
-- Structural transaction later restores the true all-perks-removal value first.
values[comp].pixel_gravity=350
assert(inv.post_tracked_cleanup(player,'ATTACK_FOOT',1))
globals.PERK_PICKED_ATTACK_FOOT_PICKUP_COUNT='0'
globals.PERK_PICKED_LEGGY_FEET_PICKUP_COUNT='0'
local ok,reason=inv.zero_cleanup(player,'ATTACK_FOOT'); assert(ok,reason)
assert(math.abs(values[comp].pixel_gravity-350)<1e-6,'stale Lukki snapshot resurrected '..tostring(values[comp].pixel_gravity))
print('lukki_order_cleanup=PASS pixel_gravity=350 reason='..tostring(reason))
