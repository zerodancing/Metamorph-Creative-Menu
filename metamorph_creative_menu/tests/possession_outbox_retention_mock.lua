local root=assert(arg[1])
local globals={}
local bases={
 'mcm_possession_retire_outbox_entity_v1','mcm_possession_retire_outbox_path_v1','mcm_possession_retire_outbox_x_v1',
 'mcm_possession_retire_outbox_y_v1','mcm_possession_retire_outbox_wait_v1','mcm_possession_retire_outbox_responsible_v1'}
local values={'42','mods/example/entities/mob.xml','10','20','0','7'}
for i,b in ipairs(bases) do globals[b]=values[i]; globals[b..'_1']=values[i] end
globals.mcm_possession_retire_outbox_seq_v1='1'
function GlobalsGetValue(k,f) local v=globals[k]; if v==nil then return f end; return v end
function GlobalsSetValue(k,v) globals[k]=tostring(v) end
function EntityGetIsAlive(e) return e==42 end
local sends=0
function CrossCall(name,entity,wait,x,y,path,responsible)
 assert(name=='ew_death_notify' and entity==42 and path=='mods/example/entities/mob.xml'); sends=sends+1
end
local common={finite_number=function(v) return type(v)=='number' and v==v and math.abs(v)<math.huge end,report_error=function() error('unexpected possession error') end}
local rpc={opts_reliable=function() end,opts_everywhere=function() end}
local bridge=assert(loadfile(root..'/files/integrations/ew/bridge/possession.lua'))()
bridge.register(rpc,common); bridge.update()
assert(sends==1 and globals.mcm_possession_retire_outbox_ack_v1=='1','completed possession event not acknowledged')
for _,b in ipairs(bases) do
 assert(globals[b]=='','completed possession base payload retained: '..b)
 assert(globals[b..'_1']=='','completed possession sequence payload retained: '..b..'_1')
end
print('possession_outbox_retention=PASS suffixed_cleared=true base_alias_cleared=true')
