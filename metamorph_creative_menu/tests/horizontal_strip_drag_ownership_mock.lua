local root=assert(arg[1])
local native_dofile=dofile
local mouse_x,mouse_y=10,10
local down=true
local just_down=true
local clicked_image=nil
local scroll_model_loaded=false

METAMORPH_CREATIVE_MENU_POINTER={
 gui_position=function() return mouse_x,mouse_y end,
 left_down=function() return down end,
 left_just_down=function() return just_down end,
 inside=function(x,y,w,h,px,py) return px>=x and px<=x+w and py>=y and py<=y+h end,
}
local prefix='mods/metamorph_creative_menu/'
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/ui/widgets/scroll_model.lua' then
  scroll_model_loaded=true
  error('horizontal strip must not load the wheel scroll model')
 end
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
GUI_OPTION={Layout_NoLayouting=1}
local last={x=0,y=0,w=0,h=0}
local row_y=4
local nav_x=0
local in_layout=false
GuiOptionsAddForNextWidget=function() end
local z_calls={}
GuiColorSetForNextWidget=function() end
GuiZSetForNextWidget=function(_,z) z_calls[#z_calls+1]=z end
GuiText=function() end
GuiLayoutBeginHorizontal=function() in_layout=true; nav_x=0 end
GuiLayoutEnd=function() if in_layout then row_y=row_y+22 end; in_layout=false end
GuiButton=function(_,_,_,_,_)
 last={x=nav_x,y=row_y,w=10,h=9}; nav_x=nav_x+12
 return false
end
GuiImageButton=function(_,_,_,_,_,image)
 last={x=nav_x,y=row_y,w=9,h=17}; nav_x=nav_x+11
 return image==clicked_image
end
GuiImage=function(_,_,x,y,_,_,sx,sy)
 if in_layout then last={x=nav_x,y=row_y,w=tonumber(sx) or 1,h=tonumber(sy) or 1}; nav_x=nav_x+(tonumber(sx) or 1)+2
 else last={x=x,y=y,w=tonumber(sx) or 1,h=tonumber(sy) or 1} end
end
GuiGetPreviousWidgetInfo=function() return 0,0,false,last.x,last.y,last.w,last.h end

METAMORPH_CREATIVE_MENU_HORIZONTAL_STRIP=nil
local strip=assert(native_dofile(root..'/files/ui/widgets/horizontal_strip.lua'))
local function draw_item(index)
 return false,false,true,4+index*20,4,18,18
end
local next_id_value=0
local function next_id() next_id_value=next_id_value+1; return next_id_value end
local options={gui=1,screen_width=320,screen_height=240,next_id=next_id}

-- LMB motion is never a strip-pan gesture. Occupied-card presses therefore stay available
-- to drag_drop for the entire gesture instead of competing with a second recognizer.
local first=strip.draw('no_pan',8,80,20,draw_item,options)
assert(first.offset==0,'initial horizontal offset changed without wheel input')
just_down=false; mouse_x=50
local second=strip.draw('no_pan',8,80,20,draw_item,options)
assert(second.offset==0,'LMB movement unexpectedly panned the horizontal strip')
down=false
strip.draw('no_pan',8,80,20,draw_item,options)

-- The inline right arrow advances exactly one visible page.
clicked_image='mods/metamorph_creative_menu/files/ui/assets/page_right.png'
local third=strip.draw('no_pan',8,80,20,draw_item,options)
assert(third.offset==2,'right arrow did not advance one visible page')
clicked_image=nil
local fourth=strip.draw('no_pan',8,80,20,draw_item,options)
assert(fourth.first==2,'advanced page was not rendered on the next frame')

-- The inline left arrow returns one page without a wheel or drag recognizer.
clicked_image='mods/metamorph_creative_menu/files/ui/assets/page_left.png'
local fifth=strip.draw('no_pan',8,80,20,draw_item,options)
assert(fifth.offset==0 and fifth.first==0,'left arrow did not return one visible page')
assert(not scroll_model_loaded,'horizontal strip unexpectedly loaded wheel scrolling')
local foreground=false
for _,z in ipairs(z_calls) do if tonumber(z) and tonumber(z)<=-110 then foreground=true end end
assert(foreground,'navigation arrows were not forced in front of the menu background')

print('horizontal_strip_drag_ownership=PASS lmb_pan=false wheel=false arrows=true page_step=2 single_tall_arrows=true foreground_z=true')
