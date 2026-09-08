local root=assert(arg[1])
local native_dofile=dofile
local values={intro_weather=true,rain=0,rain_target=0,fog=0,fog_target=0,wind=0,wind_speed=0,lightning_count=0,time=0,time_dt=0.01}
local frame=100
local weather_sync={enabled=function() return false end,can_edit=function() return true,'singleplayer' end,publish=function() end,consume=function() return false end}
local runtime={emit_rain=function() end,update_lightning=function() end}
local time_owner={is_weather_frozen=function() return false end,set_weather_frozen=function() return true end,has_day_override=function() return false end}
dofile=function(p)
 if p=='mods/metamorph_creative_menu/files/integrations/ew/weather_sync.lua' then return weather_sync end
 if p=='mods/metamorph_creative_menu/files/features/weather/runtime_effects.lua' then return runtime end
 if p=='mods/metamorph_creative_menu/files/features/world_rules/time_dt.lua' then return time_owner end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(p,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(p,#prefix+1)) end
 return native_dofile(p)
end
function GameGetWorldStateEntity() return 1 end
function EntityGetFirstComponentIncludingDisabled(e,k) return e==1 and k=='WorldStateComponent' and 10 or 0 end
function ComponentGetValue2(c,f) assert(c==10); return values[f] end
function ComponentSetValue2(c,f,v) assert(c==10); values[f]=v end
function GameGetFrameNum() return frame end
METAMORPH_CREATIVE_MENU_WEATHER_SERVICE=nil; METAMORPH_CREATIVE_MENU_WEATHER_EDITOR=nil
local weather=assert(native_dofile(root..'/files/features/weather/service.lua'))
assert(weather.apply_preset('cloudy')==true,'CLOUDY preset failed')
assert(math.abs(values.rain-0.72)<1e-9 and math.abs(values.rain_target-0.72)<1e-9,'CLOUDY did not set cloud cover')
frame=101; weather.update()
assert(math.abs(values.rain-0.72)<1e-9 and math.abs(values.rain_target-0.72)<1e-9,'rainfall=0 temporarily zeroed CLOUDY cloud cover')
print('weather_clouds=PASS cloudy_cover_persists=true')
