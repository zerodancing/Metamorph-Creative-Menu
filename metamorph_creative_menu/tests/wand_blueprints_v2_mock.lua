local root=assert(arg[1])
local native_dofile=dofile
local player,wand=1,2
local next_entity=100
local alive={[wand]=true}
local parent={}
local comps={}
local values={}
local config={stats={slots=3,mana_max=100,shuffle=false},mana=40,sprite_file='old.png'}
local visual={name='Old Wand',show_name_in_ui=true,wand_frozen=false,image_file='old.png',offset_x=1,offset_y=2,tip_x=3,tip_y=4}
local fail_appearance=false
local sync_calls=0

local function make_spell(action_id,slot,permanent,uses,frozen,forced_id)
 local e=forced_id or next_entity; if not forced_id then next_entity=next_entity+1 end
 local item=e*10+1; local action=e*10+2
 alive[e]=true; comps[e]={ItemComponent=item,ItemActionComponent=action}
 values[item]={inventory_slot={slot or 0,permanent and -1 or 0},permanently_attached=permanent==true,uses_remaining=uses,is_frozen=frozen==true,has_been_picked_by_player=true}
 values[action]={action_id=action_id}
 return e
end
local old_a=make_spell('OLD_A',0,false,2,false,10); parent[old_a]=wand
local old_b=make_spell('OLD_ALWAYS',-1,true,7,true,11); parent[old_b]=wand

dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/features/wands/service.lua' then
  return {
   snapshot=function(w)
    if w~=wand then return nil,'not_wand' end
    local stats={}; for k,v in pairs(config.stats) do stats[k]=v end
    return {wand=wand,ability=20,stats=stats,mana=config.mana,sprite_file=config.sprite_file},'ok'
   end,
   apply_configuration=function(p,w,desired,options)
    if w~=wand then return false,'not_wand' end
    for k,v in pairs(desired.stats or {}) do config.stats[k]=v end
    if desired.mana~=nil then config.mana=desired.mana end
    return true,'ok'
   end,
   refresh=function() sync_calls=sync_calls+1 end,
  }
 end
 if path=='mods/metamorph_creative_menu/files/features/wands/appearance.lua' then
  return {
   snapshot=function(w)
    if w~=wand then return nil,'not_wand' end
    return {sprite_file=config.sprite_file,name=visual.name,show_name_in_ui=visual.show_name_in_ui,wand_frozen=visual.wand_frozen,image_file=visual.image_file,offset_x=visual.offset_x,offset_y=visual.offset_y,tip_x=visual.tip_x,tip_y=visual.tip_y},'ok'
   end,
   apply=function(p,w,desired,options)
    if fail_appearance then return false,'visual_fault' end
    if desired.sprite_file~=nil and desired.sprite_file~='' then config.sprite_file=desired.sprite_file end
    local m=desired.meta or {}
    if m.name~=nil then visual.name=m.name end
    if m.show_name_in_ui~=nil then visual.show_name_in_ui=m.show_name_in_ui==true end
    if m.wand_frozen~=nil then visual.wand_frozen=m.wand_frozen==true end
    if m.image_file~=nil then visual.image_file=m.image_file end
    if m.sprite_offset_x~=nil then visual.offset_x=m.sprite_offset_x end
    if m.sprite_offset_y~=nil then visual.offset_y=m.sprite_offset_y end
    if m.tip_x~=nil then visual.tip_x=m.tip_x end
    if m.tip_y~=nil then visual.tip_y=m.tip_y end
    return true,'ok'
   end,
  }
 end
 if path=='mods/metamorph_creative_menu/files/features/spells/factory.lua' then
  return {create=function(action_id) return make_spell(action_id,0,false,nil,false),'ok' end}
 end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end

EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetAllChildren=function(e)
 local out={}; if e~=wand then return out end
 for child,p in pairs(parent) do if p==wand and alive[child] then out[#out+1]=child end end
 table.sort(out); return out
end
EntityGetFirstComponentIncludingDisabled=function(e,kind) return (comps[e] and comps[e][kind]) or 0 end
ComponentGetValue2=function(c,field)
 local v=values[c] and values[c][field]
 if type(v)=='table' then return v[1],v[2] end
 return v
end
ComponentSetValue2=function(c,field,a,b)
 values[c]=values[c] or {}
 if b~=nil then values[c][field]={a,b} else values[c][field]=a end
end
EntityAddChild=function(p,e) if not alive[e] then error('dead') end; parent[e]=p end
EntityRemoveFromParent=function(e) parent[e]=0 end
EntityGetParent=function(e) return parent[e] or 0 end
EntityKill=function(e) alive[e]=false; parent[e]=0 end
EntitySetComponentsWithTagEnabled=function() end
GameRegenItemActionsInContainer=function() end
GameRegenItemActionsInPlayer=function() end

local blueprints=assert(native_dofile(root..'/files/features/wands/blueprints.lua'))
local before=assert(blueprints.capture(wand))
assert(before.meta.name=='Old Wand' and #before.spells==2,'V2 capture metadata/spells failed')

local desired={version=2,stats={slots=5,mana_max=250,shuffle=true},mana=123,sprite_file='new.png',meta={name='Saved Wand',show_name_in_ui=true,wand_frozen=true,image_file='new.png',sprite_offset_x=9,sprite_offset_y=10,tip_x=11,tip_y=12},spells={
 {action_id='NEW_A',slot=2,slot_y=0,permanent=false,uses_remaining=4,frozen=true},
 {action_id='NEW_ALWAYS',slot=-1,slot_y=-1,permanent=true,uses_remaining=1,frozen=false},
}}
local ok,reason=blueprints.apply(player,wand,desired)
assert(ok==true and reason=='loaded','V2 apply failed '..tostring(reason))
assert(alive[old_a]==false and alive[old_b]==false,'old cards survived successful commit')
assert(config.stats.slots==5 and config.mana==123 and config.sprite_file=='new.png','configuration not applied')
assert(visual.name=='Saved Wand' and visual.offset_x==9 and visual.tip_y==12 and visual.wand_frozen==true,'appearance not applied')
local new_children=EntityGetAllChildren(wand)
assert(#new_children==2,'new cards not attached')
local found_a,found_perm=false,false
for _,e in ipairs(new_children) do
 local item=comps[e].ItemComponent; local action=comps[e].ItemActionComponent; local id=values[action].action_id
 if id=='NEW_A' then found_a=values[item].inventory_slot[1]==2 and values[item].uses_remaining==4 and values[item].is_frozen==true end
 if id=='NEW_ALWAYS' then found_perm=values[item].permanently_attached==true and values[item].inventory_slot[1]==-1 and values[item].uses_remaining==1 end
end
assert(found_a and found_perm,'card runtime/permanent state lost')

-- A later visual failure must restore the exact pre-attempt cards and non-spell state,
-- while destroying every newly prepared candidate from the failed load.
local stable=assert(blueprints.capture(wand))
local stable_children=EntityGetAllChildren(wand)
fail_appearance=true
local failed,why=blueprints.apply(player,wand,{version=2,stats={slots=2,mana_max=1},mana=1,sprite_file='bad.png',meta={name='Bad'},spells={{action_id='FAIL_NEW',slot=0,permanent=false}}})
assert(failed==false and why=='visual_fault','faulted blueprint reported success')
fail_appearance=false
local after_fail=assert(blueprints.capture(wand))
assert(config.stats.slots==stable.stats.slots and config.stats.mana_max==stable.stats.mana_max and config.mana==stable.mana,'config rollback failed')
assert(visual.name==stable.meta.name and config.sprite_file==stable.sprite_file,'appearance rollback failed')
local restored=EntityGetAllChildren(wand)
assert(#restored==#stable_children,'card count changed after failed load')
for i,e in ipairs(stable_children) do assert(parent[e]==wand and alive[e]==true,'old prepared card not restored') end
for e,_ in pairs(alive) do
 if e>=100 and parent[e]==0 then assert(alive[e]==false,'failed candidate leaked alive') end
end
assert(sync_calls>=2,'final synchronization missing')
print('wand_blueprints_v2=PASS capture=true apply=true card_runtime=true rollback=true')
