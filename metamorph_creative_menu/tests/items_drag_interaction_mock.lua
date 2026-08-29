local root=assert(arg[1],"root required")
local native_dofile=dofile
local prefix="mods/metamorph_creative_menu/"
dofile=function(path)
  if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
  return native_dofile(path)
end

-- Real Items tab/runtime/drag_drop/item service/inventory_slots/world_items are loaded below.
-- Only Noita engine boundaries are faked.
local target_path="data/entities/items/pickup/bloodmoney_10.xml"
local target_icon="data/ui_gfx/items/book.png"
local alive={[1]=true,[2]=true,[3]=true}
local names={[1]="player",[2]="inventory_quick",[3]="inventory_full"}
local parent={[2]=1,[3]=1}
local children={[1]={2,3},[2]={},[3]={}}
local comps={[1]={101},[2]={201}}
local ctype={[101]="Inventory2Component",[201]="InventoryComponent"}
local fields={
 [101]={quick_inventory_slots=4,full_inventory_slots_x=16,full_inventory_slots_y=1},
 [201]={ui_position_on_screen={240,10},ui_element_size={20,20},ui_container_size={4,2}},
}
local transforms={[1]={100,200}}
local next_entity=10
local loads={}
local ew_calls=0
local prints={}
local mouse_x,mouse_y=5,5
local world_x,world_y=1000,1000
local left_down,left_just=false,false
local frame=0
local image_draws={}

local function remove_child(e)
 local p=parent[e]; if p and children[p] then for i,v in ipairs(children[p]) do if v==e then table.remove(children[p],i); break end end end
 parent[e]=nil
end
local function add_child(p,e) remove_child(e); parent[e]=p; children[p]=children[p] or {}; children[p][#children[p]+1]=e end
local function make_item(path,x,y)
 local e=next_entity; next_entity=next_entity+1; alive[e]=true; names[e]="item"; children[e]={}; transforms[e]={x,y}
 local c=10000+e; comps[e]={c}; ctype[c]="ItemComponent"; fields[c]={inventory_slot={0,0},is_pickable=true,auto_pickup=false,has_been_picked_by_player=false}
 loads[#loads+1]={entity=e,path=path,x=x,y=y}
 return e
end
function EntityGetIsAlive(e) return alive[e]==true end
function EntityGetAllChildren(e) local t={}; for _,v in ipairs(children[e] or {}) do if alive[v] then t[#t+1]=v end end; return t end
function EntityGetFirstComponentIncludingDisabled(e,t) for _,c in ipairs(comps[e] or {}) do if ctype[c]==t then return c end end return 0 end
function EntityGetComponentIncludingDisabled(e,t) local out={}; for _,c in ipairs(comps[e] or {}) do if ctype[c]==t then out[#out+1]=c end end return out end
function ComponentGetValue2(c,k) local v=fields[c] and fields[c][k]; if type(v)=="table" then return unpack(v) end; return v end
function ComponentSetValue2(c,k,...) local a={...}; fields[c]=fields[c] or {}; fields[c][k]=#a>1 and a or a[1]; return true end
function EntityGetName(e) return names[e] or "" end
function EntityGetParent(e) return parent[e] or 0 end
function EntityGetRootEntity(e) local cur=e; while parent[cur] do cur=parent[cur] end; return cur end
function EntityHasTag() return false end
function EntityGetTransform(e) local t=transforms[e]; if not t then return nil,nil end; return t[1],t[2] end
function EntitySetTransform(e,x,y) transforms[e]={x,y} end
function EntityRemoveFromParent(e) remove_child(e) end
function EntityAddChild(p,e) add_child(p,e) end
function EntityKill(e) alive[e]=false; remove_child(e) end
function EntitySetComponentsWithTagEnabled() end
function EntityLoad(path,x,y) if path~=target_path and path~="data/entities/items/pickup/potion_empty.xml" then return 0 end; return make_item(path,x,y) end
function GamePickUpInventoryItem(_,e) add_child(2,e) end
function ModDoesFileExist(path) return path==target_path or path==target_icon or path=="data/ui_gfx/inventory/inventory_box.png" end
function ModGetActiveModIDs() return {} end
function ModIsEnabled(id) return id=="quant.ew" end
function CrossCall(name,e) assert(name=="ew_thrown"); ew_calls=ew_calls+1; return true end
function GlobalsGetValue(_,d) return d end
function GlobalsSetValue() end
function GameHasFlagRun() return false end
function GameIsInventoryOpen() return false end
function GameGetFrameNum() return frame end
function GameGetRealWorldTimeSinceStarted() return frame/60 end
function GamePrint(text) prints[#prints+1]=tostring(text) end
function DEBUG_GetMouseWorld() return world_x,world_y end
function InputGetMousePosOnScreen() return mouse_x,mouse_y end
function InputIsMouseButtonDown(code) return code==1 and left_down or false end
function InputIsMouseButtonJustDown(code) return code==1 and left_just or false end
function InputIsKeyDown() return false end
function InputIsKeyJustDown() return false end
function InputIsKeyJustUp() return false end
function MagicNumbersGetValue() return "20" end
function GameTextGetTranslatedOrNot(key) if key=="$item_bloodmoney_10" then return "Test Item" end; return key end
function ModTextFileGetContent(path)
 if path==prefix.."translations.csv" then local f=assert(io.open(root.."/translations.csv","rb")); local s=f:read("*a"); f:close(); return s end
 return ""
end
function ModTextFileSetContent() return true end
function RemoveMaterialInventoryMaterial() end
function AddMaterialInventoryMaterial() return true end

GUI_OPTION={Layout_NoLayouting=1,NoPositionTween=2}
local last={hover=false,x=0,y=0,w=18,h=18}
local function set_last(x,y,w,h,hover) last={x=tonumber(x) or 0,y=tonumber(y) or 0,w=tonumber(w) or 18,h=tonumber(h) or 18,hover=hover==true} end
GuiGetScreenDimensions=function() return 320,240 end
GuiGetTextDimensions=function(_,text) return #tostring(text or "")*5,5 end
GuiGetImageDimensions=function() return 18,18 end
GuiColorSetForNextWidget=function() end
GuiZSetForNextWidget=function() end
GuiOptionsAddForNextWidget=function() end
GuiOptionsAdd=function() end
GuiLayoutBeginHorizontal=function() end
GuiLayoutBeginVertical=function() end
GuiLayoutAddHorizontalSpacing=function() end
GuiLayoutBeginLayer=function() end
GuiLayoutEndLayer=function() end
GuiLayoutEnd=function() end
GuiBeginScrollContainer=function(_,_,x,y,w,h) set_last(x,y,w,h,mouse_x>=x and mouse_x<=x+w and mouse_y>=y and mouse_y<=y+h) end
GuiEndScrollContainer=function() end
GuiImageButton=function(_,_,x,y,_,_) set_last(x,y,18,18,mouse_x>=x and mouse_x<=x+18 and mouse_y>=y and mouse_y<=y+18); return false,false end
GuiButton=function(_,_,x,y,label) set_last(x,y,math.max(10,#tostring(label or "")*5+6),9,false); return false end
GuiTextInput=function(_,_,x,y,value,w) set_last(x,y,w or 80,9,false); return value end
GuiText=function(_,x,y,text) set_last(x,y,math.max(3,#tostring(text or "")*5),5,false) end
GuiImage=function(_,_,x,y,path,_,sx,sy) image_draws[#image_draws+1]={x=x,y=y,path=path}; set_last(x,y,math.max(1,(sx or 1)*18),math.max(1,(sy or 1)*18),false) end
GuiTooltip=function() end
GuiGetPreviousWidgetInfo=function() return 0,0,last.hover,last.x,last.y,last.w,last.h end

for _,name in ipairs({
 "METAMORPH_CREATIVE_MENU_UI_RUNTIME","METAMORPH_CREATIVE_MENU_ITEM_SERVICE","METAMORPH_CREATIVE_MENU_DRAG_DROP",
 "METAMORPH_CREATIVE_MENU_POINTER","METAMORPH_CREATIVE_MENU_EW_RUNTIME","METAMORPH_CREATIVE_MENU_ASSETS",
 "METAMORPH_CREATIVE_MENU_INPUT_GUARD","METAMORPH_CREATIVE_MENU_TEXT_ENTRY_GUARD","METAMORPH_CREATIVE_MENU_MATERIAL_PREVIEW",
}) do _G[name]=nil end
local ui=assert(native_dofile(root.."/files/ui/runtime.lua")); ui.bind(1)
local drag=assert(native_dofile(root.."/files/ui/drag_drop.lua"))
local tab=assert(native_dofile(root.."/files/ui/tabs/items.lua"))

local function draw_frame(mx,my,wx,wy,down,just)
 frame=frame+1; mouse_x,mouse_y=mx,my; world_x,world_y=wx,wy; left_down,left_just=down,just
 ui.begin_frame(); ui.set_panel_bounds(0,0,140,180); drag.begin_frame(320,240); tab.draw(1,140,180); local result=drag.end_frame(); ui.end_frame(); return result
end
local function complete_click()
 draw_frame(5,5,1,1,true,true)
 draw_frame(5,5,1,1,false,false)
 draw_frame(5,5,1,1,false,false)
end
local function complete_drag(rx,ry,wx,wy)
 draw_frame(5,5,0,0,true,true)
 draw_frame(25,5,0,0,true,false)
 draw_frame(rx,ry,wx,wy,false,false)
 draw_frame(rx,ry,wx,wy,false,false)
end

-- Short LMB is below threshold and performs exactly the old nearby spawn once.
local before=#loads
complete_click()
assert(#loads==before+1,"short LMB did not create exactly one item")
local r=loads[#loads]
assert(r.x==112 and r.y==192,"short LMB no longer spawns near player")

-- Real drag crosses the shared threshold, survives off-tile, draws a ghost, and commits exact world coordinates.
before=#loads; local ew_before=ew_calls; image_draws={}
complete_drag(200,150,777,-55)
assert(#loads==before+1,"world drag did not create exactly one item")
r=loads[#loads]
assert(r.x==777 and r.y==-55,"world drag did not use confirmed cursor world coordinates")
assert(ew_calls==ew_before+1,"world drag must issue exactly one EW handoff")
local ghost=false
for _,img in ipairs(image_draws) do if img.path==target_icon and tonumber(img.x) and img.x>=25 then ghost=true end end
assert(ghost,"drag ghost did not use the catalog item's actual icon")

-- Release inside the menu but away from the source is a cancel, never a spawn-under-menu.
before=#loads; ew_before=ew_calls
complete_drag(100,100,900,900)
assert(#loads==before and ew_calls==ew_before,"in-menu miss created an item")

-- Release over the real quick-inventory bounds chooses the existing safe inventory path only.
before=#loads; ew_before=ew_calls
complete_drag(260,20,999,888)
assert(#loads==before+1,"native inventory drop did not create its committed item")
r=loads[#loads]
assert(parent[r.entity]==2,"native inventory drop did not end in inventory_quick")
assert(ew_calls==ew_before,"native inventory drop also performed a world EW handoff")
assert(not (r.x==999 and r.y==888),"native inventory release also executed world placement")

-- Missing world coordinates after an outside release is a pure failure/cancel with no entity.
before=#loads; ew_before=ew_calls
complete_drag(200,150,nil,nil)
assert(#loads==before and ew_calls==ew_before,"missing world coordinates left an entity")

-- Catalog source is a template: repeated operations still render and can be clicked again.
before=#loads
complete_click()
assert(#loads==before+1,"catalog template disappeared after drag operations")

print("items_drag_interaction=PASS real_modules=true click_vs_drag=true exact_world=true inventory=true cancel=true missing_coords=true one_release_one_operation=true ghost=true")
