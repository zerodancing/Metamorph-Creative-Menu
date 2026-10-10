local root=assert(arg[1],"root")
local native_dofile=dofile
local player=1
local alive={[1]=true,[2]=true,[3]=true}
local children={[1]={2,3},[2]={},[3]={}}
local components={[1]={11,12},[2]={20},[3]={30}}
local ctype={[11]="SpriteComponent",[12]="LuaComponent",[20]="GameEffectComponent",[30]="GameEffectComponent"}
local owner={[11]=1,[12]=1,[20]=2,[30]=3}
local values={
 [11]={alpha=0},
 [12]={script_source_file="data/scripts/perks/radar.lua"},
 [20]={effect="INVISIBILITY",frames=-1},
 [30]={effect="INVISIBILITY",frames=300},
}
local entity_tags={[2]={perk_entity=true}}
local component_tags={[12]={perk_component=true}}
local frame=10

local function remove_component(entity,component)
 for i=#(components[entity] or {}),1,-1 do if components[entity][i]==component then table.remove(components[entity],i) end end
 ctype[component]=nil; values[component]=nil; owner[component]=nil; component_tags[component]=nil
end
EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetAllChildren=function(e) local out={} for _,c in ipairs(children[e] or {}) do if alive[c] then out[#out+1]=c end end return out end
EntityGetComponentIncludingDisabled=function(e,t)
 local out={} for _,c in ipairs(components[e] or {}) do if ctype[c]==t then out[#out+1]=c end end return out
end
EntityGetFirstComponentIncludingDisabled=function(e,t) return (EntityGetComponentIncludingDisabled(e,t) or {})[1] end
EntityGetAllComponents=function(e) return components[e] or {} end
EntitySetComponentIsEnabled=function(_,c,v) values[c]=values[c] or {}; values[c].enabled=v==true end
ComponentGetIsEnabled=function(c) return values[c] and values[c].enabled~=false end
ComponentGetTypeName=function(c) return ctype[c] or "" end
ComponentGetEntity=function(c) return owner[c] or 0 end
ComponentGetValue2=function(c,f) return values[c] and values[c][f] end
ComponentSetValue2=function(c,f,v) values[c]=values[c] or {}; values[c][f]=v end
ComponentHasTag=function(c,t) return component_tags[c] and component_tags[c][t] or false end
EntityHasTag=function(e,t) return entity_tags[e] and entity_tags[e][t] or false end
EntityRemoveComponent=remove_component
EntityKill=function(e) alive[e]=false end
EntityGetFilename=function() return "" end
EntityGetName=function() return "" end
EntityGetRootEntity=function(e) return e==1 and 1 or 1 end
EntityGetWithTag=function() return {} end
GameGetFrameNum=function() frame=frame+1 return frame end
GlobalsGetValue=function(_,d) return d end
GlobalsSetValue=function() end
GameGetGameEffect=function() return 0 end
GameRemoveFlagRun=function() end
RemoveFlagPersistent=function() end

local prefix="mods/metamorph_creative_menu/"
dofile=function(path)
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end

local player_inverse=assert(native_dofile(root.."/files/features/perks/inverse/player.lua"))
local ok_radar,reason_radar=player_inverse.handlers.RADAR_ENEMY(player,1)
assert(ok_radar,reason_radar)
assert(ctype[12]==nil,"RADAR_ENEMY LuaComponent survived inverse")

-- Removing perk invisibility must not cancel a separate potion/mod invisibility.
local ok_invis=player_inverse.zero_cleanup_handlers.INVISIBILITY(player)
assert(ok_invis~=false,"zero invis cleanup failed")
assert(alive[2]==false,"perk INVISIBILITY entity survived")
assert(alive[3]==true,"external invisibility was incorrectly removed")
assert(values[11].alpha==0,"external invisibility was visually cancelled")

-- Without an external owner, zero-count cleanup must make the player visible immediately.
alive[3]=false
alive[4]=true; children[4]={}; table.insert(children[1],4); components[4]={40}; ctype[40]="GameEffectComponent"; owner[40]=4
values[40]={effect="INVISIBILITY",frames=-1}; entity_tags[4]={perk_entity=true}; values[11].alpha=0
assert(player_inverse.zero_cleanup_handlers.INVISIBILITY(player)~=false)
assert(alive[4]==false,"second perk invisibility survived")
assert(values[11].alpha==1,"sprite alpha was not restored immediately")
print("perk_radar_invisibility_regression=PASS radar_exact_component=true external_invisibility_preserved=true zero_count_visible_immediately=true")
