local root=assert(arg[1],'root required')
local native_dofile=dofile
local queued={}
local drawn={}
local acquired,released=0,0
local frame=1
local saved={}
local left_just_down=false
local left_down=false
local mouse_gui_x,mouse_gui_y=80,30
local click_label=nil
local resize_affordance_calls=0
local highlighted_resize_edges=nil
local text_active=false
local focus_blurs=0
local panel_bounds={x=0,y=0,width=0,height=0}
local affordance_bounds=nil
local button_labels={}
local drag_handle_calls={}
local tab_tiles={}

local ui={
    ICON_STEP=20,EMPTY_SLOT='slot',audit=function() end,bind=function() end,begin_frame=function() end,
    gui=function() return 1 end,tr=function(_,fallback) return fallback end,
    tile=function(_,_,_,icon,fallback,title,description,selected,options)
        tab_tiles[title]={icon=icon,fallback=fallback,description=description,selected=selected,options=options}
        return false,false
    end,
    button=function(_,_,text)
        button_labels[#button_labels+1]=text
        if click_label~=nil and text==click_label then click_label=nil; return true end
        return false
    end,
    drag_handle=function(_,_,layout_text,title,tooltip_title,tooltip_description)
        drag_handle_calls[#drag_handle_calls+1]={layout_text=layout_text,title=title,tooltip_title=tooltip_title,tooltip_description=tooltip_description}
        return false
    end,
    text_width=function(text) return #tostring(text)*5 end,
    white_text=function() end,colored_text=function() end,
    finish_auto_box=function()
        return panel_bounds.x-4,panel_bounds.y-4,panel_bounds.width+8,panel_bounds.height+8
    end,
    set_panel_bounds=function(x,y,width,height)
        panel_bounds={x=x,y=y,width=width,height=height}
    end,
    resize_affordances=function(x,y,width,height,edges)
        resize_affordance_calls=resize_affordance_calls+1
        highlighted_resize_edges=edges
        affordance_bounds={x=x,y=y,width=width,height=height}
    end,
    hovered=function() return false end,
    text_input_active=function() return text_active end,
    blur_text_input=function()
        if text_active then focus_blurs=focus_blurs+1; text_active=false; return true end
        return false
    end,
}
local action_bindings={
    update=function() end,
    consume=function(id) if queued[id] then queued[id]=nil; return true end return false end,
    label=function() return '—' end,
}
local guard={
    inventory_open=function() return false end,
    acquire_manual_controls=function(player) assert(player==1); acquired=acquired+1; return true end,
    release_manual_controls=function() released=released+1; return true end,
    capture_scroll_selection=function() return nil end,
    restore_scroll_selection=function() end,
}
local stubs={
    ['mods/metamorph_creative_menu/files/ui/runtime.lua']=ui,
    ['mods/metamorph_creative_menu/files/platform/noita/player_locator.lua']={get=function() return 1 end},
    ['mods/metamorph_creative_menu/files/platform/noita/input_guard.lua']={blocked=function() return false end,resume_serial=function() return 0 end},
    ['mods/metamorph_creative_menu/files/platform/noita/menu_inventory_guard.lua']=guard,
    ['mods/metamorph_creative_menu/files/platform/noita/action_bindings.lua']=action_bindings,
    ['mods/metamorph_creative_menu/files/ui/drag_drop.lua']={
        begin_frame=function() end, end_frame=function() end, cancel=function() end,
    },
}
for _,name in ipairs({'spells','items','materials','perks','creatures','effects','weather','world_rules','players','controls'}) do
    stubs['mods/metamorph_creative_menu/files/ui/tabs/'..name..'.lua']={
        draw=function() drawn[#drawn+1]=name end,
        warmup_step=function() return true end,
    }
end
dofile=function(path)
    if stubs[path] then return stubs[path] end
    local prefix='mods/metamorph_creative_menu/'
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

GUI_OPTION={NoPositionTween=1}
GuiCreate=function() return 1 end
GuiStartFrame=function() end
GuiOptionsAdd=function() end
GuiGetScreenDimensions=function() return 320,200 end
GuiLayoutBeginVertical=function() end
GuiLayoutBeginHorizontal=function() end
GuiLayoutEnd=function() end
GuiBeginAutoBox=function() end
InputIsMouseButtonJustDown=function(code) return code==1 and left_just_down end
InputIsMouseButtonDown=function(code) return code==1 and left_down end
DEBUG_GetMouseWorld=function() return mouse_gui_x-160,mouse_gui_y-100 end
GameGetCameraPos=function() return 0,0 end
MagicNumbersGetValue=function(name)
    if name=='VIRTUAL_RESOLUTION_X' then return '320' end
    if name=='VIRTUAL_RESOLUTION_OFFSET_X' then return '0' end
    return '0'
end
GameGetFrameNum=function() return frame end
ModSettingGet=function(id) return saved[id] end
ModSettingSet=function(id,value) saved[id]=value end

METAMORPH_CREATIVE_MENU_MENU_CONTROLLER=nil
local controller=assert(native_dofile(root..'/files/ui/menu_controller.lua'))
queued.menu_toggle=true
controller.draw()
assert(controller.is_open() and controller.active_tab()=='spells' and drawn[#drawn]=='spells',
    'assignable menu key did not open the first useful section')
assert(acquired==0,'opening the menu alone suppressed gameplay controls')
assert(#drag_handle_calls>0 and drag_handle_calls[#drag_handle_calls].title=='SPELLS',
    'header did not expose the active section through the dedicated drag handle')
for _,label in ipairs(button_labels) do
    assert(label~='<' and label~='>','legacy previous/next section button remained in the header')
end
for title,tile in pairs(tab_tiles) do
    assert(tile.description==nil,'tab tooltip leaked an empty/service binding description for '..tostring(title))
    assert(not string.find(tostring(title),'\n',1,true) and tostring(title)~='—' and not string.find(tostring(title),'open_',1,true),
        'tab tooltip title leaked a second line/dash/technical id for '..tostring(title))
end
assert(tab_tiles.PERKS.icon=='data/ui_gfx/perk_icons/respawn.png'
    and tab_tiles.PERKS.fallback=='data/ui_gfx/perk_icons/extra_hp.png'
    and tab_tiles.PERKS.options.fill>=1.5 and tab_tiles.PERKS.options.fill<=1.6
    and tab_tiles.PERKS.options.max_scale==3.5,
    'PERKS Extra Life icon did not keep the corrected moderate scale')
assert(tab_tiles.EFFECTS.icon=='data/ui_gfx/status_indicators/hp_regeneration.png',
    'EFFECTS did not use the healing/regeneration icon')
assert(tab_tiles.WEATHER.icon=='data/ui_gfx/status_indicators/wet.png',
    'WEATHER did not use the wet status icon')
assert(tab_tiles.TELEPORTATION.icon=='data/ui_gfx/gun_actions/teleport_projectile_static.png',
    'TELEPORTATION did not use the Return spell icon')
assert(tab_tiles.CONTROLS.icon=='data/ui_gfx/gun_actions/divide_2.png',
    'CONTROLS did not use the Divide by 2 spell icon')

frame=2; text_active=true; controller.draw()
assert(acquired==1,'focused text input did not temporarily suppress gameplay controls')

-- A context/tab switch releases the real focus owner before the next tab draws, so
-- ControlsComponent is not kept disabled by a stale text-entry flag.
frame=2; queued.open_materials=true; controller.draw()
assert(controller.active_tab()=='materials' and drawn[#drawn]=='materials',
    'direct section shortcut did not navigate while menu was open')
assert(focus_blurs==1,'tab switch did not release focused text input')
assert(acquired==1,'stale text focus kept gameplay controls disabled after tab switch')
assert(saved['metamorph_creative_menu.ui_last_tab']=='materials','last section was not persisted')

frame=3; queued.tab_next=true; controller.draw()
assert(controller.active_tab()=='perks' and drawn[#drawn]=='perks','next-section action used wrong ordering')

frame=4; queued.menu_toggle=true; local before=#drawn; controller.draw()
assert(not controller.is_open() and #drawn==before,'menu toggle did not close the manual panel')
assert(released>0,'manual menu did not release controls on close')

frame=5; queued.open_controls=true; controller.draw()
assert(controller.is_open() and controller.active_tab()=='controls' and drawn[#drawn]=='controls',
    'direct section shortcut did not open a closed menu')

-- Only the click itself is modal: a panel click cannot also fire the held wand, while
-- opening or hovering the menu leaves gameplay controls untouched.
local acquired_before_click=acquired
frame=51; left_just_down=true; left_down=true; mouse_gui_x=120; mouse_gui_y=90
controller.draw()
assert(acquired==acquired_before_click+1,'panel click was not isolated from gameplay input')
frame=52; left_just_down=false; left_down=false; controller.draw()

-- The full title bar (except window controls) moves the panel, even outside the title
-- glyphs themselves, and persists its position on release.
local drag_origin=assert(controller.layout())
frame=6; left_just_down=true; left_down=true; mouse_gui_x=drag_origin.x+30; mouse_gui_y=drag_origin.y+6
controller.draw()
frame=7; left_just_down=false; left_down=true; mouse_gui_x=drag_origin.x-10; mouse_gui_y=drag_origin.y+16
controller.draw()
frame=8; left_down=false; controller.draw()
local moved=assert(controller.layout())
assert(moved.x==60 and moved.y==20,'title bar did not move/clamp the panel by the mouse delta')
assert(saved['metamorph_creative_menu.ui_panel_x']==60 and saved['metamorph_creative_menu.ui_panel_y']==20,
    'dragged panel position was not persisted')

-- The right border changes width without losing position and persists on release.
frame=9; left_just_down=true; left_down=true; mouse_gui_x=275; mouse_gui_y=100
controller.draw()
assert(type(highlighted_resize_edges)=='table' and highlighted_resize_edges.right,
    'right resize border did not expose a visible hover/drag affordance')
assert(affordance_bounds.x==56 and affordance_bounds.width==218,
    'custom frame did not overlay the measured outer AutoBox bounds')
frame=10; left_just_down=false; left_down=true; mouse_gui_x=295
controller.draw()
frame=11; left_down=false; controller.draw()
local resized=assert(controller.layout())
assert(resized.width==230 and resized.x==60,'resize grip did not widen from its drag origin')
assert(saved['metamorph_creative_menu.ui_panel_width']==230,'resized panel width was not persisted')

-- Hovering the border advertises resize without changing layout.
highlighted_resize_edges=nil
frame=111; left_just_down=false; left_down=false; mouse_gui_x=295; mouse_gui_y=100
controller.draw()
assert(type(highlighted_resize_edges)=='table' and highlighted_resize_edges.right,
    'menu border did not advertise resize before the press')
assert(controller.layout().width==230,'border hover changed menu width')

-- A press that began somewhere else stays owned by whatever interaction started it.
-- Crossing the frame while the button is held must not highlight or arm resize. This
-- rule is intentionally independent of spell/item drag-drop payload types.
frame=112; left_just_down=true; left_down=true; mouse_gui_x=310; mouse_gui_y=100
controller.draw()
highlighted_resize_edges=nil
frame=113; left_just_down=false; left_down=true; mouse_gui_x=295; mouse_gui_y=100
controller.draw()
assert(highlighted_resize_edges==nil,
    'held pointer crossing the menu border incorrectly armed resize')
frame=114; left_down=false; controller.draw()
assert(controller.layout().width==230,'cross-border held pointer changed menu width')

-- The two-pixel outward part of the thicker visible frame is a real resize target,
-- but only when the fresh press itself begins there.
highlighted_resize_edges=nil
frame=115; left_just_down=true; left_down=true; mouse_gui_x=295; mouse_gui_y=100
controller.draw()
assert(type(highlighted_resize_edges)=='table' and highlighted_resize_edges.right,
    'fresh press on the expanded visible frame did not arm resize')
frame=116; left_just_down=false; left_down=false; controller.draw()

-- The bottom border changes height independently.
frame=12; left_just_down=true; left_down=true; mouse_gui_x=150; mouse_gui_y=196
controller.draw()
frame=13; left_just_down=false; left_down=true; mouse_gui_y=166
controller.draw()
frame=14; left_down=false; controller.draw()
assert(controller.layout().height==140,'bottom border did not resize panel height')
assert(saved['metamorph_creative_menu.ui_panel_height']==140,'resized panel height was not persisted')

-- A wild drag cannot strand the menu outside the viewport.
local before_wild=assert(controller.layout())
frame=15; left_just_down=true; left_down=true; mouse_gui_x=before_wild.x+25; mouse_gui_y=before_wild.y+6
controller.draw()
frame=16; left_just_down=false; left_down=true; mouse_gui_x=-500; mouse_gui_y=-500
controller.draw()
frame=17; left_down=false; controller.draw()
local clamped=assert(controller.layout())
assert(clamped.x==10 and clamped.y==10,'panel drag did not keep the visible resize frame inside the viewport')

-- Minimize releases the gameplay-modal state and the title bar restores it.
frame=18; click_label='-'; controller.draw()
assert(controller.layout().minimized and not controller.is_open(),'hide button did not minimize the menu')
frame=19; click_label='+'; controller.draw()
assert(not controller.layout().minimized and controller.is_open(),'restore button did not restore the menu')

-- Recovery button resets both dimensions and position.
frame=20; click_label='R'; controller.draw()
local reset=assert(controller.layout())
assert(reset.x==100 and reset.y==20 and reset.width==210 and reset.height==170,
    'layout reset did not restore responsive defaults')
assert(resize_affordance_calls>0,'resizable window corners were never drawn')

-- The minimize/close control end of the title row is deliberately not a move target.
frame=21; left_just_down=true; left_down=true; mouse_gui_x=305; mouse_gui_y=22
controller.draw()
frame=22; left_just_down=false; left_down=true; mouse_gui_x=250; mouse_gui_y=50
controller.draw()
frame=23; left_down=false; controller.draw()
local controls_excluded=assert(controller.layout())
assert(controls_excluded.x==100 and controls_excluded.y==20,
    'window-control area incorrectly started title-bar movement')

print('menu_navigation_bindings=PASS useful_default=true toggle=true direct_tabs=true cycling=true persistence=true controls_guard=true focus_tab_blur=true styled_drag_handle=true no_header_arrows=true tab_tooltips_clean=true exact_tab_icons=true full_titlebar_drag=true controls_excluded=true border_hover=true press_origin=true expanded_frame_target=true noita_frame_affordance=true minimize=true viewport_clamp=true reset=true')
