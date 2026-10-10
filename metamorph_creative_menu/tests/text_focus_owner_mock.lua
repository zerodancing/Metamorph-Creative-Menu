local root=assert(arg[1],'root required')
local native_dofile=dofile
local visible_events={}
local last_info={hover=false,x=0,y=0,w=96,h=10}
local left_just=false
local input_calls={}
local button_calls=0
local native_focus_id=nil
local escape_down=false
local capture_typed=''

local function pop(events, fallback)
    if #events==0 then return fallback end
    return table.remove(events,1)
end

dofile=function(path)
    local prefix='mods/metamorph_creative_menu/'
    if path==prefix..'files/platform/noita/assets.lua' then
        return {bind_gui=function() end,resolve=function(p)return p end,path=function(p)return p end,
            dimensions=function()return 24,4 end,resolve_entity=function()return nil end}
    end
    if path==prefix..'files/platform/noita/input_guard.lua' then return {actions_allowed=function()return true end} end
    if path==prefix..'files/platform/noita/pointer.lua' then
        return {
            left_just_down=function() return left_just end,
            gui_position=function() return 300,200 end,
        }
    end
    if path==prefix..'files/platform/noita/keycodes.lua' then
        return {resolve=function(name) if name=='Key_ESCAPE' then return 27 elseif name=='Key_BACKSPACE' then return 8 end return nil end}
    end
    if path==prefix..'files/platform/noita/localization.lua' then return {translate=function(v)return v end} end
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

GUI_OPTION={Layout_NoLayouting=1,ForceFocusable=2}
GuiCreate=function() return 2 end
GuiStartFrame=function() end
GuiColorSetForNextWidget=function()end
GuiZSetForNextWidget=function()end
GuiOptionsAddForNextWidget=function()end
GuiText=function()end
GuiTooltip=function()end
GuiLayoutBeginHorizontal=function()end
GuiLayoutEnd=function()end
GuiGetTextDimensions=function(_,text)return #tostring(text)*5,8 end
GuiGetScreenDimensions=function() return 640,360 end
GuiButton=function() button_calls=button_calls+1; return false,false end
GuiTextInput=function(gui_id,id,_,_,value,width,_,allowed)
    if gui_id==2 then
        input_calls[#input_calls+1]={id=id,width=0,capture=true,gui=gui_id}
        local typed=capture_typed
        capture_typed=''
        return ' '..typed
    end
    local e=pop(visible_events,{hover=false,w=width})
    input_calls[#input_calls+1]={id=id,width=width,allowed=allowed,hover=e.hover==true,capture=false,gui=gui_id}
    if left_just then
        if e.hover==true then native_focus_id=id
        elseif native_focus_id==id then native_focus_id=nil end
    end
    local result=value
    if native_focus_id==id and e.hover==true and e.typed~=nil then result=value..e.typed end
    last_info={hover=e.hover==true,x=10,y=10,w=e.w or width,h=10}
    return result
end
GuiGetPreviousWidgetInfo=function()
    return false,false,last_info.hover,last_info.x,last_info.y,last_info.w,last_info.h
end
GameGetFrameNum=function() return 20 end
InputIsKeyJustDown=function(code) return code==27 and escape_down end
InputIsKeyDown=function() return false end

METAMORPH_CREATIVE_MENU_UI_RUNTIME=nil
METAMORPH_CREATIVE_MENU_TEXT_ENTRY_GUARD=nil
local ui=assert(native_dofile(root..'/files/ui/runtime.lua'))
ui.bind(1)

visible_events={{hover=false,w=96}}
ui.begin_frame()
local a,af=ui.text_input('α',96,20,'field.a')
ui.end_frame()
local a_id=input_calls[#input_calls].id
assert(a=='α' and af==false,'inactive field unexpectedly owned logical focus')
assert(#input_calls==1 and button_calls==0,'inactive editable field was not a native GuiTextInput')

left_just=true; visible_events={{hover=true,w=96}}
ui.begin_frame(); a,af=ui.text_input(a,96,20,'field.a'); ui.end_frame()
local click_call=input_calls[#input_calls]
assert(af==true and ui.text_input_focus_key()=='field.a','native click did not establish logical focus')
assert(click_call.id==a_id and click_call.width==96,'field native identity or width changed in click frame')
left_just=false

-- Native focus intentionally stops producing characters off-hover. MCM uses a separate
-- capture Gui, so hovering another MCM widget cannot steal or scroll the visible editor.
visible_events={{hover=false,w=96}}
capture_typed='β'
local before_calls=#input_calls
ui.begin_frame(); a,af=ui.text_input(a,96,20,'field.a'); ui.end_frame()
assert(a=='αβ' and af==true,'off-hover input did not update the logically focused field immediately')
assert(#input_calls==before_calls+2,'focused off-hover field did not draw visible+isolated capture inputs')
local visible_call=input_calls[#input_calls-1]
local capture_call=input_calls[#input_calls]
assert(visible_call.id==a_id and visible_call.width==96 and visible_call.gui==1,'visible field identity changed after pointer left')
assert(capture_call.capture==true and capture_call.width==0 and capture_call.gui==2 and capture_call.id~=a_id,
    'off-hover capture did not use a separate Gui context')

-- Numeric-style whitelists are enforced on captured text too.
left_just=true; visible_events={{hover=false,w=96}}
ui.begin_frame(); a,af=ui.text_input(a,96,20,'field.a'); ui.end_frame(); left_just=false
assert(af==false,'outside click did not release field focus')
left_just=true; visible_events={{hover=true,w=80}}
ui.begin_frame(); local n,nf=ui.text_input('1',80,20,'field.n',{allowed_characters='0123456789.-'}); ui.end_frame(); left_just=false
assert(nf==true,'numeric field did not focus')
visible_events={{hover=false,w=80}}; capture_typed='2s.5'
ui.begin_frame(); n,nf=ui.text_input(n,80,20,'field.n',{allowed_characters='0123456789.-'}); ui.end_frame()
visible_events={{hover=false,w=80}}
ui.begin_frame(); n,nf=ui.text_input(n,80,20,'field.n',{allowed_characters='0123456789.-'}); ui.end_frame()
assert(n=='12.5','off-hover capture ignored numeric whitelist: '..tostring(n))

-- Clicking another field transfers the single logical owner.
left_just=true; visible_events={{hover=false,w=80},{hover=true,w=72}}
ui.begin_frame()
n,nf=ui.text_input(n,80,20,'field.n',{allowed_characters='0123456789.-'})
local b,bf=ui.text_input('B',72,20,'field.b')
ui.end_frame(); left_just=false
assert(nf==false and bf==true and ui.text_input_focus_key()=='field.b','clicking another field did not transfer exclusive focus')

ui.begin_frame(); ui.end_frame()
assert(ui.text_input_active()==false,'unmounted focused field survived a tab/context switch')

ui.reset_text_inputs()
assert(ui.text_input_active()==false,'reset did not clear logical ownership')
print('text_focus_owner=PASS native_id_stable=true click_once=true isolated_capture=true hover_independent=true whitelist=true outside_blur=true exclusive=true unmounted_blur=true')
