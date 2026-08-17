local root=assert(arg[1],"root required")
local native_dofile=dofile
local packaged_mode=native_dofile(root.."/dev_mode.lua")
assert(tonumber(packaged_mode)==0,"Steam package dev_mode.lua must default to 0")

local function run(mode)
 local loaded={}
 local calls={diagnostics=0,qa=0}
 local stub={}
 stub["mods/metamorph_creative_menu/files/platform/noita/localization.lua"]={register=function() end}
 stub["mods/metamorph_creative_menu/files/platform/noita/input_guard.lua"]={update=function() end,blocked=function() return false end}
 stub["mods/metamorph_creative_menu/files/diagnostics/service.lua"]={update=function() calls.diagnostics=calls.diagnostics+1 end}
 stub["mods/metamorph_creative_menu/files/qa/controller.lua"]={update=function() calls.qa=calls.qa+1 end}
 stub["mods/metamorph_creative_menu/files/features/forms/manager.lua"]={current_player=function() return 1 end,update=function() end,draw_form_health=function() end,post_update=function() end,handle_tab_return=function() return false end,prepare_exact_effect_paths_from_catalog=function() return 0 end}
 stub["mods/metamorph_creative_menu/files/features/weather/service.lua"]={update=function() end}
 stub["mods/metamorph_creative_menu/files/features/world_rules/service.lua"]={update=function() end,post_update=function() end}
 stub["mods/metamorph_creative_menu/files/ui/menu_controller.lua"]={draw=function() end,post_update=function() end}
 stub["mods/metamorph_creative_menu/files/features/possession/keybinds.lua"]={update=function() end}
 stub["mods/metamorph_creative_menu/files/integrations/ew/resilience.lua"]={pre_init=function() end,post_init=function() return 0,0,0 end}
 stub["mods/metamorph_creative_menu/files/integrations/ew/perk_sync.lua"]={update=function() end}
 stub["mods/metamorph_creative_menu/files/features/perks/service.lua"]={update=function() end}
 stub["mods/metamorph_creative_menu/files/features/effects/service.lua"]={update=function() end}
 stub["mods/metamorph_creative_menu/files/features/companion/player_avatar.lua"]={update=function() end}
 local old_dofile,old_once=dofile,dofile_once
 dofile_once=function() end
 dofile=function(path)
  loaded[path]=(loaded[path] or 0)+1
  if path=="mods/metamorph_creative_menu/dev_mode.lua" then return mode end
  if stub[path] then return stub[path] end
  error("unexpected init dependency: "..tostring(path))
 end
 ModLuaFileAppend=function() end; ModIsEnabled=function() return false end; ModDoesFileExist=function() return false end
 print=function() end
 METAMORPH_CREATIVE_MENU_DEV_MODE=nil
 assert(loadfile(root.."/init.lua"))()
 OnWorldPreUpdate()
 dofile,dofile_once=old_dofile,old_once
 return loaded,calls,METAMORPH_CREATIVE_MENU_DEV_MODE
end

local release_loaded,release_calls,release_flag=run(0)
assert(release_flag==false,"dev_mode=0 did not expose release flag")
assert(release_loaded["mods/metamorph_creative_menu/files/diagnostics/service.lua"]==nil,"release mode loaded diagnostics service")
assert(release_loaded["mods/metamorph_creative_menu/files/qa/controller.lua"]==nil,"release mode loaded Z QA controller")
assert(release_calls.diagnostics==0 and release_calls.qa==0,"release mode executed diagnostics/QA update")
local dev_loaded,dev_calls,dev_flag=run(1)
assert(dev_flag==true,"dev_mode=1 did not expose developer flag")
assert(dev_loaded["mods/metamorph_creative_menu/files/diagnostics/service.lua"]==1 and dev_loaded["mods/metamorph_creative_menu/files/qa/controller.lua"]==1,"developer mode did not load diagnostics/QA")
assert(dev_calls.diagnostics==1 and dev_calls.qa==1,"developer mode did not execute diagnostics/QA update")
io.write("dev_mode_runtime_gate=PASS default=0 release_unloaded=true developer_loaded=true\n")
