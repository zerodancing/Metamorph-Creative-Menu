local root=assert(arg[1],'root required')
local native_dofile=dofile
local frame=100
local alive={[1]=true}
local children={[1]={}}
local tags={}
local filenames={}
local component_owner={}
local component_type={}
local fields={}
local next_entity=10
local next_component=100

local electro={
 kind='game_effect', id='ELECTROCUTION', path='data/entities/misc/effect_electricity.xml',
 icon='data/ui_gfx/gun_actions/electrocution_field.png', display_name='Electrified',
 display_description='', game_effect='ELECTROCUTION', authored_frames=40, disable_movement=true,
}
local catalog_stub={
 entries=function() return {electro} end,
 status_entries=function() return {} end,
 reserved_effects=function() return {POLYMORPH=true} end,
}

dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/features/effects/catalog.lua' then return catalog_stub end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end

local function add_component(entity,kind,data)
 local id=next_component; next_component=next_component+1
 component_owner[id]=entity; component_type[id]=kind; fields[id]=data or {}
 return id
end
function EntityGetIsAlive(e) return alive[e]==true end
function ModDoesFileExist(path) return path==electro.path or path==electro.icon end
function LoadGameEffectEntityTo(player,path)
 assert(player==1 and path==electro.path,'wrong electrocution target')
 local e=next_entity; next_entity=next_entity+1
 alive[e]=true; children[e]={}; tags[e]={}; filenames[e]=path
 add_component(e,'GameEffectComponent',{effect='ELECTROCUTION',custom_effect_id='',frames=40,disable_movement=true})
 children[1][#children[1]+1]=e
 return e
end
function EntityAddTag(e,tag) tags[e]=tags[e] or {}; tags[e][tag]=true end
function EntityHasTag(e,tag) return tags[e]~=nil and tags[e][tag]==true end
function EntityGetWithTag(tag)
 local out={}
 for e,set in pairs(tags) do if alive[e] and set[tag] then out[#out+1]=e end end
 return out
end
function EntityGetAllChildren(e)
 local out={}
 for _,c in ipairs(children[e] or {}) do if alive[c] then out[#out+1]=c end end
 return out
end
function EntityGetFilename(e) return filenames[e] or '' end
function EntityGetComponentIncludingDisabled(e,kind)
 local out={}
 for id,owner in pairs(component_owner) do if owner==e and component_type[id]==kind then out[#out+1]=id end end
 return out
end
function EntityGetFirstComponentIncludingDisabled(e,kind)
 local list=EntityGetComponentIncludingDisabled(e,kind); return list[1] or 0
end
function EntityAddComponent2(e,kind,data) return add_component(e,kind,data) end
function ComponentGetValue2(c,f) return fields[c] and fields[c][f] end
function ComponentSetValue2(c,f,v) fields[c]=fields[c] or {}; fields[c][f]=v end
function GameGetFrameNum() return frame end
function EntityKill(e) alive[e]=false end

METAMORPH_CREATIVE_MENU_EFFECT_SERVICE=nil
METAMORPH_CREATIVE_MENU_EFFECT_EDITOR=nil
local effects=assert(native_dofile(root..'/files/features/effects/service.lua'))
assert(effects.duration_policy(electro)=='authored','control-lock effect duration is editable')
assert(effects.authored_frames(electro)==40,'authored electrocution duration lost')

-- A caller may ask for minutes or infinity; movement-lock effects must always stay at the
-- authored short pulse so the menu cannot accidentally lock TAB/normal controls for minutes.
local ok,reason=effects.add(1,electro,-1)
assert(ok==true,'electrocution apply failed')
local child=EntityGetAllChildren(1)[1]
local comp=EntityGetFirstComponentIncludingDisabled(child,'GameEffectComponent')
assert(ComponentGetValue2(comp,'frames')==40,'infinite request escaped authored safety duration')
local count_before=#EntityGetAllChildren(1)
ok,reason=effects.add(1,electro,18000)
assert(ok==true and reason=='retriggered','control-lock repeat should retrigger, not stack')
assert(ComponentGetValue2(comp,'frames')==40,'repeated control-lock effect accumulated duration')
assert(#EntityGetAllChildren(1)==count_before,'repeated control-lock effect cloned a HUD row')

-- Repair state left by older MCM builds that stretched this effect before the safety rule.
ComponentSetValue2(comp,'frames',-1)
frame=frame+1
effects.update()
assert(ComponentGetValue2(comp,'frames')==40,'legacy infinite movement lock was not clamped')
ComponentSetValue2(comp,'frames',3600)
frame=frame+1
effects.update()
assert(ComponentGetValue2(comp,'frames')==40,'legacy long movement lock was not clamped')

assert(effects.set_remaining(1,electro,600)==false,'editor exposed duration editing for a control-lock effect')
print('effect_control_lock_safety=PASS authored_duration=40 no_stack=true no_clone=true legacy_clamp=true editor_fixed=true')
