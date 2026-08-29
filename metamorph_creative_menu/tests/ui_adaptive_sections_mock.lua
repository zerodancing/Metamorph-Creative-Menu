local root=assert(arg[1],"root required")
local native_dofile=dofile
local prefix="mods/metamorph_creative_menu/"

-- Feature/service boundaries. UI modules and runtime/layout/scroll/focus modules are real.
local stubs={}
stubs[prefix.."files/platform/noita/assets.lua"]={
    bind_gui=function() end, resolve=function(p) if p==nil or p=="" then return nil end return p end,
    path=function(p)return p end, dimensions=function()return 18,18 end,
    resolve_entity=function() return "icon.png" end,
}
stubs[prefix.."files/platform/noita/input_guard.lua"]={actions_allowed=function() return true end}
local left_just=false
local wheel=0
stubs[prefix.."files/platform/noita/pointer.lua"]={
    left_just_down=function() return left_just end,left_down=function() return false end,
    wheel_delta=function() return wheel end,inside=function(x,y,w,h,mx,my)
        return mx~=nil and my~=nil and mx>=x and my>=y and mx<=x+w and my<=y+h
    end,gui_position=function() return nil,nil end,
}
stubs[prefix.."files/platform/noita/keycodes.lua"]={resolve=function() return nil end}
local long={
    ["$mcm_teleport_bring_player"]="ПЕРЕМЕСТИТЬ ИГРОКА СЮДА",
    ["$mcm_teleport_to_player"]="ПЕРЕЙТИ К ИГРОКУ",
    ["$mcm_controls_reset_all"]="СБРОСИТЬ ВСЕ НАЗНАЧЕНИЯ",
    ["$mcm_controls_reset_confirm"]="ПОДТВЕРДИТЬ ПОЛНЫЙ СБРОС НАЗНАЧЕНИЙ",
    ["$mcm_weather_release"]="ОТПУСТИТЬ УПРАВЛЕНИЕ ПОГОДОЙ",
    ["$mcm_weather_advanced"]="РАСШИРЕННЫЕ НАСТРОЙКИ",
    ["$mcm_weather_back"]="ВЕРНУТЬСЯ К ПРЕСЕТАМ",
    ["$mcm_wand_appearance"]="ВНЕШНИЙ ВИД И БЛОКИРОВКИ",
    ["$mcm_wand_skins"]="СОХРАНЁННЫЕ ВАРИАНТЫ ВНЕШНЕГО ВИДА",
    ["$mcm_wand_presets"]="СОХРАНЁННЫЕ ЖЕЗЛЫ",
    ["$action_long"]="ОЧЕНЬ ДЛИННОЕ ЛОКАЛИЗОВАННОЕ ДЕЙСТВИЕ УПРАВЛЕНИЯ",
    ["$section_long"]="ДЛИННЫЙ РАЗДЕЛ УПРАВЛЕНИЯ",
    ["$weather_long"]="ОЧЕНЬ ДЛИННЫЙ ПАРАМЕТР ПОГОДЫ",
    ["$location_long"]="ОЧЕНЬ ДЛИННОЕ НАЗВАНИЕ МИРОВОЙ ТОЧКИ",
}
stubs[prefix.."files/platform/noita/localization.lua"]={
    translate=function(key,fallback) return long[key] or key end,
    search_aliases=function(key,fallback) return {long[key] or key,fallback or key,key} end,
}

local item_entry={path="item.xml",category="OTHER",display_name="Item",display_description="desc",icon="item.png"}
stubs[prefix.."files/features/items/ui_catalog.lua"]={
    collect=function() return {item_entry} end,
    filters=function() return {{"$f1","ALL"},{"$f2","OTHER","OTHER"}} end,
    entries_for=function() return {item_entry} end,liquids=function() return {} end,
}
stubs[prefix.."files/features/items/service.lua"]={spawn=function()return true end,give=function()return true end,spawn_filled_flask=function()return true end}
stubs[prefix.."files/platform/noita/material_preview.lua"]={new_liquid_warmup=function()return{}end,warm_liquid_colors=function()end,liquid_icon=function()return"potion.png"end,liquid_color=function()return{1,1,1,1}end}
stubs[prefix.."files/ui/drag_drop.lua"]={take_result=function()return nil end,source=function()end,active=function()return false end}
stubs[prefix.."files/platform/noita/inventory_slots.lua"]={native_drop_bounds=function()return nil end}

local perk={id="P",ui_name="Perk",ui_description="Desc",ui_icon="perk.png"}
stubs[prefix.."files/features/perks/catalog.lua"]={all=function()return{perk}end}
stubs[prefix.."files/features/perks/service.lua"]={
    count=function()return 0 end,can_remove=function()return true end,job_status=function()return nil end,
    consume_job_notice=function()return nil end,spawn=function()return true end,apply=function()return true end,
    start_take_job=function()return true end,start_remove_all_job=function()return true end,remove_one=function()return true end,
}
local effect={id="E",kind="game_effect",display_name="Effect",display_description="desc",icon="effect.png"}
stubs[prefix.."files/features/effects/service.lua"]={catalog=function()return{effect}end,active_snapshot=function()return{}end,is_active=function()return false end,add=function()return true end,remove=function()return 1 end,remove_all=function()return 0 end}
local weather_field={id="rain",label="$weather_long",min=0,max=1,step=.1,decimals=2}
stubs[prefix.."files/features/weather/service.lua"]={
    can_edit=function()return true,"single" end,is_locked=function()return true end,set_time_preset=function()return true end,
    apply_preset=function()return true end,release=function()return true end,fields=function()return{weather_field}end,
    get=function()return .5 end,set=function()return true end,debug_state=function()return{}end,
}
local rule={id="relations",label="Rule",description="Description",choices={{native=true},{value=1}}}
stubs[prefix.."files/features/world_rules/service.lua"]={can_edit=function()return true,"single"end,has_overrides=function()return false end,rules=function()return{rule}end,choice_label=function()return"NATIVE"end,is_overridden=function()return false end,supported=function()return true end,step=function()return true end,reset=function()return true end}
stubs[prefix.."files/features/player_tools/service.lua"]={
    has_pending_teleport=function()return false end,visible_players=function()return{2}end,position=function()return 123,456 end,
    teleport_to=function()return true end,bring_to_me=function()return true end,
    locations=function()return{{id="loc",key="$location_long",fallback="Long location",x=10,y=20}}end,
    teleport_location=function()return true end,
}
local registry={
    sections=function()return{{id="s",key="$section_long",fallback="SECTION"}}end,
    actions=function()return{{id="long",section="s",key="$action_long",fallback="ACTION",default="CTRL+SHIFT+ALT+MOUSE4"}}end,
    get=function(id) if id=="long" then return registry.actions()[1] end end,
}
stubs[prefix.."files/platform/noita/action_bindings.lua"]={
    update=function()end,label=function()return"CTRL+SHIFT+ALT+MOUSE4"end,capture_action=function()return nil end,
    registry=function()return registry end,conflicts=function()return{}end,get=function()return"CTRL+SHIFT+ALT+MOUSE4"end,
    start_capture=function()end,set=function()end,reset=function()end,reset_all=function()end,
}
local visual={name="Wand",show_name_in_ui=true,wand_frozen=false,sprite_file="very/long/path/to/a/wand/sprite.xml",image_file="wand.png",offset_x=1,offset_y=2,tip_x=3,tip_y=4}
stubs[prefix.."files/features/wands/appearance.lua"]={
    snapshot=function()return visual,"ok"end,spell_freeze_state=function()return false,false,1 end,
    set_name=function()return true end,set_wand_frozen=function()return true end,set_spells_frozen=function()return true end,set_visual=function()return true end,
}
stubs[prefix.."files/features/wands/history.lua"]={perform=function(_,_,_,cb)return cb()end}
stubs[prefix.."files/features/wands/skins.lua"]={entries=function()return{{name="Long skin",sprite_file="skin.xml",image_file="skin.png",icon="skin.png",source_path="source"}}end}
stubs[prefix.."files/features/wands/presets.lua"]={
    all=function()return{{name="Очень длинное имя сохранённого жезла",blueprint={meta={image_file="wand.png"},sprite_file="wand.xml"}}}end,
    save=function()return false,"intentional_preset_failure"end,load=function()return true end,give=function()return true end,delete=function()return true end,
}

-- Runtime/module path routing.
dofile=function(path)
    if stubs[path]~=nil then return stubs[path] end
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

-- Minimal Noita GUI layout simulator. It records real widget bounds generated by the
-- production runtime and validates them against the active viewport content width.
GUI_OPTION={Layout_NoLayouting=1,NoPositionTween=2}
local panel_width=96
local layouts,scrolls,layers={},{},{}
local last={hover=false,x=0,y=0,w=1,h=1}
local no_layout=false
local overflow={}
local max_right=0
local horizontal_rows=0
local texts={}
local tooltips={}
local input_ids={}
local hover_input_id=nil
local native_focus_id=nil
local click_next_button=false
local click_label=nil
local prints={}
local diagnostics={}
local frame=1

local function current_layout() return layouts[#layouts] end
local function current_scroll() return scrolls[#scrolls] end
local function base_position(x,y)
    local l=current_layout()
    if no_layout then
        local s=current_scroll(); return (s and s.x or 0)+(tonumber(x)or 0),(s and s.y or 0)+(tonumber(y)or 0),false
    end
    -- Native Noita scroll children are relative to the active container even while the
    -- outer window layout remains on the stack. Do not require a synthetic layout layer:
    -- that was the bad mock assumption which hid the real top-left-origin regression.
    local s=current_scroll()
    if s and l==s.parent_layout then
        return s.x+(tonumber(x)or 0),s.y+(tonumber(y)or 0),false
    end
    if l then return l.x+l.cx+(tonumber(x)or 0),l.y+l.cy+(tonumber(y)or 0),true end
    if s then return s.x+(tonumber(x)or 0),s.y+(tonumber(y)or 0),false end
    return tonumber(x)or 0,tonumber(y)or 0,false
end
local function advance(w,h)
    local l=current_layout(); if not l then return end
    if l.mode=="h" then l.cx=l.cx+w+2; l.h=math.max(l.h,h); l.w=math.max(l.w,l.cx)
    else l.cy=l.cy+h+1; l.w=math.max(l.w,w); l.h=math.max(l.h,l.cy) end
end
local function place(x,y,w,h,interactive,label)
    w,h=math.max(1,tonumber(w)or 1),math.max(1,tonumber(h)or 1)
    local ax,ay,participates=base_position(x,y)
    last={hover=false,x=ax,y=ay,w=w,h=h}
    if interactive then
        local limit=panel_width
        local s=current_scroll(); if s then limit=s.content_right end
        local right=ax+w; max_right=math.max(max_right,right)
        if right>limit+0.01 then overflow[#overflow+1]=tostring(label or "widget").." right="..right.." limit="..limit end
    end
    if participates then advance(w,h) end
    no_layout=false
    return ax,ay
end
local function begin_layout(mode,x,y)
    local base_x,base_y
    local layer_scroll=layers[#layers]
    local native_scroll=current_scroll()
    if native_scroll~=nil and current_layout()==native_scroll.parent_layout then
        base_x=native_scroll.x+(tonumber(x)or 0); base_y=native_scroll.y+(tonumber(y)or 0)
        layouts[#layouts+1]={mode=mode,x=base_x,y=base_y,cx=0,cy=0,w=0,h=0,detached=true}
    elseif layer_scroll~=nil and layer_scroll==native_scroll then
        base_x=layer_scroll.x+(tonumber(x)or 0); base_y=layer_scroll.y+(tonumber(y)or 0)
        layouts[#layouts+1]={mode=mode,x=base_x,y=base_y,cx=0,cy=0,w=0,h=0,detached=true}
    else
        local ax,ay=base_position(x,y); layouts[#layouts+1]={mode=mode,x=ax,y=ay,cx=0,cy=0,w=0,h=0,detached=false}
    end
end
function GuiLayoutBeginVertical(_,x,y) begin_layout("v",x,y) end
function GuiLayoutBeginHorizontal(_,x,y) horizontal_rows=horizontal_rows+1; begin_layout("h",x,y) end
function GuiLayoutEnd()
    local l=table.remove(layouts); if not l then return end
    if not l.detached then advance(math.max(1,l.w),math.max(1,l.h)) end
end
function GuiLayoutAddHorizontalSpacing(_,v) local l=current_layout(); if l and l.mode=="h" then l.cx=l.cx+(tonumber(v)or 0) end end
function GuiLayoutAddVerticalSpacing(_,v) local l=current_layout(); if l and l.mode=="v" then l.cy=l.cy+(tonumber(v)or 0) end end
function GuiLayoutBeginLayer() layers[#layers+1]=current_scroll() end
function GuiLayoutEndLayer() table.remove(layers) end
function GuiBeginScrollContainer(_,id,x,y,w,h)
    local ax,ay=base_position(x,y)
    local s={id=id,x=ax,y=ay,w=w,h=h,content_right=ax+w-10,parent_layout=current_layout()}
    scrolls[#scrolls+1]=s; last={hover=true,x=ax,y=ay,w=w,h=h}
end
function GuiEndScrollContainer()
    local s=table.remove(scrolls); if s and s.parent_layout then advance(s.w,s.h) end
end
function GuiColorSetForNextWidget() end
function GuiZSetForNextWidget() end
function GuiOptionsAddForNextWidget(_,option) if option==GUI_OPTION.Layout_NoLayouting then no_layout=true end end
function GuiOptionsAdd() end
local function glyph_count(text)
    local count=0; for _ in string.gmatch(tostring(text or ""),"[\1-\127\194-\244][\128-\191]*") do count=count+1 end; return count
end
function GuiGetTextDimensions(_,text) return glyph_count(text)*5,5 end
function GuiGetImageDimensions() return 18,18 end
function GuiButton(_,_,x,y,label)
    local w=math.max(10,glyph_count(label)*5+6); place(x,y,w,9,true,"button:"..tostring(label))
    local clicked=false
    if click_label~=nil and tostring(label)==click_label then clicked=true; click_label=nil
    elseif click_next_button then clicked=true; click_next_button=false end
    return clicked
end
function GuiImageButton(_,_,x,y)
    place(x,y,18,18,true,"tile")
    return false,false
end
function GuiTextInput(_,id,x,y,value,w)
    local hovered=hover_input_id==id
    local ax,ay=place(x,y,w or 68,9,true,"input:"..tostring(id)); last.hover=hovered
    input_ids[#input_ids+1]=id
    if left_just then
        if hovered then native_focus_id=id elseif native_focus_id==id then native_focus_id=nil end
    end
    return value
end
function GuiText(_,x,y,text)
    texts[#texts+1]=tostring(text or "")
    place(x,y,math.max(1,glyph_count(text)*5),5,false,"text")
end
function GuiImage(_,_,x,y,_,_,sx,sy) place(x,y,18*(tonumber(sx)or 1),18*(tonumber(sy)or 1),false,"image") end
function GuiTooltip(_,title,description) tooltips[#tooltips+1]={title=tostring(title or ""),description=description~=nil and tostring(description) or nil} end
function GuiGetPreviousWidgetInfo() return 0,0,last.hover,last.x,last.y,last.w,last.h end
function GuiGetScreenDimensions() return 320,240 end
function GameGetFrameNum() return frame end
function InputIsMouseButtonJustDown() return false end
function InputIsMouseButtonDown() return false end
function InputIsKeyDown() return false end
function InputIsKeyJustDown() return false end
function InputIsKeyJustUp() return false end
function ModDoesFileExist() return true end
function GamePrint(message) prints[#prints+1]=tostring(message) end
METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE=function(scope,reason) diagnostics[#diagnostics+1]={scope,reason} end

local function reset_geometry(width)
    panel_width=width; layouts={};scrolls={};layers={};last={hover=false,x=0,y=0,w=1,h=1};no_layout=false
    overflow={};max_right=0;horizontal_rows=0;texts={};tooltips={};input_ids={};click_next_button=false;click_label=nil
end

for _,name in ipairs({"METAMORPH_CREATIVE_MENU_UI_RUNTIME","METAMORPH_CREATIVE_MENU_SCROLL_MODEL","METAMORPH_CREATIVE_MENU_TEXT_ENTRY_GUARD"}) do _G[name]=nil end
local ui=assert(native_dofile(root.."/files/ui/runtime.lua")); ui.bind(1)

-- A non-empty shared search field also renders its right-side clear button; both must fit
-- the narrowest supported panel instead of only proving the empty-input case.
reset_geometry(96); ui.begin_frame(); ui.search_input("query",68,64,"adaptive.search.clear"); ui.end_frame()
assert(#overflow==0,"shared search input/clear button overflowed width 96: "..table.concat(overflow," | "))
ui.blur_text_input("adaptive_probe_done")

local modules={
    items=assert(native_dofile(root.."/files/ui/tabs/items.lua")),
    perks=assert(native_dofile(root.."/files/ui/tabs/perks.lua")),
    effects=assert(native_dofile(root.."/files/ui/tabs/effects.lua")),
    weather=assert(native_dofile(root.."/files/ui/tabs/weather.lua")),
    rules=assert(native_dofile(root.."/files/ui/tabs/world_rules.lua")),
    players=assert(native_dofile(root.."/files/ui/tabs/players.lua")),
    controls=assert(native_dofile(root.."/files/ui/tabs/controls.lua")),
}

local function render(tab,width)
    reset_geometry(width); ui.begin_frame(); tab.draw(1,width,190); ui.end_frame()
    assert(#overflow==0,"UI overflow at width "..width..": "..table.concat(overflow," | "))
    return horizontal_rows,texts,input_ids
end

-- Basic weather first: its four icon actions must wrap by shared grid and it must not
-- repeat the WEATHER tab title as a content heading.
local weather_rows={}
for _,width in ipairs({96,160,280}) do
    local rows,drawn=render(modules.weather,width); weather_rows[width]=rows
    for _,text in ipairs(drawn) do assert(text~="WEATHER","WEATHER tab repeated its own title inside content") end
end
assert(weather_rows[96]>=weather_rows[280],"weather rows did not adapt to width")

-- Enter advanced weather once, then verify the real shared stepper at all widths.
reset_geometry(96); click_next_button=true; ui.begin_frame(); modules.weather.draw(1,96,190); ui.end_frame()
for _,width in ipairs({96,160,280}) do render(modules.weather,width) end

local reflow={}
for name,tab in pairs(modules) do
    if name~="weather" then
        reflow[name]={}
        for _,width in ipairs({96,160,280}) do
            local rows=render(tab,width); reflow[name][width]=rows
        end
    end
end
assert(reflow.players[96]>reflow.players[280],"teleport action row did not reflow on narrow menu")
assert(reflow.controls[96]>reflow.controls[280],"controls action row did not reflow on narrow menu")

-- Stable native focus survives width changes in a real CONTROLS render.
reset_geometry(96); ui.begin_frame(); modules.controls.draw(1,96,190); ui.end_frame()
local control_input=assert(input_ids[1],"controls search input was not rendered")
reset_geometry(96); hover_input_id=control_input; left_just=true; ui.begin_frame(); modules.controls.draw(1,96,190); ui.end_frame()
assert(ui.text_input_focus_key()=="controls","controls search did not acquire existing native input")
reset_geometry(280); hover_input_id=nil; left_just=false; ui.begin_frame(); modules.controls.draw(1,280,190); ui.end_frame()
assert(input_ids[1]==control_input and ui.text_input_focus_key()=="controls","responsive redraw changed native input identity or focus")
ui.blur_text_input("test_done")

-- WAND appearance receives the inner workspace content width (80 at a 96-wide panel),
-- not the outer window width. Its path/name/lock/numeric controls must stay inside it.
_G.METAMORPH_CREATIVE_MENU_WAND_APPEARANCE_EDITOR_UI=nil
_G.METAMORPH_CREATIVE_MENU_WAND_SKIN_PICKER_UI=nil
local appearance_editor=assert(native_dofile(root.."/files/ui/components/wand_appearance_editor.lua"))
reset_geometry(80); click_next_button=true; ui.begin_frame(); appearance_editor.draw(1,2,80); ui.end_frame()
for _,width in ipairs({80,144,264}) do
    reset_geometry(width); ui.begin_frame(); appearance_editor.draw(1,2,width); ui.end_frame()
    assert(#overflow==0,"wand appearance overflow at inner width "..width..": "..table.concat(overflow," | "))
end

-- Skin picker is a nested long list and must share the same viewport path.
_G.METAMORPH_CREATIVE_MENU_WAND_SKIN_PICKER_UI=nil
local skin_picker=assert(native_dofile(root.."/files/ui/components/wand_skin_picker.lua"))
reset_geometry(80); click_next_button=true; ui.begin_frame(); skin_picker.draw(1,2,visual,80); ui.end_frame()
for _,width in ipairs({80,144,264}) do
    reset_geometry(width); ui.begin_frame(); skin_picker.draw(1,2,visual,width); ui.end_frame()
    assert(#overflow==0,"wand skin picker overflow at inner width "..width..": "..table.concat(overflow," | "))
end

-- Presets: narrow name/actions fit; a failed SAVE reports once and never becomes a
-- permanent bottom row on following frames.
_G.METAMORPH_CREATIVE_MENU_WAND_PRESETS_UI=nil
local presets_ui=assert(native_dofile(root.."/files/ui/components/wand_presets.lua"))
reset_geometry(80); click_next_button=true; ui.begin_frame(); presets_ui.draw(1,2,80); ui.end_frame()
local before_prints=#prints
reset_geometry(80); click_label="SAVE"; ui.begin_frame(); presets_ui.draw(1,2,80); ui.end_frame()
assert(#overflow==0,"wand presets overflowed narrow workspace")
assert(#prints==before_prints+1,"preset failure was not reported once")
local failure_text=prints[#prints]
reset_geometry(80); ui.begin_frame(); presets_ui.draw(1,2,80); ui.end_frame()
assert(#prints==before_prints+1,"stale preset failure repeated on next frame")
for _,text in ipairs(texts) do assert(not string.find(text,"intentional_preset_failure",1,true),"raw stale preset reason remained in layout") end
assert(failure_text~="","preset failure user message was empty")

print("ui_adaptive_sections=PASS widths=96_160_280 bounds=true rows_reflow=true weather_no_duplicate=true focus_stable=true wand_inner_width=true transient_errors=true")
