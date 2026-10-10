local root=assert(arg[1],"root required")
local patches=assert(loadfile(root.."/files/integrations/ew/resilience_patches.lua"))()
local source=[[
local old_entity_load = EntityLoad
function EntityLoad(filename,x,y)
 if filename == "portal" then CrossCall("ew_kolmi_spawn_portal",x,y) end
 return old_entity_load(filename,x,y)
end
local old_main_anim=set_main_animation
function set_main_animation(a,b)
 old_main_anim(a,b)
 CrossCall("ew_kolmi_anim",a,b,false)
end
local old_shield_on=shield_on
function shield_on()
 CrossCall("ew_kolmi_shield",true,0)
 return old_shield_on()
end
]]
local patched,count=patches.patch_kolmi_boss_update_source(source)
assert(count==3,"not every Kolmi transport CrossCall was guarded")
assert(string.find(patched,"mcm_kolmi_crosscall_failopen_v1",1,true),"fail-open marker missing")
assert(not string.find(patched,'CrossCall("ew_kolmi_',1,true),"raw Kolmi CrossCall survived patch")
local old_load_calls,anim_calls,shield_calls=0,0,0
EntityLoad=function() old_load_calls=old_load_calls+1; return 9 end
set_main_animation=function() anim_calls=anim_calls+1 end
shield_on=function() shield_calls=shield_calls+1; return "shield-ok" end
CrossCall=function() error("split registry") end
np=nil
GlobalsSetValue=function() end
local chunk=assert(load(patched))
chunk()
local ok,res=pcall(shield_on)
assert(ok and res=="shield-ok" and shield_calls==1,"CrossCall failure aborted vanilla shield_on")
local ok2=pcall(set_main_animation,"a","b")
assert(ok2 and anim_calls==1,"CrossCall failure aborted vanilla animation")
local ok3=pcall(EntityLoad,"portal",1,2)
assert(ok3 and old_load_calls==1,"CrossCall failure aborted vanilla EntityLoad")
print("ew_kolmi_crosscall_failopen=PASS transport_failure_does_not_abort_vanilla_coroutine=true")
