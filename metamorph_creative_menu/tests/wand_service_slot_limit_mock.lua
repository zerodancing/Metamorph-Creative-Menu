local root=assert(arg[1],'root required')
local native_dofile=dofile
local sync_calls=0
local objects={
 gun_config={deck_capacity=6,actions_per_round=1,reload_time=10,shuffle_deck_when_empty=false},
 gunaction_config={fire_rate_wait=5,spread_degrees=0,speed_multiplier=1},
}
local scalars={mana=50,mana_max=100,mana_charge_speed=20,item_recoil_recovery_speed=0,gun_level=1,never_reload=false,sprite_file='wand.png'}

dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/platform/noita/wand.lua' then
  return {
   ability=function(wand) return wand==2 and 21 or 0 end,
   get_object=function(_,object,field)
    local bucket=objects[object] or {}
    return bucket[field],bucket[field]~=nil
   end,
   set_object=function(_,object,field,value)
    objects[object]=objects[object] or {}; objects[object][field]=value; return true
   end,
   get_scalar=function(_,field) return scalars[field],scalars[field]~=nil end,
   set_scalar=function(_,field,value) scalars[field]=value; return true end,
  }
 end
 if path=='mods/metamorph_creative_menu/files/features/wands/sync.lua' then
  return {inventory=function(player) assert(player==1); sync_calls=sync_calls+1 end}
 end
 if path=='mods/metamorph_creative_menu/files/features/wands/appearance.lua' then
  return {set_visual=function() return true,'ok' end}
 end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
EntityGetAllChildren=function() return {} end

METAMORPH_CREATIVE_MENU_WAND_SERVICE=nil
local service=assert(native_dofile(root..'/files/features/wands/service.lua'))
assert(service.max_slots()==64,'reported editable slot maximum is not 64')
local def=assert(service.definition('slots'))
assert(def.min==1 and def.max==64 and def.integer==true,'slot definition bounds wrong')

local ok,why=service.set_stat(1,2,'slots',1000)
assert(ok==true and why=='ok','oversized direct edit failed instead of clamping')
assert(objects.gun_config.deck_capacity==64,'direct slot edit exceeded 64: '..tostring(objects.gun_config.deck_capacity))

objects.gun_config.deck_capacity=6
local ok2,why2=service.apply_configuration(1,2,{stats={slots=999}},{skip_sync=false})
assert(ok2==true and why2=='ok','configuration slot edit failed instead of clamping')
assert(objects.gun_config.deck_capacity==64,'configuration path exceeded 64: '..tostring(objects.gun_config.deck_capacity))
assert(sync_calls==2,'unexpected sync count '..tostring(sync_calls))
print('wand_service_slot_limit=PASS max=64 direct_clamp=true configuration_clamp=true')
