local root=assert(arg[1],'root required')
local native_dofile=dofile
local pending=false
local click_count=0
local target_count=0

local ui={
 gui=function() return 1 end,
 tr=function(_,fallback) return fallback end,
 white_text=function() end,
 wrapped_text=function() end,
 button=function() return true,false,10,10,20,10 end,
}
local drag={
 target=function() target_count=target_count+1 end,
 pending=function() return pending end,
}
local strip={draw=function() error('empty Always Cast must not draw strip') end}

dofile=function(path)
 local prefix='mods/metamorph_creative_menu/'
 if path==prefix..'files/ui/runtime.lua' then return ui end
 if path==prefix..'files/ui/drag_drop.lua' then return drag end
 if path==prefix..'files/ui/widgets/horizontal_strip.lua' then return strip end
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
GuiLayoutBeginHorizontal=function() end
GuiLayoutEnd=function() end

METAMORPH_CREATIVE_MENU_WAND_ALWAYS_CAST_UI=nil
local view=assert(native_dofile(root..'/files/ui/components/wand_always_cast_strip.lua'))

pending=false
view.draw({},180,640,360,nil,{on_add_click=function() click_count=click_count+1 end})
assert(click_count==1,'ordinary + click no longer promotes selected spell')
assert(target_count==1,'Always Cast + lost its drop target')

pending=true
view.draw({},180,640,360,nil,{on_add_click=function() click_count=click_count+1 end})
assert(click_count==1,'drag release over + also fired the ordinary click promotion')
assert(target_count==2,'drag-owned release removed Always Cast drop target')
print('wand_always_cast_drop_click=PASS click=true drag_release_single_mutation=true')
