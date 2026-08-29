local root=assert(arg[1])
local native_dofile=dofile
local mouse_x,mouse_y=10,10
local down=true
local just_down=true
local wheel=0

METAMORPH_CREATIVE_MENU_POINTER={
 gui_position=function() return mouse_x,mouse_y end,
 left_down=function() return down end,
 left_just_down=function() return just_down end,
 inside=function(x,y,w,h,px,py) return px>=x and px<=x+w and py>=y and py<=y+h end,
}
local scroll_stub={
 HORIZONTAL_STEP=3,
 consume_wheel=function() return wheel end,
 horizontal_offset=function(offset,count,visible_count,delta,step)
  local maximum=math.max(0,count-visible_count)
  local next_offset=math.max(0,math.min(maximum,offset+delta*(step or 3)))
  return next_offset,maximum
 end,
}
local prefix='mods/metamorph_creative_menu/'
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/ui/widgets/scroll_model.lua' then return scroll_stub end
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
GuiLayoutBeginHorizontal=function() end
GuiLayoutEnd=function() end

METAMORPH_CREATIVE_MENU_HORIZONTAL_STRIP=nil
local strip=assert(native_dofile(root..'/files/ui/widgets/horizontal_strip.lua'))
local function draw_item(index)
 return false,false,true,4+index*20,4,18,18
end
local options={gui=1,screen_width=320,screen_height=240}

-- LMB motion is never a strip-pan gesture. Occupied-card presses therefore stay available
-- to drag_drop for the entire gesture instead of competing with a second recognizer.
local first=strip.draw('no_pan',8,80,20,draw_item,options)
assert(first.offset==0,'initial horizontal offset changed without wheel input')
just_down=false; mouse_x=50
local second=strip.draw('no_pan',8,80,20,draw_item,options)
assert(second.offset==0,'LMB movement unexpectedly panned the horizontal strip')
down=false
strip.draw('no_pan',8,80,20,draw_item,options)

-- Wheel remains the sole horizontal scroll gesture and uses the fixed three-slot step.
wheel=1
local third=strip.draw('no_pan',8,80,20,draw_item,options)
assert(third.offset==3,'horizontal wheel did not move by the fixed three-slot step')

print('horizontal_strip_drag_ownership=PASS lmb_pan=false card_drag_uncontested=true wheel_step=3')
