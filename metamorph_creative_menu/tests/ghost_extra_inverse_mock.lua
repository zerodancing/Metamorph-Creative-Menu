local root=assert(arg[1])
local native_dofile=dofile
dofile=function(path)
 local prefix="mods/metamorph_creative_menu/"
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
local alive={[1]=true,[2]=true,[3]=true}
local children={[1]={2,3},[2]={},[3]={}}
local tags={[2]={angry_ghost=true},[3]={ghostly_ghost=true}}
GlobalsGetValue=function(name,default) return "0" end
GlobalsSetValue=function() end
EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetAllChildren=function(e) local r={}; for _,v in ipairs(children[e] or {}) do if alive[v] then r[#r+1]=v end end; return r end
EntityHasTag=function(e,t) return tags[e] and tags[e][t] or false end
EntityGetFilename=function(e) return e==2 and "data/entities/misc/perks/angry_ghost.xml" or e==3 and "data/entities/misc/perks/ghostly_ghost.xml" or "" end
EntityGetName=function() return "" end
EntityGetComponentIncludingDisabled=function() return {} end
EntityGetFirstComponentIncludingDisabled=function() return 0 end
EntitySetComponentIsEnabled=function() end
EntityKill=function(e) alive[e]=false end
ComponentGetValue2=function() return nil end
GameGetGameEffect=function() return 0 end
GameRemoveFlagRun=function() end
RemoveFlagPersistent=function() end
local inv=assert(dofile(root.."/files/features/perks/inverse_registry.lua"))
local ok,reason=inv.zero_cleanup(1,"ANGRY_GHOST"); assert(ok,reason)
assert(not alive[2] and not alive[3],"ghost family residue")
local ok2,reason2=inv.remove(1,"EXTRA_MANA",1); assert(ok2 and reason2=="inverse_extra_mana_orphan_counter_only",tostring(reason2))
print("ghost_and_extra_mana_orphan=PASS ghost_children=0 extra_mana_counter_inverse=true")
