local root=assert(arg[1],'root required')
local native_dofile=dofile
local typed='1000'
local applied=nil
local focused=true
local ui={
 gui=function() return 1 end,
 white_text=function() end,
 wrapped_text=function() end,
 text_width=function(text) return #tostring(text)*5 end,
 button=function() return false end,
 text_input=function(before,width,max_chars,key,options)
  return typed,focused
 end,
}
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/ui/runtime.lua' then return ui end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
GuiLayoutBeginHorizontal=function() end
GuiLayoutAddHorizontalSpacing=function() end
GuiLayoutEnd=function() end

METAMORPH_CREATIVE_MENU_FIXED_NUMERIC_EDITOR=nil
local numeric=assert(native_dofile(root..'/files/ui/components/fixed_numeric_editor.lua'))
local changed,reason,draft=numeric.draw('slots','SLOTS',10,{
 integer=true,min=1,max=64,value_width=58,value_chars=8,max_width=300,
 on_apply=function(value) applied=value; return true,'ok' end,
})
assert(changed==true and reason==nil,'bounded typed value was not applied')
assert(applied==64,'typed value was not clamped to 64: '..tostring(applied))
assert(draft=='64','visible draft did not normalize to 64: '..tostring(draft))

-- A button-side apply must not be overwritten afterwards by the unchanged text draft.
typed='64'; focused=false; applied=nil
local click_once=true
ui.button=function(_,_,label)
 if click_once and string.find(label,'>') then click_once=false; return true end
 return false
end
numeric.reset('slots2')
local changed2,reason2,draft2=numeric.draw('slots2','SLOTS',64,{
 integer=true,min=1,max=64,value_width=58,value_chars=8,max_width=300,
 on_apply=function(value) applied=value; return true,'ok' end,
})
assert(changed2==true and reason2==nil and applied==64,'increment at cap did not stay at 64')
assert(draft2=='64','button apply was overwritten by stale text draft')
print('fixed_numeric_editor_bounds=PASS typed_clamp=64 button_clamp=64 draft_sync=true')
