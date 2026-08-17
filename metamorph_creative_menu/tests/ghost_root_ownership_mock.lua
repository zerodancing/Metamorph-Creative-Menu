local root=assert(arg[1])
local native_dofile=dofile
local frame=10
local alive={[1]=true}
local globals={}
local ghost=60
local tags={[ghost]={death_ghost=true}}
local inv={has=function(id) return id=='DEATH_GHOST' end,remove=function() return true,'inverse_death_ghost_counter_only' end,zero_cleanup=function() return true,'ok' end,maintenance_cleanup=function() return true end,capture_pre_pickup=function() return true end,post_tracked_cleanup=function() return true end}
local tx={begin=function(player,id) return {player=player,perk_id=id} end,start_capture=function() return true end,stop_capture=function() end,commit=function() return true,'tracked' end,has=function() return false end,revert=function() return false,'none' end}
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/features/perks/inverse_registry.lua' then return inv end
 if path=='mods/metamorph_creative_menu/files/features/perks/transactions.lua' then return tx end
 local prefix='mods/metamorph_creative_menu/'; if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
dofile_once=function() end
GlobalsGetValue=function(k,d) return globals[k] or d end
GlobalsSetValue=function(k,v) globals[k]=tostring(v) end
GameGetFrameNum=function() return frame end
GameRemoveFlagRun=function() end
EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetRootEntity=function(e) return e end
EntityGetTransform=function() return 0,0 end
EntityGetInRadius=function() local t={}; if alive[ghost] then t[#t+1]=ghost end; return t end
EntityGetWithTag=function(tag) if alive[ghost] and tags[ghost] and tags[ghost][tag] then return {ghost} end return {} end
EntityHasTag=function(e,t) return tags[e] and tags[e][t] or false end
EntityGetFilename=function(e) return e==ghost and 'data/entities/misc/perks/death_ghost.xml' or '' end
EntityGetAllChildren=function() return {} end
EntityGetComponentIncludingDisabled=function() return {} end
EntityGetFirstComponentIncludingDisabled=function() return 0 end
EntitySetComponentIsEnabled=function() end
EntityKill=function(e) alive[e]=false end
ComponentGetValue2=function() return nil end
ComponentSetValue2=function() end
GameGetGameEffect=function() return 0 end
local editor=assert(native_dofile(root..'/files/features/perks/service.lua'))
local perk={id='DEATH_GHOST',func=function() end,ui_name='death ghost',ui_icon='death.png'}
-- Baseline before pickup has no ghost.
local token=assert(editor.begin_pickup(1,perk))
alive[ghost]=true
assert(select(1,editor.commit_pickup(token)))
globals.PERK_PICKED_DEATH_GHOST_PICKUP_COUNT='1'
local ok,reason=editor.remove_one(1,perk); assert(ok,reason)
assert(globals.PERK_PICKED_DEATH_GHOST_PICKUP_COUNT=='0')
assert(not alive[ghost],'detached root ghost survived owned removal')
print('ghost_root_ownership=PASS removed=true')
