local root=assert(arg[1],"root")
local native_dofile=dofile
METAMORPH_CREATIVE_MENU_PERK_SERVICE=nil
METAMORPH_CREATIVE_MENU_PERK_TRANSACTIONS=nil

local player=1
local platform=10
local alive={[player]=true}
local parent={}
local children={[player]={}}
local components={[player]={platform}}
local component_type={[platform]="CharacterPlatformingComponent"}
local component_enabled={[platform]=true}
local component_values={[platform]={pixel_gravity=350}}
local component_meta={[platform]={run_velocity=100,velocity_min_x=-100,velocity_max_x=100}}
local globals={}
local flags={}
local next_entity=100

local function add_child(p,c)
    local old=parent[c] or 0
    if old~=0 and children[old] then
        for i=#children[old],1,-1 do if children[old][i]==c then table.remove(children[old],i) end end
    end
    parent[c]=p
    children[p]=children[p] or {}
    table.insert(children[p],c)
end
local function kill(e)
    alive[e]=false
    local p=parent[e] or 0
    if p~=0 and children[p] then for i=#children[p],1,-1 do if children[p][i]==e then table.remove(children[p],i) end end end
    parent[e]=0
end

EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetTransform=function(e) if alive[e] then return 10,20 end end
EntityGetParent=function(e) return parent[e] or 0 end
EntityGetRootEntity=function(e) local r=e; while (parent[r] or 0)~=0 do r=parent[r] end; return r end
EntityAddChild=function(p,c) add_child(p,c) end
EntityRemoveFromParent=function(c) add_child(0,c) end
EntityGetAllChildren=function(e) local out={}; for _,v in ipairs(children[e] or {}) do if alive[v] then out[#out+1]=v end end; return out end
EntityGetAllComponents=function(e) return components[e] or {} end
EntityGetComponentIncludingDisabled=function(e,t)
    local out={}
    for _,c in ipairs(components[e] or {}) do if component_type[c]==t then out[#out+1]=c end end
    return out
end
EntityGetFirstComponentIncludingDisabled=function(e,t) return (EntityGetComponentIncludingDisabled(e,t) or {})[1] end
EntitySetComponentIsEnabled=function(_,c,v) component_enabled[c]=v==true end
ComponentGetIsEnabled=function(c) return component_enabled[c]==true end
ComponentGetTypeName=function(c) return component_type[c] or "" end
ComponentGetMembers=function(c)
    local out={}
    for k in pairs(component_values[c] or {}) do out[k]=true end
    return out
end
ComponentGetValue=function(c,k) local v=component_values[c] and component_values[c][k]; return v==nil and "" or tostring(v) end
ComponentSetValue=function(c,k,v) component_values[c]=component_values[c] or {}; component_values[c][k]=tonumber(v) or v end
ComponentGetValue2=function(c,k) return component_values[c] and component_values[c][k] end
ComponentSetValue2=function(c,k,v) component_values[c]=component_values[c] or {}; component_values[c][k]=v end
ComponentGetMetaCustom=function(c,k) return component_meta[c] and component_meta[c][k] end
ComponentSetMetaCustom=function(c,k,v) component_meta[c]=component_meta[c] or {}; component_meta[c][k]=v end
ComponentHasTag=function() return false end
EntitySetComponentsWithTagEnabled=function() end
EntityGetFilename=function(e) return tostring(e)>=tostring(1000) and "data/entities/misc/perks/attack_foot/limb.xml" or "" end
EntityHasTag=function() return false end
EntityGetName=function(e) return e>=100 and "$perk_attack_foot" or "" end
EntityKill=kill
EntityLoad=function(path)
    next_entity=next_entity+1; local e=next_entity; alive[e]=true; children[e]={}; components[e]={}; return e
end
EntityCreateNew=function() return EntityLoad("") end
EntityAddComponent2=function(e,t,data)
    next_entity=next_entity+1; local c=next_entity+1000; component_type[c]=t; component_values[c]=data or {}; component_enabled[c]=true
    components[e]=components[e] or {}; table.insert(components[e],c); return c
end
EntityAddComponent=function(e,t) return EntityAddComponent2(e,t,{}) end
EntityRemoveComponent=function(e,c)
    if components[e] then for i=#components[e],1,-1 do if components[e][i]==c then table.remove(components[e],i) end end end
    component_type[c]=nil; component_values[c]=nil; component_meta[c]=nil; component_enabled[c]=nil
end
GameGetWorldStateEntity=function() return 0 end
GameGetFrameNum=(function() local f=100; return function() f=f+20; return f end end)()
GlobalsGetValue=function(k,d) local v=globals[k]; return v==nil and d or v end
GlobalsSetValue=function(k,v) globals[k]=tostring(v) end
GameHasFlagRun=function(k) return flags[k]==true end
GameAddFlagRun=function(k) flags[k]=true end
GameRemoveFlagRun=function(k) flags[k]=nil end
get_perk_picked_flag_name=function(id) return "PERK_PICKED_"..id end

local root_companions={supports=function() return false end,commit=function() end,update=function() end,on_count_zero=function() end,debug=function() return "" end}
local inverses={
 capture_pre_pickup=function() return true end,
 has=function(id) return id=="ATTACK_FOOT" end,
 post_tracked_cleanup=function() return true,"tracked" end,
 zero_cleanup=function(_,id) if id=="ATTACK_FOOT" then GlobalsSetValue("PLAYER_LUKKINESS_LEVEL","0"); GlobalsSetValue("LUKKI_PERK_TOTAL_COUNT","0") end; return true,"zero" end,
 maintenance_cleanup=function() return true end,
 can_fallback_after_stale_transaction=function() return false end,
}
local presentation={expire_one_game_effect=function() end,on_count_zero=function() end,update=function() end}
local ew_runtime={force_inventory_sync=function() end}
local catalog={all=function() return {
    {id="ATTACK_FOOT",stackable=true,func=function() end,ui_name="$perk_attack_foot"},
    {id="GAMBLE",stackable=true,func=function() end,ui_name="$perk_gamble"},
} end}
local locator={get=function() return player end}
dofile=function(path)
    if path=="mods/metamorph_creative_menu/files/features/perks/inverse_registry.lua" then return inverses end
    if path=="mods/metamorph_creative_menu/files/features/perks/root_companions.lua" then return root_companions end
    if path=="mods/metamorph_creative_menu/files/features/perks/presentation.lua" then return presentation end
    if path=="mods/metamorph_creative_menu/files/integrations/ew/runtime.lua" then return ew_runtime end
    if path=="mods/metamorph_creative_menu/files/features/perks/catalog.lua" then return catalog end
    if path=="mods/metamorph_creative_menu/files/platform/noita/player_locator.lua" then return locator end
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

local spawned_pickups={}
perk_spawn=function(_,_,id)
    local e=EntityLoad("data/entities/items/pickup/perk.xml")
    spawned_pickups[e]=id
    return e
end
local function apply_mock_lukki(who,count)
    local speed=ComponentGetMetaCustom(platform,"run_velocity")
    local vmax=math.abs(ComponentGetMetaCustom(platform,"velocity_max_x"))
    ComponentSetMetaCustom(platform,"run_velocity",speed*1.1)
    ComponentSetMetaCustom(platform,"velocity_min_x",-vmax*1.1)
    ComponentSetMetaCustom(platform,"velocity_max_x",vmax*1.1)
    ComponentSetValue2(platform,"pixel_gravity",0)
    GlobalsSetValue("PLAYER_LUKKINESS_LEVEL",tostring(count))
    GlobalsSetValue("LUKKI_PERK_TOTAL_COUNT",tostring(count))
    local limb=EntityLoad("data/entities/misc/perks/attack_foot/limb.xml")
    EntityAddChild(who,limb)
end
perk_pickup=function(perk_entity,who)
    local id=assert(spawned_pickups[perk_entity])
    local key="PERK_PICKED_"..id.."_PICKUP_COUNT"
    local count=(tonumber(GlobalsGetValue(key,"0")) or 0)+1
    GlobalsSetValue(key,tostring(count)); GameAddFlagRun("PERK_PICKED_"..id)
    if id=="ATTACK_FOOT" then
        apply_mock_lukki(who,count)
    elseif id=="GAMBLE" then
        -- Vanilla GAMBLE does not grant rewards in this call. It spawns a LuaComponent
        -- helper whose two real perk_pickup calls happen on a later frame. The test below
        -- reproduces that asynchronous boundary through the appended pickup hook.
    end
end

local service=assert(native_dofile(root.."/files/features/perks/service.lua"))
local perk={id="ATTACK_FOOT",stackable=true,func=function() end,ui_name="$perk_attack_foot"}

local function living_children()
    local n=0
    for e,p in pairs(parent) do if p==player and alive[e] then n=n+1 end end
    return n
end
local function assert_baseline(label)
    assert(service.count(perk.id)==0,label..": count")
    assert(math.abs(ComponentGetMetaCustom(platform,"run_velocity")-100)<1e-9,label..": run velocity")
    assert(math.abs(ComponentGetMetaCustom(platform,"velocity_min_x")+100)<1e-9,label..": min velocity")
    assert(math.abs(ComponentGetMetaCustom(platform,"velocity_max_x")-100)<1e-9,label..": max velocity")
    assert(ComponentGetValue2(platform,"pixel_gravity")==350,label..": gravity")
    assert(tonumber(GlobalsGetValue("PLAYER_LUKKINESS_LEVEL","0"))==0,label..": lukkiness")
    assert(tonumber(GlobalsGetValue("LUKKI_PERK_TOTAL_COUNT","0"))==0,label..": total")
    assert(living_children()==0,label..": child residue="..living_children())
end

for cycle=1,2 do
    for i=1,3 do
        local ok,reason,tracked=service.apply(player,perk,{ignore_debounce=true})
        assert(ok and tracked==true,"cycle "..cycle.." apply "..i.." failed: "..tostring(reason))
    end
    assert(service.count(perk.id)==3,"cycle "..cycle..": stack count")
    assert(math.abs(ComponentGetMetaCustom(platform,"run_velocity")-133.1)<1e-6,"cycle "..cycle..": stacked speed")
    assert(ComponentGetValue2(platform,"pixel_gravity")==0,"cycle "..cycle..": perk gravity")
    local removed,reason=service.remove_all(player,perk)
    assert(removed==3,"cycle "..cycle.." remove failed: "..tostring(reason))
    assert_baseline("cycle "..cycle)
end

-- GAMBLE grants two rewards asynchronously from perk_gamble_spawn.lua. They must be
-- joined to the older parent transaction even if the user later takes another copy of
-- the same reward before GAMBLE is removed.
METAMORPH_CREATIVE_MENU_PERK_PICKUP_HOOK_V2=nil
native_dofile(root.."/files/features/perks/pickup_hook.lua")
local gamble={id="GAMBLE",stackable=true,func=function() end,ui_name="$perk_gamble"}
local ok_gamble,reason_gamble,tracked_gamble=service.apply(player,gamble,{ignore_debounce=true})
assert(ok_gamble and tracked_gamble==true,"gamble apply failed: "..tostring(reason_gamble))
for reward_index=1,2 do
    local reward_entity=EntityLoad("data/entities/items/pickup/perk.xml")
    spawned_pickups[reward_entity]="ATTACK_FOOT"
    EntityAddComponent2(reward_entity,"VariableStorageComponent",{name="perk_id",value_string="ATTACK_FOOT"})
    perk_pickup(reward_entity,player,"",false,false)
end
assert(service.count("GAMBLE")==1 and service.count("ATTACK_FOOT")==2,"async nested reward counts were not applied")
assert(math.abs(ComponentGetMetaCustom(platform,"run_velocity")-121)<1e-6 and living_children()==2,"async nested reward mechanics missing")
-- New independent copy sits above both GAMBLE-owned rewards.
local ok_direct,reason_direct,tracked_direct=service.apply(player,perk,{ignore_debounce=true})
assert(ok_direct and tracked_direct==true,"direct reward copy failed: "..tostring(reason_direct))
assert(service.count("ATTACK_FOOT")==3 and living_children()==3,"independent reward copy missing")
local removed_gamble,remove_reason=service.remove_all(player,gamble)
assert(removed_gamble==1,"gamble remove failed: "..tostring(remove_reason))
assert(service.count("ATTACK_FOOT")==1,"GAMBLE did not retire exactly its two async rewards")
assert(living_children()==1,"GAMBLE removed wrong child ownership")
local removed_direct,direct_reason=service.remove_all(player,perk)
assert(removed_direct==1,"independent reward removal failed: "..tostring(direct_reason))
assert_baseline("gamble async nested rewards")

-- Ordinary vanilla/temple pickups are observed by the appended perk hook and must become
-- just as removable as perks taken through RMB in this menu.
local external_entity=EntityLoad("data/entities/items/pickup/perk.xml")
spawned_pickups[external_entity]="ATTACK_FOOT"
perk_pickup(external_entity,player,"ATTACK_FOOT",false,false)
assert(service.count("ATTACK_FOOT")==1,"external pickup count missing")
assert(ComponentGetValue2(platform,"pixel_gravity")==0 and living_children()==1,"external pickup mechanics missing")
local removed_external,external_reason=service.remove_all(player,perk)
assert(removed_external==1,"external pickup not removable: "..tostring(external_reason))
assert_baseline("external pickup")
print("perk_service_repeated_cycle=PASS same_user_path=true stacks=3 cycles=2 gravity=true locomotion=true children=true globals=true async_nested_rewards=true exact_parent_ownership=true external_pickup_removal=true")
