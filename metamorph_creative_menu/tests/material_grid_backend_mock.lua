local root=assert(arg[1], 'root required')
local native_dofile=dofile
local native_require=require
local bootstrap_options=nil
local patcher_bridge={get=function(options) bootstrap_options=options; return {GetWorldInfo=function() return {} end} end}
dofile=function(path)
    if path=='mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua' then return patcher_bridge end
    return native_dofile(path)
end

local loaded=true
local fail_construct_id=nil
local remove_calls,construct_calls,events,scene_calls={},{},{},{}
local cells={}
local ids={air=0,water=1,oil=2,rock_static=3,ptrless_valid=4}
local material_ptrs={
    [1]={id=1,cell_type=1,liquid_static=false,solid_static_type=0,platform_type=0,cell_holes_in_texture=false},
    [2]={id=2,cell_type=1,liquid_static=false,solid_static_type=0,platform_type=0,cell_holes_in_texture=false},
    -- Noita's authored *_static terrain may report cell_type=liquid while still being
    -- semantically solid/static. This fixture mirrors that shape instead of pretending
    -- CellFactory_GetAllSolids implies CELL_TYPE_SOLID.
    [3]={id=3,cell_type=1,liquid_static=true,solid_static_type=1,platform_type=1,cell_holes_in_texture=true},
}
local world_lookup_count=0
local function make_cell(id)
    local cell={material={id=id}}
    cell.vtable={get_material=function(self) return self.material end}
    return cell
end
local chunk_map={}
local grid_world={vtable={get_chunk_map=function(self) return chunk_map end}}
local world_ffi={}
function world_ffi.get_grid_world() world_lookup_count=world_lookup_count+1; return grid_world end
function world_ffi.chunk_loaded(map,x,y) assert(map==chunk_map); return loaded end
function world_ffi.get_cell(map,x,y)
    assert(map==chunk_map); local key=x..','..y
    cells[key]=cells[key] or {[0]=nil}; return cells[key]
end
function world_ffi.get_material_id(material) return material.id end
function world_ffi.remove_cell(world,cell,x,y,flag)
    assert(world==grid_world and flag==false)
    remove_calls[#remove_calls+1]={cell=cell,x=x,y=y}; events[#events+1]='remove:'..x..','..y
    cells[x..','..y][0]=nil
end
function world_ffi.get_material_ptr(id) return material_ptrs[id] end
function world_ffi.construct_cell(world,x,y,ptr,memory)
    assert(world==grid_world and memory==nil)
    construct_calls[#construct_calls+1]={x=x,y=y,id=ptr.id}; events[#events+1]='construct:'..x..','..y..':'..ptr.id
    if ptr.id==fail_construct_id then return nil end
    return make_cell(ptr.id)
end
require=function(name) if name=='noitapatcher.nsew.world_ffi' then return world_ffi end; return native_require(name) end
local compat_status="disabled"
function GlobalsGetValue(key,default) if key=="mcm_compat_material_scene_patch_v1" then return compat_status end; return default end
function GameGetFrameNum() return 100 end
function CellFactory_GetType(name) return ids[name] or -1 end
function DoesWorldExistAt() return loaded end
function LoadPixelScene(materials,colors,x,y,background,skip_biome,skip_edges,color_map,z,load_duplicate)
    scene_calls[#scene_calls+1]={materials=materials,x=x,y=y,map=color_map,skip_biome=skip_biome,skip_edges=skip_edges,duplicate=load_duplicate}
end

METAMORPH_CREATIVE_MENU_MATERIAL_GRID_BACKEND=nil
local backend=assert(native_dofile(root..'/files/platform/noita/material_grid.lua'))
local ok,reason=backend.status()
assert(ok and reason=='ready','grid backend did not initialize')
assert(type(bootstrap_options)=='table' and bootstrap_options.bootstrap_if_installed==true and bootstrap_options.capability=='GetWorldInfo',
    'grid backend does not bootstrap standalone NoitaPatcher through patcher_bridge')

local context=assert(backend.begin_paint('water'))
assert(context.mode=='direct_cell','liquid incorrectly routed away from direct cell backend')
assert(world_lookup_count==1,'begin_paint did not acquire one frame-local world context')
ok,reason=backend.paint_cell_prepared(context,10.8,20.9)
assert(ok and reason=='painted','empty liquid cell was not painted')
assert(#construct_calls==1 and construct_calls[1].x==10 and construct_calls[1].y==20 and construct_calls[1].id==1,'wrong constructed cell')
assert(cells['10,20'][0] and cells['10,20'][0].material.id==1,'constructed cell not assigned')

-- Same material does not churn native cells.
local constructs_before=#construct_calls
ok,reason=backend.paint_cell_prepared(context,10,20)
assert(ok and reason=='unchanged' and #construct_calls==constructs_before,'same material reconstructed')

-- Textured/static solid is deliberately routed through PixelScene, not construct_cell.
context=assert(backend.begin_paint('rock_static'))
assert(context.mode=='solid_scene','static terrain material was not detected from CellData semantic flags')
local before_construct=#construct_calls
ok,reason=backend.paint_cell_prepared(context,10,20)
assert(not ok and reason=='solid_scene_required' and #construct_calls==before_construct,'solid attempted unsafe direct construct')
ok,reason=backend.paint_solid_scene_prepared(context,'mods/test/brush.png',8,18,'ff5ac75a')
assert(ok and reason=='painted' and #scene_calls==1,'solid PixelScene placement failed')
assert(scene_calls[1].map.ff5ac75a=='rock_static' and scene_calls[1].skip_biome==true
    and scene_calls[1].skip_edges==false and scene_calls[1].duplicate==true,'solid PixelScene options changed')

-- A material known to CellFactory can lack a constructible native pointer. It remains
-- paintable through Noita's authored PixelScene path instead of disabling the brush.
local ptrless=assert(backend.begin_paint('ptrless_valid'))
assert(ptrless.mode=='solid_scene' and ptrless.material_ptr==nil,
    'valid pointerless material did not select the safe scene path')
ok,reason=backend.paint_solid_scene_prepared(ptrless,'mods/test/brush.png',8,18,'ff5ac75a')
assert(ok and reason=='painted' and #scene_calls==2
    and scene_calls[2].map.ff5ac75a=='ptrless_valid','pointerless material was not painted')

-- If MCM cannot install its narrow EW PixelScene guard, solid painting fails closed
-- instead of sending an invalid MCM-owned mask through stock EW. SP uses disabled.
compat_status='anchor_mismatch'
local scenes_before_failure=#scene_calls
ok,reason=backend.paint_solid_scene_prepared(context,'mods/test/brush.png',8,18,'ff5ac75a')
assert(not ok and reason=='ew_material_scene_patch' and #scene_calls==scenes_before_failure,'unsafe EW PixelScene fallback was not blocked')
compat_status='applied'

-- Failed liquid replacement still restores previous material.
context=assert(backend.begin_paint('oil'))
-- Put water back at a direct-cell location.
cells['30,40']={[0]=make_cell(1)}
fail_construct_id=2
local event_before=#events
ok,reason=backend.paint_cell_prepared(context,30,40)
assert(not ok and reason=='construct','forced liquid construct failure was not reported')
assert(events[event_before+1]=='remove:30,40' and events[event_before+2]=='construct:30,40:2'
    and events[event_before+3]=='construct:30,40:1','failed replacement did not rollback previous material')
assert(cells['30,40'][0] and cells['30,40'][0].material.id==1,'failed replacement destroyed previous terrain')
fail_construct_id=nil

-- PixelScene is the general authored-material fallback, not a solid-only primitive.
local generic_scenes_before=#scene_calls
ok,reason=backend.paint_scene_prepared(context,'mods/test/brush.png',28,38,'ff5ac75a')
assert(ok and reason=='painted' and #scene_calls==generic_scenes_before+1
    and scene_calls[#scene_calls].map.ff5ac75a=='oil',
    'generic PixelScene fallback rejected a valid dynamic material')

loaded=false; context=assert(backend.begin_paint('water'))
local removes_before=#remove_calls; constructs_before=#construct_calls
ok,reason=backend.paint_cell_prepared(context,50,60)
assert(not ok and reason=='unloaded','unloaded direct-cell chunk was not rejected')
assert(#remove_calls==removes_before and #construct_calls==constructs_before,'unloaded world was mutated')
local solid=assert(backend.begin_paint('rock_static'))
ok,reason=backend.paint_solid_scene_prepared(solid,'mods/test/brush.png',50,60,'ff5ac75a')
assert(not ok and reason=='unloaded' and #scene_calls==3,'unloaded solid scene was written')

assert(backend.begin_paint('missing')==nil,'invalid material was accepted')
io.write('material_grid_backend=PASS direct=true generic_scene_fallback=true rollback=true unloaded_safe=true\n')
