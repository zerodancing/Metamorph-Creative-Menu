local root = assert(arg[1], "root required")
local native_dofile = dofile
local horizontal_rows = 0
local largest_spacing = 0
local widget_y = 0
local widget_h = 0
local click_label = nil
local rendered_text = {}
local tooltip_calls = {}

local stubs={
    ["mods/metamorph_creative_menu/files/platform/noita/assets.lua"]={bind_gui=function() end},
    ["mods/metamorph_creative_menu/files/platform/noita/input_guard.lua"]={actions_allowed=function() return true end},
    ["mods/metamorph_creative_menu/files/platform/noita/keycodes.lua"]={},
    ["mods/metamorph_creative_menu/files/platform/noita/localization.lua"]={
        translate=function(key,fallback) return key=="$new_label" and "ДЛИННАЯ РУССКАЯ НАДПИСЬ" or (fallback or key) end,
    },
}
dofile=function(path)
    if stubs[path] then return stubs[path] end
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

function GuiGetTextDimensions(_,text) return #tostring(text)*5,9 end
function GuiLayoutBeginHorizontal() horizontal_rows=horizontal_rows+1 end
function GuiLayoutEnd() end
function GuiLayoutAddHorizontalSpacing(_,value) largest_spacing=math.max(largest_spacing,tonumber(value) or 0) end
function GuiColorSetForNextWidget() end
function GuiZSetForNextWidget() end
function GuiButton(_,_,_,_,text)
    if click_label ~= nil and text == click_label then click_label=nil; return true end
    return false
end
function GuiGetPreviousWidgetInfo() return false,false,false,0,widget_y,100,widget_h end
function GuiTooltip(...)
    tooltip_calls[#tooltip_calls+1]={
        argc=select('#', ...), title=select(2, ...), description=select(3, ...),
    }
end
function GuiText(_,_,_,text) rendered_text[#rendered_text+1]=tostring(text or "") end
function GameGetFrameNum() return 10 end

METAMORPH_CREATIVE_MENU_UI_RUNTIME=nil
local ui=assert(native_dofile(root.."/files/ui/runtime.lua"))
ui.bind(1)
assert(ui.tr("$new_label","English")=="ДЛИННАЯ РУССКАЯ НАДПИСЬ","runtime did not use localized fallback service")
ui.button(0,0,"TAB",false,"PERKS",nil)
local tooltip=assert(tooltip_calls[#tooltip_calls])
assert(tooltip.argc==3 and tooltip.title=="PERKS" and tooltip.description=="",
    "title-only tooltip did not call Noita with an explicit empty description")

rendered_text={}
local line_count=ui.wrapped_text(0,0,"one two three four five",45)
assert(line_count>=3 and #rendered_text==line_count,"narrow translated/help text was not wrapped")
for _,line in ipairs(rendered_text) do assert(ui.text_width(line)<=45,"wrapped line exceeded panel width") end
rendered_text={}
local utf8_line_count=ui.wrapped_text(0,0,"界界界界界界",30)
assert(utf8_line_count>=3 and #rendered_text==utf8_line_count,"unspaced UTF-8 text was not wrapped")
for _,line in ipairs(rendered_text) do assert(ui.text_width(line)<=30,"UTF-8 wrapped line exceeded panel width") end
local ranked=ui.rank_entries("alpha", {
    {id="later",name="beta alpha"}, {id="first",name="alpha"},
}, function(entry) return {entry.name,entry.id} end, function(entry) return entry.id end)
assert(#ranked==2 and ranked[1].id=="first","shared catalogue search did not rank exact matches first")
click_label="RESET"
assert(ui.confirm_button("reset","RESET","CONFIRM")==false,"destructive action skipped its first confirmation click")
click_label="CONFIRM"
assert(ui.confirm_button("reset","RESET","CONFIRM")==true,"destructive action did not accept its second confirmation click")
click_label="+"
assert(ui.stepper("VALUE","1")==1,"shared stepper did not report increment")

local before=horizontal_rows
ui.button_grid({
    {label="12345678"},{label="abcdefgh"},{label="ABCDEFGH"},
},55)
assert(horizontal_rows-before==3,"button grid did not adapt rows to narrow width")
ui.panel_width_anchor(240)
assert(largest_spacing>=230,"sparse tab did not honor resized panel width")
assert(ui.grid_height(600,160)==440,"large window list kept an obsolete fixed height cap")
assert(ui.grid_height(120,160)==64,"small window list dropped below its usable minimum")
widget_y,widget_h=120,10
ui.set_panel_bounds(10,20,240,300)
assert(ui.scroll_height(258,160)==181,
    "catalogue did not consume the measured space down to the panel border")

for _,name in ipairs({"controls","creatures","effects","items","materials","perks","players","spells","weather","world_rules"}) do
    local handle=assert(io.open(root.."/files/ui/tabs/"..name..".lua","rb"))
    local source=handle:read("*a"); handle:close()
    assert(string.find(source,"ui.scroll_height(",1,true),
        name.." tab bypassed the shared adaptive scroll-height system")
end


METAMORPH_CREATIVE_MENU_PANEL_LAYOUT=nil
local panel_layout=assert(native_dofile(root.."/files/core/panel_layout.lua"))
local frame_outsets={left=6,right=6,top=6,bottom=6}
local compact_default=panel_layout.create(320,240,{},frame_outsets)
assert(compact_default.x==100 and compact_default.y==28
    and compact_default.width==210 and compact_default.height==187,
    "320x240 default was not lower, narrower and taller")
assert(compact_default.x-frame_outsets.left>=panel_layout.MARGIN
    and compact_default.x+compact_default.width+frame_outsets.right<=320-panel_layout.MARGIN
    and compact_default.y-frame_outsets.top>=panel_layout.MARGIN
    and compact_default.y+compact_default.height+frame_outsets.bottom<=240-panel_layout.MARGIN,
    "default visible resize frame escaped the compact viewport")
local preserved=panel_layout.create(640,360,{x=123,y=67,width=260,height=190},frame_outsets)
assert(preserved.x==123 and preserved.y==67 and preserved.width==260 and preserved.height==190,
    "valid saved user layout was changed")
local edge_saved=panel_layout.create(320,240,{x=110,y=80,width=210,height=187},frame_outsets)
assert(edge_saved.x==100 and edge_saved.y==43,
    "saved layout was not clamped by the visual frame outset")

io.write("ui_responsive_layout=PASS wrapping=true utf8=true dynamic_rows=true ranked_search=true confirmations=true steppers=true width_anchor=true measured_fill=true all_scroll_tabs=true localized_runtime=true compact_default=true saved_layout_preserved=true frame_outset_clamp=true\n")
