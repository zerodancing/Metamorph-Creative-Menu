local root=assert(arg[1],'root required')
local native_dofile=dofile
local typed='-'
local focused=true
local last_blur=nil
local focus_key='numeric.focus'
local applied=nil
local blur_calls=0
local allowed_seen=nil

local ui={
 gui=function() return 1 end,
 white_text=function() end,
 wrapped_text=function() end,
 text_width=function(text) return #tostring(text)*5 end,
 button=function() return false end,
 text_input=function(before,width,max_chars,key,options)
  focus_key=key
  last_blur=options.on_blur
  allowed_seen=options.allowed_characters
  return typed,focused
 end,
 text_input_focus_key=function() return focus_key end,
 blur_text_input=function(reason)
  blur_calls=blur_calls+1
  if last_blur then last_blur(reason,focus_key) end
  focus_key=nil
  return true
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
local opts={integer=false,value_width=58,value_chars=8,max_width=300,
 on_apply=function(value) applied=value; return true end}

-- Intermediate text remains a draft for as long as logical focus remains, regardless of hover.
local changed,reason,draft,is_focused=numeric.draw('numeric.focus','VALUE',10,opts)
assert(not changed and reason==nil and draft=='-' and is_focused,'unfinished draft did not remain while focused')
assert(allowed_seen=='0123456789.-','numeric field lost its restricted native character set')
typed='-'; focused=true
changed,reason,draft,is_focused=numeric.draw('numeric.focus','VALUE',10,opts)
assert(draft=='-' and is_focused,'unfinished numeric draft reset while logical focus remained')

-- Context blur cancels only the unfinished draft back to the model's canonical value.
assert(type(last_blur)=='function','numeric field did not register blur resolution')
last_blur('tab_changed','numeric.focus')
typed='10'; focused=false
changed,reason,draft,is_focused=numeric.draw('numeric.focus','VALUE',10,opts)
assert(draft=='10' and not is_focused and applied==nil,'tab/context blur did not cancel unfinished draft safely')

-- A valid draft commits immediately and remains canonical after a later blur.
typed='12'; focused=true
changed,reason,draft,is_focused=numeric.draw('numeric.focus','VALUE',10,opts)
assert(changed and applied==12 and draft=='12','valid numeric draft did not commit immediately')
typed='12'; focused=true
numeric.draw('numeric.focus','VALUE',12,opts) -- refresh canonical/blur callback from committed model
assert(type(last_blur)=='function'); last_blur('pointer','numeric.focus')
typed='12'; focused=false
local _,_,draft_after=numeric.draw('numeric.focus','VALUE',12,opts)
assert(draft_after=='12','blur rolled back an already committed numeric value')

-- Wand-context reset blurs a matching active stat field before discarding its draft.
focus_key='wand.stat.7.mana'; last_blur=function() end
numeric.reset('wand.stat.')
assert(blur_calls==1,'wand numeric reset did not release matching focus before discarding drafts')

print('fixed_numeric_focus_draft=PASS hover_safe=true unfinished_cancel=true committed_preserved=true wand_reset_blurs=true')
