local root=assert(arg[1], 'root required')
local patches=assert(dofile(root..'/files/integrations/ew/resilience_patches.lua'))
local source=[[
local old_LoadPixelScene = LoadPixelScene
function LoadPixelScene(materials_filename,colors_filename,x,y,background_file,skip_biome_checks,skip_edge_textures,color_to_material_table,background_z_index,load_even_if_duplicate)
    old_LoadPixelScene(materials_filename,colors_filename,x,y,background_file,skip_biome_checks,skip_edge_textures,color_to_material_table,background_z_index,load_even_if_duplicate)
    -- TODO there are a couple more parameters, tho they don't seem to be used in vanilla
    CrossCall(
        "ew_sync_pixel_scene",
        materials_filename,
        colors_filename,
        x,
        y,
        background_file,
        skip_biome_checks,
        skip_edge_textures
    )
end
return true
]]
local patched,count=patches.patch_material_pixel_scene_source(source)
assert(count==1 and patched:find('mcm_material_brush_pixel_scene_v1',1,true),'material scene patch did not apply')
local again,again_count=patches.patch_material_pixel_scene_source(patched)
assert(again_count==0 and again==patched,'material scene patch not idempotent')
local unchanged,missing=patches.patch_material_pixel_scene_source('return true')
assert(missing==0 and unchanged=='return true','anchor mismatch modified unrelated EW source')

local local_loads,network_calls={},{}
LoadPixelScene=function(...) end -- captured as old_LoadPixelScene by patched chunk
CrossCall=function(name,...)
    network_calls[#network_calls+1]={name=name,args={...}}
end
local chunk,err=load(patched,'patched_synced_pixel_scenes','t',_G); assert(chunk,err); chunk()
-- The patched wrapper replaced the global function. MCM brush must still be applied
-- locally but must not enter EW's filename-only pixel-scene RPC.
-- Rebuild with a recorder because source captured the global that existed at load time.
LoadPixelScene=function(...) local_loads[#local_loads+1]={...} end
local chunk2=assert(load(patched,'patched_synced_pixel_scenes2','t',_G)); chunk2()
LoadPixelScene('mods/metamorph_creative_menu/files/features/materials/brushes/brush_r2.png','',10,20,'',true,false,{ff5ac75a='rock_static'},50,true)
assert(#local_loads==1,'MCM brush scene was not applied locally')
assert(#network_calls==0,'MCM dynamic brush leaked into EW filename-only pixel-scene RPC')

LoadPixelScene('data/biome_impl/some_scene.png','data/biome_impl/some_colors.png',30,40,'',false,false,nil,50,false)
assert(#local_loads==2,'ordinary EW pixel scene stopped loading locally')
assert(#network_calls==1 and network_calls[1].name=='ew_sync_pixel_scene','ordinary EW pixel-scene synchronization was changed')
print('ew_material_pixel_scene_patch=PASS mcm_scene_local_only=true upstream_scene_sync_preserved=true')
