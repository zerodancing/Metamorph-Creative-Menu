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
    local clicked=ui.tile(0,0,ui.EMPTY_SLOT,icon,ui.EMPTY_SLOT,ui.tr(key,fallback),"",false,{target_size=18,max_scale=2.5})
    if clicked then fn() end
end
function weather_tab.draw(_, panel_width, screen_height)
    local can_edit,mode=weather_service.can_edit()
    GuiLayoutBeginVertical(ui.gui(),0,2,true)
    if not can_edit then ui.white_text(0,0,ui.tr("$mcm_weather_unavailable","Weather editing unavailable"))
    elseif not advanced then
        ui.white_text(0,0,ui.tr("$mcm_weather_time_presets","TIME OF DAY"))
        GuiLayoutBeginHorizontal(ui.gui(),0,0,true)
        tile("data/ui_gfx/items/sunseed.png","$mcm_weather_morning","MORNING",function() time("morning") end)
        tile("data/ui_gfx/items/sunseed_2.png","$mcm_weather_day","DAY",function() time("day") end)
        tile("data/ui_gfx/items/moon.png","$mcm_weather_evening","EVENING",function() time("evening") end)
        tile("data/ui_gfx/items/moon.png","$mcm_weather_night","NIGHT",function() time("night") end)
        GuiLayoutEnd(ui.gui())
        ui.white_text(0,2,ui.tr("$mcm_weather_presets","WEATHER"))
        GuiLayoutBeginHorizontal(ui.gui(),0,0,true)
        tile("data/ui_gfx/items/waterstone.png","$mcm_weather_clear","CLEAR",function() preset("clear") end)
        tile("data/ui_gfx/items/material_pouch.png","$mcm_weather_cloudy","CLOUDY",function() preset("cloudy") end)
        tile("data/ui_gfx/items/evil_eye.png","$mcm_weather_foggy","FOGGY",function() preset("foggy") end)
        tile("data/ui_gfx/items/brimstone.png","$mcm_weather_storm","STORM",function() preset("storm") end)
        GuiLayoutEnd(ui.gui())
        GuiLayoutBeginHorizontal(ui.gui(),0,3,true)
        if ui.button(0,0,ui.tr("$mcm_weather_advanced","ADVANCED")) then advanced=true end
        if weather_service.is_locked() and ui.button(0,0,ui.tr("$mcm_weather_release","RELEASE")) then local ok=weather_service.release(); audit("weather.release", "result="..tostring(ok)) end
        GuiLayoutEnd(ui.gui())
    else
        GuiLayoutBeginHorizontal(ui.gui(),0,0,true)
        if ui.button(0,0,ui.tr("$mcm_weather_back","BACK")) then advanced=false end
        if weather_service.is_locked() and ui.button(0,0,ui.tr("$mcm_weather_release","RELEASE")) then local ok=weather_service.release(); audit("weather.release", "result="..tostring(ok)) end
        GuiLayoutEnd(ui.gui())
        for _,field in ipairs(weather_service.fields()) do
            local value=weather_service.get(field)
            if type(value)=="number" then
                GuiLayoutBeginHorizontal(ui.gui(),0,1,true)
                if ui.button(0,0,"  -  ") then weather_service.set(field,value-(tonumber(field.step) or 0.05)) end
                if ui.button(0,0,"  +  ") then weather_service.set(field,value+(tonumber(field.step) or 0.05)) end
                ui.white_text(0,1,ui.tr(field.label,field.id)..": "..string.format("%."..tostring(tonumber(field.decimals) or 2).."f",value))
                GuiLayoutEnd(ui.gui())
            end
        end
    end
    local label=mode=="ew_host" and ui.tr("$mcm_weather_mode_ew_host","EW HOST") or (mode=="ew_peer" and ui.tr("$mcm_weather_mode_ew_client","EW CLIENT") or ui.tr("$mcm_weather_mode_local","LOCAL"))
    ui.white_text(0,4,label..(weather_service.is_locked() and (" • "..ui.tr("$mcm_weather_locked","LOCKED")) or ""))
    GuiLayoutEnd(ui.gui())
end
return weather_tab
