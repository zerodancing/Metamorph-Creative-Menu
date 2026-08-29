local root=assert(arg[1],'root required')
local native_dofile=dofile
local text_events={}
local last_info={hover=false,x=0,y=0,w=96,h=10}
local left_just=false
local input_calls={}
local button_calls=0
local native_focus_id=nil
local escape_down=false

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
        return {left_just_down=function() return left_just end}
    end
    if path==prefix..'files/platform/noita/keycodes.lua' then
        return {resolve=function(name) if name=='Key_ESCAPE' then return 27 elseif name=='Key_BACKSPACE' then return 8 end return nil end}
    end
    if path==prefix..'files/platform/noita/localization.lua' then return {translate=function(v)return v end} end
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

GUI_OPTION={Layout_NoLayouting=1}
GuiColorSetForNextWidget=function()end
GuiZSetForNextWidget=function()end
GuiOptionsAddForNextWidget=function()end
GuiText=function()end
GuiTooltip=function()end
GuiLayoutBeginHorizontal=function()end
GuiLayoutEnd=function()end
GuiGetTextDimensions=function(_,text)return #tostring(text)*5,8 end
GuiButton=function() button_calls=button_calls+1; return false,false end
GuiTextInput=function(_,id,_,_,value,width,_,allowed)
    local e=pop(text_events,{hover=false,w=width})
    input_calls[#input_calls+1]={id=id,width=width,allowed=allowed,hover=e.hover==true}
    if left_just then
        if e.hover==true then native_focus_id=id
        elseif native_focus_id==id then native_focus_id=nil end
    end
    local result=value
    if native_focus_id==id and e.typed~=nil then result=value..e.typed end
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

-- Before activation the editable control is already the real native GuiTextInput.
text_events={{hover=false,w=96}}
ui.begin_frame()
local a,af=ui.text_input('α',96,20,'field.a')
ui.end_frame()
local a_id=input_calls[#input_calls].id
assert(a=='α' and af==false,'inactive field unexpectedly owned logical focus')
assert(#input_calls==1 and button_calls==0,'inactive editable field was not a native GuiTextInput')
assert(input_calls[1].width==96,'inactive native field did not use full requested width')

-- The original click lands on that same GuiTextInput; no type/identity swap occurs.
left_just=true; text_events={{hover=true,w=96}}
ui.begin_frame(); a,af=ui.text_input(a,96,20,'field.a'); ui.end_frame()
local click_call=input_calls[#input_calls]
assert(af==true and ui.text_input_focus_key()=='field.a','native click did not establish logical focus')
assert(click_call.id==a_id and click_call.width==96,'field native identity or width changed in click frame')
assert(native_focus_id==a_id,'mock native GuiTextInput did not receive the original click')
left_just=false

-- Typing after the cursor leaves is delivered only because the native focus retained
-- the same widget ID. The mock does not return queued text merely because hover=false.
text_events={{hover=false,w=96,typed='β'}}
ui.begin_frame(); a,af=ui.text_input(a,96,20,'field.a'); ui.end_frame()
local off_hover_call=input_calls[#input_calls]
assert(a=='αβ' and af==true,'native focus did not survive pointer leaving the field')
assert(off_hover_call.id==a_id and off_hover_call.width==96,'native field identity/width changed after hover ended')
assert(button_calls==0,'editable field changed widget type during its lifecycle')

-- A click outside the active field clears both the mocked native focus and logical owner.
left_just=true; text_events={{hover=false,w=96,typed='X'}}
ui.begin_frame(); a,af=ui.text_input(a,96,20,'field.a'); ui.end_frame()
assert(a=='αβ' and af==false and ui.text_input_active()==false,'outside click did not release field focus or leaked native text')
assert(native_focus_id==nil,'mock native focus did not blur on outside click')
left_just=false

-- Re-focus A, then click B once. Both are persistent GuiTextInputs with distinct IDs;
-- the guard transfers its single logical owner in the same frame.
left_just=true; text_events={{hover=true,w=96}}
ui.begin_frame(); a,af=ui.text_input(a,96,20,'field.a'); ui.end_frame()
assert(af==true and input_calls[#input_calls].id==a_id,'field A could not be re-focused with stable identity')

text_events={{hover=false,w=96},{hover=true,w=80}}
ui.begin_frame()
a,af=ui.text_input(a,96,20,'field.a')
local b,bf=ui.text_input('B',80,20,'field.b')
ui.end_frame()
local b_id=input_calls[#input_calls].id
assert(af==false and bf==true and ui.text_input_focus_key()=='field.b','clicking field B did not transfer exclusive focus')
assert(b_id~=a_id,'distinct focus keys mapped to the same native widget ID')
left_just=false

-- If the owner disappears because its tab/context changed, end_frame releases it.
ui.begin_frame(); ui.end_frame()
assert(ui.text_input_active()==false,'unmounted focused field survived a tab/context switch')

-- Reset clears logical ownership even if a native widget would retain internal state;
-- without the guard owner, its returned text is ignored.
left_just=true; text_events={{hover=true,w=96}}
ui.begin_frame(); a,af=ui.text_input(a,96,20,'field.a'); ui.end_frame(); left_just=false
assert(af==true,'field A did not focus before reset check')
ui.reset_text_inputs()
text_events={{hover=false,w=96,typed='Ж'}}
ui.begin_frame(); a,af=ui.text_input(a,96,20,'field.a'); ui.end_frame()
assert(a=='αβ' and af==false,'reset logical owner accepted native text without ownership')

print('text_focus_owner=PASS native_type_stable=true native_id_stable=true click_origin=true hover_persistent=true outside_blur=true exclusive=true unmounted_blur=true utf8_safe=true native_frame_width=true')
