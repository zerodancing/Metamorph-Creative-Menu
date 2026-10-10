local weather_tab = {}
local ui = dofile("mods/metamorph_creative_menu/files/ui/runtime.lua")
local audit = ui.audit
local weather_service = dofile("mods/metamorph_creative_menu/files/features/weather/service.lua")
local advanced=false

local function time(name)
    local ok,reason=weather_service.set_time_preset(name)
    audit("weather.time", "preset="..tostring(name).." result="..tostring(ok).." reason="..tostring(reason))
end
local function preset(name)
    local ok,reason=weather_service.apply_preset(name)
    local detail=""
    if type(weather_service.debug_state)=="function" then
        local good,state=pcall(weather_service.debug_state)
        if good and type(state)=="table" then
            detail=" rainfall="..tostring(state.rainfall).." rain="..tostring(state.rain).." rain_target="..tostring(state.rain_target)
                .." last_emit="..tostring(state.last_rain_emit_frame).." stop_guard_until="..tostring(state.rain_stop_guard_until)
        end
    end
    audit("weather.preset", "preset="..tostring(name).." result="..tostring(ok).." reason="..tostring(reason)..detail)
end
local function tile(icon,key,fallback,fn)
    local clicked=ui.tile(0,0,ui.EMPTY_SLOT,icon,ui.EMPTY_SLOT,ui.tr(key,fallback),nil,false,{target_size=18,max_scale=2.5})
    if clicked then fn() end
end
local function tile_group(items,panel_width,y)
    local columns=math.max(1,ui.columns(math.max(ui.ICON_STEP,(tonumber(panel_width) or 220)-10),ui.ICON_STEP,{reserve_scrollbar=false}))
    local cursor=1
    while cursor<=#items do
        GuiLayoutBeginHorizontal(ui.gui(),0,y or 0,true)
        for _=1,columns do
            local item=items[cursor]; if item==nil then break end
            tile(item[1],item[2],item[3],item[4]); cursor=cursor+1
        end
        GuiLayoutEnd(ui.gui())
        y=0
    end
end
function weather_tab.draw(_, panel_width, screen_height)
    local can_edit,mode=weather_service.can_edit()
    GuiLayoutBeginVertical(ui.gui(),0,2,true)
    local mode_label=mode=="ew_host" and ui.tr("$mcm_weather_mode_ew_host","EW HOST")
        or (mode=="ew_peer" and ui.tr("$mcm_weather_mode_ew_client","EW CLIENT")
        or ui.tr("$mcm_weather_mode_local","LOCAL"))
    ui.wrapped_text(0,0,mode_label..(weather_service.is_locked() and (" • "..ui.tr("$mcm_weather_locked","LOCKED")) or ""),math.max(24,panel_width-10))
    if not can_edit then ui.white_text(0,0,ui.tr("$mcm_weather_unavailable","Weather editing unavailable"))
    elseif not advanced then
        ui.white_text(0,0,ui.tr("$mcm_weather_time_presets","TIME OF DAY"))
        tile_group({
            {"data/ui_gfx/items/sunseed.png","$mcm_weather_morning","MORNING",function() time("morning") end},
            {"data/ui_gfx/items/sunseed_2.png","$mcm_weather_day","DAY",function() time("day") end},
            {"data/ui_gfx/items/moon.png","$mcm_weather_evening","EVENING",function() time("evening") end},
            {"data/ui_gfx/items/moon.png","$mcm_weather_night","NIGHT",function() time("night") end},
        },panel_width,0)
        tile_group({
            {"data/ui_gfx/items/waterstone.png","$mcm_weather_clear","CLEAR",function() preset("clear") end},
            {"data/ui_gfx/items/material_pouch.png","$mcm_weather_cloudy","CLOUDY",function() preset("cloudy") end},
            {"data/ui_gfx/items/evil_eye.png","$mcm_weather_foggy","FOGGY",function() preset("foggy") end},
            {"data/ui_gfx/items/brimstone.png","$mcm_weather_storm","STORM",function() preset("storm") end},
        },panel_width,2)
        local actions={{label=ui.tr("$mcm_weather_advanced","ADVANCED")}}
        if weather_service.is_locked() then actions[#actions+1]={label=ui.tr("$mcm_weather_release","RELEASE")} end
        local clicked=ui.button_grid(actions,math.max(32,panel_width-10))
        if clicked==1 then advanced=true
        elseif clicked==2 and weather_service.is_locked() then local ok=weather_service.release(); audit("weather.release", "result="..tostring(ok)) end
    else
        local actions={{label=ui.tr("$mcm_weather_back","BACK")}}
        if weather_service.is_locked() then actions[#actions+1]={label=ui.tr("$mcm_weather_release","RELEASE")} end
        local clicked=ui.button_grid(actions,math.max(32,panel_width-10))
        if clicked==1 then advanced=false
        elseif clicked==2 and weather_service.is_locked() then local ok=weather_service.release(); audit("weather.release", "result="..tostring(ok)) end
        local scroll_height=ui.scroll_height(screen_height,72)
        local scroll=ui.begin_scroll_viewport("weather.advanced",12100,0,0,panel_width-4,scroll_height)
        for _,field in ipairs(weather_service.fields()) do
            local value=weather_service.get(field)
            if type(value)=="number" then
                local formatted=string.format("%."..tostring(tonumber(field.decimals) or 2).."f",value)
                local delta=ui.stepper(ui.tr(field.label,field.id),formatted,{
                    decrease_enabled=field.wrap==true or field.min==nil or value>field.min,
                    increase_enabled=field.wrap==true or field.max==nil or value<field.max,
                    max_width=scroll.content_width,
                })
                if delta~=0 then weather_service.set(field,value+delta*(tonumber(field.step) or 0.05)) end
            end
        end
        ui.end_scroll_viewport(scroll)
    end
    GuiLayoutEnd(ui.gui())
end
return weather_tab
