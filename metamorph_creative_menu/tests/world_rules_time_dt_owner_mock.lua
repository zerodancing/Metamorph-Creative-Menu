local root = assert(arg[1], "root required")
local native_dofile = dofile
local globals = {}
local time_dt = 0.01

local function nearly(a, b) return math.abs((tonumber(a) or 0) - (tonumber(b) or 0)) < 0.0000001 end

dofile = function(path)
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path, 1, #prefix) == prefix then return native_dofile(root .. "/" .. string.sub(path, #prefix + 1)) end
    return native_dofile(path)
end
function GlobalsGetValue(key, fallback) local value=globals[key]; if value==nil then return fallback end; return value end
function GlobalsSetValue(key, value) globals[key]=tostring(value) end
function GameGetWorldStateEntity() return 1 end
function EntityGetFirstComponentIncludingDisabled(entity, kind)
    if entity==1 and kind=="WorldStateComponent" then return 10 end
    return 0
end
function ComponentGetValue2(component, field)
    assert(component==10 and field=="time_dt")
    return time_dt
end
function ComponentSetValue2(component, field, value)
    assert(component==10 and field=="time_dt")
    time_dt=tonumber(value)
end

METAMORPH_CREATIVE_MENU_WORLD_RULE_RECOVERY=nil
METAMORPH_CREATIVE_MENU_TIME_DT_OWNER=nil
local owner=assert(native_dofile(root.."/files/features/world_rules/time_dt.lua"))

local ok=owner.apply_day_multiplier(2)
assert(ok==true and nearly(time_dt,0.02),"Day Speed did not use baseline*time multiplier")
ok=owner.set_weather_frozen(true)
assert(ok==true and nearly(time_dt,0),"Weather did not temporarily override Day Speed with time_dt=0")
ok=owner.apply_day_multiplier(4)
assert(ok==true and nearly(time_dt,0),"changing Day Speed while Weather freeze is active leaked through freeze priority")
ok=owner.set_weather_frozen(false)
assert(ok==true and nearly(time_dt,0.04),"Weather release did not resume the latest Day Speed multiplier")

-- RESET/NATIVE must be compare-and-swap. A later write from another mod wins.
time_dt=0.123
ok=owner.release_day_multiplier()
assert(ok==true and nearly(time_dt,0.123),"Day Speed RESET overwrote a newer external time_dt write")
assert(owner.has_persisted_recovery()==false,"CAS external-preserve path left stale recovery metadata")

-- A clean release restores the baseline captured for this ownership session.
ok=owner.apply_day_multiplier(0.5)
assert(ok==true and nearly(time_dt,0.0615),"new Day Speed session captured the wrong baseline")
ok=owner.release_day_multiplier()
assert(ok==true and nearly(time_dt,0.123),"clean Day Speed release did not restore its baseline")

-- Crash/reload recovery restores only a value that still equals MCM's last verified write.
ok=owner.apply_day_multiplier(2)
assert(ok==true and nearly(time_dt,0.246),"pre-reload Day Speed write failed")
METAMORPH_CREATIVE_MENU_TIME_DT_OWNER=nil
local owner2=assert(native_dofile(root.."/files/features/world_rules/time_dt.lua"))
assert(owner2.has_persisted_recovery()==true,"time_dt recovery state was not persisted")
ok=owner2.recover_persisted()
assert(ok==true and nearly(time_dt,0.123),"startup recovery did not restore owned time_dt")

ok=owner2.apply_day_multiplier(2)
assert(ok==true and nearly(time_dt,0.246),"second ownership session failed")
time_dt=0.777
METAMORPH_CREATIVE_MENU_TIME_DT_OWNER=nil
local owner3=assert(native_dofile(root.."/files/features/world_rules/time_dt.lua"))
ok=owner3.recover_persisted()
assert(ok==true and nearly(time_dt,0.777),"startup recovery overwrote a newer external time_dt write")
assert(owner3.has_persisted_recovery()==false,"external startup CAS path left stale recovery")

io.write("world_rules_time_dt_owner=PASS multiplier=true weather_priority=true cas=true restart_recovery=true\n")
