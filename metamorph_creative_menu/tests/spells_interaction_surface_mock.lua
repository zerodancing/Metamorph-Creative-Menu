local root = assert(arg[1], "root required")
local native_dofile = dofile
local prefix = "mods/metamorph_creative_menu/"
dofile = function(path)
    if string.sub(path, 1, #prefix) == prefix then
        return native_dofile(root .. "/" .. string.sub(path, #prefix + 1))
    end
    return native_dofile(path)
end

-- This is an executable render scenario for the real Spells tab and its real UI/service
-- modules. Only Noita engine boundaries are faked below.
ACTION_TYPE_PROJECTILE=0; ACTION_TYPE_STATIC_PROJECTILE=1; ACTION_TYPE_MODIFIER=2
ACTION_TYPE_DRAW_MANY=3; ACTION_TYPE_MATERIAL=4; ACTION_TYPE_OTHER=5
ACTION_TYPE_UTILITY=6; ACTION_TYPE_PASSIVE=7
actions = {
    {id="TEST", type=ACTION_TYPE_PROJECTILE, name="$test_spell", description="$test_desc",
     sprite="data/ui_gfx/gun_actions/light_bullet.png"},
}
dofile_once = function() return true end

local alive = {[1]=true,[2]=true,[3]=true,[10]=true}
local children = {[1]={3}, [2]={10}, [3]={}, [10]={}}
local parent = {[3]=1,[10]=2}
local names = {[1]="player",[2]="wand",[3]="inventory_full",[10]="spell"}
local entity_components = {[1]={101},[2]={201},[10]={1001,1002}}
local component_type = {[101]="Inventory2Component",[201]="AbilityComponent",[1001]="ItemActionComponent",[1002]="ItemComponent"}
local fields = {
    [101]={mActualActiveItem=2,mActiveItem=2,quick_inventory_slots=4,full_inventory_slots_x=4,full_inventory_slots_y=1},
    [201]={use_gun_script=true,mana=50,mana_max=100,mana_charge_speed=10},
    [1001]={action_id="TEST"},
    [1002]={inventory_slot={0,0},permanently_attached=false,has_been_picked_by_player=true,is_pickable=true},
}
local objects = {[201]={gun_config={deck_capacity=2}}}

EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetAllChildren=function(e) local out={}; for _,v in ipairs(children[e] or {}) do out[#out+1]=v end; return out end
EntityGetFirstComponentIncludingDisabled=function(e,t)
    for _,c in ipairs(entity_components[e] or {}) do if component_type[c]==t then return c end end
    return 0
end
EntityGetComponentIncludingDisabled=function(e,t)
    local out={}; for _,c in ipairs(entity_components[e] or {}) do if t==nil or component_type[c]==t then out[#out+1]=c end end; return out
end
ComponentGetValue2=function(c,k)
    local v=fields[c] and fields[c][k]
    if type(v)=="table" then return unpack(v) end
    return v
end
ComponentSetValue2=function(c,k,...)
    local a={...}; fields[c]=fields[c] or {}; fields[c][k]=#a>1 and a or a[1]
end
ComponentObjectGetValue2=function(c,obj,k) return objects[c] and objects[c][obj] and objects[c][obj][k] end
ComponentObjectSetValue2=function(c,obj,k,v) objects[c]=objects[c] or {}; objects[c][obj]=objects[c][obj] or {}; objects[c][obj][k]=v end
EntityGetName=function(e) return names[e] or "" end
EntityHasTag=function(e,tag) return e==2 and tag=="wand" end
EntityGetParent=function(e) return parent[e] or 0 end
EntityGetRootEntity=function(e) local p=e; while parent[p] do p=parent[p] end; return p end
EntityGetTransform=function(e) return e==1 and 100 or 0, e==1 and 50 or 0 end
EntitySetComponentsWithTagEnabled=function() end

-- Noita GUI/input/localization boundary.
GUI_OPTION={Layout_NoLayouting=1, NoPositionTween=2}
local texts, tooltips = {}, {}
local widget_counter=0
local last={hover=false,x=0,y=0,w=18,h=18}
local function set_last(x,y,w,h,hover) last={x=x or 0,y=y or 0,w=w or 18,h=h or 18,hover=hover==true} end
local function next_pos(w,h)
    widget_counter=widget_counter+1
    local x=((widget_counter-1)%8)*20+4
    local y=math.floor((widget_counter-1)/8)*20+4
    set_last(x,y,w or 18,h or 18,false)
    return x,y
end
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
GuiBeginScrollContainer=function(_,_,x,y,w,h) set_last(x,y,w,h,false) end
GuiEndScrollContainer=function() end
GuiImageButton=function(_,_,_,_,_,_) next_pos(18,18); return false,false end
GuiButton=function(_,_,_,_,label) next_pos(math.max(10,#tostring(label or "")*5+6),9); return false end
GuiTextInput=function(_,_,_,_,value,w) next_pos(w or 80,9); return value end
GuiText=function(_,x,y,text) texts[#texts+1]=tostring(text or ""); next_pos(math.max(3,#tostring(text or "")*5),5) end
GuiImage=function(_,_,x,y,_,_,sx,sy) set_last(x,y,math.max(1,(sx or 1)*18),math.max(1,(sy or 1)*18),false) end
GuiTooltip=function(_,title,description) tooltips[#tooltips+1]={title=tostring(title or ""),description=tostring(description or "")} end
GuiGetPreviousWidgetInfo=function() return 0,0,last.hover,last.x,last.y,last.w,last.h end

InputIsMouseButtonJustDown=function() return false end
InputIsMouseButtonDown=function() return false end
InputIsKeyDown=function() return false end
InputIsKeyJustDown=function() return false end
InputIsKeyJustUp=function() return false end
InputGetMousePosOnScreen=function() return nil,nil end
GameGetFrameNum=function() return 1 end
GameGetRealWorldTimeSinceStarted=function() return 1 end
GameTextGetTranslatedOrNot=function(key)
    if key=="$test_spell" then return "Test Spell" end
    if key=="$test_desc" then return "Test description" end
    return key
end
ModTextFileGetContent=function(path)
    if path==prefix.."translations.csv" then local h=assert(io.open(root.."/translations.csv","rb")); local s=h:read("*a"); h:close(); return s end
    return ""
end
ModDoesFileExist=function() return false end
MagicNumbersGetValue=function() return "0" end

-- Ensure a clean real-module graph in this Lua process.
for _,name in ipairs({
    "METAMORPH_CREATIVE_MENU_UI_RUNTIME","METAMORPH_CREATIVE_MENU_SPELL_CATALOG",
    "METAMORPH_CREATIVE_MENU_SPELL_FACTORY","METAMORPH_CREATIVE_MENU_SPELL_INVENTORY_SERVICE",
    "METAMORPH_CREATIVE_MENU_SPELL_SERVICE","METAMORPH_CREATIVE_MENU_PERMANENT_SPELL_SERVICE",
    "METAMORPH_CREATIVE_MENU_DRAG_DROP","METAMORPH_CREATIVE_MENU_HORIZONTAL_STRIP",
    "METAMORPH_CREATIVE_MENU_WAND_API","METAMORPH_CREATIVE_MENU_INPUT_GUARD",
    "METAMORPH_CREATIVE_MENU_TEXT_ENTRY_GUARD","METAMORPH_CREATIVE_MENU_POINTER",
}) do _G[name]=nil end

local ui=assert(native_dofile(root.."/files/ui/runtime.lua")); ui.bind(1); ui.begin_frame(); ui.set_panel_bounds(0,0,260,220)
local drag=assert(native_dofile(root.."/files/ui/drag_drop.lua")); drag.begin_frame(320,240)
local tab=assert(native_dofile(root.."/files/ui/tabs/spells.lua"))
tab.draw(1,260,220)
drag.end_frame(); ui.end_frame()

local joined="\n"..table.concat(texts,"\n").."\n"
assert(string.find(joined,"\nWAND SLOTS\n",1,true),"real Spells draw did not render WAND SLOTS in CATALOG")
assert(string.find(joined,"\nSPELL INVENTORY\n",1,true),"real Spells draw did not render SPELL INVENTORY in CATALOG")
local saw_always=false
for _,record in ipairs(tooltips) do
    if record.title=="ALWAYS CAST" or string.find(record.description,"Always Cast",1,true) then saw_always=true end
end
-- The Always Cast label itself is ordinary GuiText, so accept either recorded text or tooltip.
assert(saw_always or string.find(joined,"ALWAYS CAST",1,true),"real Spells draw did not render Always Cast surface")
local saw_catalog_spell=false
for _,record in ipairs(tooltips) do
    if string.find(record.title,"Test Spell [TEST]",1,true) then saw_catalog_spell=true; break end
end
assert(saw_catalog_spell,"real Spells module did not render the catalog spell tile")

print("spells_interaction_surface=PASS real_module=true catalog_surfaces=true catalog_tile=true no_internal_stubs=true")
