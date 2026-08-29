local root = assert(arg[1], "root required")
local native_dofile = dofile
local globals = {}
local values = {time=0.12, time_dt=0.01, intro_weather=true, rain=0, rain_target=0, fog=0, fog_target=0, wind=0, wind_speed=0, lightning_count=0}
local frame = 100
local is_host = false
local rain_updates, lightning_updates = 0, 0

local ew_runtime_stub = {
    enabled=function() return true end,
    mode=function() return is_host and "host" or "peer" end,
}
local runtime_effects_stub = {
    emit_rain=function() rain_updates=rain_updates+1 end,
    update_lightning=function() lightning_updates=lightning_updates+1 end,
}

dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/integrations/ew/runtime.lua" then return ew_runtime_stub end
    if path == "mods/metamorph_creative_menu/files/features/weather/runtime_effects.lua" then return runtime_effects_stub end
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path, 1, #prefix) == prefix then return native_dofile(root .. "/" .. string.sub(path, #prefix + 1)) end
    return native_dofile(path)
end
function GlobalsGetValue(key, fallback) local value=globals[key]; if value==nil then return fallback end; return value end
function GlobalsSetValue(key, value) globals[key]=tostring(value) end
function GameHasFlagRun(flag) return flag == "ew_flag_this_is_host" and is_host end
function GameGetFrameNum() return frame end
function GameGetWorldStateEntity() return 1 end
function EntityGetFirstComponentIncludingDisabled(entity, component_type)
    if entity == 1 and component_type == "WorldStateComponent" then return 10 end
    return 0
end
function ComponentGetValue2(component, field) assert(component == 10); return values[field] end
local blocked_field=nil
function ComponentSetValue2(component, field, value)
    assert(component == 10)
    if field==blocked_field then return end
    values[field] = value
end
function print() end

METAMORPH_CREATIVE_MENU_WEATHER_SERVICE = nil
METAMORPH_CREATIVE_MENU_WEATHER_EDITOR = nil
local weather = assert(native_dofile(root .. "/files/features/weather/service.lua"))
local fields = {}
for _, field in ipairs(weather.fields()) do fields[field.id] = field end

local allowed, role = weather.can_edit()
assert(allowed == true and role == "ew_peer", "EW client lost weather editing rights")
local ok = weather.set_time_preset("night")
assert(ok == true and values.time == 0.5 and values.time_dt == 0, "time preset did not lock world time")
assert(tonumber(globals.mcm_weather_outbox_seq_v1 or "0") >= 1, "time preset was not published to EW mailbox")

ok = weather.set(fields.fog, 0.7)
assert(ok == true and values.fog == 0.7 and values.fog_target == 0.7, "precise fog field did not update field and target")
local before_storm_seq = tonumber(globals.mcm_weather_outbox_seq_v1)
ok = weather.apply_preset("storm")
assert(ok == true, "storm preset failed")
assert(values.rain == 1 and values.rain_target == 1 and values.wind_speed == 48, "storm preset did not apply world fields")
assert(tonumber(globals.mcm_weather_outbox_seq_v1) > before_storm_seq, "storm preset did not publish a newer snapshot")
local storm_snapshot = globals.mcm_weather_outbox_snapshot_v1

local original_dt = 0.01
ok = weather.release()
assert(ok == true and values.time_dt == original_dt and weather.is_locked() == false, "weather release did not restore native time progression")

-- Consume a complete remote snapshot as a client and verify it re-establishes the same
-- world state without requiring host-only permissions.
globals.mcm_weather_remote_seq_v1 = "remote-1"
globals.mcm_weather_remote_version_v1 = "1"
globals.mcm_weather_remote_snapshot_v1 = storm_snapshot
frame = frame + 1
weather.update()
assert(weather.is_locked() == true, "remote weather snapshot was not adopted")
weather.update()
assert(rain_updates == 1 and lightning_updates == 1,
    "duplicate same-frame weather call repeated particle/network-side runtime work")
local state = weather.debug_state()
assert(state.fog == 0.5 and state.wind_speed == 48, "remote storm snapshot did not converge world fields")

-- A peer taking over a remote active lock must retain its local pre-override time_dt.
ok=weather.set(fields.fog,0.25)
assert(ok==true,"local takeover after remote snapshot failed")
ok=weather.release()
assert(ok==true and values.time_dt==original_dt,"remote takeover RELEASE lost local time_dt baseline")

-- User-facing writes are verified once. A silent engine no-op must fail and rollback
-- earlier fields instead of reporting success with a half-applied weather rule.
values.fog,values.fog_target=0.1,0.1
blocked_field="fog_target"
ok=weather.set(fields.fog,0.8)
assert(ok==false,"silent weather setter failure reported success")
assert(values.fog==0.1 and values.fog_target==0.1,"failed weather edit did not rollback earlier field")
blocked_field=nil

print("weather_state_sync=PASS client_edit=true preset=true precise=true remote_converges=true takeover_release=true verified_write=true")
