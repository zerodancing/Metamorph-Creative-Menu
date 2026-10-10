local root=assert(arg[1],"root required")
local native_dofile=dofile
local prefix="mods/metamorph_creative_menu/"
local catalog_path=prefix.."files/features/items/catalog.lua"
local outliers_path=prefix.."files/features/items/vanilla_outliers.lua"
local registry_path=prefix.."files/item_registry.lua"

dofile=function(path)
    if path==catalog_path then
        return {{path="data/entities/items/pickup/test_item.xml",name="$item_test",description="$item_test_desc",category="OTHER"}}
    end
    if path==outliers_path then return {} end
    if path==registry_path then METAMORPH_CREATIVE_MENU_EXTERNAL_ITEMS={}; return METAMORPH_CREATIVE_MENU_EXTERNAL_ITEMS end
    return native_dofile(path)
end
function ModDoesFileExist(path) return path=="data/entities/items/pickup/test_item.xml" or path==registry_path end
function ModGetActiveModIDs() return {"metamorph_creative_menu"} end
function CellFactory_GetAllLiquids() return {"water","oil"} end
function CellFactory_GetType(name) if name=="water" then return 1 elseif name=="oil" then return 2 end return -1 end
function CellFactory_GetUIName(id) if id==1 then return "$mat_water" elseif id==2 then return "$mat_oil" end return "" end
local translations={
    ["$item_test"]="Тестовый предмет", ["$item_test_desc"]="Описание",
    ["$mat_water"]="Вода", ["$mat_oil"]="Масло",
}
local function tr(key) return translations[key] or key end
local function trf(key,fallback) local value=tr(key); return value==key and fallback or value end

local item_catalog=assert(native_dofile(root.."/files/features/items/ui_catalog.lua"))
local all=item_catalog.entries_for(1,tr,trf)
local water=nil
local item=nil
for _,entry in ipairs(all) do
    if entry.id=="water" then water=entry end
    if entry.path=="data/entities/items/pickup/test_item.xml" then item=entry end
end
assert(item and item.kind=="item","ALL lost ordinary items")
assert(water and water.kind=="liquid","ALL does not include dynamic liquids")
assert(water.display_name=="Вода","liquid current-language display name was not preserved")
assert(water.ui_name_key=="$mat_water","liquid localization key was not retained for multilingual search aliases")
local liquids=item_catalog.liquids(tr)
assert(#liquids==2 and liquids[1].id=="water","dedicated liquid catalogue regressed")
print("item_all_liquid_catalog=PASS all_union=true localized_name=true localization_key=true")
