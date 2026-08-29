local root=assert(arg[1])
local native_dofile=dofile
local player=1
local next_entity=100
local alive={[player]=true}
local parent={}
local position={[player]={100,200}}
local stored=''
local current={version=2,stats={slots=4,mana_max=250,shuffle=true},mana=123,sprite_file='saved_sprite.png',meta={name='Saved Wand',show_name_in_ui=true,wand_frozen=true,image_file='saved_image.png'},spells={{action_id='A',slot=0,slot_y=0,permanent=false},{action_id='B',slot=-1,slot_y=-1,permanent=true}}}
local applied=nil
local plan_mode='inventory'
local place_fail=false
local apply_fail=false
local notify_fail=false
local sync_calls=0
local world_enabled={}
local notified={}
local attempts={}

local function clone(v)
 if type(v)~='table' then return v end
 local out={}; for k,x in pairs(v) do out[k]=clone(x) end; return out
end
local function create_child(p)
 next_entity=next_entity+1; local e=next_entity; alive[e]=true; parent[e]=p; attempts[#attempts+1]=e; return e
end
local function all_children(e)
 local out={}; for child,p in pairs(parent) do if p==e and alive[child] then out[#out+1]=child end end
 table.sort(out); return out
end

dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/features/wands/blueprints.lua' then
  return {
   capture=function() return clone(current),'ok' end,
   apply=function(p,w,bp)
    applied=clone(bp)
    create_child(w) -- assembled spell candidate or a partial child on failure
    if apply_fail then create_child(w); return false,'apply_failed' end
    return true,'loaded'
   end,
  }
 end
 if path=='mods/metamorph_creative_menu/files/platform/noita/inventory_slots.lua' then
  return {
   preflight=function(p,e)
    if plan_mode=='inventory' then return {name='inventory_quick',x=2,y=0},'ok' end
    if plan_mode=='full' then return nil,'full' end
    return nil,'inventory_missing'
   end,
   place_exact=function(p,e,name,x,y)
    assert(name=='inventory_quick' and x==2 and y==0,'preset did not use planned quick slot')
    if place_fail then return false,'attach_failed' end
    parent[e]=50
    return true,'ok'
   end,
   enable_world=function(e) world_enabled[e]=true end,
  }
 end
 if path=='mods/metamorph_creative_menu/files/features/wands/sync.lua' then
  return {inventory=function() sync_calls=sync_calls+1 end}
 end
 if path=='mods/metamorph_creative_menu/files/integrations/ew/world_items.lua' then
  return {notify_world_item=function(e) notified[e]=true; return not notify_fail end}
 end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end

ModSettingGet=function() return stored end
ModSettingSet=function(_,value) stored=value; return true end
EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetTransform=function(e) local p=position[e]; if p then return p[1],p[2] end; return nil end
EntitySetTransform=function(e,x,y) position[e]={x,y} end
EntityLoad=function(path,x,y)
 assert(path=='data/entities/items/starting_wand.xml','unexpected base wand path')
 next_entity=next_entity+1; local e=next_entity; alive[e]=true; position[e]={x,y}; attempts[#attempts+1]=e
 create_child(e) -- default child from the base wand, must also be cleaned on failure
 return e
end
EntityGetAllChildren=all_children
EntityRemoveFromParent=function(e) parent[e]=0 end
EntityKill=function(e) alive[e]=false; parent[e]=0 end

local presets=assert(native_dofile(root..'/files/features/wands/presets.lua'))
assert(presets.save('Saved',2)==true,'fixture save failed')

local ok,reason,entity=presets.give(1,player)
assert(ok==true and reason=='given_inventory' and entity~=0,'inventory copy failed')
assert(parent[entity]==50 and sync_calls==1,'copy was not committed to planned quick inventory slot')
assert(applied.meta.name=='Saved Wand' and applied.stats.mana_max==250 and #applied.spells==2,'exact saved blueprint was not applied')

plan_mode='full'
local world_ok,world_reason,world_entity=presets.give(1,player)
assert(world_ok==true and world_reason=='given_world','full inventory did not fall back to world')
assert(parent[world_entity]==0 and world_enabled[world_entity]==true and notified[world_entity]==true,'world fallback not enabled/synchronized')
assert(position[world_entity][1]==112 and position[world_entity][2]==192,'world fallback position wrong')

local function assert_attempt_dead(from_index,message)
 for i=from_index,#attempts do assert(alive[attempts[i]]~=true,message..' leaked entity '..tostring(attempts[i])) end
end

plan_mode='inventory'; apply_fail=true
local start=#attempts+1
local failed,why,failed_entity=presets.give(1,player)
assert(failed==false and why=='apply_failed' and failed_entity==0,'blueprint failure was not reported')
assert_attempt_dead(start,'blueprint failure cleanup')
apply_fail=false

place_fail=true
start=#attempts+1
failed,why,failed_entity=presets.give(1,player)
assert(failed==false and why=='attach_failed' and failed_entity==0,'inventory commit failure was not reported')
assert_attempt_dead(start,'inventory failure cleanup')
place_fail=false

plan_mode='full'; notify_fail=true
start=#attempts+1
failed,why,failed_entity=presets.give(1,player)
assert(failed==false and why=='world_sync_failed' and failed_entity==0,'world sync failure was not reported')
assert_attempt_dead(start,'world sync failure cleanup')

print('wand_presets_copy=PASS blueprint_apply=true quick_slot=true full_world=true recursive_cleanup=true sync_failure_cleanup=true')
