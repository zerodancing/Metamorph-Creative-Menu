local root=assert(arg[1],"root")
METAMORPH_CREATIVE_MENU_PERK_TRANSACTIONS=nil

local alive={}
local parents={}
local children={}
local components={}
local component_types={}
local values={}
local meta={}
local enabled={}
local filenames={}
local names={}
local next_entity=100
local next_component=1000

local function make_entity(id,filename,name)
    alive[id]=true; children[id]={}; components[id]={}; filenames[id]=filename or ""; names[id]=name or ""
    return id
end
local function make_component(entity_id,id,component_type,member_values,meta_values)
    component_types[id]=component_type; values[id]=member_values or {}; meta[id]=meta_values or {}; enabled[id]=true
    components[entity_id]=components[entity_id] or {}; table.insert(components[entity_id],id); return id
end
local function add_child(parent,child)
    local old=parents[child] or 0
    if old~=0 and children[old] then for i=#children[old],1,-1 do if children[old][i]==child then table.remove(children[old],i) end end end
    parents[child]=parent
    children[parent]=children[parent] or {}; table.insert(children[parent],child)
end
local function kill(entity_id)
    if not alive[entity_id] then return end
    for _,child in ipairs(children[entity_id] or {}) do kill(child) end
    alive[entity_id]=false
    local old=parents[entity_id] or 0
    if old~=0 and children[old] then for i=#children[old],1,-1 do if children[old][i]==entity_id then table.remove(children[old],i) end end end
    parents[entity_id]=0
end

local old_player=make_entity(1,"data/entities/player.xml","$player")
local old_platform=make_component(old_player,10,"CharacterPlatformingComponent",{pixel_gravity=350},{run_velocity=100,velocity_min_x=-100,velocity_max_x=100})

EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetParent=function(e) return parents[e] or 0 end
EntityGetRootEntity=function(e) local r=e; while (parents[r] or 0)~=0 do r=parents[r] end; return r end
EntityGetAllChildren=function(e) local out={}; for _,c in ipairs(children[e] or {}) do if alive[c] then out[#out+1]=c end end; return out end
EntityGetAllComponents=function(e) return components[e] or {} end
EntityGetComponentIncludingDisabled=function(e,t) local out={}; for _,c in ipairs(components[e] or {}) do if component_types[c]==t then out[#out+1]=c end end; return out end
EntityGetFirstComponentIncludingDisabled=function(e,t) return (EntityGetComponentIncludingDisabled(e,t) or {})[1] end
EntityGetFilename=function(e) return filenames[e] or "" end
EntityGetName=function(e) return names[e] or "" end
EntityAddChild=function(p,c) add_child(p,c) end
EntityRemoveFromParent=function(c) local old=parents[c] or 0; if old~=0 and children[old] then for i=#children[old],1,-1 do if children[old][i]==c then table.remove(children[old],i) end end end; parents[c]=0 end
EntityKill=kill
EntityCreateNew=function(name) next_entity=next_entity+1; return make_entity(next_entity,"",name) end
EntityLoad=function(path) next_entity=next_entity+1; return make_entity(next_entity,path,"") end
EntityAddComponent2=function(e,t,data) next_component=next_component+1; return make_component(e,next_component,t,data or {},{}) end
EntityAddComponent=function(e,t,data) return EntityAddComponent2(e,t,data) end
EntityRemoveComponent=function(e,c) for i=#(components[e] or {}),1,-1 do if components[e][i]==c then table.remove(components[e],i) end end; component_types[c]=nil; values[c]=nil; meta[c]=nil; enabled[c]=nil end
EntitySetComponentsWithTagEnabled=function() end
ComponentGetTypeName=function(c) return component_types[c] or "" end
ComponentGetMembers=function(c) local out={}; for k in pairs(values[c] or {}) do out[k]=true end; return out end
ComponentGetValue=function(c,k) local v=values[c] and values[c][k]; return v==nil and "" or tostring(v) end
ComponentSetValue=function(c,k,v) values[c]=values[c] or {}; values[c][k]=tonumber(v) or v end
ComponentGetValue2=function(c,k) return values[c] and values[c][k] end
ComponentSetValue2=function(c,k,v) values[c]=values[c] or {}; values[c][k]=v end
ComponentGetMetaCustom=function(c,k) return meta[c] and meta[c][k] end
ComponentSetMetaCustom=function(c,k,v) meta[c]=meta[c] or {}; meta[c][k]=v end
ComponentGetIsEnabled=function(c) return enabled[c]==true end
EntitySetComponentIsEnabled=function(_,c,v) enabled[c]=v==true end
GameGetWorldStateEntity=function() return 0 end
GlobalsGetValue=function(_,d) return d end
GlobalsSetValue=function() end
GameHasFlagRun=function() return false end
GameAddFlagRun=function() end
GameRemoveFlagRun=function() end

local native_dofile=dofile
dofile=function(path)
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

local transactions=assert(native_dofile(root.."/files/features/perks/transactions.lua"))

local function take_stack(stack_index)
    local token=assert(transactions.begin(old_player,"ATTACK_FOOT"))
    assert(transactions.start_capture(token,_G))
    ComponentSetMetaCustom(old_platform,"run_velocity",ComponentGetMetaCustom(old_platform,"run_velocity")*1.1)
    ComponentSetMetaCustom(old_platform,"velocity_min_x",ComponentGetMetaCustom(old_platform,"velocity_min_x")*1.1)
    ComponentSetMetaCustom(old_platform,"velocity_max_x",ComponentGetMetaCustom(old_platform,"velocity_max_x")*1.1)
    ComponentSetValue2(old_platform,"pixel_gravity",0)
    local limb=EntityLoad("data/entities/misc/perks/attack_foot/limb.xml")
    EntityAddChild(old_player,limb)
    transactions.stop_capture(token)
    local ok,reason=transactions.commit(token)
    assert(ok,"commit stack "..stack_index.." failed: "..tostring(reason))
end

take_stack(1)
take_stack(2)
assert(math.abs(ComponentGetMetaCustom(old_platform,"run_velocity")-121)<1e-6,"old player stack setup")
assert(#EntityGetAllChildren(old_player)==2,"old player children setup")

-- Simulate NoitaPatcher polymorph-backup deserialization: the whole attached human tree
-- comes back with fresh entity/component ids but the same semantic layout and post-perk values.
local new_player=make_entity(2,"data/entities/player.xml","$player")
local new_platform=make_component(new_player,20,"CharacterPlatformingComponent",{pixel_gravity=0},{run_velocity=121,velocity_min_x=-121,velocity_max_x=121})
local new_limb1=make_entity(201,"data/entities/misc/perks/attack_foot/limb.xml","")
local new_limb2=make_entity(202,"data/entities/misc/perks/attack_foot/limb.xml","")
add_child(new_player,new_limb1); add_child(new_player,new_limb2)
kill(old_player)

local rebound,reason,count,unresolved=transactions.rebind_player(old_player,new_player)
assert(rebound,"rebind failed: "..tostring(reason).." rebound="..tostring(count).." unresolved="..tostring(unresolved))
assert(count==2 and unresolved==0,"both stack deltas must rebind")
assert(transactions.has("ATTACK_FOOT",new_player),"history still belongs to old player")

local ok2,reason2=transactions.revert("ATTACK_FOOT",new_player)
assert(ok2,"top stack remove after rebind failed: "..tostring(reason2))
assert(math.abs(ComponentGetMetaCustom(new_platform,"run_velocity")-110)<1e-6,"top stack locomotion restore")
assert(ComponentGetValue2(new_platform,"pixel_gravity")==0,"first stack must still own zero gravity")
local live_children=EntityGetAllChildren(new_player)
assert(#live_children==1,"top stack must remove exactly one serialized child")

local ok1,reason1=transactions.revert("ATTACK_FOOT",new_player)
assert(ok1,"final stack remove after rebind failed: "..tostring(reason1))
assert(math.abs(ComponentGetMetaCustom(new_platform,"run_velocity")-100)<1e-6,"final locomotion baseline")
assert(math.abs(ComponentGetMetaCustom(new_platform,"velocity_min_x")+100)<1e-6,"final min velocity baseline")
assert(math.abs(ComponentGetMetaCustom(new_platform,"velocity_max_x")-100)<1e-6,"final max velocity baseline")
assert(ComponentGetValue2(new_platform,"pixel_gravity")==350,"final gravity baseline")
assert(#EntityGetAllChildren(new_player)==0,"serialized perk children survived final removal")
print("perk_player_rebind=PASS stacks=2 new_ids=true locomotion=true gravity=true serialized_children=true")
