local root=assert(arg[1],"root required")
local native_dofile=dofile

local function run(mode)
 local loaded={}
 local registrations={}
 local rpc={opts_reliable=function() end,opts_everywhere=function() end}
 local modules={}
 local function bridge(name)
  return {register=function() registrations[#registrations+1]=name end,update=function() end}
 end
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/protocol.lua"]={NAMESPACE="test"}
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/common.lua"]={clean=tostring,report_error=function() end}
 modules["mods/metamorph_creative_menu/files/integrations/ew/perk_runtime_guard.lua"]={install=function() return true,"ok" end}
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/world_rules.lua"]=bridge("world_rules")
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/qa.lua"]=bridge("qa_full")
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/qa_reserved.lua"]=bridge("qa_reserved")
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/companion.lua"]=bridge("companion")
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/perks.lua"]=bridge("perks")
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/weather.lua"]=bridge("weather")
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/possession.lua"]=bridge("possession")
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/items.lua"]={init=function() end,update=function() end}
 modules["mods/metamorph_creative_menu/files/integrations/ew/bridge/forms.lua"]={register_pose=function() registrations[#registrations+1]="forms_pose" end,register_reserved=function() registrations[#registrations+1]="forms_reserved" end,update=function() end,metrics=function() return 0,0 end}
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
 return loaded,registrations,module
end

local release_loaded,release_reg=run(0)
assert(release_loaded["mods/metamorph_creative_menu/files/integrations/ew/bridge/qa.lua"]==nil,"release EW bootstrap loaded full QA telemetry bridge")
assert(release_loaded["mods/metamorph_creative_menu/files/integrations/ew/bridge/qa_reserved.lua"]==1,"release EW bootstrap did not preserve reserved QA slot")
assert(release_reg[2]=="qa_reserved","release QA slot moved from RPC position 3 registration group")
local dev_loaded,dev_reg=run(1)
assert(dev_loaded["mods/metamorph_creative_menu/files/integrations/ew/bridge/qa.lua"]==1,"developer EW bootstrap did not load full QA bridge")
assert(dev_loaded["mods/metamorph_creative_menu/files/integrations/ew/bridge/qa_reserved.lua"]==nil,"developer EW bootstrap loaded release placeholder")
assert(dev_reg[2]=="qa_full","developer QA registration order changed")
io.write("ew_dev_mode_bridge_gate=PASS release_qa_unloaded=true reserved_slot=true developer_qa=true\n")
