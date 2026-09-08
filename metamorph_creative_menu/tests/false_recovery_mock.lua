local root=assert(arg[1])
local globals={}
function GlobalsGetValue(k,f) local v=globals[k]; if v==nil then return f end; return v end
function GlobalsSetValue(k,v) globals[k]=tostring(v) end
METAMORPH_CREATIVE_MENU_WORLD_RULE_RECOVERY=nil
local recovery=assert(loadfile(root..'/files/features/world_rules/recovery.lua'))()
assert(recovery.capture('world','flag',true,'meta')==true)
assert(recovery.update_last('world','flag',false)==true)
local record=assert(recovery.read('world','flag'))
assert(record.original==true and record.last==false and record.phase=='owned','saved false was lost from recovery journal')
recovery.mark_partial('world','flag',false)
record=assert(recovery.read('world','flag'))
assert(record.last==false and record.phase=='partial','false was lost in partial recovery record')
print('false_recovery=PASS false_roundtrip=true')
