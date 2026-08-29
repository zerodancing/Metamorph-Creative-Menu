local root=assert(arg[1],"root required")
local native_dofile=dofile
local remove_mode_clicked=false
local remove_calls=0

local ui={
    ICON_STEP=20,EMPTY_SLOT="slot",audit=function() end,gui=function() return 1 end,
    tr=function(_,fallback) return fallback end,translated=function(value) return value end,
    white_text=function() end,wrapped_text=function() end,search_input=function(value) return value end,
    button_grid=function(items)
        for index,item in ipairs(items or {}) do
            if item.label=="REMOVE" and not remove_mode_clicked then remove_mode_clicked=true; return index end
        end
        return nil
    end,
    columns=function() return 4 end,scroll_height=function() return 100 end,
    mark_hovered=function() end,
    begin_scroll_viewport=function(_,_,_,_,width,height) return {content_width=math.max(20,(tonumber(width) or 100)-12),padding_left=2,padding_top=2,state={offset=0},height=height} end,
    scroll_y=function(_,y) return y end, end_scroll_viewport=function() end,search_status=function() end,
    rank_entries=function(_,entries) return entries end,
    resolve=function(path) return path end,dimensions=function() return 18,18 end,
    button=function(_,_,label)
        if label=="REMOVE" and not remove_mode_clicked then remove_mode_clicked=true; return true end
        return false
    end,
    tile=function() return true,false,false end,
}
local service={
    count=function() return 1 end,
    can_remove=function() return false,"no_safe_inverse" end,
    remove_one=function() remove_calls=remove_calls+1; return false,"unsafe" end,
    remove_all=function() remove_calls=remove_calls+1; return 0,"unsafe" end,
}
local catalog={all=function() return {{
    id="UNSAFE_TEST",ui_name="Unsafe test",ui_description="No inverse",ui_icon="perk.png",
}} end}

dofile=function(path)
    if path=="mods/metamorph_creative_menu/files/ui/runtime.lua" then return ui end
    if path=="mods/metamorph_creative_menu/files/features/perks/service.lua" then return service end
    if path=="mods/metamorph_creative_menu/files/features/perks/catalog.lua" then return catalog end
    return native_dofile(path)
end
function GuiLayoutBeginVertical() end
function GuiLayoutBeginHorizontal() end
function GuiLayoutEnd() end
function GuiBeginScrollContainer() end
function GuiEndScrollContainer() end
function GuiGetPreviousWidgetInfo() return false,false,false end
function GamePrint() error("unsafe removal should not reach user-error fallback") end

local tab=assert(native_dofile(root.."/files/ui/tabs/perks.lua"))
tab.draw(1,220,180)
assert(remove_mode_clicked,"test did not enter perk removal mode")
assert(remove_calls==0,"unsafe perk removal service was invoked despite can_remove=false")
print("perk_tab_unsafe_removal=PASS warning_only=true mutation_blocked=true")
