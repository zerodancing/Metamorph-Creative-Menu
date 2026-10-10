local root=assert(arg[1])
local native_dofile=dofile
local text_calls=0
local capture_calls=0
local text_events={}
local last_hover=false
local left_just=false
local native_focus_id=nil
local first_id=nil
local capture_typed=''

local function pop()
 if #text_events==0 then return {hover=false} end
 return table.remove(text_events,1)
end

dofile=function(path)
 local prefix='mods/metamorph_creative_menu/'
 if path==prefix..'files/platform/noita/assets.lua' then
  return {bind_gui=function() end,resolve=function(p)return p end,path=function(p)return p end,dimensions=function()return 18,18 end,resolve_entity=function()return nil end}
 end
 if path==prefix..'files/platform/noita/input_guard.lua' then return {actions_allowed=function()return true end} end
 if path==prefix..'files/platform/noita/pointer.lua' then return {left_just_down=function() return left_just end,gui_position=function() return 200,100 end} end
 if path==prefix..'files/platform/noita/keycodes.lua' then return {resolve=function() return 1 end} end
 if path==prefix..'files/platform/noita/localization.lua' then
  return {translate=function(v)return v end,english=function(k)return k=='$spell' and 'Fireball' or k end,
   search_aliases=function(k) if k=='$spell' then return {'Огненный шар','Fireball',k} end return {k} end}
 end
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end

GUI_OPTION={Layout_NoLayouting=1,ForceFocusable=2}
GuiCreate=function() return 2 end
GuiStartFrame=function() end
GuiColorSetForNextWidget=function()end
GuiZSetForNextWidget=function()end
GuiText=function()end
GuiImage=function()end
GuiOptionsAddForNextWidget=function()end
GuiLayoutBeginHorizontal=function()end
GuiLayoutEnd=function()end
local after_id=nil
GuiButton=function(_,id,_,_,label)
 if label=='AFTER' then
  if after_id then assert(id==after_id,'first character shifted following widget IDs') else after_id=id end
 end
 return false
end
GuiGetPreviousWidgetInfo=function() return false,false,last_hover,0,0,100,10 end
GuiGetScreenDimensions=function() return 640,360 end
GuiTextInput=function(gui_id,id,_,_,value,width)
 if gui_id==2 then
  capture_calls=capture_calls+1
  local typed=capture_typed; capture_typed=''
  return ' '..typed
 end
 text_calls=text_calls+1
 local e=pop(); last_hover=e.hover==true
 if first_id==nil then first_id=id else assert(id==first_id,'search native widget identity changed across frames') end
 if left_just then
  if last_hover then native_focus_id=id elseif native_focus_id==id then native_focus_id=nil end
 end
 if native_focus_id==id and last_hover and e.typed then return value..e.typed end
 return value
end
GuiGetTextDimensions=function(_,text) return #tostring(text)*5,8 end
GameGetFrameNum=function() return 10 end
InputIsKeyJustDown=function() return false end
InputIsKeyDown=function() return false end

METAMORPH_CREATIVE_MENU_UI_RUNTIME=nil
METAMORPH_CREATIVE_MENU_TEXT_ENTRY_GUARD=nil
local ui=assert(native_dofile(root..'/files/ui/runtime.lua'))
ui.bind(1)
text_events={{hover=false}}
ui.begin_frame()
local value=ui.search_input('',100,64,'focus_test')
ui.button(0,0,'AFTER')
assert(value=='' and text_calls==1 and capture_calls==0,'inactive search was not a persistent GuiTextInput')
assert(ui.text_input_active()==false,'inactive search incorrectly reserved keyboard input')

left_just=true; text_events={{hover=true}}
ui.begin_frame(); value=ui.search_input(value,100,64,'focus_test')
assert(text_calls==2 and ui.text_input_active()==true,'native activation click did not focus search in-place')
left_just=false

text_events={{hover=false}}; capture_typed='x'
ui.begin_frame(); value=ui.search_input(value,100,64,'focus_test'); ui.end_frame()
ui.button(0,0,'AFTER')
assert(text_calls==3 and capture_calls==1 and value=='x','focused search did not accept off-hover input through isolated capture gui')
text_events={{hover=false}}; capture_typed='y'
ui.begin_frame(); value=ui.search_input(value,100,64,'focus_test'); ui.end_frame()
assert(text_calls==4 and capture_calls==2 and value=='xy','hovering another MCM surface interrupted logical text focus')
assert(ui.matches_search('fireball','$spell'),'English localization alias was not searchable')
assert(ui.matches_search('огнен','$spell'),'client-language localization alias was not searchable')

ui.reset_text_inputs()
assert(ui.text_input_active()==false,'reset left keyboard input reserved')
text_events={{hover=false,typed='z'}}
ui.begin_frame(); value=ui.search_input(value,100,64,'focus_test')
assert(value=='' and text_calls==5,'menu reset did not clear search or leaked text from unowned native focus')
print('search_focus=PASS persistent_native=true explicit_click=true isolated_capture=true hover_independent=true close_reset=true bilingual_alias=true')
