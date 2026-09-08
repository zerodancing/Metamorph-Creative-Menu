local root=assert(arg[1],"root required")
local native_dofile=dofile
local alive={[1]=true,[2]=true}
local children={[1]={2},[2]={}}
local components={[1]={11,12},[2]={21}}
local types={[11]="LuaComponent",[12]="DamageModelComponent",[21]="LuaComponent"}
local removed_components={}
local disabled={}
local removed_tags={}
local added_tags={}
local killed={}
local loaded=0
local tree={walk=function(entity,fn)
 local function rec(e) fn(e); for _,c in ipairs(children[e] or {}) do rec(c) end end
 rec(entity)
end}
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua" then return tree end
 if path=="mods/metamorph_creative_menu/files/integrations/ew/runtime.lua" then return {enabled=function() return true end} end
 return native_dofile(path)
end
EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetAllChildren=function(e) return children[e] or {} end
EntityGetComponentIncludingDisabled=function(e,kind,tag)
 if tag~=nil then return {} end
 if kind=="LuaComponent" then
   local out={}; for _,c in ipairs(components[e] or {}) do if types[c]=="LuaComponent" then out[#out+1]=c end end; return out
 end
 return {}
end
EntityGetFirstComponentIncludingDisabled=function(e,kind)
 if kind=="GameEffectComponent" then return 0 end
 if kind=="DamageModelComponent" and e==1 then return 12 end
 return 0
end
EntityGetAllComponents=function(e) return components[e] or {} end
ComponentGetTypeName=function(c) return types[c] end
ComponentGetValue2=function() return nil end
ComponentSetValue2=function() end
EntityRemoveComponent=function(e,c) removed_components[c]=true end
EntitySetComponentIsEnabled=function(e,c,v) disabled[c]=(v==true) end
EntityRemoveTag=function(e,t) removed_tags[t]=true end
EntityAddTag=function(e,t) added_tags[t]=true end
EntitySetTransform=function(e,x,y) assert(x==10000000 and y==10000000) end
EntityKill=function(e) killed[e]=true; alive[e]=false end
EntityGetFilename=function() return "data/entities/animals/boss_centipede/boss_centipede.xml" end
EntityGetTransform=function() return 10,20 end
EntityHasTag=function() return false end
GameGetFrameNum=function() return 10 end
ModDoesFileExist=function() return false end
EntityLoad=function() loaded=loaded+1; return 99 end
local corpse=assert(native_dofile(root.."/files/features/forms/corpse_service.lua"))
assert(corpse.detach(1,"data/entities/animals/boss_centipede/boss_centipede.xml","death",0)==true)
assert(killed[1]==true,"network player-form body remained alive")
assert(removed_components[11] and removed_components[21],"network body death Lua hooks were not stripped")
assert(not added_tags.ew_synced and not added_tags.metamorph_creative_menu_form_corpse,
 "network player-form was converted into a second DES corpse")
assert(removed_tags.ew_synced==true and removed_tags.ew_des==true,"network DES tags were not cleared during retirement")
corpse.update()
assert(loaded==0,"network boss retirement spawned a fallback/resurrection body")
print("form_network_body_retire=PASS quiet=true no_ew_synced_clone=true no_boss_respawn_fallback=true")
