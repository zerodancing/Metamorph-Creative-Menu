local root=assert(arg[1])
local native_dofile=dofile
local mouse_x,mouse_y=10,10
local world_x,world_y=100,100
local down=false
local just_down=false
METAMORPH_CREATIVE_MENU_POINTER={
 left_down=function() return down end,
 left_just_down=function() return just_down end,
 gui_position=function() return mouse_x,mouse_y end,
 world_position=function() return world_x,world_y end,
 inside=function(x,y,w,h,px,py)
  return px~=nil and py~=nil and px>=x and px<=x+w and py>=y and py<=y+h
 end,
}
dofile=function(path)
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
METAMORPH_CREATIVE_MENU_DRAG_DROP=nil
local drag=assert(native_dofile(root..'/files/ui/drag_drop.lua'))
local visible={x=0,y=0,width=40,height=30}
local tile={x=4,y=4,width=18,height=18}

-- Measured press-origin wins even when Gui hover is false. Clipping still prevents a
-- hidden/off-viewport tile from claiming a press.
down=true; just_down=true; mouse_x=10; mouse_y=10
drag.begin_frame(320,240)
assert(drag.source('hidden',{kind='catalog_spell'},tile,{x=30,y=30,width=20,height=20},false)==false,
 'clipped-away source claimed the press')
assert(drag.source('catalog.A',{kind='catalog_spell',action_id='A'},tile,visible,false)==true,
 'measured tile bounds did not claim press-origin without hover')
assert(drag.pending() and not drag.active(),'fresh source should be pending before threshold')
assert(drag.end_frame()==nil,'held press completed in source frame')

-- The source is intentionally not registered again: it disappeared from the viewport.
-- begin_frame must keep the original owner and payload alive while pointer movement crosses
-- the threshold. Reflow may replace every target geometry without touching the source.
just_down=false; mouse_x=30; mouse_y=10
drag.begin_frame(320,240)
assert(drag.active()==true and drag.source_id()=='catalog.A','source vanished when its tile left the viewport')
assert(drag.payload().action_id=='A','payload changed after source virtualization')
drag.target('old.slot',{x=60,y=0,width=18,height=18},function() return true end,function() error('stale target fired') end,10)
assert(drag.end_frame()==nil,'held drag completed during reflow frame')

-- A later frame represents scroll/reflow: old targets are gone because begin_frame resets
-- them, and only the newly drawn target may commit on release.
local commits=0
mouse_x=82; mouse_y=12; down=true
drag.begin_frame(320,240)
drag.target('new.slot',{x=74,y=4,width=18,height=18},function(payload) return payload.action_id=='A' end,function()
 commits=commits+1; return true,'moved'
end,20)
assert(drag.end_frame()==nil,'held drag completed before release')

down=false; mouse_x=82; mouse_y=12
drag.begin_frame(320,240)
local gx,gy=drag.mouse_position()
assert(gx==82 and gy==12 and drag.active()==true,'ghost did not survive through the release frame')
drag.target('new.slot',{x=74,y=4,width=18,height=18},function(payload) return payload.action_id=='A' end,function()
 commits=commits+1; return true,'moved'
end,20)
local result=assert(drag.end_frame())
assert(result.target=='new.slot' and result.ok==true and commits==1,'reflowed target did not receive exactly one commit')

-- A target that refuses the payload must not run its mutation callback and must not turn
-- the same release into a second operation.
down=true; just_down=true; mouse_x=10; mouse_y=10
drag.begin_frame(320,240)
assert(drag.source('wand.1',{kind='wand_spell',entity=11},tile,visible)==true)
just_down=false; mouse_x=30; drag.begin_frame(320,240); assert(drag.active())
local refused_calls=0
drag.target('reject',{x=45,y=4,width=18,height=18},function() return false end,function() refused_calls=refused_calls+1; return true end,100)
down=false; mouse_x=50; drag.begin_frame(320,240)
drag.target('reject',{x=45,y=4,width=18,height=18},function() return false end,function() refused_calls=refused_calls+1; return true end,100)
result=assert(drag.end_frame())
assert(result.target==nil and result.ok==false and refused_calls==0,'refused target mutated source or reported a commit')

-- Outside release is metadata only at the generic layer. The Spells tab decides whether
-- this no-target release is world/native-inventory or an in-menu cancel.
down=true; just_down=true; mouse_x=10; mouse_y=10
drag.begin_frame(320,240); assert(drag.source('inventory.7',{kind='inventory_spell',entity=7},tile,visible))
just_down=false; mouse_x=30; drag.begin_frame(320,240); assert(drag.active())
down=false; mouse_x=300; mouse_y=200; world_x=777; world_y=-55
drag.begin_frame(320,240)
result=assert(drag.end_frame())
assert(result.target==nil and result.reason=='no_target' and result.release_x==300 and result.world_x==777,
 'outside release metadata changed')

-- Sub-threshold motion remains an ordinary click; drag sensitivity was not lowered.
down=true; just_down=true; mouse_x=10; mouse_y=10
drag.begin_frame(320,240); assert(drag.source('catalog.click',{kind='catalog_spell',action_id='CLICK'},tile,visible))
just_down=false; mouse_x=12; mouse_y=11; drag.begin_frame(320,240)
assert(not drag.active(),'ordinary click crossed drag threshold too early')
down=false; drag.begin_frame(320,240)
result=assert(drag.end_frame())
assert(result.click==true and result.payload.action_id=='CLICK','ordinary click no longer resolves as click')

-- Overlapping accepted targets still execute at most one operation: highest priority wins.
down=true; just_down=true; mouse_x=10; mouse_y=10
drag.begin_frame(320,240); assert(drag.source('single.release',{kind='wand_spell',entity=9},tile,visible))
just_down=false; mouse_x=30; drag.begin_frame(320,240); assert(drag.active())
down=false; mouse_x=55; mouse_y=10; drag.begin_frame(320,240)
local high,low=0,0
local overlap={x=45,y=4,width=20,height=20}
drag.target('low',overlap,function() return true end,function() low=low+1; return true end,1)
drag.target('high',overlap,function() return true end,function() high=high+1; return true end,200)
result=assert(drag.end_frame())
assert(result.target=='high' and high==1 and low==0,'one release executed more than one target operation')

-- A completed result is intentionally consumed on the following GUI frame. If the menu
-- closes/minimizes before that frame, cancel() must discard it instead of replaying the
-- stale click/drop after the menu is opened again.
down=true; just_down=true; mouse_x=10; mouse_y=10
drag.begin_frame(320,240); assert(drag.source('stale.result',{kind='catalog_item'},tile,visible))
just_down=false; down=false
drag.begin_frame(320,240); result=assert(drag.end_frame())
assert(result.click==true and drag.last_result()~=nil,'completed result was not retained for normal next-frame consumption')
drag.cancel()
assert(drag.take_result()==nil and drag.last_result()==nil,'cancel kept a stale completed result across menu lifecycle')


local function read(path)
 local handle=assert(io.open(root..'/'..path,'rb'))
 local text=handle:read('*a'); handle:close(); return text
end
local menu=read('files/ui/menu_controller.lua')
local tab_draw=assert(string.find(menu,'pcall(tab.module.draw',1,true),'menu no longer draws tab module through expected lifecycle')
local arbitrate=assert(string.find(menu,'if pointer_operation == nil and not tile_press_owned',1,true),
 'window move/resize does not yield to tile press owner')
assert(tab_draw<arbitrate,'window move/resize is armed before draggable tile sources can claim press')

print('drag_drop_lifecycle=PASS press_origin=true source_persists=true reflow_safe=true reject_safe=true outside_metadata=true click_threshold=true single_commit=true lifecycle_cancel=true window_yields=true')
