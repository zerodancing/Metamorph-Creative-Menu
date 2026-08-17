local definitions = {}

-- WorldStateComponent.rain is cloud cover (the engine field predates its final
-- meaning). Real rain particles are a separate runtime capability.
definitions.fields = {
    { id = "time", label = "$mcm_weather_time", field = "time", min = 0, max = 1, step = 0.02, decimals = 2, wrap = true },
    { id = "clouds", label = "$mcm_weather_clouds", field = "rain", target = "rain_target", min = 0, max = 1, step = 0.10, decimals = 1 },
    { id = "rainfall", label = "$mcm_weather_rainfall", virtual = true, min = 0, max = 1, step = 0.10, decimals = 1 },
    { id = "fog", label = "$mcm_weather_fog", field = "fog", target = "fog_target", min = 0, max = 1, step = 0.10, decimals = 1 },
    { id = "wind", label = "$mcm_weather_wind", field = "wind", min = 0, max = 1, step = 0.10, decimals = 1 },
    { id = "wind_speed", label = "$mcm_weather_wind_speed", field = "wind_speed", min = -50, max = 50, step = 5, decimals = 0 },
    { id = "lightning", label = "$mcm_weather_lightning", virtual = true, min = 0, max = 1, step = 0.10, decimals = 1 },
}

-- Empirically aligned to Noita's time cycle: 0 is the bright part of the cycle and
-- ~0.5 the dark part. Fine adjustment remains available in Advanced.
definitions.time_presets = {
    day = 0.00,
    evening = 0.25,
    night = 0.50,
    morning = 0.75,
}

definitions.weather_presets = {
    clear  = { rain = 0.00, rain_target = 0.00, fog = 0.00, fog_target = 0.00, wind = 0.00, wind_speed = 0, rainfall = 0.00, lightning = 0.00 },
    cloudy = { rain = 0.72, rain_target = 0.72, fog = 0.12, fog_target = 0.12, wind = 0.24, wind_speed = 8, rainfall = 0.00, lightning = 0.00 },
    foggy  = { rain = 0.32, rain_target = 0.32, fog = 0.78, fog_target = 0.78, wind = 0.10, wind_speed = 3, rainfall = 0.08, lightning = 0.00 },
    storm  = { rain = 1.00, rain_target = 1.00, fog = 0.50, fog_target = 0.50, wind = 1.00, wind_speed = 48, rainfall = 1.00, lightning = 0.55 },
}

return definitions
