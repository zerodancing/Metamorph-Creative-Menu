local root=assert(arg[1],"root")
local native_dofile=dofile
METAMORPH_CREATIVE_MENU_PERK_SERVICE=nil; METAMORPH_CREATIVE_MENU_PERK_TRANSACTIONS=nil; METAMORPH_CREATIVE_MENU_PERK_PICKUP_HOOK_V2=nil
local player,wand=1,2
local alive={[1]=true,[2]=true}
local parent={[2]=1}
local children={[1]={2},[2]={}}
local components={[1]={},[2]={}}
local ctype,values,enabled={},{},{}
local next_id=100
local globals={}
local flags={}
local spawned={}

local function add_child(p,c)
 local old=parent[c] or 0
 if old~=0 and children[old] then for i=#children[old],1,-1 do if children[old][i]==c then table.remove(children[old],i) end end end
 parent[c]=p; children[p]=children[p] or {}; table.insert(children[p],c)
end
local function new_entity()
 next_id=next_id+1; local e=next_id; alive[e]=true; children[e]={}; components[e]={}; return e
end
EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetTransform=function(e) if alive[e] then return 0,0 end end
EntityGetParent=function(e) return parent[e] or 0 end
EntityGetRootEntity=function(e) local r=e while (parent[r] or 0)~=0 do r=parent[r] end return r end
EntityAddChild=add_child
EntityRemoveFromParent=function(e) local old=parent[e] or 0; if old~=0 then for i=#children[old],1,-1 do if children[old][i]==e then table.remove(children[old],i) end end end; parent[e]=0 end
EntityGetAllChildren=function(e) local out={} for _,c in ipairs(children[e] or {}) do if alive[c] then out[#out+1]=c end end return out end
EntityGetAllComponents=function(e) return components[e] or {} end
EntityGetComponentIncludingDisabled=function(e,t) local out={} for _,c in ipairs(components[e] or {}) do if ctype[c]==t then out[#out+1]=c end end return out end
EntityGetFirstComponentIncludingDisabled=function(e,t) return (EntityGetComponentIncludingDisabled(e,t) or {})[1] end
EntitySetComponentIsEnabled=function(_,c,v) enabled[c]=v==true end
ComponentGetIsEnabled=function(c) return enabled[c]~=false end
ComponentGetTypeName=function(c) return ctype[c] or "" end
ComponentGetMembers=function(c) local out={} for k in pairs(values[c] or {}) do out[k]=true end return out end
ComponentGetValue=function(c,k) local v=values[c] and values[c][k]; return v==nil and "" or tostring(v) end
ComponentGetValue2=function(c,k) return values[c] and values[c][k] end
ComponentSetValue=function(c,k,v) values[c]=values[c] or {}; values[c][k]=v end
ComponentSetValue2=function(c,k,v) values[c]=values[c] or {}; values[c][k]=v end
ComponentHasTag=function() return false end
EntityHasTag=function() return false end
EntityGetFilename=function(e) return e==wand and "data/entities/items/wand_level_01.xml" or "" end
EntityGetName=function() return "" end
EntityCreateNew=function() return new_entity() end
EntityLoad=function() return new_entity() end
EntityAddComponent2=function(e,t,data) next_id=next_id+1; local c=next_id+1000; ctype[c]=t; values[c]=data or {}; enabled[c]=true; components[e][#components[e]+1]=c; return c end
EntityAddComponent=function(e,t,data) return EntityAddComponent2(e,t,data) end
EntityRemoveComponent=function(e,c) for i=#(components[e] or {}),1,-1 do if components[e][i]==c then table.remove(components[e],i) end end; ctype[c]=nil; values[c]=nil end
EntityKill=function(e) alive[e]=false; local p=parent[e] or 0; if p~=0 and children[p] then for i=#children[p],1,-1 do if children[p][i]==e then table.remove(children[p],i) end end end; parent[e]=0 end
GameGetFrameNum=(function() local f=0; return function() f=f+1 return f end end)()
GlobalsGetValue=function(k,d) return globals[k]~=nil and globals[k] or d end
GlobalsSetValue=function(k,v) globals[k]=tostring(v) end
GameHasFlagRun=function(k) return flags[k]==true end
GameAddFlagRun=function(k) flags[k]=true end
GameRemoveFlagRun=function(k) flags[k]=nil end
GameGetWorldStateEntity=function() return 0 end
get_perk_picked_flag_name=function(id) return "PERK_PICKED_"..id end

local root_companions={supports=function() return false end,commit=function() end,update=function() end,on_count_zero=function() end,debug=function() return {} end}
local inverses={capture_pre_pickup=function() return true end,has=function() return false end,zero_cleanup=function() return true end,maintenance_cleanup=function() return true end,post_tracked_cleanup=function() return true end,can_fallback_after_stale_transaction=function() return false end}
local presentation={expire_one_game_effect=function() end,on_count_zero=function() end,update=function() end,rebind_player=function() end}
local catalog={all=function() return {{id="GAMBLE",stackable=true,func=function() end},{id="ALWAYS_CAST",stackable=true,func=function() end}} end}
local locator={get=function() return player end}
local ew_runtime={force_inventory_sync=function() end}
local prefix="mods/metamorph_creative_menu/"
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/features/perks/inverse_registry.lua" then return inverses end
 if path=="mods/metamorph_creative_menu/files/features/perks/root_companions.lua" then return root_companions end
 if path=="mods/metamorph_creative_menu/files/features/perks/presentation.lua" then return presentation end
 if path=="mods/metamorph_creative_menu/files/features/perks/catalog.lua" then return catalog end
 if path=="mods/metamorph_creative_menu/files/platform/noita/player_locator.lua" then return locator end
 if path=="mods/metamorph_creative_menu/files/integrations/ew/runtime.lua" then return ew_runtime end
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
perk_spawn=function(_,_,id) local e=new_entity(); spawned[e]=id; return e end
local function add_permanent_action()
 local action=EntityCreateNew(); EntityAddChild(wand,action); return action
end
perk_pickup=function(perk_entity,who)
 local id=assert(spawned[perk_entity]); local key="PERK_PICKED_"..id.."_PICKUP_COUNT"
 local count=(tonumber(GlobalsGetValue(key,"0")) or 0)+1; GlobalsSetValue(key,tostring(count)); GameAddFlagRun("PERK_PICKED_"..id)
 if id=="ALWAYS_CAST" then add_permanent_action() end
end

local service=assert(native_dofile(root.."/files/features/perks/service.lua"))
local gamble={id="GAMBLE",stackable=true,func=function() end}
local always={id="ALWAYS_CAST",stackable=true,func=function() end}
assert(select(1,service.apply(player,gamble,{ignore_debounce=true})))
native_dofile(root.."/files/features/perks/pickup_hook.lua")
-- Actual GAMBLE helper calls perk_pickup with an empty item_name; resolution must come
-- from the perk entity's exact VariableStorage perk_id.
for _=1,2 do
 local e=new_entity(); spawned[e]="ALWAYS_CAST"; EntityAddComponent2(e,"VariableStorageComponent",{name="perk_id",value_string="ALWAYS_CAST"})
 perk_pickup(e,player,"",false,false)
end
assert(service.count("ALWAYS_CAST")==2 and #children[wand]==2,"async ALWAYS_CAST rewards missing")
assert(select(1,service.apply(player,always,{ignore_debounce=true})))
assert(service.count("ALWAYS_CAST")==3 and #children[wand]==3,"independent ALWAYS_CAST missing")
local rg,reason_g=service.remove_all(player,gamble); assert(rg==1,reason_g)
assert(service.count("ALWAYS_CAST")==1,"GAMBLE did not retire its exact ALWAYS_CAST counts")
assert(#children[wand]==1,"GAMBLE removed wrong permanent actions or left its own")
local ra,reason_a=service.remove_all(player,always); assert(ra==1,reason_a)
assert(service.count("ALWAYS_CAST")==0 and #children[wand]==0,"direct ALWAYS_CAST transaction not removable")
print("perk_always_cast_ownership=PASS async_gamble=true exact_permanent_action_ownership=true newer_copy_preserved=true")
