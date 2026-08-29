local root=assert(arg[1], 'root required')
local native_dofile=dofile
local globals={}
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/integrations/ew/runtime.lua' then return {enabled=function() return true end} end
 return native_dofile(path)
end
function GlobalsSetValue(k,v) globals[k]=tostring(v) end
function GlobalsGetValue(k,d) return globals[k] or d end
METAMORPH_CREATIVE_MENU_EW_PERK_VISIBILITY=nil
local visibility=assert(native_dofile(root..'/files/integrations/ew/perk_visibility.lua'))
local tx={source_count=function(perk_id,source,player) assert(perk_id=='GOLD_IS_FOREVER' and source=='mcm_creative' and player==7); return 2 end}
assert(visibility.refresh('GOLD_IS_FOREVER',7,tx)==true,'visibility refresh failed')
assert(globals['mcm_creative_perk_hidden_count_v1:GOLD_IS_FOREVER']=='2','creative hidden count not published')
assert(visibility.hidden_count('GOLD_IS_FOREVER')==2,'published hidden count did not roundtrip')
assert(visibility.publish('GOLD_IS_FOREVER',-4)==true and visibility.hidden_count('GOLD_IS_FOREVER')==0,'hidden count was not clamped')
print('ew_perk_visibility=PASS source_count_published=true bounded_nonnegative=true')
