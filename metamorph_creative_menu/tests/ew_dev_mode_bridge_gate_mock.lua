local root=assert(arg[1],"root required")
local native_dofile=dofile

local function run(mode)
 local loaded={}
 local registrations={}
 local updates={}
 local reported={}
 local rpc={opts_reliable=function() end,opts_everywhere=function() end}
 local modules={}
 local function bridge(name)
  return {register=function() registrations[#registrations+1]=name end,update=function()
   updates[name]=(updates[name] or 0)+1
   if name=="world_rules" then error("isolated update failure") end
  end}
 end
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/protocol.lua"]={NAMESPACE="test"}
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/common.lua"]={clean=tostring,report_error=function(scope) reported[#reported+1]=scope end}
 modules["mods/metamorph_creative_menu/files/integrations/ew/form_death_intercept.lua"]={install=function()
  updates.death_intercept=(updates.death_intercept or 0)+1
  return true,"installed"
 end}
 modules["mods/metamorph_creative_menu/files/integrations/ew/perk_runtime_guard.lua"]={install=function() return true,"ok" end}
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/world_rules.lua"]=bridge("world_rules")
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/qa.lua"]=bridge("qa_full")
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/qa_reserved.lua"]=bridge("qa_reserved")
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/companion.lua"]=bridge("companion")
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/perks.lua"]=bridge("perks")
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/weather.lua"]=bridge("weather")
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/possession.lua"]=bridge("possession")
 local material_bridge=bridge("materials")
 material_bridge.set_metrics_enabled=function(value) updates.material_metrics_enabled=value end
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/materials.lua"]=material_bridge
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/teleport.lua"]=bridge("teleport")
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/items.lua"]={init=function() end,update=function() updates.items=(updates.items or 0)+1 end}
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/forms.lua"]={register_pose=function() registrations[#registrations+1]="forms_pose" end,register_reserved=function() registrations[#registrations+1]="forms_reserved" end,update=function() updates.forms=(updates.forms or 0)+1 end,metrics=function() return 0,0 end,set_profiling_enabled=function(value) updates.form_profiling_enabled=value end}
 local old_dofile,old_once=dofile,dofile_once
 dofile_once=function(path)
  if path=="mods/quant.ew/files/api/ew_api.lua" then return {new_rpc_namespace=function() return rpc end} end
  error("unexpected dofile_once "..tostring(path))
 end
 dofile=function(path)
  loaded[path]=(loaded[path] or 0)+1
  if path=="mods/metamorph_creative_menu/dev_mode.lua" then return mode end
  if modules[path] then return modules[path] end
  error("unexpected EW bootstrap dependency: "..tostring(path))
 end
 GlobalsSetValue=function() end; GameGetFrameNum=function() return 10 end
 ctx={my_id="me",host_id="host"}
 local module=assert(loadfile(root.."/files/integrations/ew/bootstrap.lua"))()
 dofile,dofile_once=old_dofile,old_once
 return loaded,registrations,module,updates,reported
end

local release_loaded,release_reg,release_module,release_updates,release_reported=run(0)
assert(release_loaded["mods/metamorph_creative_menu/files/integrations/ew/bridge/qa.lua"]==nil,"release EW bootstrap loaded full QA telemetry bridge")
assert(release_loaded["mods/metamorph_creative_menu/files/integrations/ew/bridge/qa_reserved.lua"]==1,"release EW bootstrap did not preserve reserved QA slot")
assert(release_reg[2]=="qa_reserved","release QA slot moved from RPC position 3 registration group")
release_module.on_world_update()
assert(release_updates.perks == nil, "reserved perk RPC mailbox is still polled every EW frame")
assert(release_updates.qa_reserved == nil, "release placeholder QA bridge was still polled every frame")
assert(release_updates.material_metrics_enabled==false and release_updates.form_profiling_enabled==false,
 "release EW telemetry was not disabled")
assert(release_updates.materials == 1, "material bridge was not updated in release mode")
assert(release_updates.teleport == 1, "teleport bridge was not updated in release mode")
assert(release_updates.death_intercept == 1, "runtime form-death intercept was not installed by EW bootstrap")
assert(release_reported[1]=="world_rules.update" and release_updates.items==1 and release_updates.forms==1,
 "one failing EW bridge stopped later network updates")
local dev_loaded,dev_reg,_,dev_updates=run(1)
assert(dev_loaded["mods/metamorph_creative_menu/files/integrations/ew/bridge/qa.lua"]==1,"developer EW bootstrap did not load full QA bridge")
assert(dev_loaded["mods/metamorph_creative_menu/files/integrations/ew/bridge/qa_reserved.lua"]==nil,"developer EW bootstrap loaded release placeholder")
assert(dev_reg[2]=="qa_full","developer QA registration order changed")
assert(dev_updates.material_metrics_enabled==true and dev_updates.form_profiling_enabled==true,
 "developer EW telemetry was not enabled")
io.write("ew_dev_mode_bridge_gate=PASS release_qa_unloaded=true reserved_slot=true release_telemetry=false developer_qa=true developer_telemetry=true\n")
