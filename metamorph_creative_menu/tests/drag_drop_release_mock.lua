local root=assert(arg[1])
local native_dofile=dofile
dofile=function(path)
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
local mouse_x,mouse_y=10,10
local world_x,world_y=100,100
local down=true
local just_down=true
METAMORPH_CREATIVE_MENU_POINTER={
 left_down=function() return down end,
 left_just_down=function() return just_down end,
 gui_position=function() return mouse_x,mouse_y end,
 world_position=function() return world_x,world_y end,
 inside=function(x,y,w,h,px,py)
  return px~=nil and py~=nil and px>=x and px<=x+w and py>=y and py<=y+h
 end,
}
local drag=assert(native_dofile(root..'/files/ui/drag_drop.lua'))
drag.begin_frame(427,242)
assert(drag.source('source',{kind='anything'},true)==true,'fresh press did not arm source')
assert(drag.end_frame()==nil,'held press completed too early')

just_down=false; mouse_x=30; mouse_y=10
drag.begin_frame(427,242)
assert(drag.active()==true,'drag threshold did not activate')
assert(drag.end_frame()==nil,'active held drag completed too early')

down=false; mouse_x=300; mouse_y=120; world_x=777; world_y=-55
drag.begin_frame(427,242)
local result=assert(drag.end_frame())
assert(result.target==nil and result.reason=='no_target','empty release unexpectedly found a target')
assert(result.start_x==10 and result.start_y==10,'press origin metadata lost')
assert(result.release_x==300 and result.release_y==120,'release gui position metadata lost')
assert(result.world_x==777 and result.world_y==-55,'release world position metadata lost')
print('drag_drop_release=PASS generic_release_metadata=true no_target=true')
