local root=assert(arg[1],'root required')
local native_dofile=dofile
local runtime={enabled=function() return true end}
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/integrations/ew/runtime.lua' then return runtime end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
local globals={}
GlobalsGetValue=function(k,d) return globals[k] or d end
GlobalsSetValue=function(k,v) globals[k]=tostring(v) end
EntityGetIsAlive=function(e) return e==77 end
EntityGetTransform=function(e) assert(e==77); return 123.5,-44 end
GameGetFrameNum=function() return 321 end
local world=assert(native_dofile(root..'/files/integrations/ew/world_items.lua'))
local ok,reason=world.register_creative_perk(77,'TEST_PERK')
assert(ok==true and reason=='registered:1','creative perk registration failed')
assert(globals.mcm_creative_perk_spawn_seq_v1=='1','sequence not published last')
assert(globals['mcm_creative_perk_spawn_entity_v1:1']=='77','entity mailbox mismatch')
assert(globals['mcm_creative_perk_spawn_id_v1:1']=='TEST_PERK','perk id mailbox mismatch')
assert(globals['mcm_creative_perk_spawn_x_v1:1']=='123.5' and globals['mcm_creative_perk_spawn_y_v1:1']=='-44','position mailbox mismatch')
assert(globals['mcm_creative_perk_spawn_frame_v1:1']=='321','frame mailbox mismatch')
print('creative_perk_registration=PASS atomic_mailbox=true position=true frame=true')
