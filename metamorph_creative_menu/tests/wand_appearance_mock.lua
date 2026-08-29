local root=assert(arg[1])
local native_dofile=dofile
local sync_calls=0
local scalar={sprite_file='old.png'}
local next_component=100
local item_id,sprite_id,hotspot_id,spell_item_id=31,32,33,41
local spell_action_id=42
local active={[31]=true,[32]=true,[33]=true,[41]=true,[42]=true}
local values={
 [31]={item_name='Old',always_use_item_name_in_ui=true,is_frozen=false},
 [32]={image_file='old.png',offset_x=3,offset_y=4},
 [33]={offset={5,6}},
 [41]={is_frozen=false},
 [42]={action_id='A'},
 [90]={image_file='overlay.png',offset_x=90,offset_y=90},
}
active[90]=true
local item_primary=true
local sprite_tagged=true
local hotspot_tagged=true
local extra_sprite=false
local sabotage_next_offset=false
local refreshes={}

local function clone_fields(source)
 local out={}
 for k,v in pairs(source or {}) do
  if type(v)=='table' then out[k]={v[1],v[2]} else out[k]=v end
 end
 return out
end
local function replace_component(old)
 next_component=next_component+1
 local new=next_component
 values[new]=clone_fields(values[old])
 active[old]=false; active[new]=true
 return new
end
local function sync_replace()
 sync_calls=sync_calls+1
 item_id=replace_component(item_id)
 sprite_id=replace_component(sprite_id)
 hotspot_id=replace_component(hotspot_id)
 spell_item_id=replace_component(spell_item_id)
 if sabotage_next_offset then
  sabotage_next_offset=false
  values[sprite_id].offset_x=-999
 end
end

dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/platform/noita/wand.lua' then
  return {
   ability=function(wand) return wand==2 and 21 or 0 end,
   get_scalar=function(component,field) return scalar[field],true end,
   set_scalar=function(component,field,value) scalar[field]=value; return true end,
  }
 end
 if path=='mods/metamorph_creative_menu/files/features/wands/sync.lua' then
  return {inventory=function(player) sync_replace() end}
 end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
EntityGetFirstComponentIncludingDisabled=function(entity,kind,tag)
 if entity==2 and kind=='ItemComponent' then return item_primary and item_id or 0 end
 if entity==2 and kind=='SpriteComponent' then
  if tag=='item' then return sprite_tagged and sprite_id or 0 end
  return sprite_id
 end
 if entity==2 and kind=='HotspotComponent' then
  if tag=='shoot_pos' then return hotspot_tagged and hotspot_id or 0 end
  return hotspot_id
 end
 if entity==3 and kind=='ItemComponent' then return spell_item_id end
 if entity==3 and kind=='ItemActionComponent' then return spell_action_id end
 return 0
end
EntityGetComponentIncludingDisabled=function(entity,kind)
 if entity==2 and kind=='ItemComponent' then return {item_id} end
 if entity==2 and kind=='SpriteComponent' then
  if extra_sprite then return {sprite_id,90} end
  return {sprite_id}
 end
 if entity==2 and kind=='HotspotComponent' then return {hotspot_id} end
 if entity==3 and kind=='ItemComponent' then return {spell_item_id} end
 if entity==3 and kind=='ItemActionComponent' then return {spell_action_id} end
 return {}
end
EntityGetAllChildren=function(entity) return entity==2 and {3} or {} end
ComponentGetValue2=function(component,field)
 if active[component]~=true then error('stale component read '..tostring(component)) end
 local v=values[component] and values[component][field]
 if type(v)=='table' then return v[1],v[2] end
 return v
end
ComponentSetValue2=function(component,field,a,b)
 if active[component]~=true then error('stale component write '..tostring(component)) end
 values[component]=values[component] or {}
 if b~=nil then values[component][field]={a,b} else values[component][field]=a end
end
EntityRefreshSprite=function(wand,component)
 if active[component]~=true then error('stale sprite refresh '..tostring(component)) end
 refreshes[#refreshes+1]=component
end
ModDoesFileExist=function(path) return path=='new.png' or path=='different.png' or path=='old.png' end

local appearance=assert(native_dofile(root..'/files/features/wands/appearance.lua'))
local snap=assert(appearance.snapshot(2))
assert(snap.name=='Old' and snap.sprite_file=='old.png' and snap.image_file=='old.png' and snap.offset_x==3 and snap.tip_y==6,'snapshot failed')

-- Missing primary/tagged components fall back only when the component type is unambiguous.
item_primary=false; sprite_tagged=false; hotspot_tagged=false
snap=assert(appearance.snapshot(2))
assert(snap.item==item_id and snap.item_resolution=='unique_fallback','unique item fallback failed')
assert(snap.sprite==sprite_id and snap.sprite_resolution=='unique_fallback','unique sprite fallback failed')
assert(snap.hotspot==hotspot_id and snap.hotspot_resolution=='unique_fallback','unique hotspot fallback failed')
extra_sprite=true
snap=assert(appearance.snapshot(2))
assert(snap.sprite==0 and snap.sprite_resolution=='ambiguous','ambiguous sprite fallback touched an unrelated sprite')
extra_sprite=false; item_primary=true; sprite_tagged=true; hotspot_tagged=true

-- Visual writes must survive sync component replacement and refresh the fresh visible sprite.
local old_sprite_id=sprite_id
assert(appearance.set_visual(1,2,{sprite_file='new.png',image_file='different.png',offset_x=7,offset_y=8,tip_x=9,tip_y=10})==true,'visual apply failed')
assert(sprite_id~=old_sprite_id,'sync did not replace sprite component in test')
snap=assert(appearance.snapshot(2))
assert(snap.sprite_file=='new.png' and snap.image_file=='different.png' and snap.offset_x==7 and snap.offset_y==8 and snap.tip_x==9,'visual fields failed after sync')
assert(refreshes[#refreshes]==sprite_id,'fresh visible sprite was not refreshed after sync')
assert(values[90].offset_x==90,'unrelated SpriteComponent was modified')

-- Every flag must work in both directions even though sync replaces component IDs.
assert(appearance.set_name(1,2,'Custom',false)==true,'show-name off failed')
snap=assert(appearance.snapshot(2)); assert(snap.name=='Custom' and snap.show_name_in_ui==false,'show-name off snapshot stale')
assert(appearance.set_name(1,2,'Custom',true)==true,'show-name on failed')
snap=assert(appearance.snapshot(2)); assert(snap.show_name_in_ui==true,'show-name on snapshot stale')
assert(appearance.set_wand_frozen(1,2,true)==true,'wand lock on failed')
snap=assert(appearance.snapshot(2)); assert(snap.wand_frozen==true,'wand lock on snapshot stale')
assert(appearance.set_wand_frozen(1,2,false)==true,'wand lock off failed')
snap=assert(appearance.snapshot(2)); assert(snap.wand_frozen==false,'wand lock off snapshot stale')
assert(appearance.set_spells_frozen(1,2,true)==true,'spell lock on failed')
assert(select(1,appearance.spell_freeze_state(2))==true,'spell lock on state stale')
assert(appearance.set_spells_frozen(1,2,false)==true,'spell lock off failed')
local all,mixed,total=appearance.spell_freeze_state(2)
assert(all==false and mixed==false and total==1,'spell lock off state stale')

-- A post-sync verification failure rolls geometry back through freshly resolved components.
local before=assert(appearance.snapshot(2))
sabotage_next_offset=true
local ok,why=appearance.set_visual(1,2,{offset_x=99})
assert(ok==false and why=='visual_verify_failed','post-sync offset failure reported success')
local after=assert(appearance.snapshot(2))
assert(after.offset_x==before.offset_x,'failed offset did not roll back')
assert(values[90].offset_x==90,'rollback touched unrelated SpriteComponent')

assert(sync_calls>=8,'expected sync-backed appearance operations')
print('wand_appearance=PASS fallback=true post_sync=true toggles_both_ways=true visual_verify=true rollback=true')
