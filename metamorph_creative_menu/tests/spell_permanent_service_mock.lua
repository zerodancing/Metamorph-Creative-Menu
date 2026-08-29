local root=assert(arg[1])
local native_dofile=dofile
local sync_calls=0
local world_notified={}

dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/integrations/ew/runtime.lua' then
  return {force_inventory_sync=function() sync_calls=sync_calls+1 end}
 end
 if path=='mods/metamorph_creative_menu/files/integrations/ew/world_items.lua' then
  return {notify_world_item=function(entity) world_notified[#world_notified+1]=entity; return true,'direct' end}
 end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end

local alive={[1]=true,[2]=true,[10]=true,[3]=true,[4]=true,[20]=true}
local parent={[1]=0,[2]=0,[10]=1,[3]=2,[4]=2,[20]=10}
local children={[1]={10},[2]={3,4},[10]={20},[3]={},[4]={},[20]={}}
local names={[1]='player',[2]='wand',[10]='inventory_full'}
local component_owner={}
local component_type={}
local fields={}
local objects={}
local fail_capacity_write=false

local function add_component(entity,id,kind,data)
 component_owner[id]=entity; component_type[id]=kind; fields[id]=data or {}
end
add_component(1,11,'Inventory2Component',{full_inventory_slots_x=4,full_inventory_slots_y=1,quick_inventory_slots=4,mForceRefresh=false,mActiveItem=2})
add_component(2,12,'AbilityComponent',{use_gun_script=true,mana=50,mana_max=100,mana_charge_speed=10})
objects[12]={deck_capacity=3}
add_component(3,31,'ItemComponent',{permanently_attached=false,inventory_slot={0,0},uses_remaining=7,is_frozen=false})
add_component(3,32,'ItemActionComponent',{action_id='A'})
add_component(4,41,'ItemComponent',{permanently_attached=true,inventory_slot={-1,-1},uses_remaining=5,is_frozen=true})
add_component(4,42,'ItemActionComponent',{action_id='P'})
add_component(20,201,'ItemComponent',{permanently_attached=false,inventory_slot={0,0},uses_remaining=3,is_frozen=true})
add_component(20,202,'ItemActionComponent',{action_id='X'})

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
ComponentObjectSetValue2=function(component,object,field,value)
 if fail_capacity_write and field=='deck_capacity' then return end
 objects[component]=objects[component] or {}; objects[component][field]=value
end
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
 if old~=0 then for i=#(children[old] or {}),1,-1 do if children[old][i]==entity then table.remove(children[old],i) end end end
 parent[entity]=0
end
EntityAddChild=function(new_parent,entity)
 EntityRemoveFromParent(entity); parent[entity]=new_parent; children[new_parent]=children[new_parent] or {}; children[new_parent][#children[new_parent]+1]=entity
end
EntityKill=function(entity) alive[entity]=false end
EntitySetComponentsWithTagEnabled=function() end
EntityGetTransform=function() return 100,200 end
EntitySetTransform=function() end
GameRegenItemActionsInContainer=function() end
GameRegenItemActionsInPlayer=function() end
GamePickUpInventoryItem=function(player,entity)
 -- The tested exact-placement path does not depend on this, but generic inventory does.
 local inv=10; EntityAddChild(inv,entity)
end
ModTextFileGetContent=function() return '' end

local next_entity=30
CreateItemActionEntity=function(action_id)
 local entity=next_entity; next_entity=next_entity+1
 alive[entity]=true; parent[entity]=0; children[entity]={}
 local item=entity*10+1; local action=entity*10+2
 add_component(entity,item,'ItemComponent',{permanently_attached=false,inventory_slot={-1,-1},uses_remaining=9,is_frozen=false})
 add_component(entity,action,'ItemActionComponent',{action_id=action_id})
 return entity
end

local spell_service=assert(native_dofile(root..'/files/features/spells/service.lua'))
local permanent_service=assert(native_dofile(root..'/files/features/spells/permanent_service.lua'))
local inventory_service=assert(native_dofile(root..'/files/features/spells/inventory_service.lua'))

local slots,highest,permanent,entries,permanent_entries=spell_service.contents(2)
assert(permanent==1 and #permanent_entries==1 and permanent_entries[1].action_id=='P','permanent action enumeration failed')
assert(spell_service.capacity(2,highest,permanent)==2,'effective capacity must exclude Always Cast actions')

-- Promotion grows raw capacity by one, preserving the number of ordinary slots.
local normal=slots[0]
assert(permanent_service.promote(1,2,normal)==true,'promote failed')
assert(fields[31].permanently_attached==true and fields[31].inventory_slot[1]==-1,'promote did not mark card permanent')
assert(objects[12].deck_capacity==4,'promote did not preserve effective capacity')
slots,highest,permanent,entries,permanent_entries=spell_service.contents(2)
assert(permanent==2 and spell_service.capacity(2,highest,permanent)==2,'promotion changed ordinary capacity')

-- Demotion reverses the raw-capacity increment and restores an ordinary slot.
local promoted
for _,entry in ipairs(permanent_entries) do if entry.action_id=='A' then promoted=entry end end
assert(promoted and permanent_service.demote(1,2,promoted,0)==true,'demote failed')
assert(fields[31].permanently_attached==false and fields[31].inventory_slot[1]==0,'demote did not restore card slot')
assert(objects[12].deck_capacity==3,'demote did not restore raw capacity')

-- Swapping a normal card with an Always Cast card keeps raw capacity exactly unchanged.
slots,highest,permanent,entries,permanent_entries=spell_service.contents(2)
local perm_p=permanent_entries[1]
local raw_before_swap=objects[12].deck_capacity
assert(permanent_service.swap_with_slot(1,2,perm_p,slots[0])==true,'Always Cast/slot swap failed')
assert(objects[12].deck_capacity==raw_before_swap,'role swap changed raw capacity')
assert(fields[41].permanently_attached==false and fields[41].inventory_slot[1]==0,'old permanent did not become normal')
assert(fields[31].permanently_attached==true,'old normal did not become permanent')

-- Catalog add and replacement preserve progression-neutral card creation semantics while
-- maintaining the raw-capacity invariant.
local raw_before_add=objects[12].deck_capacity
local add_ok,_,added_entity=permanent_service.add(1,2,'Q')
assert(add_ok and alive[added_entity] and objects[12].deck_capacity==raw_before_add+1,'Always Cast add failed')
slots,highest,permanent,entries,permanent_entries=spell_service.contents(2)
local q
for _,entry in ipairs(permanent_entries) do if entry.action_id=='Q' then q=entry end end
local raw_before_replace=objects[12].deck_capacity
assert(q and permanent_service.replace(1,2,q,'R')==true,'Always Cast replacement failed')
assert(objects[12].deck_capacity==raw_before_replace,'Always Cast replacement changed capacity')

-- Inventory -> Always Cast moves the exact entity, preserving mutable/custom-like state.
local inv=assert(inventory_service.contents(1))
local inv_x=inv.by_index[0]
local raw_before_adopt=objects[12].deck_capacity
assert(permanent_service.adopt_inventory(1,2,inv_x)==true,'inventory->Always Cast failed')
assert(parent[20]==2 and fields[201].permanently_attached==true,'inventory entity was cloned/lost instead of promoted')
assert(fields[201].uses_remaining==3 and fields[201].is_frozen==true,'inventory card runtime state changed')
assert(objects[12].deck_capacity==raw_before_adopt+1,'inventory promotion changed ordinary capacity')

-- Exporting the same permanent entity to an exact empty spell-inventory slot reverses raw capacity.
slots,highest,permanent,entries,permanent_entries=spell_service.contents(2)
local perm_x
for _,entry in ipairs(permanent_entries) do if entry.entity==20 then perm_x=entry end end
local raw_before_export=objects[12].deck_capacity
assert(perm_x and permanent_service.export_to_inventory_slot(1,2,perm_x,2,0)==true,'Always Cast exact inventory export failed')
assert(parent[20]==10 and fields[201].inventory_slot[1]==2 and fields[201].permanently_attached==false,'permanent export did not preserve exact entity/slot')
assert(objects[12].deck_capacity==raw_before_export-1,'permanent export did not restore raw capacity')

-- A failed capacity write must rollback the card itself; no half-promoted state is allowed.
slots,highest,permanent,entries,permanent_entries=spell_service.contents(2)
local regular_p=slots[0]
assert(regular_p and regular_p.action_id=='P','fault setup lost normal spell')
local old_slot=fields[regular_p.item_component].inventory_slot[1]
local raw_fault=objects[12].deck_capacity
fail_capacity_write=true
local fault_ok=permanent_service.promote(1,2,regular_p)
fail_capacity_write=false
assert(fault_ok==false,'failed capacity write reported successful promote')
assert(fields[regular_p.item_component].permanently_attached==false and fields[regular_p.item_component].inventory_slot[1]==old_slot,'failed promote did not rollback card metadata')
assert(objects[12].deck_capacity==raw_fault,'failed promote changed raw capacity')

assert(sync_calls>=6,'Always Cast operations did not refresh inventory/EW state')
print('spell_permanent_service=PASS enumerate=true capacity_invariant=true promote_demote=true role_swap=true exact_entity=true rollback=true')
