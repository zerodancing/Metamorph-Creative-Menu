local root=assert(arg[1],"root required")
local native_dofile=dofile
local prefix="mods/metamorph_creative_menu/"
local tiles,targets,rows,buttons=0,0,0,0

local ui={
    ICON_STEP=20, EMPTY_SLOT="empty.png",
    gui=function() return 1 end,
    white_text=function() end,
    tr=function(_,fallback) return fallback end,
    tile=function()
        tiles=tiles+1
        return false,false,false,tiles*20,10,18,18
    end,
}
local drag={
    source=function() end,
    target=function(id,bounds,accept,drop,priority)
        targets=targets+1
        assert(id=="spells.inventory_target."..tostring(targets-1),"inventory target index drifted while wrapping")
    end,
}
local inventory={contents=function()
    return {inventory=10,width=16,height=1,capacity=16,by_index={},entries={}},"ok"
end}

dofile=function(path)
    if path==prefix.."files/ui/runtime.lua" then return ui end
    if path==prefix.."files/ui/drag_drop.lua" then return drag end
    if path==prefix.."files/features/spells/inventory_service.lua" then return inventory end
    return native_dofile(path)
end
function GuiLayoutBeginHorizontal() rows=rows+1 end
function GuiLayoutEnd() end
function GuiButton() buttons=buttons+1; return false end

METAMORPH_CREATIVE_MENU_SPELL_INVENTORY_UI=nil
local component=assert(native_dofile(root.."/files/ui/components/spell_inventory_strip.lua"))
local layout,reason=component.draw(1,150,640,360,nil,{})
assert(reason=="ok" and layout.capacity==16,"spell inventory did not expose stock 16-cell capacity")
assert(tiles==16 and targets==16,"narrow menu hid spell inventory cells")
assert(rows==2,"16 cells should use the available narrow-menu width before wrapping")
assert(buttons==0,"spell inventory pagination arrows/buttons survived")
print("spell_inventory_grid=PASS all_16=true arrows=false wrap_rows=2 exact_targets=true")
