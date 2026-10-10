local root=assert(arg[1])
local native_dofile=dofile
dofile=function(path)
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
local inventory_open=true
function GameIsInventoryOpen() return inventory_open end
function MagicNumbersGetValue(name)
 if name=='INVENTORY_ICON_SIZE' then return '20' end
 if name=='UI_BARS_POS_X' then return '20' end
 if name=='UI_BARS_POS_Y' then return '20' end
 return nil
end
function EntityGetAllChildren(entity)
 if entity==1 then return {20} end
 return {}
end
function EntityGetName(entity) if entity==20 then return 'inventory_full' end return '' end
function EntityGetFirstComponentIncludingDisabled(entity,kind)
 if entity==1 and kind=='Inventory2Component' then return 11 end
 return 0
end
function ComponentGetValue2(component,field)
 if component==11 and field=='full_inventory_slots_x' then return 16 end
 if component==11 and field=='full_inventory_slots_y' then return 1 end
 if component==11 and field=='quick_inventory_slots' then return 4 end
 return nil
end
local slots=assert(native_dofile(root..'/files/platform/noita/inventory_slots.lua'))
local bounds=assert(slots.native_drop_bounds(1,'inventory_full',427,242))
assert(bounds.x==87 and bounds.y==16 and bounds.width==320 and bounds.height==28,'native inventory fallback geometry changed')
inventory_open=false
assert(slots.native_drop_bounds(1,'inventory_full',427,242)==nil,'closed inventory remained a drop target')
print('native_inventory_drop_bounds=PASS open_only=true grid_geometry=true')
