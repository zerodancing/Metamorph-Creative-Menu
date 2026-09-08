local root=assert(arg[1], 'root required')
local native_dofile=dofile
local step_calls=0
local catalog={
    categories=function()
        return {
            {id='ALL',key='all',fallback='ALL'},
            {id='LIQUIDS',key='liquids',fallback='LIQUIDS'},
            {id='SANDS',key='sands',fallback='SANDS'},
        }
    end,
    is_ready=function() return false end,
    step=function(category,translate,budget)
        assert(category=='LIQUIDS','first category changed unexpectedly')
        assert(type(translate)=='function','translation callback missing')
        assert(budget>0 and budget<=24,'catalog per-frame budget is no longer bounded')
        step_calls=step_calls+1
        return false,0
    end,
    entries_for=function() return {} end,
    get=function() return nil end,
}
local painter={
    get_material=function() return 'water' end,
    brush_diameter=function() return 5 end,
    adjust_brush=function() end,
    is_enabled=function() return false end,
    set_enabled=function() return true,'enabled' end,
    set_material=function() return true end,
}
local material_preview={
    new_liquid_warmup=function() return {} end,
    warm_liquid_colors=function() return true end,
    texture=function() return nil end,
    tint=function() return nil end,
    liquid_icon=function() return 'data/items_gfx/potion.png' end,
    liquid_mask=function() return 'data/items_gfx/flask_liquid.png' end,
    liquid_offset=function() return -1,0 end,
    liquid_color=function() return nil end,
}
local ui={
    audit=function() end, gui=function() return {} end,
    tr=function(_,fallback) return fallback end,
    translated=function(v) return v end,
    white_text=function() end, button=function() return false end,
    wrapped_text=function() end,
    button_grid=function() return nil end,
    stepper=function() return 0 end,
    search_input=function(v) return v end,
    search_status=function() end,
    columns=function() return 4 end, scroll_height=function() return 100 end,
    mark_hovered=function() end,
    begin_scroll_viewport=function(_,_,_,_,width,height) return {content_width=math.max(20,(tonumber(width) or 100)-12),padding_left=2,padding_top=2,state={offset=0},height=height} end,
    scroll_y=function(_,y) return y end, end_scroll_viewport=function() end, tile=function() return false end,
    matches_search=function() return false end,
    EMPTY_SLOT='slot', ICON_STEP=20,
}
dofile=function(path)
    if path=='mods/metamorph_creative_menu/files/ui/runtime.lua' then return ui end
    if path=='mods/metamorph_creative_menu/files/features/materials/catalog.lua' then return catalog end
    if path=='mods/metamorph_creative_menu/files/features/materials/painter.lua' then return painter end
    if path=='mods/metamorph_creative_menu/files/platform/noita/action_bindings.lua' then return {label=function() return 'MOUSE MIDDLE' end} end
    if path=='mods/metamorph_creative_menu/files/platform/noita/material_preview.lua' then return material_preview end
    return native_dofile(path)
end
GuiLayoutBeginVertical=function() end
GuiLayoutEnd=function() end
GuiLayoutBeginHorizontal=function() end
GuiBeginScrollContainer=function() end
GuiEndScrollContainer=function() end
GuiGetPreviousWidgetInfo=function() return 0,0,false end
local tab=assert(native_dofile(root..'/files/ui/tabs/materials.lua'))
-- Critical regression: entering the tab must not enumerate CellFactory on that same
-- GUI frame. EW networking/inventory work is also concentrated on the open frame.
tab.draw(1,220,720)
assert(step_calls==0,'MATERIALS tab performs catalog work on its opening frame')
tab.draw(1,220,720)
assert(step_calls==1,'MATERIALS catalog did not resume incrementally after deferred frame')
print('material_tab_deferred_catalog=PASS open_frame_work=0 incremental_after=true')

-- Search from the default LIQUIDS category must still find static paint materials.
local requested,selected,selected_solid,rendered=nil,nil,nil,{}
local query="water_static"
local static={id="water_static",display_name="Static water",category="STATIC",categories={STATIC=true}}
catalog.is_ready=function() return true end
catalog.step=function(category,_,budget) requested=category;assert(budget<=24);return true end
catalog.entries_for=function(category) return category=="ALL" and {static} or {} end
ui.search_input=function() return query end
ui.rank_entries=function(_,values) return values end
ui.tile=function(_,_,_,_,_,name) rendered[#rendered+1]=name;return true end
painter.material_color=function() return {1,1,1,1} end
painter.set_material=function(id,options) selected=id;selected_solid=options.solid;return true end
for i=1,3 do tab.draw(1,220,720) end
assert(requested=="ALL" and #rendered>0,"search still restricted to LIQUIDS")
assert(selected=="water_static" and selected_solid,"static water search result cannot be selected for painting")
query=""; for i=1,3 do tab.draw(1,220,720) end
assert(requested=="LIQUIDS","clearing search did not restore chosen category")
print('material_search_all=PASS default_liquids=true water_static_paintable=true category_restored=true')
