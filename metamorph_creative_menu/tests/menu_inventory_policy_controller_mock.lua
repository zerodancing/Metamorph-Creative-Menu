local root=assert(arg[1], 'root required')
local native_dofile=dofile

local saved={
    ['metamorph_creative_menu.ui_panel_x']=61,
    ['metamorph_creative_menu.ui_panel_y']=23,
    ['metamorph_creative_menu.ui_panel_width']=244,
    ['metamorph_creative_menu.ui_panel_height']=151,
}
local inventory_open=false
local queued={}
local drawn=0
local frame=1
local blocked=false
local text_active=false
local capture_active=false
local left_just=false
local left_down=false
local drag_pending=false
local acquire_calls=0
local mouse_x,mouse_y=8,8
local screen_width,screen_height=320,200

local ui={
    ICON_STEP=20, EMPTY_SLOT='slot',
    audit=function() end, bind=function() end, begin_frame=function() end, end_frame=function() end,
    gui=function() return 1 end, tr=function(_,fallback) return fallback end,
    tile=function() return false,false end, white_text=function() end, colored_text=function() end,
    text_width=function(text) return #tostring(text)*5 end,
    button=function() return false end,
    drag_handle=function(x,y) return false, tonumber(x) or 0, tonumber(y) or 0, 16, 10 end,
    finish_auto_box=function() return 57,19,252,159 end,
    set_panel_bounds=function() end, resize_affordances=function() end,
    hovered=function() return false end,
    text_input_active=function() return text_active end,
    reset_text_inputs=function() text_active=false end,
    blur_text_input=function() text_active=false; return true end,
}

local action_bindings={
    update=function() end,
    consume=function(id)
        if blocked or text_active or capture_active then return false end
        if queued[id] then queued[id]=nil; return true end
        return false
    end,
    label=function() return '—' end,
}
local input_guard={blocked=function() return blocked end,resume_serial=function() return 0 end}
local pointer={
    left_just_down=function() return left_just end,
    left_down=function() return left_down end,
    right_down=function() return false end,
    gui_position=function() return mouse_x,mouse_y end,
    inside=function(x,y,w,h,mx,my) return mx>=x and mx<=x+w and my>=y and my<=y+h end,
}
local guard={
    inventory_open=function() return inventory_open end,
    acquire_manual_controls=function() acquire_calls=acquire_calls+1; return true end,
    release_manual_controls=function() return true end,
    capture_scroll_selection=function() return nil end,
    restore_scroll_selection=function() end,
}

local stubs={
    ['mods/metamorph_creative_menu/files/ui/runtime.lua']=ui,
    ['mods/metamorph_creative_menu/files/platform/noita/player_locator.lua']={get=function() return 1 end},
    ['mods/metamorph_creative_menu/files/platform/noita/input_guard.lua']=input_guard,
    ['mods/metamorph_creative_menu/files/platform/noita/menu_inventory_guard.lua']=guard,
    ['mods/metamorph_creative_menu/files/platform/noita/action_bindings.lua']=action_bindings,
    ['mods/metamorph_creative_menu/files/platform/noita/pointer.lua']=pointer,
    ['mods/metamorph_creative_menu/files/ui/drag_drop.lua']={begin_frame=function() end,end_frame=function() end,cancel=function() end,pending=function() return drag_pending end},
}
for _,name in ipairs({'spells','items','materials','perks','creatures','effects','weather','world_rules','players','controls'}) do
    stubs['mods/metamorph_creative_menu/files/ui/tabs/'..name..'.lua']={draw=function() drawn=drawn+1 end,warmup_step=function() return true end}
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
GuiGetScreenDimensions=function() return screen_width,screen_height end
GuiLayoutBeginVertical=function() end
GuiLayoutBeginHorizontal=function() end
GuiLayoutEnd=function() end
GuiBeginAutoBox=function() end
InputIsMouseButtonJustDown=function() return false end
InputIsMouseButtonDown=function() return false end
GameGetFrameNum=function() return frame end
ModSettingGet=function(id) return saved[id] end
ModSettingSet=function(id,value) saved[id]=value end

local function reset_inputs()
    queued={}; blocked=false; text_active=false; capture_active=false
    left_just=false; left_down=false; drag_pending=false; mouse_x,mouse_y=8,8
end
local function load_controller(mode, remembered)
    reset_inputs()
    inventory_open=false
    saved['metamorph_creative_menu.inventory_open_policy']=mode
    saved['metamorph_creative_menu.ui_inventory_remembered_open']=remembered
    METAMORPH_CREATIVE_MENU_MENU_CONTROLLER=nil
    return assert(native_dofile(root..'/files/ui/menu_controller.lua'))
end
local function draw(controller)
    frame=frame+1
    controller.draw()
end

-- Legacy layout values survive loading the new policy unchanged.
do
    local c=load_controller('always_closed', true)
    queued.menu_toggle=true; draw(c)
    local l=assert(c.layout())
    assert(l.x==61 and l.y==23 and l.width==244 and l.height==151,
        'new inventory policy lost legacy panel layout settings')
end

-- Always Open: temporary F4 close, then reopen on next inventory edge.
do
    local c=load_controller('always_open', true)
    inventory_open=true; draw(c)
    assert(c.is_open(), 'Always Open did not auto-open with native inventory')
    queued.menu_toggle=true; draw(c)
    assert(not c.is_open(), 'Always Open F4 did not temporarily close')
    inventory_open=false; draw(c)
    inventory_open=true; draw(c)
    assert(c.is_open(), 'Always Open did not reopen on next inventory cycle')
end

-- Always Closed: F4 opens only this inventory session; no hidden auxiliary surface is required.
do
    local c=load_controller('always_closed', true)
    inventory_open=true; draw(c)
    assert(not c.is_open(), 'Always Closed auto-opened')
    queued.menu_toggle=true; draw(c)
    assert(c.is_open(), 'Always Closed F4 did not manually open')
    inventory_open=false; draw(c)
    assert(not c.is_open(), 'in-inventory manual open leaked after inventory close')
    inventory_open=true; draw(c)
    assert(not c.is_open(), 'next Always Closed inventory session did not start hidden')
end

-- Remember Last State persists explicit choices but not automatic inventory close.
do
    local c=load_controller('remember', false)
    inventory_open=true; draw(c)
    assert(not c.is_open(), 'remember=false did not restore closed state')
    queued.menu_toggle=true; draw(c)
    assert(c.is_open() and saved['metamorph_creative_menu.ui_inventory_remembered_open']==true,
        'explicit Remember open was not persisted')
    inventory_open=false; draw(c)
    assert(not c.is_open() and saved['metamorph_creative_menu.ui_inventory_remembered_open']==true,
        'automatic inventory close corrupted remembered preference')
    inventory_open=true; draw(c)
    assert(c.is_open(), 'remember=true did not restore after inventory cycle')
    queued.menu_toggle=true; draw(c)
    assert(not c.is_open() and saved['metamorph_creative_menu.ui_inventory_remembered_open']==false,
        'explicit Remember close was not persisted')

    -- Simulated game reload uses the saved preference.
    inventory_open=false
    c=load_controller('remember', saved['metamorph_creative_menu.ui_inventory_remembered_open'])
    inventory_open=true; draw(c)
    assert(not c.is_open(), 'Remember preference did not survive controller reload')
end

-- Focused text/binding capture and quarantine must not leak F4 into visibility state.
do
    local c=load_controller('always_closed', true)
    inventory_open=true; draw(c)
    text_active=true; queued.menu_toggle=true; draw(c)
    assert(not c.is_open(), 'focused text input leaked F4 into menu toggle')
    text_active=false; capture_active=true; queued.menu_toggle=true; draw(c)
    assert(not c.is_open(), 'binding capture leaked F4 into menu toggle')
    capture_active=false; blocked=true; queued.menu_toggle=true; draw(c)
    assert(not c.is_open(), 'input quarantine leaked F4 into menu toggle')
end

-- Always Closed remains reachable by F4 with no auxiliary inventory handle.
do
    local c=load_controller('always_closed', true)
    inventory_open=true; draw(c)
    assert(not c.is_open(), 'Always Closed fixture auto-opened')
    queued.menu_toggle=true; draw(c)
    assert(c.is_open(), 'removing inventory handle disabled F4 menu access')
end

-- An MCM drag still owns controls on the release frame (left_down is already false).
-- Otherwise vanilla InventoryGui can complete the same release and overwrite its slot.
do
    local c=load_controller('always_closed', true)
    inventory_open=true; queued.menu_toggle=true; draw(c)
    assert(c.is_open(), 'release-ownership fixture did not open')
    mouse_x,mouse_y=319,199
    left_down=false; drag_pending=true
    local before=acquire_calls
    draw(c)
    assert(acquire_calls==before+1,'drag release frame returned controls to vanilla InventoryGui early')
    drag_pending=false
end

print('menu_inventory_policy_controller=PASS modes=true f4=true remember_restart=true auto_close=true focus=true quarantine=true release_owned=true legacy_layout=true')

-- Exercise the real guard across native engine updates, not just API call counts.
stubs['mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua']={get=function() return nil end}
local controls_enabled=true
function EntityGetIsAlive(e) return e==1 end
function EntityGetFirstComponentIncludingDisabled(e,kind)
 if e~=1 then return nil end
 if kind=="ControlsComponent" then return 20 end
 if kind=="InventoryGuiComponent" then return 21 end
end
function ComponentGetValue2(c,field)
 if c==20 and field=="enabled" then return controls_enabled end
 if c==21 and field=="mActive" then return inventory_open end
end
function ComponentSetValue2(c,field,value)
 if c==20 and field=="enabled" then controls_enabled=value end
 if c==21 and field=="mActive" then inventory_open=value end
end
function GameIsInventoryOpen() return inventory_open end
METAMORPH_CREATIVE_MENU_MENU_INVENTORY_GUARD=nil
local real_guard=native_dofile(root..'/files/platform/noita/menu_inventory_guard.lua')
for k,v in pairs(real_guard) do guard[k]=v end
local c=load_controller('always_open',true)
inventory_open=true; draw(c)
local focus_on_draw=true
stubs['mods/metamorph_creative_menu/files/ui/tabs/spells.lua'].draw=function()
 if focus_on_draw then text_active=true end
end
mouse_x,mouse_y=100,60; left_just=true; left_down=true
draw(c)
assert(controls_enabled and not real_guard.manual_controls_owned(),"focus click left controls disabled through first typing frame")
left_just=false; left_down=false; focus_on_draw=false
-- I processed after MCM's pre-update.
inventory_open=false; c.post_update()
assert(inventory_open and text_active,"native inventory key closed focused editor in post-update")
draw(c); assert(c.is_open() and text_active,"next frame reset the editor")
-- A native edge already visible before MCM draws must also be neutralized.
inventory_open=false; draw(c)
assert(c.is_open() and inventory_open and text_active,"pre-draw native edge closed focused editor")
-- A click out of the field releases ownership; normal inventory closing works again.
text_active=false; draw(c)
inventory_open=false; draw(c)
assert(not c.is_open(),"inventory guard remained stuck after blur")
-- F4-only menu must not open the native inventory when typing I either.
c=load_controller('always_closed',false)
queued.menu_toggle=true; draw(c)
text_active=true; draw(c)
inventory_open=true; c.post_update()
assert(not inventory_open and c.is_open(),"I opened native inventory behind a manual text editor")
text_active=false; draw(c)
inventory_open=true; draw(c)
assert(inventory_open,"normal inventory opening remained blocked after blur")
print("menu_text_native_edges=PASS same_frame_release=true native_i=true pre_sync=true post_update=true manual_mode=true blur_releases=true")
