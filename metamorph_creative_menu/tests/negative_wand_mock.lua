local root=assert(arg[1])
local native_dofile=dofile
local objects={gun_config={deck_capacity=6,actions_per_round=1,reload_time=-1,shuffle_deck_when_empty=false},gunaction_config={fire_rate_wait=-3,spread_degrees=0,speed_multiplier=1}}
local scalars={mana=50,mana_max=100,mana_charge_speed=20,item_recoil_recovery_speed=0,gun_level=1,never_reload=false,sprite_file='wand.png'}
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/platform/noita/wand.lua' then return {
  ability=function() return 21 end,
  get_object=function(_,o,f) local v=(objects[o] or {})[f]; return v,v~=nil end,
  set_object=function(_,o,f,v) objects[o][f]=v; return true end,
  get_scalar=function(_,f) return scalars[f],scalars[f]~=nil end,
  set_scalar=function(_,f,v) scalars[f]=v; return true end,
 } end
 if path=='mods/metamorph_creative_menu/files/features/wands/sync.lua' then return {inventory=function() end} end
 if path=='mods/metamorph_creative_menu/files/features/wands/appearance.lua' then return {set_visual=function() return true end} end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
EntityGetAllChildren=function() return {} end
METAMORPH_CREATIVE_MENU_WAND_SERVICE=nil
local service=assert(native_dofile(root..'/files/features/wands/service.lua'))
assert(service.set_stat(1,2,'reload_time',-1)==true and objects.gun_config.reload_time==-1,'negative integer -1 changed during rounding')
assert(service.set_stat(1,2,'fire_rate_wait',-3)==true and objects.gunaction_config.fire_rate_wait==-3,'negative fire-rate integer changed during rounding')
assert(service.set_stat(1,2,'reload_time',-1.4)==true and objects.gun_config.reload_time==-1,'negative nearest rounding biased downward')
assert(service.set_stat(1,2,'reload_time',-1.6)==true and objects.gun_config.reload_time==-2,'negative nearest rounding failed below half')
print('negative_wand=PASS exact_negative=true symmetric_rounding=true')
