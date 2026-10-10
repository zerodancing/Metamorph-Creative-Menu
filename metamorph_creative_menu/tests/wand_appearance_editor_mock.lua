local root=assert(arg[1])
local native_dofile=dofile
local apply_index=0
local click_expand=true
local click_name_apply=false
local click_grid=nil
local typed_name='Draft Ω'
local input_calls={}
local game_prints={}
local diagnostics={}
local wrapped_calls=0
local reset_calls=0
local fail_name=false
local state={
 wand=2,item=31,sprite=32,hotspot=33,name='Old',show_name_in_ui=true,wand_frozen=false,
 sprite_file='old.png',image_file='old.png',offset_x=3,offset_y=4,tip_x=5,tip_y=6,
}
local spell_frozen=false

local function copy(t) local o={}; for k,v in pairs(t) do o[k]=v end; return o end
local ui={}
function ui.gui() return 1 end
function ui.tr(key,fallback) return fallback end
function ui.white_text() end
function ui.wrapped_text() wrapped_calls=wrapped_calls+1 end
function ui.button(x,y,label)
 label=tostring(label or '')
 if string.find(label,'APPEARANCE & LOCKS',1,true) then
  local v=click_expand; click_expand=false; return v
 end
 if string.find(label,'APPLY',1,true) then
  apply_index=apply_index+1
  return click_name_apply and apply_index==1
 end
 return false
end
function ui.button_grid(items)
 for index,item in ipairs(items or {}) do
  local label=tostring(item.label or '')
  if string.find(label,'APPEARANCE & LOCKS',1,true) and click_expand then click_expand=false; return index end
  if label=='APPLY' then
   apply_index=apply_index+1
   if click_name_apply and apply_index==1 then return index end
  end
 end
 local v=click_grid; click_grid=nil; return v
end
function ui.text_input(value,width,max_length,key)
 input_calls[#input_calls+1]={value=value,width=width,key=key}
 if string.find(tostring(key),'wand.name.',1,true) then return typed_name,true end
 return value,false
end

local appearance={}
function appearance.snapshot(wand) local s=copy(state); s.wand=wand; return s,'ok' end
function appearance.spell_freeze_state() return spell_frozen,false,1 end
function appearance.set_name(player,wand,name,show)
 if fail_name then return false,'name_fault' end
 state.name=tostring(name or '')
 state.show_name_in_ui=show==true and state.name~=''
 return true,'ok'
end
function appearance.set_wand_frozen(player,wand,value) state.wand_frozen=value==true; return true,'ok' end
function appearance.set_spells_frozen(player,wand,value) spell_frozen=value==true; return true,'ok' end
function appearance.set_visual(player,wand,values)
 for k,v in pairs(values or {}) do
  if k=='sprite_file' then state.sprite_file=v; state.image_file=v else state[k]=v end
 end
 return true,'ok'
end
local history={perform=function(player,wand,label,callback,options) return callback() end}
local numeric={
 reset=function() reset_calls=reset_calls+1 end,
 draw=function(key,label,value,options) return false,nil,tostring(value or ''),false end,
}
local skin_picker={draw=function() return false,nil end}

dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/ui/runtime.lua' then return ui end
 if path=='mods/metamorph_creative_menu/files/features/wands/appearance.lua' then return appearance end
 if path=='mods/metamorph_creative_menu/files/features/wands/history.lua' then return history end
 if path=='mods/metamorph_creative_menu/files/ui/components/fixed_numeric_editor.lua' then return numeric end
 if path=='mods/metamorph_creative_menu/files/ui/components/wand_skin_picker.lua' then return skin_picker end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
GuiLayoutBeginHorizontal=function() end
GuiLayoutEnd=function() end
GuiTooltip=function() end
GamePrint=function(message) game_prints[#game_prints+1]=message end
METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE=function(source,details) diagnostics[#diagnostics+1]={source,details} end

local editor=assert(native_dofile(root..'/files/ui/components/wand_appearance_editor.lua'))
local function draw(width)
 apply_index=0
 input_calls={}
 local ok,reason=editor.draw(1,2,width)
 assert(ok==true,'editor draw failed '..tostring(reason))
 return input_calls
end

-- The section opens with the name field present even at a narrow legal panel width.
local calls=draw(72)
local name_call=nil
for _,call in ipairs(calls) do if string.find(call.key,'wand.name.',1,true) then name_call=call end end
assert(name_call~=nil,'name field disappeared at narrow width')
assert(name_call.width>=36 and name_call.width<=60,'name field overflowed narrow panel: '..tostring(name_call.width))
assert(name_call.value=='Old','initial name draft did not come from current wand')

-- A changed snapshot on the next frame must not replace an in-progress draft.
state.name='Synced Remote Name'
calls=draw(280)
name_call=nil
for _,call in ipairs(calls) do if string.find(call.key,'wand.name.',1,true) then name_call=call end end
assert(name_call and name_call.value=='Draft Ω','name draft was reset by snapshot refresh')
assert(name_call.width==268,'wide name field did not use available panel width')
assert(reset_calls==1,'numeric/name state reset unexpectedly between frames')

-- One real failure is surfaced once via user + diagnostics, never as a persistent layout row.
fail_name=true; click_name_apply=true
draw(160)
assert(#game_prints==1 and #diagnostics==1,'first appearance error was not reported once')
assert(diagnostics[1][1]=='wand.appearance' and diagnostics[1][2]=='name_fault','appearance diagnostic payload wrong')
draw(160)
assert(#game_prints==1 and #diagnostics==1,'same stale error repeated on retry/frame')
assert(wrapped_calls==0,'appearance error is still rendered permanently in the section')

-- A successful operation clears the old error, allowing a later real failure to report again.
fail_name=false; draw(160)
fail_name=true; draw(160)
assert(#game_prints==2 and #diagnostics==2,'successful operation did not clear prior error state')

print('wand_appearance_editor=PASS name_visible=true draft_persists=true error_once=true')
