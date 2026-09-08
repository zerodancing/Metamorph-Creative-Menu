local root=assert(arg[1],'root required')
local native_dofile=dofile
local prefix='mods/metamorph_creative_menu/'
local phase=1
local drawn={}
local external={path='mods/example/entities/late_item.xml',icon='mods/example/files/late_icon.xml',category='OTHER',display_name='Late item',display_description=''}
local fallback={kind='raster',path='data/ui_gfx/items/ingredient_1.png'}
local recovered={kind='sprite_xml',path='mods/example/files/late_icon.xml'}
local ui={
  EMPTY_SLOT='empty.png',ICON_STEP=20,
  audit=function()end,gui=function()return 1 end,tr=function(_,fallback_text)return fallback_text end,
  translated=function(v)return v end,button_grid=function()return nil end,
  search_input=function(v)return v end,search_status=function()end,wrapped_text=function()end,white_text=function()end,
  rank_entries=function(_,entries)return entries end,scroll_height=function()return 100 end,
  begin_scroll_viewport=function()return{content_width=100,padding_left=2,x=0,y=0,width=100,height=100}end,
  columns=function()return 4 end,scroll_y=function(_,y)return y end,end_scroll_viewport=function()end,
  panel_bounds=function()return{x=0,y=0,width=100,height=100}end,
  tile=function(_,_,_,icon)
    drawn[#drawn+1]=icon
    return false,false,false,0,0,18,18
  end,
  asset=function(path)
    if path=='mods/example/files/late_icon.xml' then
      if phase==1 then return {kind='placeholder',path='unknown.png'} end
      return recovered
    end
    if path=='data/ui_gfx/items/ingredient_1.png' then return fallback end
    if path=='empty.png' then return {kind='raster',path='empty.png'} end
    return nil
  end,
  resolve=function(path)return path end,
  entity_asset=function()return nil end,entity_icon=function()return nil end,
}
local catalog={
  collect=function()return{external}end,
  filters=function()return{{'$all','ALL'}}end,
  entries_for=function()return{external}end,
  liquids=function()return{}end,
}
local stubs={
  [prefix..'files/ui/runtime.lua']=ui,
  [prefix..'files/features/items/service.lua']={},
  [prefix..'files/features/items/ui_catalog.lua']=catalog,
  [prefix..'files/platform/noita/material_preview.lua']={
    new_liquid_warmup=function()return{}end,warm_liquid_colors=function()end,
    liquid_icon=function()return'potion.png'end,liquid_mask=function()return'liquid.png'end,
    liquid_offset=function()return-1,0 end,liquid_color=function()return nil end,
  },
  [prefix..'files/ui/drag_drop.lua']={
    take_result=function()return nil end,source=function()end,active=function()return false end,
  },
  [prefix..'files/platform/noita/inventory_slots.lua']={},
}
dofile=function(path)
  if stubs[path] then return stubs[path] end
  if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
  return native_dofile(path)
end
function GuiGetScreenDimensions() return 320,240 end
function GuiLayoutBeginVertical()end
function GuiLayoutEnd()end

local tab=assert(native_dofile(root..'/files/ui/tabs/items.lua'))
tab.draw(1,140,180)
assert(drawn[1]==fallback,'first unavailable external icon did not use a safe fallback')
phase=2
tab.draw(1,140,180)
assert(drawn[2]==recovered,'transient fallback was permanently cached over the recovered mod icon')
tab.draw(1,140,180)
assert(drawn[3]==recovered,'recovered item-specific icon was not cached')

local source_file=assert(io.open(root..'/files/features/items/ui_catalog.lua','rb'))
local source=source_file:read('*a'); source_file:close()
local prewarm_first=assert(string.find(source,'function item_catalog.prewarm_icons',1,true))
local prewarm_last=assert(string.find(source,'function item_catalog.collect',prewarm_first,true))
local prewarm=string.sub(source,prewarm_first,prewarm_last-1)
assert(not string.find(prewarm,'add_external_entries(',1,true),
  'init-time icon prewarm still executes external item manifests')

local init_file=assert(io.open(root..'/init.lua','rb'))
local init=init_file:read('*a'); init_file:close()
local pre_first=assert(string.find(init,'function OnModPreInit()',1,true))
local post_first=assert(string.find(init,'function OnModPostInit()',pre_first,true))
local pre=string.sub(init,pre_first,post_first-1)
local post=string.sub(init,post_first)
assert(not string.find(pre,'item_icons.prewarm',1,true) and string.find(post,'item_icons.prewarm',1,true),
  'known icon prewarm does not wait for normal mod VFS initialization')

print('item_icon_transient_fallback=PASS fallback_not_cached=true recovered_cached=true external_prewarm=false post_init=true')
