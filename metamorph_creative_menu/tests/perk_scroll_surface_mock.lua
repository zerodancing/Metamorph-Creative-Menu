local root=assert(arg[1],'root required')
local native_dofile=dofile
local buttons={}
local tiles=0
local ui={
 ICON_STEP=20,EMPTY_SLOT='slot',audit=function() end,gui=function() return 1 end,
 tr=function(_,fallback) return fallback end,translated=function(v) return v end,
 white_text=function() end,wrapped_text=function() end,search_input=function(v) return v end,
 scroll_height=function() return 90 end,columns=function() return 4 end,search_status=function() end,
 rank_entries=function(_,entries) return entries end,resolve=function(p) return p end,dimensions=function() return 18,18 end,
 button=function(_,_,label) buttons[#buttons+1]=tostring(label); return false end,
 button_grid=function(items) for _,item in ipairs(items or {}) do buttons[#buttons+1]=tostring(item.label or '') end; return nil end,
 begin_scroll_viewport=function(key,id,x,y,w,h) return {padding_left=2,content_width=math.max(20,w-12)} end,
 scroll_y=function(_,y) return y end,end_scroll_viewport=function(_,height) _G.__perk_content_height=height end,
 tile=function() tiles=tiles+1; return false,false,false end,
}
local service={count=function() return 0 end,can_remove=function() return true end,job_status=function() return nil end,consume_job_notice=function() return nil end}
local list={}
for i=1,60 do list[i]={id='P'..i,ui_name='Perk '..i,ui_description='Desc',ui_icon='perk.png'} end
local catalog={all=function() return list end}
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/ui/runtime.lua' then return ui end
 if path=='mods/metamorph_creative_menu/files/ui/drag_drop.lua' then return {take_result=function() return nil end,source=function() end,active=function() return false end} end
 if path=='mods/metamorph_creative_menu/files/features/perks/service.lua' then return service end
 if path=='mods/metamorph_creative_menu/files/features/perks/catalog.lua' then return catalog end
 return native_dofile(path)
end
GuiLayoutBeginVertical=function() end; GuiLayoutBeginHorizontal=function() end; GuiLayoutEnd=function() end
InputIsMouseButtonDown=function() return false end; GamePrint=function() end
local tab=assert(native_dofile(root..'/files/ui/tabs/perks.lua'))
tab.draw(1,220,180)
for _,label in ipairs(buttons) do assert(label~='<' and label~='>','perk catalogue still exposes page arrows') end
assert(tiles==60,'perk catalogue did not render one continuous scroll surface: '..tostring(tiles))
assert(tonumber(_G.__perk_content_height or 0)>0,'perk scroll content height missing')
print('perk_scroll_surface=PASS arrows=false continuous=true tiles='..tiles)
