local root=assert(arg[1])
local native_dofile=dofile
local sync_calls=0

dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/integrations/ew/runtime.lua' then
  return {force_inventory_sync=function() sync_calls=sync_calls+1 end}
 end
 if path=='mods/metamorph_creative_menu/files/integrations/ew/world_items.lua' then
  return {notify_world_item=function() return true,'direct' end}
 end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end

local alive={[1]=true,[2]=true,[10]=true,[3]=true,[4]=true,[20]=true,[21]=true}
local parent={[1]=0,[2]=0,[10]=1,[3]=2,[4]=2,[20]=10,[21]=10}
local children={[1]={10},[2]={3,4},[10]={20,21},[3]={},[4]={},[20]={},[21]={}}
local names={[1]='player',[2]='wand',[10]='inventory_full'}
local component_owner={}
local component_type={}
local fields={}
local objects={}

local function add_component(entity,id,kind,data)
 component_owner[id]=entity; component_type[id]=kind; fields[id]=data or {}
end
add_component(1,11,'Inventory2Component',{full_inventory_slots_x=4,full_inventory_slots_y=1,quick_inventory_slots=4,mForceRefresh=false})
add_component(2,12,'AbilityComponent',{use_gun_script=true,mana=50,mana_max=100,mana_charge_speed=10})
objects[12]={deck_capacity=2}
add_component(3,31,'ItemComponent',{permanently_attached=false,inventory_slot={0,0},uses_remaining=7,is_frozen=false})
add_component(3,32,'ItemActionComponent',{action_id='A'})
add_component(4,41,'ItemComponent',{permanently_attached=false,inventory_slot={1,0},uses_remaining=5,is_frozen=false})
add_component(4,42,'ItemActionComponent',{action_id='B'})
add_component(20,201,'ItemComponent',{permanently_attached=false,inventory_slot={0,0},uses_remaining=3,is_frozen=true})
add_component(20,202,'ItemActionComponent',{action_id='X'})
add_component(21,211,'ItemComponent',{permanently_attached=false,inventory_slot={1,0},uses_remaining=2,is_frozen=false})
add_component(21,212,'ItemActionComponent',{action_id='Y'})

EntityGetIsAlive=function(entity) return alive[entity]==true end
EntityGetAllChildren=function(entity)
 local out={}
 for _,child in ipairs(children[entity] or {}) do if alive[child] then out[#out+1]=child end end
 return out
end
EntityGetFirstComponentIncludingDisabled=function(entity,kind)
 for id,owner in pairs(component_owner) do if owner==entity and component_type[id]==kind then return id end end
 return 0
end
ComponentGetValue2=function(component,field)
 local value=fields[component] and fields[component][field]
 if type(value)=='table' then return value[1],value[2] end
 return value
end
ComponentSetValue2=function(component,field,a,b)
 fields[component]=fields[component] or {}
 if b~=nil then fields[component][field]={a,b} else fields[component][field]=a end
end
ComponentObjectGetValue2=function(component,object,field) return objects[component] and objects[component][field] end
ComponentObjectSetValue2=function(component,object,field,value) objects[component]=objects[component] or {}; objects[component][field]=value end
EntityGetName=function(entity) return names[entity] or '' end
EntityGetParent=function(entity) return parent[entity] or 0 end
EntityGetRootEntity=function(entity)
 local current=entity
 for _=1,16 do local p=parent[current] or 0; if p==0 then return current end; current=p end
 return current
end
EntityHasTag=function() return false end
EntityRemoveFromParent=function(entity)
 local old=parent[entity] or 0
 if old~=0 then
  for i=#(children[old] or {}),1,-1 do if children[old][i]==entity then table.remove(children[old],i) end end
 end
 parent[entity]=0
end
EntityAddChild=function(new_parent,entity)
 EntityRemoveFromParent(entity)
 parent[entity]=new_parent
 children[new_parent]=children[new_parent] or {}
 children[new_parent][#children[new_parent]+1]=entity
end
EntityKill=function(entity) alive[entity]=false end
EntitySetComponentsWithTagEnabled=function() end
EntityGetTransform=function() return 100,200 end
EntitySetTransform=function() end
GameRegenItemActionsInContainer=function() end
GameRegenItemActionsInPlayer=function() end
CreateItemActionEntity=function() return 0 end
ModTextFileGetContent=function() return '' end

local inventory_service=assert(native_dofile(root..'/files/features/spells/inventory_service.lua'))
local spell_service=assert(native_dofile(root..'/files/features/spells/service.lua'))

local inv=assert(inventory_service.contents(1))
assert(inv.capacity==4 and inv.by_index[0].action_id=='X' and inv.by_index[1].action_id=='Y','spell inventory snapshot changed')
local source_x=inv.by_index[0]
assert(inventory_service.move(1,source_x,2)==true,'move to empty inventory slot failed')
inv=assert(inventory_service.contents(1))
assert(inv.by_index[2].action_id=='X' and inv.by_index[0]==nil,'exact inventory move used wrong slot')
assert(inventory_service.move(1,inv.by_index[2],1)==true,'inventory swap failed')
inv=assert(inventory_service.contents(1))
assert(inv.by_index[1].action_id=='X' and inv.by_index[2].action_id=='Y','inventory occupied drop did not swap')

local wand_slots,_,_,wand_entries=spell_service.contents(2)
local x=inv.by_index[1]
assert(spell_service.adopt_inventory(1,2,x,0,wand_slots[0],wand_entries)==true,'inventory->wand occupied swap failed')
assert(parent[20]==2 and fields[201].inventory_slot[1]==0,'inventory source was not moved into exact wand slot')
assert(parent[3]==10 and fields[31].inventory_slot[1]==1,'replaced wand card was not returned to source inventory slot')
assert(fields[201].uses_remaining==3 and fields[201].is_frozen==true,'inventory card runtime state was lost')

wand_slots,_,_,wand_entries=spell_service.contents(2)
assert(spell_service.export_to_inventory_slot(1,2,wand_slots[0],wand_entries,3,0)==true,'wand->empty inventory slot failed')
assert(parent[20]==10 and fields[201].inventory_slot[1]==3,'wand export did not use requested inventory slot')
assert(fields[201].uses_remaining==3 and fields[201].is_frozen==true,'wand export changed card runtime state')

inv=assert(inventory_service.contents(1))
wand_slots,_,_,wand_entries=spell_service.contents(2)
local inv_a=inv.by_index[1]
local wand_b=wand_slots[1]
assert(inv_a and inv_a.action_id=='A' and wand_b and wand_b.action_id=='B','reverse swap setup invalid')
assert(spell_service.adopt_inventory(1,2,inv_a,1,wand_b,wand_entries)==true,'occupied inventory<->wand reverse swap failed')
assert(parent[3]==2 and fields[31].inventory_slot[1]==1,'inventory card did not enter wand')
assert(parent[4]==10 and fields[41].inventory_slot[1]==1,'wand card did not return to exact inventory slot')
assert(sync_calls>=5,'transfers did not request inventory synchronization')

print('spell_inventory_transfer=PASS exact_slots=true inventory_swap=true cross_swap=true entity_identity=true entity_state=true')
