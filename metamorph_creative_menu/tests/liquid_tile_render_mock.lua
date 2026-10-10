local root=assert(arg[1],'root required')
local native_dofile=dofile
local prefix='mods/metamorph_creative_menu/'

local dimensions={
  ['data/ui_gfx/inventory/inventory_box.png']={18,18},
  ['data/ui_gfx/items/potion.png']={16,16},
  ['data/ui_gfx/health_slider_front.png']={24,4},
}
local assets={
  bind_gui=function() end,
  resolve=function(path)
    local d=dimensions[path]
    if not d then return nil end
    return {kind='raster',path=path,width=d[1],height=d[2],animation_name=''}
  end,
  path=function(asset) return type(asset)=='table' and asset.path or asset end,
  dimensions=function(asset)
    if type(asset)=='table' then return asset.width,asset.height end
    local d=dimensions[asset]; if d then return d[1],d[2] end
  end,
}
local stubs={
  [prefix..'files/platform/noita/assets.lua']=assets,
  [prefix..'files/platform/noita/input_guard.lua']={actions_allowed=function()return true end},
  [prefix..'files/platform/noita/pointer.lua']={left_just_down=function()return false end},
  [prefix..'files/platform/noita/text_entry_guard.lua']={active=function()return false end,clear=function()end,key=function()return nil end},
  [prefix..'files/platform/noita/keycodes.lua']={resolve=function()return nil end},
  [prefix..'files/platform/noita/localization.lua']={translate=function(v)return tostring(v or '')end,search_aliases=function()return{}end},
  [prefix..'files/core/search_engine.lua']={},
  [prefix..'files/ui/widgets/scroll_model.lua']={begin_frame=function()end},
}
dofile=function(path)
  if stubs[path] then return stubs[path] end
  if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
  return native_dofile(path)
end

GUI_OPTION={Layout_NoLayouting=1}
local last={x=10,y=20,w=18,h=18,hover=false}
local next_color={1,1,1,1}
local next_z=0
local draws={}
function GuiImageButton(_,_,x,y)
  last={x=10,y=20,w=18,h=18,hover=false}
  return false,false
end
function GuiGetPreviousWidgetInfo(gui)
  assert(gui==1,'runtime omitted gui handle')
  return 0,0,last.hover,last.x,last.y,last.w,last.h
end
function GuiTooltip() end
function GuiOptionsAddForNextWidget() end
function GuiColorSetForNextWidget(_,r,g,b,a) next_color={r,g,b,a} end
function GuiZSetForNextWidget(_,z) next_z=z end
function GuiImage(_,_,x,y,path,alpha,sx,sy)
  draws[#draws+1]={
    path=path,x=x,y=y,alpha=alpha,sx=sx,sy=sy,z=next_z,
    color={next_color[1],next_color[2],next_color[3],next_color[4]},
  }
  next_color={1,1,1,1}; next_z=0
end

METAMORPH_CREATIVE_MENU_UI_RUNTIME=nil
local ui=assert(native_dofile(root..'/files/ui/runtime.lua'))
ui.bind(1)
ui.begin_frame()
local liquid={0.1,0.35,0.8,1}
local options={
  target_size=18,max_scale=3,
  icon_tint=liquid,
}
ui.tile(0,0,'data/ui_gfx/inventory/inventory_box.png','data/ui_gfx/items/potion.png',nil,'Water','water',false,options)
ui.drag_ghost('data/ui_gfx/inventory/inventory_box.png','data/ui_gfx/items/potion.png',50,60,options)

local bottles=0
for _,draw in ipairs(draws) do
  assert(draw.path~='data/ui_gfx/health_slider_front.png',
    'liquid preview still draws the old rectangular colour patch')
  assert(draw.path~='data/items_gfx/potion.png' and draw.path~='data/items_gfx/flask_liquid.png',
    'physical-world flask sprite/mask leaked into inventory preview')
  if draw.path=='data/ui_gfx/items/potion.png' then
    bottles=bottles+1
    assert(math.abs(draw.color[1]-liquid[1])<0.00001
      and math.abs(draw.color[2]-liquid[2])<0.00001
      and math.abs(draw.color[3]-liquid[3])<0.00001,
      'vanilla inventory flask lost the sampled potion colour')
  end
end
assert(bottles==2,'tile and drag ghost do not share the vanilla inventory flask')

local runtime_file=assert(io.open(root..'/files/ui/runtime.lua','rb'))
local runtime_source=runtime_file:read('*a'); runtime_file:close()
assert(not string.find(runtime_source,'bottle_fill_color',1,true),
  'obsolete rectangular bottle-fill API remains in runtime')
assert(not string.find(runtime_source,'draw_liquid_contents',1,true),
  'physical-world liquid-mask renderer remains in runtime')

print('liquid_tile_render=PASS vanilla_inventory_bottle=true sampled_tint=true opaque_tile=true tile_and_drag=true no_world_mask=true no_rectangle=true')
