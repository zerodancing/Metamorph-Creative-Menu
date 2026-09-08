local root=assert(arg[1])
local native_dofile=dofile
local globals={}
local runtime={enabled=function() return true end,mode=function() return 'peer' end}
local owner={is_weather_frozen=function() return false end,set_weather_frozen=function() return true end,has_day_override=function() return false end,accept_legacy_sync_value=function() end,legacy_sync_value=function() return nil end}
dofile=function(p)
 if p=='mods/metamorph_creative_menu/files/integrations/ew/runtime.lua' then return runtime end
 if p=='mods/metamorph_creative_menu/files/features/world_rules/time_dt.lua' then return owner end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(p,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(p,#prefix+1)) end
 return native_dofile(p)
end
function GlobalsGetValue(k,f) local v=globals[k]; if v==nil then return f end; return v end
function GlobalsSetValue(k,v) globals[k]=tostring(v) end
function GameHasFlagRun() return false end
local sync=assert(native_dofile(root..'/files/integrations/ew/weather_sync.lua'))
local state={active=true,lightning=0.55,next_lightning_frame=777,lightning_clear_frame=456,values={},rainfall=0}
local function snapshot(lightning) return table.concat({'1','~','0',tostring(lightning),'~','~','~','~','~','~','~'},'|') end
local function world() return nil end
local function clear() error('unexpected clear') end
globals.mcm_weather_remote_version_v1='1'; globals.mcm_weather_remote_seq_v1='a'; globals.mcm_weather_remote_snapshot_v1=snapshot(0.55)
assert(sync.consume(state,world,clear,owner)==true,'identical remote snapshot not consumed')
assert(state.next_lightning_frame==777 and state.lightning_clear_frame==456,'periodic identical sync reset lightning scheduler')
globals.mcm_weather_remote_seq_v1='b'; globals.mcm_weather_remote_snapshot_v1=snapshot(0.80)
assert(sync.consume(state,world,clear,owner)==true and state.next_lightning_frame==0,'real lightning-rate change did not reschedule')
print('lightning_sync=PASS periodic_preserves_scheduler=true rate_change_reschedules=true')
