local root=assert(arg[1])
local native_dofile=dofile
local sync_calls=0
local notified_world_items={}
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/integrations/ew/runtime.lua' then
  return {force_inventory_sync=function() sync_calls=sync_calls+1 end}
 end
 if path=='mods/metamorph_creative_menu/files/integrations/ew/world_items.lua' then
  return {notify_world_item=function(entity) notified_world_items[#notified_world_items+1]=entity; return true,'direct' end}
 end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
local alive={[1]=true,[2]=true,[3]=true,[4]=true}
local transforms={[1]={100,50}}
local parent={[1]=0,[2]=1,[3]=2,[4]=2}
local children={[1]={2},[2]={3,4},[3]={},[4]={}}
local component_owner={[11]=1,[21]=2,[31]=3,[32]=3,[41]=4,[42]=4}
local component_type={[11]='Inventory2Component',[21]='AbilityComponent',[31]='ItemComponent',[32]='ItemActionComponent',[41]='ItemComponent',[42]='ItemActionComponent'}
local fields={
 [11]={mActiveItem=2},
 [21]={use_gun_script=true,mana=50,mana_max=100,mana_charge_speed=10},
 [31]={permanently_attached=false,inventory_slot={0,0}}, [32]={action_id='A'},
 [41]={permanently_attached=false,inventory_slot={0,0}}, [42]={action_id='B'},
}
local gun_config={[21]={deck_capacity=3}}
EntityGetIsAlive=function(entity) return alive[entity]==true end
EntityGetAllChildren=function(entity) local result={} for _,child in ipairs(children[entity] or {}) do if alive[child] then result[#result+1]=child end end return result end
EntityGetFirstComponentIncludingDisabled=function(entity,component_name)
 for component,owner in pairs(component_owner) do if owner==entity and component_type[component]==component_name then return component end end
 return 0
end
EntityGetComponentIncludingDisabled=function(entity,component_name)
 local result={}
 for component,owner in pairs(component_owner) do if owner==entity and component_type[component]==component_name then result[#result+1]=component end end
 return result
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
ComponentObjectGetValue2=function(component,object_name,field) return gun_config[component] and gun_config[component][field] end
EntityRemoveFromParent=function(entity)
 local old=parent[entity] or 0
 if old~=0 then for index=#(children[old] or {}),1,-1 do if children[old][index]==entity then table.remove(children[old],index) end end end
 parent[entity]=0
end
EntityKill=function(entity) alive[entity]=false end
EntityGetParent=function(entity) return parent[entity] or 0 end
EntityAddChild=function(new_parent,entity) EntityRemoveFromParent(entity); parent[entity]=new_parent; children[new_parent]=children[new_parent] or {}; children[new_parent][#children[new_parent]+1]=entity end
EntitySetComponentsWithTagEnabled=function() end
EntityGetTransform=function(entity) local t=transforms[entity] or {0,0}; return t[1],t[2] end
EntitySetTransform=function(entity,x,y) transforms[entity]={x,y} end
GameRegenItemActionsInContainer=function() fields[21].mana=0; fields[21].mana_max=1; fields[21].mana_charge_speed=1 end
GameRegenItemActionsInPlayer=function() end
local next_entity=5
CreateItemActionEntity=function(action_id)
 local entity=next_entity; next_entity=next_entity+1
 alive[entity]=true; parent[entity]=0; children[entity]={}
 local item_component=50+entity
 local action_component=150+entity
 component_owner[item_component]=entity; component_type[item_component]='ItemComponent'
 component_owner[action_component]=entity; component_type[action_component]='ItemActionComponent'
 fields[item_component]={permanently_attached=false,inventory_slot={-1,-1}}
 fields[action_component]={action_id=action_id}
 local velocity_component=250+entity
 component_owner[velocity_component]=entity; component_type[velocity_component]='VelocityComponent'
 fields[velocity_component]={mVelocity={0,0}}
 return entity
end

local service=assert(native_dofile(root..'/files/features/spells/service.lua'))
assert(service.held_wand(1)==2,'held wand detection changed')
local by_slot,highest,permanent,entries=service.contents(2)
assert(highest==1 and permanent==0 and by_slot[0].entity==3 and by_slot[1].entity==4,'duplicate slot normalization plan changed')
assert(service.capacity(2,highest,permanent)==3,'wand capacity changed')
local replaced=service.replace(1,2,1,'C',by_slot[1],entries); assert(replaced)
assert(not alive[4],'replaced spell survived')
assert(fields[41].inventory_slot[1]==0,'replaced card was mutated before retirement')
assert(fields[21].mana==50 and fields[21].mana_max==100 and fields[21].mana_charge_speed==10,'wand mana state not preserved')
assert(sync_calls==1,'spell edit did not request EW inventory sync')

-- INSERT preserves the selected card and shifts the suffix into the nearest free slot.
-- A failed attach must leave the old spell intact and must not publish inventory sync.
local by_slot2,_,_,entries2=service.contents(2)
local old_entity=by_slot2[0].entity
local old_add_child=EntityAddChild
EntityAddChild=function(new_parent,entity)
 if entity>=next_entity-1 then return end
 return old_add_child(new_parent,entity)
end
-- Re-introduce a conflicting physical coordinate on the other card. A failed replacement
-- must not normalize that unrelated card before its candidate has committed.
local other_entry=by_slot2[1]
assert(other_entry~=nil,'test setup lost replacement card')
ComponentSetValue2(other_entry.item_component,'inventory_slot',0,0)
local by_slot_fault,_,_,entries_fault=service.contents(2)
assert(by_slot_fault[1]~=nil and by_slot_fault[1].actual_slot==0,'fault setup did not create duplicate slot')
local before_other_slot=fields[by_slot_fault[1].item_component].inventory_slot[1]
local before_sync=sync_calls
local failed=service.replace(1,2,0,'D',by_slot_fault[0],entries_fault)
assert(failed==false,'failed attach reported success')
assert(alive[old_entity]==true and parent[old_entity]==2,'failed replacement destroyed or detached old spell')
assert(fields[by_slot_fault[1].item_component].inventory_slot[1]==before_other_slot,'failed replacement mutated another card before commit')
assert(sync_calls==before_sync,'failed replacement published inventory sync')
EntityAddChild=old_add_child

-- DROP must commit only after the entity is really detached, then advertise the real
-- vanilla action through the same optional EW world-item adapter used by ITEMS.
local by_slot3,_,_,entries3=service.contents(2)
local drop_entry=by_slot3[0]
local drop_entity=drop_entry.entity
local drop_sync_before=sync_calls
assert(service.remove(1,2,drop_entry,entries3,true)==true,'world drop failed')
assert(parent[drop_entity]==0 and alive[drop_entity]==true,'world drop did not preserve a detached live action')
assert(notified_world_items[#notified_world_items]==drop_entity,'world drop was not handed to EW world-item transport')
assert(sync_calls==drop_sync_before+1,'committed world drop did not refresh inventory')

-- Dragging a catalog spell into the world creates a real card near the player and
-- gives it velocity toward the release point instead of spawning motionless at the feet.
local throw_notify_before=#notified_world_items
local thrown,throw_reason,throw_entity=service.throw_catalog(1,'THROW',300,50)
assert(thrown==true and throw_reason=='thrown' and alive[throw_entity]==true,'catalog throw failed')
local throw_x,throw_y=EntityGetTransform(throw_entity)
assert(throw_x>100 and math.abs(throw_y-44)<1,'thrown card origin did not move toward cursor')
local velocity_component=EntityGetFirstComponentIncludingDisabled(throw_entity,'VelocityComponent')
local throw_vx,throw_vy=ComponentGetValue2(velocity_component,'mVelocity')
assert(throw_vx>100 and math.abs(throw_vy)<1,'thrown card did not receive directional velocity')
assert(#notified_world_items==throw_notify_before+1 and notified_world_items[#notified_world_items]==throw_entity,'thrown card was not handed to world-item sync')

-- If Noita reports a still-attached entity, DROP must not expose/network it or publish
-- an inventory commit. This guards the transaction boundary against partial detach.
local by_slot4,_,_,entries4=service.contents(2)
local stuck_entry=by_slot4[1]
assert(stuck_entry~=nil,'test setup lost second spell')
local real_remove=EntityRemoveFromParent
EntityRemoveFromParent=function(entity) if entity==stuck_entry.entity then return end return real_remove(entity) end
local notify_before=#notified_world_items
local failed_drop_sync=sync_calls
assert(service.remove(1,2,stuck_entry,entries4,true)==false,'failed detach reported committed DROP')
assert(parent[stuck_entry.entity]==2 and alive[stuck_entry.entity]==true,'failed detach mutated the original spell')
assert(#notified_world_items==notify_before,'failed detach published a world item')
assert(sync_calls==failed_drop_sync,'failed detach published inventory sync')
EntityRemoveFromParent=real_remove

print('spell_service=PASS duplicate_slots=true mana_preserved=true transactional_replace=true transactional_drop=true directional_throw=true world_handoff=true sync=true')
