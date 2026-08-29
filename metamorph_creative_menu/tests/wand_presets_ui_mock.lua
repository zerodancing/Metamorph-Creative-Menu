local root=assert(arg[1])
local native_dofile=dofile
local images={}
local buttons={}
local save_calls=0
local list={
 {name='Meta icon',blueprint={meta={image_file='meta.png'},sprite_file='sprite_a.xml'}},
 {name='Sprite icon',blueprint={meta={},sprite_file='sprite_b.xml'}},
 {name='Fallback icon',blueprint={meta={image_file='missing.png'},sprite_file='missing.xml'}},
}
local next_id=0
local scroll_width=nil
local scroll_options='unset'
local truncated={}

local ui={}
function ui.gui() return 1 end
function ui.next_id() next_id=next_id+1; return next_id end
function ui.tr(_,fallback) return fallback end
function ui.text_input() return 'New preset' end
function ui.white_text() end
function ui.text_width(text) return #tostring(text or '')*5 end
function ui.truncate_text(text,width) truncated[#truncated+1]={text=text,width=width}; return text end
function ui.resolve(path)
 if path=='missing.png' or path=='missing.xml' or path==nil then return nil end
 return path
end
function ui.dimensions() return 16,16 end
function ui.button(_,_,label) buttons[#buttons+1]=label; return false end
function ui.button_grid(items)
 for index,item in ipairs(items or {}) do
  buttons[#buttons+1]=item.label
  if item.label=='+ WAND PRESETS' then return index end
  if item.label=='SAVE' and save_calls==0 then save_calls=save_calls+1; return index end
 end
 return nil
end
function ui.clear_error_notice() end
function ui.report_error_once() end
function ui.begin_scroll_viewport(_,_,_,_,width,_,options)
 scroll_width=width; scroll_options=options
 return {content_width=math.max(48,width-12)}
end
function ui.end_scroll_viewport() end

local presets={}
function presets.save(name,wand)
 assert(name=='New preset' and wand==2,'save did not receive current name/wand')
 list[#list+1]={name=name,blueprint={meta={},sprite_file='missing.xml'}}
 return true,'ok'
end
function presets.all() return list end
function presets.load() return true,'loaded' end
function presets.give() return true,'given_inventory' end
function presets.delete() return true,'ok' end
local history={perform=function(_,_,_,callback) return callback() end}

dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/ui/runtime.lua' then return ui end
 if path=='mods/metamorph_creative_menu/files/features/wands/presets.lua' then return presets end
 if path=='mods/metamorph_creative_menu/files/features/wands/history.lua' then return history end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
GuiLayoutBeginHorizontal=function() end
GuiLayoutEnd=function() end
GuiLayoutAddVerticalSpacing=function() end
GuiZSetForNextWidget=function() end
GuiImage=function(_,_,_,_,path) images[#images+1]=path end

local component=assert(native_dofile(root..'/files/ui/components/wand_presets.lua'))
component.draw(1,2,150)
assert(#list==4 and list[4].name=='New preset','saved preset was not rendered from updated same-frame list')
assert(images[1]=='meta.png','meta.image_file did not win icon selection')
assert(images[2]=='sprite_b.xml','sprite_file fallback was not used')
assert(images[3]=='data/items_gfx/handgun.xml' and images[4]=='data/items_gfx/handgun.xml','safe standard wand icon fallback missing')
local apply_count,copy_count=0,0
for _,label in ipairs(buttons) do
 if label=='APPLY' then apply_count=apply_count+1 end
 if label=='GET COPY' then copy_count=copy_count+1 end
end
assert(apply_count==4 and copy_count==4,'apply/copy actions were not rendered for every preset')
assert(scroll_width==142 and scroll_options==nil,'preset list did not use shared scroll viewport with default fixed step')
for _,entry in ipairs(truncated) do assert(entry.width<=110,'preset name was allowed to occupy action area') end
print('wand_presets_ui=PASS same_frame=true icon_priority=true apply_copy=true narrow_card=true shared_scroll=true')
