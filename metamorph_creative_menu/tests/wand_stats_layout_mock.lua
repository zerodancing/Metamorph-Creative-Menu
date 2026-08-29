local root=assert(arg[1],'root required')
local native_dofile=dofile

-- First exercise the real fixed numeric editor with a tiny deterministic layout model.
local cursor=0
local buttons={}
local fields={}
local ui={
 gui=function() return 1 end,
 text_width=function(text) return #tostring(text or '')*5 end,
 truncate_text=function(text,width)
  text=tostring(text or '')
  while #text>1 and #text*5>width-15 do text=string.sub(text,1,#text-1) end
  return (#text*5<=width) and text or string.sub(text,1,1)
 end,
 white_text=function(_,_,text) cursor=cursor+#tostring(text or '')*5 end,
 button=function(_,_,label)
  buttons[#buttons+1]={label=label,x=cursor}
  cursor=cursor+#tostring(label or '')*5+6
  return false
 end,
 text_input=function(before,width,max_chars,key,options)
  fields[#fields+1]={key=key,x=cursor,width=width,value=before}
  cursor=cursor+width
  return before,false
 end,
 text_input_focus_key=function() return nil end,
}
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/ui/runtime.lua' then return ui end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
GuiLayoutBeginHorizontal=function() cursor=0 end
GuiLayoutAddHorizontalSpacing=function(_,amount) cursor=cursor+(tonumber(amount) or 0) end
GuiLayoutEnd=function() end
GuiTooltip=function() end

METAMORPH_CREATIVE_MENU_FIXED_NUMERIC_EDITOR=nil
local numeric=assert(native_dofile(root..'/files/ui/components/fixed_numeric_editor.lua'))

local function geometry(value,panel_width)
 buttons,fields={},{}
 numeric.reset('wand.layout.')
 local changed,reason=numeric.draw('wand.layout.slots','SLOTS',value,{
  integer=true,min=1,max=64,label_width=94,value_width=58,value_chars=8,max_width=panel_width,
  on_apply=function() return true,'ok' end,
 })
 assert(changed==false and reason==nil,'layout-only draw unexpectedly mutated capacity')
 assert(#buttons==2 and #fields==1,'numeric row did not draw exactly decrement/field/increment')
 return {dec=buttons[1].x, field=fields[1].x, field_width=fields[1].width, inc=buttons[2].x, finish=cursor}
end

for _,width in ipairs({120,260}) do
 local one=geometry(1,width)
 local twenty_six=geometry(26,width)
 local sixty_four=geometry(64,width)
 for _,g in ipairs({twenty_six,sixty_four}) do
  assert(g.dec==one.dec,'capacity value moved decrement column at width '..width)
  assert(g.field==one.field and g.field_width==one.field_width,'capacity value moved/resized field at width '..width)
  assert(g.inc==one.inc,'capacity value moved increment column at width '..width)
 end
 assert(one.finish<=width and twenty_six.finish<=width and sixty_four.finish<=width,
  'numeric row exceeded viewport at width '..width)
end

-- Render the real wand stats shell with collaborators stubbed. The removed Current State
-- component must not be linked, while unit-bearing stats keep localized tooltip descriptions.
local stat_calls={}
local sequence={}
local numeric_stub={
 reset=function() end,
 draw=function(key,label,value,options)
  stat_calls[key]={label=label,value=value,options=options}
  sequence[#sequence+1]='stat:'..key
  return false,nil
 end,
}
local stats={
 slots=26,actions_per_round=1,reload_time=30,fire_rate_wait=12,spread_degrees=-3,
 speed_multiplier=1,mana_max=100,mana_charge_speed=50,item_recoil_recovery_speed=0,gun_level=1,
 shuffle=false,never_reload=false,
}
local editor_ui={
 tr=function(key,fallback)
  local descriptions={
   ['$mcm_wand_recharge_desc']='recharge frames help',
   ['$mcm_wand_cast_delay_desc']='cast frames help',
   ['$mcm_wand_spread_desc']='spread degrees help',
  }
  return descriptions[key] or fallback
 end,
 button=function() return false end,
 button_grid=function() sequence[#sequence+1]='toggles'; return nil end,
 wrapped_text=function() end,
}
local service={
 snapshot=function() return {stats=stats},'ok' end,
 definition=function(id)
  if id=='slots' then return {integer=true,min=1,max=64,step=1} end
  if id=='actions_per_round' or id=='reload_time' or id=='fire_rate_wait' or id=='gun_level' then return {integer=true,step=1} end
  return {step=1}
 end,
 set_stat=function() return true,'ok' end,
 set_boolean=function() return true,'ok' end,
}
local history_options={}
local history={perform=function(player,wand,label,callback,options) history_options[#history_options+1]=options; return callback() end}
local history_bar={draw=function() sequence[#sequence+1]='history'; return false,nil end}
local appearance={draw=function() sequence[#sequence+1]='appearance'; return true end}

dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/ui/runtime.lua' then return editor_ui end
 if path=='mods/metamorph_creative_menu/files/features/wands/service.lua' then return service end
 if path=='mods/metamorph_creative_menu/files/features/wands/history.lua' then return history end
 if path=='mods/metamorph_creative_menu/files/ui/components/wand_history_bar.lua' then return history_bar end
 if path=='mods/metamorph_creative_menu/files/ui/components/fixed_numeric_editor.lua' then return numeric_stub end
 if path=='mods/metamorph_creative_menu/files/ui/components/wand_appearance_editor.lua' then return appearance end
 if path=='mods/metamorph_creative_menu/files/ui/components/wand_runtime_editor.lua' then error('runtime editor must not be linked by wand stats UI') end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
METAMORPH_CREATIVE_MENU_WAND_EDITOR_UI=nil
local editor=assert(native_dofile(root..'/files/ui/components/wand_editor.lua'))
assert(editor.draw(1,2,180)==true,'wand editor draw failed')
for id,expected in pairs({reload_time='recharge frames help',fire_rate_wait='cast frames help',spread_degrees='spread degrees help'}) do
 local call=assert(stat_calls['wand.stat.2.'..id],'missing stat '..id)
 assert(call.options.suffix==nil or call.options.suffix=='','visible technical suffix survived for '..id)
 assert(call.options.label_tooltip_description==expected,'localized unit help missing for '..id)
end
assert(sequence[#sequence]=='appearance','appearance did not follow stats directly after runtime UI removal')
local slot_apply=assert(stat_calls['wand.stat.2.slots'].options.on_apply)
assert(slot_apply(27)==true and slot_apply(28)==true,'repeated capacity edits did not route through history')
assert(#history_options==2 and history_options[1].coalesce_key=='stat.slots' and history_options[2].coalesce_key=='stat.slots'
 and history_options[1].coalesce_frames==45 and history_options[2].coalesce_frames==45,
 'wand stat repeat edits lost history coalescing contract')

print('wand_stats_layout=PASS capacity_columns=1_26_64 narrow=true wide=true current_state_absent=true suffixes_hidden=true unit_tooltips=true')
