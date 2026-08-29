local root = assert(arg[1], "root required")
local native_dofile = dofile
local selected_category_once = false
local tiles = {}
local liquid_warmups = 0

local water = {
    id="water", display_name="Water", category="LIQUIDS",
    categories={LIQUIDS=true},
}
local stone = {
    id="stone", display_name="Stone", category="SOLIDS",
    categories={SOLIDS=true},
}
local catalog = {
    categories=function()
        return {
            {id="ALL",key="all",fallback="ALL"},
            {id="LIQUIDS",key="liquids",fallback="LIQUIDS"},
            {id="SOLIDS",key="solids",fallback="SOLIDS"},
        }
    end,
    is_ready=function() return true end,
    step=function() return true end,
    entries_for=function(category)
        if category == "LIQUIDS" then return {water} end
        if category == "SOLIDS" then return {stone} end
        return {water,stone}
    end,
    get=function(id) return id == "water" and water or stone end,
}
local painter = {
    get_material=function() return "water" end,
    brush_diameter=function() return 5 end,
    adjust_brush=function() end,
    is_enabled=function() return false end,
    set_enabled=function() return true end,
    set_material=function() return true end,
    material_color=function() error("authored texture unexpectedly used a colour fallback") end,
}
local liquid_color = {0.1,0.2,0.3,0.96}
local texture_tint = {0.4,0.5,0.6,1}
local material_preview = {
    new_liquid_warmup=function() return {} end,
    warm_liquid_colors=function(_, entries)
        if #entries > 0 then
            liquid_warmups = liquid_warmups + 1
            assert(#entries == 1 and entries[1].id == "water",
                "materials tab did not pass its liquid entries to the shared preview service")
        end
        return true
    end,
    texture=function(id) return id == "stone" and "data/materials_gfx/stone.png" or nil end,
    tint=function(id) return id == "stone" and texture_tint or nil end,
    liquid_icon=function() return "data/ui_gfx/items/potion.png" end,
    liquid_color=function(id) return id == "water" and liquid_color or nil end,
}
local ui = {
    EMPTY_SLOT="slot", ICON_STEP=20,
    audit=function() end,
    gui=function() return {} end,
    tr=function(_,fallback) return fallback end,
    translated=function(value) return value end,
    white_text=function() end,
    wrapped_text=function() end,
    button=function() return false end,
    button_grid=function()
        if not selected_category_once then selected_category_once=true; return 3 end
        return nil
    end,
    stepper=function() return 0 end,
    search_input=function(value) return value end,
    search_status=function() end,
    columns=function() return 4 end,
    scroll_height=function() return 200 end,
    mark_hovered=function() end,
    begin_scroll_viewport=function(_,_,_,_,width,height) return {content_width=math.max(20,(tonumber(width) or 100)-12),padding_left=2,padding_top=2,state={offset=0},height=height} end,
    scroll_y=function(_,y) return y end, end_scroll_viewport=function() end,
    matches_search=function() return true end,
    tile=function(_,_,background,icon,fallback,title,description,selected,options)
        tiles[#tiles+1] = {
            background=background, icon=icon, fallback=fallback, title=title,
            description=description, selected=selected, options=options,
        }
        return false,false
    end,
}

dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/ui/runtime.lua" then return ui end
    if path == "mods/metamorph_creative_menu/files/features/materials/catalog.lua" then return catalog end
    if path == "mods/metamorph_creative_menu/files/features/materials/painter.lua" then return painter end
    if path == "mods/metamorph_creative_menu/files/platform/noita/action_bindings.lua" then
        return {label=function() return "MOUSE MIDDLE" end}
    end
    if path == "mods/metamorph_creative_menu/files/platform/noita/material_preview.lua" then
        return material_preview
    end
    return native_dofile(path)
end

GuiLayoutBeginVertical=function() end
GuiLayoutEnd=function() end
GuiLayoutBeginHorizontal=function() end
GuiBeginScrollContainer=function() end
GuiEndScrollContainer=function() end
GuiGetPreviousWidgetInfo=function() return 0,0,false end

local tab = assert(native_dofile(root .. "/files/ui/tabs/materials.lua"))
tab.draw(1,260,500)
assert(#tiles == 1, "liquid preview tile was not drawn")
assert(tiles[1].icon == "data/ui_gfx/items/potion.png", "liquid did not use the item flask icon")
assert(tiles[1].options.bottle_fill_color == liquid_color,
    "liquid did not use the shared item-style bottle fill")
assert(tiles[1].options.swatch_color == nil, "liquid leaked the old generic swatch preview")

tab.draw(1,260,500)
assert(#tiles == 2, "authored solid preview tile was not drawn")
assert(tiles[2].icon == "data/materials_gfx/stone.png", "solid did not use its authored material texture")
assert(tiles[2].options.icon_tint == texture_tint, "solid did not use its authored texture tint")
assert(tiles[2].options.swatch_color == nil, "authored texture was replaced by a random colour")
assert(liquid_warmups >= 1, "shared liquid preview cache was not warmed")

print("material_tab_preview=PASS shared_liquid_display=true authored_texture=true")
