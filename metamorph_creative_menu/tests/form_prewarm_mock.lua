local root=assert(arg[1])
local candidates={
 {path='data/entities/animals/drone.xml'},
 {path='data/entities/animals/mimic_potion.xml'},
 {path='data/entities/animals/boss_book/book_physics.xml'},
 {path='data/entities/animals/boss_sky/boss_sky.xml'},
 {path='data/entities/animals/boss_limbs/boss_limbs_physics.xml'},
 {path='data/entities/animals/lukki/lukki_creepy.xml'},
 {path='data/entities/animals/darkghost.xml'},
}
local writes={}
ModDoesFileExist=function() return true end
ModTextFileSetContent=function(path,text) writes[path]=text; return true end
ModTextFileGetContent=function() return '<Entity></Entity>' end
local native=dofile
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua' then return {get=function() return nil end} end
 if path=='mods/metamorph_creative_menu/files/platform/noita/player_locator.lua' then return {get=function() return 0 end} end
 if path=='mods/metamorph_creative_menu/files/core/hash.lua' then return {hex64=function(v) return tostring(#tostring(v))..'abcd' end} end
 if path=='mods/metamorph_creative_menu/files/features/forms/profile.lua' then return {} end
 if path=='mods/metamorph_creative_menu/files/features/forms/runtime.lua' then return {reset=function() end} end
 if path=='mods/metamorph_creative_menu/files/features/creatures/service.lua' then return {collect_prewarm_candidates=function() return candidates end, collect_all_candidates=function() error('UI compatibility API must not drive prewarm') end} end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native(root..'/'..string.sub(path,#prefix+1)) end
 return native(path)
end
local fm=assert(native(root..'/files/features/forms/manager.lua'))
local n=fm.prepare_exact_effect_paths_from_catalog()
assert(n==#candidates,'prepared '..tostring(n)..' expected '..#candidates)
for _,e in ipairs(candidates) do
 local p=fm.exact_effect_path_for_target(e.path)
 assert(type(p)=='string' and p~='', 'missing exact effect '..e.path)
 assert(type(writes[p])=='string' and writes[p]:find(e.path,1,true), 'effect XML target missing '..e.path)
end
print('form_prewarm_publish=PASS prepared='..tostring(n))
