local root=assert(arg[1],"root required")
local native_dofile=dofile
local prefix="mods/metamorph_creative_menu/"
local rendered,warmed=0,0
local liquid={id="water",display_name="water",ui_name_key="$mat_water",icon="potion.png",kind="liquid"}

local ui={
    ICON_STEP=20, EMPTY_SLOT="empty.png", audit=function() end,
    gui=function() return 1 end,
    translated=function(key) return key end,
    tr=function(_,fallback) return fallback end,
    white_text=function() end,
    button_grid=function() return nil end,
    search_input=function() return "Вода" end,
    search_aliases=function(key,fallback)
        assert(key=="$mat_water" and fallback=="water","liquid localization metadata was not passed to search aliases")
        return {"Вода","Water","water","$mat_water"}
    end,
    rank_entries=function(query,entries,fields_for)
        local out={}
        for _,entry in ipairs(entries) do
            local fields=fields_for(entry)
            for _,field in ipairs(fields) do
                if tostring(field)==query then out[#out+1]=entry; break end
            end
        end
        return out
    end,
    search_status=function(_,count) assert(count==1,"localized liquid query returned no result") end,
    wrapped_text=function() end,
    scroll_height=function() return 100 end,
    begin_scroll_viewport=function() return {content_width=100,padding_left=0,x=0,y=0,width=100,height=100} end,
    columns=function() return 4 end,
    scroll_y=function(_,y) return y end,
    tile=function(_,_,_,_,_,name)
        rendered=rendered+1
        assert(name=="water","wrong entry survived localized search")
        return false,false,false,0,0,18,18
    end,
    end_scroll_viewport=function() end,
}
local stubs={}
stubs[prefix.."files/ui/runtime.lua"]=ui
stubs[prefix.."files/features/items/service.lua"]={}
stubs[prefix.."files/features/items/ui_catalog.lua"]={
    collect=function() return {liquid} end,
    filters=function() return {{"$all","ALL"}} end,
    entries_for=function() return {liquid} end,
    liquids=function() return {liquid} end,
}
stubs[prefix.."files/platform/noita/material_preview.lua"]={
    new_liquid_warmup=function() return {} end,
    warm_liquid_colors=function(_,entries) warmed=#entries end,
    liquid_icon=function() return "potion.png" end,
    liquid_color=function() return {1,1,1,1} end,
}
stubs[prefix.."files/ui/drag_drop.lua"]={
    take_result=function() return nil end, source=function() end, active=function() return false end,
}
stubs[prefix.."files/platform/noita/inventory_slots.lua"]={native_drop_bounds=function() return nil end}

dofile=function(path) if stubs[path]~=nil then return stubs[path] end return native_dofile(path) end
function GuiGetScreenDimensions() return 640,360 end
function GuiLayoutBeginVertical() end
function GuiLayoutEnd() end
function GamePrint() end

local tab=assert(native_dofile(root.."/files/ui/tabs/items.lua"))
tab.draw(1,180,300)
assert(rendered==1,"localized liquid result was not rendered")
assert(warmed==1,"localized liquid result did not reach preview warmup")
print("item_liquid_localized_search=PASS current_language_alias=true mixed_all=true")
