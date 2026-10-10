local root=assert(arg[1],'root required')
local native_dofile=dofile
local frame=1
local just_keys={}
local held_keys={}
local just_mouse={}
local held_mouse={}
local allowed=true
local text_active=false
local stored={['metamorph_creative_menu.possession_key']='CTRL+Key_k'}
local codes={Key_F4=4,Key_g=10,Key_k=11,Key_TAB=43,Key_ESCAPE=27,Key_DELETE=46,Key_BACKSPACE=8,
    Key_LCTRL=100,Key_LSHIFT=101,Key_LALT=102,Key_ALTERASE=103}

local keycodes={
    resolve=function(name) return codes[name] end,
    available=function()
        return {
            {code=4,name='Key_F4',label='F4'}, {code=10,name='Key_g',label='G'},
            {code=11,name='Key_k',label='K'}, {code=27,name='Key_ESCAPE',label='ESC'},
            {code=46,name='Key_DELETE',label='DELETE'}, {code=100,name='Key_LCTRL',label='LEFT CTRL'},
            {code=101,name='Key_LSHIFT',label='LEFT SHIFT'}, {code=102,name='Key_LALT',label='LEFT ALT'},
            {code=103,name='Key_ALTERASE',label='ALTERASE'},
        }
    end,
    pretty_name=function(name) return string.upper(string.gsub(name,'^Key_','')) end,
}

dofile=function(path)
    if path=='mods/metamorph_creative_menu/files/platform/noita/keycodes.lua' then return keycodes end
    if path=='mods/metamorph_creative_menu/files/platform/noita/input_guard.lua' then
        return {actions_allowed=function() return allowed end}
    end
    if path=='mods/metamorph_creative_menu/files/platform/noita/text_entry_guard.lua' then
        return {active=function() return text_active end}
    end
    local prefix='mods/metamorph_creative_menu/'
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

GameGetFrameNum=function() return frame end
ModSettingGet=function(id) return stored[id] end
ModSettingSet=function(id,value) stored[id]=value end
ModSettingSetNextValue=function(id,value) stored[id]=value end
InputIsKeyJustDown=function(code) return just_keys[code]==true end
InputIsKeyDown=function(code) return held_keys[code]==true end
InputIsMouseButtonJustDown=function(code) return just_mouse[code]==true end
InputIsMouseButtonDown=function(code) return held_mouse[code]==true end

METAMORPH_CREATIVE_MENU_ACTION_BINDINGS=nil
METAMORPH_CREATIVE_MENU_ACTION_REGISTRY=nil
METAMORPH_CREATIVE_MENU_BINDING_CODEC=nil
METAMORPH_CREATIVE_MENU_BINDING_CAPTURE=nil
local bindings=assert(native_dofile(root..'/files/platform/noita/action_bindings.lua'))
local codec=assert(native_dofile(root..'/files/core/binding_codec.lua'))
local malformed, malformed_reason=codec.parse('Key_g+Key_k')
assert(malformed==nil and malformed_reason=='multiple_base','binding codec accepted multiple base keys')

-- Defaults work immediately and an action can only be consumed once per frame.
just_keys[4]=true
bindings.update()
assert(bindings.consume('menu_toggle')==true and bindings.consume('menu_toggle')==false,
    'default menu binding was not edge-triggered/consumable')

-- The old possession setting is migrated once and modifiers are matched exactly.
frame=2; just_keys={ [11]=true }; held_keys={ [100]=true }
bindings.update()
assert(bindings.consume('possession')==true,'legacy modified possession key was not migrated')
assert(stored['metamorph_creative_menu.binding_possession']=='CTRL+Key_k','legacy binding was not persisted')
frame=3; just_keys={ [11]=true }; held_keys={}
bindings.update()
assert(bindings.just_pressed('possession')==false,'unmodified key triggered a CTRL binding')

-- Held actions support remappable mouse buttons (the material brush path).
assert(bindings.set('paint_draw','SHIFT+Mouse:4'))
held_keys={[101]=true}; held_mouse={[4]=true}
assert(bindings.is_down('paint_draw')==true,'modified held mouse binding was not recognized')
held_keys={}
assert(bindings.is_down('paint_draw')==false,'held binding ignored exact modifiers')

-- Conflicts are observable rather than silently choosing one action.
assert(bindings.set('tab_previous','Key_k'))
assert(bindings.set('tab_next','Key_k'))
local conflicts=bindings.conflicts('tab_previous')
assert(#conflicts==1 and conflicts[1].id=='tab_next','binding conflict was not reported')
frame=4; just_keys={[11]=true}; held_keys={}
bindings.update()
assert(bindings.consume('tab_previous')==true and bindings.consume('tab_next')==false,
    'one physical conflict dispatched more than one action')

-- In-game capture accepts modifiers and suppresses normal actions on the capture frame.
frame=10; just_keys={}; held_keys={}
assert(bindings.start_capture('menu_close'))
bindings.update()
frame=11; just_keys={[11]=true}; held_keys={[101]=true}
bindings.update()
assert(bindings.get('menu_close')=='SHIFT+Key_k','capture lost key modifiers')
assert(bindings.just_pressed('tab_next')==false,'capture leaked the key into gameplay actions')

-- DELETE is a deliberate unbind operation; reset restores the registry default.
frame=12; just_keys={}; held_keys={}; assert(bindings.start_capture('menu_toggle')); bindings.update()
frame=13; just_keys={[46]=true}; bindings.update()
assert(bindings.get('menu_toggle')=='NONE','DELETE did not clear captured binding')
assert(bindings.reset('menu_toggle') and bindings.get('menu_toggle')=='Key_F4','default reset failed')

-- SDL's ALTERASE key contains the letters ALT but is an ordinary bindable key.
frame=14; just_keys={}; held_keys={}; assert(bindings.start_capture('menu_close')); bindings.update()
frame=15; just_keys={[103]=true}; bindings.update()
assert(bindings.get('menu_close')=='Key_ALTERASE','ALTERASE was mistaken for the ALT modifier')

text_active=true; allowed=true; frame=16; just_keys={[4]=true}; held_keys={[101]=true}; held_mouse={[4]=true}
bindings.update()
assert(bindings.just_pressed('menu_toggle')==false,'focused text leaked a key into action bindings')
assert(bindings.is_down('paint_draw')==false,'focused text leaked a held binding into gameplay')

text_active=false; allowed=false; frame=17; just_keys={[4]=true}; held_keys={}; held_mouse={}
bindings.update()
assert(bindings.just_pressed('menu_toggle')==false,'input quarantine did not block action registry')

print('action_bindings=PASS defaults=true migration=true modifiers=true malformed_rejected=true alterase=true mouse_hold=true conflicts=true capture=true text_focus=true quarantine=true')
