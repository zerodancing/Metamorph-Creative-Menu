local root=assert(arg[1])
local native_dofile=dofile
local sync_calls=0
local frame=1
local regen_calls=0
local sentinel_create_count=0
local sentinel_kill_count=0
local fail_slot_write=nil
local fail_real_pickup_once=false
local bridge=nil

-- The real-game regression only affects already-registered spell entities. The full build
-- now serializes those cards, creates a fresh ECS entity, and then sends that fresh card
-- through the same exact native pickup transaction that already works for catalog cards.
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/integrations/ew/runtime.lua' then
  return {force_inventory_sync=function() sync_calls=sync_calls+1 end}
 end
 if path=='mods/metamorph_creative_menu/files/integrations/ew/world_items.lua' then
  return {notify_world_item=function() return true,'direct' end}
 end
 if path=='mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua' then
  return {get=function() return bridge end}
 end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end

local alive={[1]=true,[2]=true,[10]=true,[3]=true,[4]=true,[20]=true,[21]=true}
local parent={[1]=0,[2]=0,[10]=1,[3]=2,[4]=2,[20]=10,[21]=10}
local children={[1]={10},[2]={3,4},[10]={20,21},[3]={},[4]={},[20]={},[21]={}}
local names={[1]='player',[2]='wand',[10]='inventory_full'}
local tags={}
local component_owner={}
local component_type={}
local fields={}
local objects={}
local next_entity=1000
local next_component=10000

local function copy(value)
 if type(value)~='table' then return value end
 local out={}
 for k,v in pairs(value) do out[k]=copy(v) end
 return out
end

local function add_component(entity,id,kind,data)
 component_owner[id]=entity; component_type[id]=kind; fields[id]=data or {}
end
local function new_component(entity,kind,data)
 local id=next_component; next_component=next_component+1
 add_component(entity,id,kind,data)
 return id
end
add_component(1,11,'Inventory2Component',{full_inventory_slots_x=4,full_inventory_slots_y=1,quick_inventory_slots=4,mForceRefresh=false})
add_component(2,12,'AbilityComponent',{use_gun_script=true,mana=50,mana_max=100,mana_charge_speed=10})
objects[12]={deck_capacity=2}
add_component(3,31,'ItemComponent',{permanently_attached=false,inventory_slot={0,0},uses_remaining=7,is_frozen=false,mItemUid=301,mFramePickedUp=31,has_been_picked_by_player=true})
add_component(3,32,'ItemActionComponent',{action_id='A'})
add_component(4,41,'ItemComponent',{permanently_attached=false,inventory_slot={1,0},uses_remaining=5,is_frozen=false,mItemUid=401,mFramePickedUp=41,has_been_picked_by_player=true})
add_component(4,42,'ItemActionComponent',{action_id='B'})
add_component(20,201,'ItemComponent',{permanently_attached=false,inventory_slot={0,0},uses_remaining=3,is_frozen=true,mItemUid=2001,mFramePickedUp=201,has_been_picked_by_player=true})
add_component(20,202,'ItemActionComponent',{action_id='X'})
add_component(21,211,'ItemComponent',{permanently_attached=false,inventory_slot={1,0},uses_remaining=2,is_frozen=false,mItemUid=2101,mFramePickedUp=211,has_been_picked_by_player=true})
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
 if field=='inventory_slot' and fail_slot_write and fail_slot_write.component==component and fail_slot_write.x==a then
  fail_slot_write=nil; error('injected slot write failure')
 end
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
EntityAddTag=function(entity,tag) tags[entity]=tags[entity] or {}; tags[entity][tag]=true end
EntityHasTag=function(entity,tag) return tags[entity]~=nil and tags[entity][tag]==true end
EntityRemoveFromParent=function(entity)
 local old=parent[entity] or 0
 if old~=0 then for i=#(children[old] or {}),1,-1 do if children[old][i]==entity then table.remove(children[old],i) end end end
 parent[entity]=0
end
EntityAddChild=function(new_parent,entity)
 EntityRemoveFromParent(entity)
 parent[entity]=new_parent
 children[new_parent]=children[new_parent] or {}
 children[new_parent][#children[new_parent]+1]=entity
end
EntityKill=function(entity)
 EntityRemoveFromParent(entity)
 alive[entity]=false
end
EntityCreateNew=function()
 local entity=next_entity; next_entity=next_entity+1
 alive[entity]=true; parent[entity]=0; children[entity]={}; names[entity]=''; tags[entity]={}
 return entity
end
EntitySetComponentsWithTagEnabled=function() end
EntityGetTransform=function() return 100,200 end
EntitySetTransform=function() end
GameGetFrameNum=function() return frame end
GameRegenItemActionsInContainer=function() regen_calls=regen_calls+1 end
GameRegenItemActionsInPlayer=function() regen_calls=regen_calls+1 end
ModTextFileGetContent=function() return '' end

bridge={
 SerializeEntity=function(entity)
  local item=EntityGetFirstComponentIncludingDisabled(entity,'ItemComponent')
  local action=EntityGetFirstComponentIncludingDisabled(entity,'ItemActionComponent')
  assert(item~=0 and action~=0,'serialize missing spell components')
  return {item=copy(fields[item]), action=copy(fields[action]), tags=copy(tags[entity] or {})}
 end,
 DeserializeEntity=function(entity,data)
  new_component(entity,'ItemComponent',copy(data.item))
  new_component(entity,'ItemActionComponent',copy(data.action))
  tags[entity]=copy(data.tags or {})
 end,
}

local function make_action(action_id)
 local entity=EntityCreateNew()
 new_component(entity,'ItemComponent',{permanently_attached=false,inventory_slot={-1,-1},uses_remaining=-1,is_frozen=false,mItemUid=0,mFramePickedUp=0})
 new_component(entity,'ItemActionComponent',{action_id=action_id})
 return entity
end
CreateItemActionEntity=function(action_id)
 sentinel_create_count=sentinel_create_count+1
 return make_action(action_id)
end

local function first_free_spell_slot(inventory)
 local occupied={}
 for _,child in ipairs(EntityGetAllChildren(inventory) or {}) do
  local action=EntityGetFirstComponentIncludingDisabled(child,'ItemActionComponent')
  local item=EntityGetFirstComponentIncludingDisabled(child,'ItemComponent')
  if action~=0 and item~=0 then
   local x,y=ComponentGetValue2(item,'inventory_slot')
   x=tonumber(x); y=tonumber(y) or 0
   if x~=nil and x>=0 and x<4 and y==0 then occupied[x]=true end
  end
 end
 for x=0,3 do if not occupied[x] then return x,0 end end
 return nil,nil
end

-- Deliberately model the hostile native behavior from the game: preferred inventory_slot is
-- ignored for a picked card and the private InventoryComponent registration chooses the first
-- free spell cell. Sentinel isolation is therefore meaningful in this test.
GamePickUpInventoryItem=function(player_entity,entity)
 local sentinel=EntityHasTag(entity,'metamorph_creative_menu_inventory_sentinel')
 if fail_real_pickup_once and not sentinel then fail_real_pickup_once=false; return false end
 local x,y=first_free_spell_slot(10)
 if x==nil then return false end
 local item=EntityGetFirstComponentIncludingDisabled(entity,'ItemComponent')
 ComponentSetValue2(item,'inventory_slot',x,y)
 -- A real pickup assigns fresh registration history; this is exactly what a rehydrated card
 -- needs instead of carrying the wand's stale native identity into inventory_full.
 ComponentSetValue2(item,'mItemUid',entity*10+1)
 ComponentSetValue2(item,'mFramePickedUp',frame)
 EntityAddChild(10,entity)
 return true
end
GameKillInventoryItem=function(player_entity,entity)
 if EntityHasTag(entity,'metamorph_creative_menu_inventory_sentinel') then sentinel_kill_count=sentinel_kill_count+1 end
 EntityKill(entity)
 return true
end

local inventory_service=assert(native_dofile(root..'/files/features/spells/inventory_service.lua'))
local spell_service=assert(native_dofile(root..'/files/features/spells/service.lua'))

local function inv_entry(action_id)
 local inv=assert(inventory_service.contents(1))
 for _,entry in ipairs(inv.entries) do if entry.action_id==action_id then return entry,inv end end
 return nil,inv
end
local function wand_entry(action_id)
 local slots,_,_,entries=spell_service.contents(2)
 for _,entry in pairs(slots or {}) do if entry and entry.action_id==action_id then return entry,slots,entries end end
 for _,entry in ipairs(entries or {}) do if entry.action_id==action_id then return entry,slots,entries end end
 return nil,slots,entries
end
local function assert_state(entry,uses,frozen,label)
 assert(entry and EntityGetIsAlive(entry.entity),label..' missing')
 local item=entry.item_component
 assert(ComponentGetValue2(item,'uses_remaining')==uses and ComponentGetValue2(item,'is_frozen')==frozen,label..' runtime state changed')
end

local x,inv=inv_entry('X')
assert(inv.capacity==4 and x.index==0,'spell inventory snapshot changed')
local old_x_entity=x.entity
assert(inventory_service.move(1,x,2)==true,'move to empty inventory slot failed')
x,inv=inv_entry('X')
assert(x.index==2 and inv.by_index[0]==nil,'rehydrated inventory move used wrong slot')
assert(x.entity~=old_x_entity and not EntityGetIsAlive(old_x_entity),'registered card was not rehydrated into a fresh entity')
assert_state(x,3,true,'rehydrated X')
assert(sentinel_create_count>0 and sentinel_kill_count==sentinel_create_count,'fresh exact pickup did not clean sentinels')

-- A delayed native packing pass must rehydrate the current registered card again and return it
-- to the requested cell rather than trying another direct inventory_slot write.
local drift_entity=x.entity
ComponentSetValue2(x.item_component,'inventory_slot',3,0)
frame=frame+1
local sentinels_before=sentinel_create_count
local repaired=select(1,spell_service.settle_slots())
assert(repaired==1,'next-frame slot settle did not report a repair')
x=assert(inv_entry('X'))
assert(x.index==2 and x.entity~=drift_entity and not EntityGetIsAlive(drift_entity),'next-frame repair did not use fresh native registration')
assert(sentinel_create_count>sentinels_before,'deferred repair did not use exact native pickup')
assert_state(x,3,true,'settled X')

-- Occupied inventory drops are collision-safe swaps. Entity ids may change deliberately, but
-- action identity and runtime card state must survive full serialization.
local y=assert(inv_entry('Y'))
assert(inventory_service.move(1,x,1)==true,'inventory swap failed')
x,inv=inv_entry('X'); y=assert(inv_entry('Y'))
assert(x.index==1 and y.index==2,'inventory occupied drop did not swap exact cells')
assert_state(x,3,true,'swapped X'); assert_state(y,2,false,'swapped Y')

-- Inject one failed native registration. Rehydration must restore logical cards and their prior
-- exact positions even though rollback necessarily gets new entity ids as well.
fail_real_pickup_once=true
assert(inventory_service.move(1,x,2)==false,'injected native pickup failure reported success')
x,inv=inv_entry('X'); y=assert(inv_entry('Y'))
assert(x.index==1 and y.index==2,'failed exact swap did not restore prior slots')
assert_state(x,3,true,'rollback X'); assert_state(y,2,false,'rollback Y')

-- Cross-surface transfer is the user-reported case: inventory -> wand and then the same card
-- back from wand -> a distant exact inventory cell. The latter must discard the wand's native
-- registration and return a freshly deserialized card through GamePickUpInventoryItem.
local wand_a,wand_slots,wand_entries=wand_entry('A')
assert(spell_service.adopt_inventory(1,2,x,0,wand_a,wand_entries)==true,'inventory->wand occupied swap failed')
x=assert(wand_entry('X'))
local a=assert(inv_entry('A'))
assert(x.slot==0 and a.index==1,'inventory->wand swap exact positions wrong')
assert_state(x,3,true,'wand X'); assert_state(a,7,false,'inventory A')

local wand_x,slots_after,entries_after=wand_entry('X')
local wand_x_old=wand_x.entity
assert(spell_service.export_to_inventory_slot(1,2,wand_x,entries_after,3,0)==true,'wand->distant inventory slot failed')
x=assert(inv_entry('X'))
assert(x.index==3,'wand export did not land in requested inventory cell')
assert(x.entity~=wand_x_old and not EntityGetIsAlive(wand_x_old),'wand card retained stale registered entity id')
assert_state(x,3,true,'exported X')

-- Reverse occupied cross-surface swap still works with the replacement ids returned by exact
-- inventory placement.
a=assert(inv_entry('A'))
local b,slots_b,entries_b=wand_entry('B')
assert(a and a.index==1 and b and b.slot==1,'reverse swap setup invalid')
assert(spell_service.adopt_inventory(1,2,a,1,b,entries_b)==true,'occupied inventory<->wand reverse swap failed')
a=assert(wand_entry('A')); b=assert(inv_entry('B'))
assert(a.slot==1 and b.index==1,'reverse cross-surface exact positions wrong')
assert_state(a,7,false,'wand A'); assert_state(b,5,false,'inventory B')

-- Wand slot repair stays a simple component transaction; only inventory_full needs rehydration.
spell_service.expect_exact_slots(1,'injected_settle_failure',{{entity=a.entity,parent=2,x=1,y=0}})
ComponentSetValue2(a.item_component,'inventory_slot',0,0)
fail_slot_write={component=a.item_component,x=1}
frame=frame+1
local repaired_fault,failed_fault=spell_service.settle_slots()
assert(repaired_fault==0 and failed_fault==1 and ComponentGetValue2(a.item_component,'inventory_slot')==0,'failed deferred wand settle changed last valid coordinate')

assert(sentinel_kill_count==sentinel_create_count,'transaction leaked sentinel entities')
assert(sync_calls>=5,'transfers did not request inventory synchronization')
assert(regen_calls==0,'ordinary spell drag called gameplay action regeneration APIs')
print('spell_inventory_transfer=PASS rehydrate_registered_cards=true engine_first_free_model=true exact_native_pickup=true state_preserved=true distant_wand_export=true rollback=true swaps=true no_action_regen=true')
