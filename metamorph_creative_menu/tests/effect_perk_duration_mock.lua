local root=assert(arg[1])
local native_dofile=dofile
local path='data/entities/misc/effect_test.xml'
local entry={kind='game_effect',id='TEST',path=path,icon='',display_name='Test',display_description='',game_effect='CUSTOM',custom_effect_id='TEST'}
local alive={[1]=true,[10]=true}
local children={[1]={10}}
local frames={[100]=600,[110]=0}
local tags={[10]={perk_entity=true}}
local catalog={entries=function() return {entry} end,status_entries=function() return {} end,reserved_effects=function() return {} end}
dofile=function(p)
 if p=='mods/metamorph_creative_menu/files/features/effects/catalog.lua' then return catalog end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(p,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(p,#prefix+1)) end
 return native_dofile(p)
end
function EntityGetIsAlive(e) return alive[e]==true end
function EntityGetAllChildren(e) local o={} for _,c in ipairs(children[e] or {}) do if alive[c] then o[#o+1]=c end end return o end
function EntityGetFilename(e) return (e==10 or e==11) and path or '' end
function EntityHasTag(e,t) return tags[e] and tags[e][t] or false end
function EntityAddTag(e,t) tags[e]=tags[e] or {}; tags[e][t]=true end
function EntityGetComponentIncludingDisabled(e,k)
 if k=='GameEffectComponent' then if e==10 then return {100} elseif e==11 then return {110} end end
 return {}
end
function EntityGetFirstComponentIncludingDisabled(e,k)
 local v=EntityGetComponentIncludingDisabled(e,k); if #v>0 then return v[1] end
 return 0
end
function ComponentGetValue2(c,f)
 if c==100 or c==110 then if f=='frames' then return frames[c] elseif f=='effect' then return 'CUSTOM' elseif f=='custom_effect_id' then return 'TEST' end end
 return nil
end
function ComponentSetValue2(c,f,v) if f=='frames' then frames[c]=v end end
function ModDoesFileExist(p) return p==path end
function LoadGameEffectEntityTo(player,p) assert(player==1 and p==path); alive[11]=true; children[1][#children[1]+1]=11; return 11 end
function EntityAddComponent2() return 500 end
function EntityKill(e) alive[e]=false end
function GameGetFrameNum() return 1 end
METAMORPH_CREATIVE_MENU_EFFECT_SERVICE=nil; METAMORPH_CREATIVE_MENU_EFFECT_EDITOR=nil
local effects=assert(native_dofile(root..'/files/features/effects/service.lua'))
local ok,why=effects.set_remaining(1,entry,120)
assert(ok==false and why=='inactive' and frames[100]==600,'duration editor modified perk-owned effect')
ok,why=effects.add(1,entry,300)
assert(ok==true and frames[100]==600 and frames[110]==300,'adding editor effect reused/extended perk-owned entity')
assert(tags[11] and tags[11].metamorph_creative_menu_effect==true,'new editor effect was not ownership-tagged')
assert(effects.set_remaining(1,entry,90)==true and frames[110]==90 and frames[100]==600,'editable effect duration did not stay isolated from perk')
print('effect_perk_duration=PASS perk_untouched=true editor_owned_copy=true')
