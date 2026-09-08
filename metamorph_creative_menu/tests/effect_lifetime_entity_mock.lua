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

local twitchy={
 kind='game_effect',id='TWITCHY',path='data/entities/misc/effect_twitchy.xml',
 icon='data/ui_gfx/status_indicators/twitchy.png',display_name='Twitchy',display_description='',
 authored_lifetime=1200,
}
local catalog_stub={
 entries=function() return {twitchy} end,
 status_entries=function() return {} end,
 reserved_effects=function() return {POLYMORPH=true} end,
}
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/features/effects/catalog.lua' then return catalog_stub end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
local function add_component(e,kind,data)
 local id=next_component; next_component=next_component+1
 component_owner[id]=e; component_type[id]=kind; fields[id]=data or {}
 return id
end
function EntityGetIsAlive(e) return alive[e]==true end
function ModDoesFileExist(path) return path==twitchy.path or path==twitchy.icon end
function LoadGameEffectEntityTo(player,path)
 assert(player==1 and path==twitchy.path,'wrong lifetime effect target')
 local e=next_entity; next_entity=next_entity+1
 alive[e]=true; children[e]={}; tags[e]={}; filenames[e]=path
 add_component(e,'LifetimeComponent',{lifetime=1200})
 add_component(e,'UIIconComponent',{icon_sprite_file=twitchy.icon})
 children[1][#children[1]+1]=e
 return e
end
function EntityAddTag(e,tag) tags[e]=tags[e] or {}; tags[e][tag]=true end
function EntityHasTag(e,tag) return tags[e]~=nil and tags[e][tag]==true end
function EntityGetAllChildren(e)
 local out={}; for _,c in ipairs(children[e] or {}) do if alive[c] then out[#out+1]=c end end; return out
end
function EntityGetFilename(e) return filenames[e] or '' end
function EntityGetComponentIncludingDisabled(e,kind)
 local out={}; for id,owner in pairs(component_owner) do if owner==e and component_type[id]==kind then out[#out+1]=id end end; table.sort(out); return out
end
function EntityGetFirstComponentIncludingDisabled(e,kind) return EntityGetComponentIncludingDisabled(e,kind)[1] or 0 end
function EntityAddComponent2(e,kind,data) return add_component(e,kind,data) end
function ComponentGetValue2(c,f) return fields[c] and fields[c][f] end
function ComponentSetValue2(c,f,v) fields[c]=fields[c] or {}; fields[c][f]=v end
function GameGetFrameNum() return frame end
function EntityKill(e) alive[e]=false end
function EntityGetWithTag() return {} end

METAMORPH_CREATIVE_MENU_EFFECT_SERVICE=nil
METAMORPH_CREATIVE_MENU_EFFECT_EDITOR=nil
local effects=assert(native_dofile(root..'/files/features/effects/service.lua'))
assert(effects.authored_frames(twitchy)==1200,'LifetimeComponent authored duration not exposed')
local ok,reason=effects.add(1,twitchy,1800)
assert(ok==true and reason=='TWITCHY','lifetime-backed effect failed to apply')
local child=EntityGetAllChildren(1)[1]
local life=EntityGetFirstComponentIncludingDisabled(child,'LifetimeComponent')
assert(ComponentGetValue2(life,'lifetime')==1800,'requested duration not written to LifetimeComponent')
assert(effects.is_active(1,twitchy,effects.active_snapshot(1))==true,'lifetime-backed effect not visible as active')
frame=frame+300
ok,reason=effects.add(1,twitchy,600)
assert(ok==true and reason=='stacked','lifetime-backed reapply did not stack')
assert(ComponentGetValue2(life,'lifetime')==2400,'lifetime stacking did not add requested duration')
local set,why=effects.set_remaining(1,twitchy,600)
assert(set==true and why=='set','lifetime editor could not set remaining time')
assert(ComponentGetValue2(life,'lifetime')==900,'remaining-time edit ignored elapsed lifetime')
assert(effects.remaining_frames(1,twitchy)==600,'remaining lifetime calculation incorrect')
local removed=effects.remove(1,twitchy)
assert(removed==1 and alive[child]==false,'lifetime-backed effect removal did not run exact child cleanup')
print('effect_lifetime_entity=PASS catalog_duration=true apply=true stack=true set_remaining=true active=true remove=true')
