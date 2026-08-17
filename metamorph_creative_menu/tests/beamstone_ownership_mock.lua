local root=assert(arg[1])
local native_dofile=dofile
local frame=10
local alive={[1]=true}
local globals={}
local beam=50
local inv={has=function(id) return id=="MEGA_BEAM_STONE" end,remove=function() return true,"inverse_mega_beam_stone_counter" end,zero_cleanup=function() return true,"ok" end,maintenance_cleanup=function() return true end,capture_pre_pickup=function() return true end,post_tracked_cleanup=function() return true end}
local tx={begin=function(player,id) return {player=player,perk_id=id} end,start_capture=function() return true end,stop_capture=function() end,commit=function() return true,"tracked" end,has=function() return false end,revert=function() return false,"none" end}
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/features/perks/inverse_registry.lua" then return inv end
 if path=="mods/metamorph_creative_menu/files/features/perks/transactions.lua" then return tx end
 local prefix="mods/metamorph_creative_menu/"; if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
dofile_once=function() end
GlobalsGetValue=function(k,d) return globals[k] or d end
GlobalsSetValue=function(k,v) globals[k]=tostring(v) end
GameGetFrameNum=function() return frame end
GameRemoveFlagRun=function() end
EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetRootEntity=function(e) return e end
EntityGetTransform=function(e) return 0,0 end
EntityGetInRadius=function(x,y,r) local t={}; if alive[beam] then t[#t+1]=beam end; return t end
EntityHasTag=function() return false end
EntityGetFilename=function(e) return e==beam and "data/entities/items/pickup/beamstone.xml" or "" end
EntityGetAllChildren=function() return {} end
EntityGetComponentIncludingDisabled=function() return {} end
EntityGetFirstComponentIncludingDisabled=function() return 0 end
EntitySetComponentIsEnabled=function() end
EntityKill=function(e) alive[e]=false end
ComponentGetValue2=function() return nil end
ComponentSetValue2=function() end
GameGetGameEffect=function() return 0 end
local editor=assert(native_dofile(root.."/files/features/perks/service.lua"))
local perk={id="MEGA_BEAM_STONE",func=function() end,game_effect=nil,game_effect2=nil,ui_name="beam",ui_icon="beam.png"}
local token=assert(editor.begin_pickup(1,perk))
alive[beam]=true
local okc=select(1,editor.commit_pickup(token)); assert(okc)
globals["PERK_PICKED_MEGA_BEAM_STONE_PICKUP_COUNT"]="1"
local ok,reason=editor.remove_one(1,perk); assert(ok,reason)
assert(globals["PERK_PICKED_MEGA_BEAM_STONE_PICKUP_COUNT"]=="0")
assert(not alive[beam],"beamstone root survived removal")
print("beamstone_root_ownership=PASS removed=true")
