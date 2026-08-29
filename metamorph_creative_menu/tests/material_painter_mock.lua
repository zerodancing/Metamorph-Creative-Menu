local root=assert(arg[1], 'root required')
local native_dofile=dofile
local actions_allowed=true
local buttons
local input_guard={actions_allowed=function() return actions_allowed end}
local action_bindings={
    get=function(id) assert(id=='paint_draw'); return 'Mouse:3' end,
    is_down=function(id) assert(id=='paint_draw'); return buttons and buttons[3]==true end,
}
local grid_calls={}
local solid_calls={}
local generic_scene_calls={}
local sync_calls={}
local begin_calls=0
local last_begin_options=nil
local backend_ready=true
local direct_construct_fails=false
local ids={water=1,oil=2,rock_static=3}
local grid_backend={
    status=function() return backend_ready, backend_ready and 'ready' or 'noitapatcher' end,
    material_id=function(name) return ids[name] end,
    begin_paint=function(material,options)
        begin_calls=begin_calls+1
        last_begin_options=options
        local force_scene=type(options)=='table' and options.force_scene==true
        return {material=material,mode=(force_scene or material=='rock_static') and 'solid_scene' or 'direct_cell'},'ready'
    end,
    paint_cell_prepared=function(context,x,y)
        assert(context.mode=='direct_cell','solid leaked into direct cell painter')
        grid_calls[#grid_calls+1]={material=context.material,x=x,y=y}
        if direct_construct_fails then return false,'construct' end
        return true,'painted'
    end,
    paint_scene_prepared=function(context,file,x,y,color)
        assert(context.mode=='direct_cell','generic fallback did not preserve direct material context')
        generic_scene_calls[#generic_scene_calls+1]={material=context.material,file=file,x=x,y=y,color=color}
        return true,'painted'
    end,
    paint_solid_scene_prepared=function(context,file,x,y,color)
        assert(context.mode=='solid_scene','non-solid leaked into PixelScene painter')
        solid_calls[#solid_calls+1]={material=context.material,file=file,x=x,y=y,color=color}
        return true,'painted'
    end,
}
local material_sync={
    publish_batch=function(material,solid,brush,points)
        sync_calls[#sync_calls+1]={material=material,solid=solid,brush=brush,points=points}
        return true
    end,
}
dofile=function(path)
    if path=='mods/metamorph_creative_menu/files/platform/noita/input_guard.lua' then return input_guard end
    if path=='mods/metamorph_creative_menu/files/platform/noita/action_bindings.lua' then return action_bindings end
    if path=='mods/metamorph_creative_menu/files/platform/noita/material_grid.lua' then return grid_backend end
    if path=='mods/metamorph_creative_menu/files/integrations/ew/material_paint_sync.lua' then return material_sync end
    return native_dofile(path)
end

Mouse_middle=3
buttons={[1]=false,[3]=false}
local mouse_x,mouse_y=100,200
local inventory_is_open=true
local game_prints={}
function InputIsMouseButtonDown(button)
    assert(button==3,'material painter must consume only middle mouse')
    return buttons[button]==true
end
function DEBUG_GetMouseWorld() return mouse_x,mouse_y end
function GameIsInventoryOpen() return inventory_is_open end
function EntityGetIsAlive(id) return id==77 end
function GameGetFrameNum() return 100 end
function GamePrint(text) game_prints[#game_prints+1]=text end
function CellFactory_GetType(name) return ids[name] or -1 end
function EntityGetFirstComponentIncludingDisabled() error('material painter must not mutate ControlsComponent') end
function ComponentSetValue2() error('material painter must not mutate ControlsComponent') end

METAMORPH_CREATIVE_MENU_MATERIAL_PAINTER=nil
local painter=assert(native_dofile(root..'/files/features/materials/painter.lua'))
assert(painter.paint_button()==3,'middle mouse constant not resolved')
assert(painter.set_material('missing')==false,'invalid material accepted')
assert(painter.set_material('rock_static')==true,'valid solid material rejected')
assert(painter.brush_diameter()==5,'default brush size changed unexpectedly')

backend_ready=false
local enabled,reason=painter.set_enabled(true)
assert(enabled==false and reason=='noitapatcher' and painter.is_enabled()==false,'unavailable backend armed painter')
backend_ready=true
assert(painter.set_enabled(true)==true and painter.is_enabled()==true,'paint mode did not arm')

local painted
painted,reason=painter.update(77)
assert(painted==false and reason=='armed_in_menu','menu-open armed state painted world')
inventory_is_open=false
buttons[1]=true
painted,reason=painter.update(77)
assert(painted==false and reason=='idle','LMB incorrectly drives material brush')

-- Solid uses one PixelScene stamp, not per-cell native construction.
buttons[3]=true
painted,reason=painter.update(77)
assert(painted==true and reason=='painted','MMB solid press did not paint')
assert(#solid_calls==1 and #grid_calls==0,'solid brush did not use dedicated PixelScene path')
assert(solid_calls[1].material=='rock_static' and solid_calls[1].color=='ff5ac75a','solid material/mask changed')
assert(solid_calls[1].x==98 and solid_calls[1].y==198,'solid mask was not centered on cursor')
assert(#sync_calls==1 and sync_calls[1].material=='rock_static' and sync_calls[1].solid==true,
    'actual solid backend mode was not published to EW adapter')

-- Continuous solid movement is interpolated by stamp count.
mouse_x=110; mouse_y=200
painter.update(77)
assert(#solid_calls>1,'solid continuous stroke did not interpolate movement')

-- Liquid retains the direct-cell backend that worked in-game.
buttons[3]=false; painter.update(77)
assert(painter.set_material('water')==true,'liquid selection failed')
buttons[3]=true; mouse_x,mouse_y=120,210
local before_liquid=#grid_calls
painter.update(77)
assert(#grid_calls-before_liquid==13,'5px circular liquid brush should write 13 direct cells')
for i=before_liquid+1,#grid_calls do assert(grid_calls[i].material=='water','liquid path changed material') end
assert(sync_calls[#sync_calls].material=='water' and sync_calls[#sync_calls].solid==false,
    'liquid backend mode was not published to EW adapter')
assert(begin_calls>=3,'paint context was not acquired per painted frame')

-- A cursor jump larger than the per-frame budget must be continued on later frames,
-- never skipped. Radius zero makes every missing interpolation point observable.
buttons[3]=false; painter.update(77)
assert(painter.set_material('water')==true)
painter.set_brush_index(1)
buttons[3]=true; mouse_x,mouse_y=200,220
painter.update(77)
local moving_sync_start=#sync_calls
mouse_x=240
for _=1,5 do painter.update(77) end
local expected_x=201
for i=moving_sync_start+1,#sync_calls do
    for _,point in ipairs(sync_calls[i].points) do
        assert(point[1]==expected_x and point[2]==220,
            'bounded moving stroke skipped or reordered point '..tostring(expected_x))
        expected_x=expected_x+1
    end
end
assert(expected_x==241,'moving stroke did not eventually reach the live cursor')

-- construct_cell can legitimately refuse a valid dynamic material at authored texture
-- coordinates. The painter must fall back to a one-stamp PixelScene placement and still
-- publish the operation as dynamic terrain.
buttons[3]=false; painter.update(77)
assert(painter.set_material('oil')==true)
direct_construct_fails=true
buttons[3]=true; mouse_x,mouse_y=300,230
painted,reason=painter.update(77)
direct_construct_fails=false
assert(painted and reason=='painted' and #generic_scene_calls==1,
    'valid dynamic material was lost when direct construction failed')
assert(generic_scene_calls[1].material=='oil' and sync_calls[#sync_calls].material=='oil'
    and sync_calls[#sync_calls].solid==false,'dynamic PixelScene fallback changed sync semantics')


-- Public CellFactory SOLIDS membership is forwarded as an explicit semantic hint. This
-- covers authored terrain that reports an internal liquid cell_type (e.g. *_static).
buttons[3]=false; painter.update(77)
assert(painter.set_material('oil',{solid=true})==true,'semantic solid selection failed')
buttons[3]=true; mouse_x,mouse_y=125,215
local semantic_solid_before=#solid_calls
painter.update(77)
assert(type(last_begin_options)=='table' and last_begin_options.force_scene==true,'SOLIDS membership was not forwarded to backend')
assert(#solid_calls>semantic_solid_before and solid_calls[#solid_calls].material=='oil','semantic solid did not use PixelScene path')

actions_allowed=false; buttons[3]=true
local before_block=#grid_calls; local before_solid=#solid_calls
painted,reason=painter.update(77)
assert(not painted and reason=='input_blocked' and #grid_calls==before_block and #solid_calls==before_solid and painter.is_enabled(),
    'input quarantine did not safely pause painter')
actions_allowed=true

buttons[3]=false; inventory_is_open=true
painted,reason=painter.update(77)
assert(not painted and reason=='menu_reopened' and painter.is_enabled()==false,'reopening inventory did not disarm paint mode')
inventory_is_open=true; assert(painter.set_enabled(true)==true)
painted,reason=painter.update(0)
assert(not painted and reason=='player' and painter.is_enabled()==false,'invalid player left painter armed')

io.write('material_painter=PASS materials_fallback=true moving_continuous=true bounded=true lifecycle=true\n')
