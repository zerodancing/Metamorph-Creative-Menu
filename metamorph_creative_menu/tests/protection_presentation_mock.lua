local root=assert(arg[1])
local player=1
local frame=10
local alive={[1]=true,[2]=true,[3]=true}
local children={[1]={2,3},[2]={},[3]={}}
local tags={} -- legacy v13 entity-less pickup could leave presentation without perk_entity
local comps={
 [20]={type='GameEffectComponent',effect='PROTECTION_ELECTRICITY',frames=-1},
 [30]={type='UIIconComponent',name='$perk_protection_electricity',icon_sprite_file='data/ui_gfx/perk_icons/electricity.png'},
}
local ent_comps={[2]={GameEffectComponent=20},[3]={UIIconComponent=30}}
local globals={PERK_PICKED_PROTECTION_ELECTRICITY_PICKUP_COUNT='1'}
GameGetFrameNum=function() return frame end
EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetAllChildren=function(e) local r={} for _,v in ipairs(children[e] or {}) do if alive[v] then r[#r+1]=v end end return r end
EntityGetFirstComponentIncludingDisabled=function(e,t) return ent_comps[e] and ent_comps[e][t] or nil end
EntityGetComponentIncludingDisabled=function() return {} end
ComponentGetValue2=function(c,f) return comps[c] and comps[c][f] end
ComponentSetValue2=function(c,f,v) assert(comps[c]); comps[c][f]=v end
EntityHasTag=function(e,t) return tags[e] and tags[e][t] or false end
EntityKill=function(e) alive[e]=false end
EntityGetFilename=function() return '' end
EntityGetRootEntity=function(e) return e end
EntityGetTransform=function() return 0,0 end
EntityGetInRadius=function() return {} end
EntityGetWithTag=function() return {} end
GlobalsGetValue=function(k,d) return globals[k] or d end
GlobalsSetValue=function(k,v) globals[k]=tostring(v) end
GameGetGameEffect=function() return 0 end
GameRemoveFlagRun=function() end
get_perk_picked_flag_name=function(id) return 'PERK_PICKED_'..id end
perk_list={
 {id='PROTECTION_ELECTRICITY',game_effect='PROTECTION_ELECTRICITY',ui_name='$perk_protection_electricity',ui_icon='data/ui_gfx/perk_icons/electricity.png'},
 {id='PROTECTION_RADIOACTIVITY',game_effect='PROTECTION_RADIOACTIVITY',ui_name='$perk_protection_radioactivity',ui_icon='data/ui_gfx/perk_icons/radioactivity.png'},
}
dofile_once=function(path) return true end
local native_dofile=dofile
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/features/perks/inverse_registry.lua' then return {zero_cleanup=function() end,maintenance_cleanup=function() end,has=function() return false end} end
 if path=='mods/metamorph_creative_menu/files/features/perks/transactions.lua' then return {has=function() return false end} end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
local editor=assert(native_dofile(root..'/files/features/perks/service.lua'))
local perk=perk_list[1]
local ok,reason=editor.remove_one(player,perk)
assert(ok,reason)
assert(globals.PERK_PICKED_PROTECTION_ELECTRICITY_PICKUP_COUNT=='0','counter not cleared')
assert(alive[2]==false,'legacy untagged protection effect was not retired')
assert(alive[3]==false,'legacy untagged matching protection UI icon was not removed')
-- Simulate a late perk-owned presentation recreation: maintenance must remove it, but
-- production maintenance is strict and will not touch unrelated untagged icons.
alive[4]=true; alive[5]=true; children[1]={2,4,5}; children[4]={}; children[5]={}
tags[4]={perk_entity=true}; tags[5]={perk_entity=true}
comps[40]={type='GameEffectComponent',effect='PROTECTION_ELECTRICITY',frames=-1}
comps[50]={type='UIIconComponent',name='$perk_protection_electricity',icon_sprite_file='data/ui_gfx/perk_icons/electricity.png'}
ent_comps[4]={GameEffectComponent=40}; ent_comps[5]={UIIconComponent=50}
frame=30
editor.update(player)
assert(alive[4]==false,'late perk-owned protection effect was not retired')
assert(alive[5]==false,'late perk-owned protection icon was not removed')
print('protection_zero_presentation=PASS legacy_untagged=true late_owned=true immediate_retire=true')
