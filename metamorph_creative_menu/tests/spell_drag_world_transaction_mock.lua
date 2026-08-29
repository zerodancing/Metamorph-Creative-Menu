local root=assert(arg[1])
local native_dofile=dofile
local sync_calls=0
local notified={}
local raw_capacity=3
local loaded_service=nil

local alive={[1]=true,[2]=true,[3]=true,[4]=true,[10]=true,[20]=true}
local parent={[1]=0,[2]=1,[3]=2,[4]=2,[10]=1,[20]=10}
local fields={
 [31]={inventory_slot={0,0},permanently_attached=false},
 [41]={inventory_slot={-1,-1},permanently_attached=true},
 [201]={inventory_slot={2,0},permanently_attached=false},
}
local item_for_entity={[3]=31,[4]=41,[20]=201}
local fail_transform={}

local inventory_slots={}
function inventory_slots.place_exact(player,entity,name,x,y)
 if player~=1 or name~='inventory_full' or not alive[entity] then return false,'invalid' end
 parent[entity]=10
 local item=item_for_entity[entity]
 if item then fields[item].inventory_slot={x,y}; fields[item].permanently_attached=false end
 return true,'ok'
end
function inventory_slots.snapshot() return nil,'unused' end
function inventory_slots.is_inside_player_inventory() return true end

local wand_api={}
function wand_api.ability(wand) return wand==2 and 99 or 0 end
function wand_api.get_object(component,object,key)
 if component==99 and object=='gun_config' and key=='deck_capacity' then return raw_capacity,true end
 return nil,false
end
function wand_api.set_object(component,object,key,value)
 if component~=99 or object~='gun_config' or key~='deck_capacity' then return false end
 raw_capacity=value; return true
end
function wand_api.held() return 2 end

local prefix='mods/metamorph_creative_menu/'
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/integrations/ew/runtime.lua' then
  return {force_inventory_sync=function() sync_calls=sync_calls+1 end}
 end
 if path=='mods/metamorph_creative_menu/files/integrations/ew/world_items.lua' then
  return {notify_world_item=function(entity) notified[#notified+1]=entity; return true,'direct' end}
 end
 if path=='mods/metamorph_creative_menu/files/platform/noita/inventory_slots.lua' then return inventory_slots end
 if path=='mods/metamorph_creative_menu/files/platform/noita/wand.lua' then return wand_api end
 if path=='mods/metamorph_creative_menu/files/features/spells/factory.lua' then return {create=function() return 0,'unused' end} end
 if path=='mods/metamorph_creative_menu/files/features/spells/service.lua' and loaded_service~=nil then return loaded_service end
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end

EntityGetIsAlive=function(entity) return alive[entity]==true end
EntityGetParent=function(entity) return parent[entity] or 0 end
EntityRemoveFromParent=function(entity) parent[entity]=0 end
EntityAddChild=function(new_parent,entity) parent[entity]=new_parent end
EntityGetFirstComponentIncludingDisabled=function(entity,kind)
 if kind=='ItemComponent' then return item_for_entity[entity] or 0 end
 return 0
end
EntityGetComponentIncludingDisabled=function() return {} end
ComponentGetValue2=function(component,key)
 local value=fields[component] and fields[component][key]
 if type(value)=='table' then return value[1],value[2] end
 return value
end
ComponentSetValue2=function(component,key,a,b)
 fields[component]=fields[component] or {}
 if b~=nil then fields[component][key]={a,b} else fields[component][key]=a end
end
EntitySetComponentsWithTagEnabled=function() end
EntityGetTransform=function(entity) if entity==1 then return 100,50 end return 0,0 end
EntitySetTransform=function(entity,x,y)
 if fail_transform[entity] then error('simulated transform failure') end
end
GameRegenItemActionsInContainer=function() end
GameRegenItemActionsInPlayer=function() end

loaded_service=assert(native_dofile(root..'/files/features/spells/service.lua'))
local inventory_service=assert(native_dofile(root..'/files/features/spells/inventory_service.lua'))
local permanent_service=assert(native_dofile(root..'/files/features/spells/permanent_service.lua'))

local regular={entity=3,item_component=31,slot=0,actual_slot=0,actual_slot_y=0}
local regular_entries={regular}
fail_transform[3]=true
local ok,reason=loaded_service.drop_to_world(1,2,regular,regular_entries,300,50)
assert(ok==false and reason=='world_position_failed','wand world target failure did not propagate')
assert(parent[3]==2 and fields[31].inventory_slot[1]==0 and fields[31].permanently_attached==false,
 'failed wand world drop did not restore exact source')
assert(#notified==0,'failed wand world drop published world entity')

local inventory={entity=20,item_component=201,action_id='X',x=2,y=0,index=2}
fail_transform[20]=true
ok,reason=inventory_service.drop_to_world(1,inventory,250,50)
assert(ok==false and reason=='world_position_failed','inventory world target failure did not propagate')
assert(parent[20]==10 and fields[201].inventory_slot[1]==2 and fields[201].inventory_slot[2]==0,
 'failed inventory world drop did not rollback source slot')
assert(#notified==0,'failed inventory world drop published world entity')

local permanent={entity=4,item_component=41,actual_slot=-1,actual_slot_y=-1}
fail_transform[4]=true
local before_capacity=raw_capacity
ok,reason=permanent_service.drop_to_world(1,2,permanent,250,50)
assert(ok==false and reason=='world_position_failed','Always Cast world target failure did not propagate')
assert(parent[4]==2 and fields[41].permanently_attached==true and raw_capacity==before_capacity,
 'failed Always Cast world drop did not restore source/capacity')
assert(#notified==0,'failed Always Cast world drop published world entity')

-- Success is the commit boundary: only now may the source detach and be advertised.
fail_transform[3]=false
ok,reason=loaded_service.drop_to_world(1,2,regular,regular_entries,300,50)
assert(ok==true and reason=='thrown' and parent[3]==0,'successful wand world drop did not commit detach')
assert(#notified==1 and notified[1]==3,'successful world drop did not publish exactly once')

print('spell_drag_world_transaction=PASS wand_rollback=true inventory_rollback=true always_rollback=true success_commit=true')
