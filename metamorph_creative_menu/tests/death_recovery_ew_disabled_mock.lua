local root=assert(arg[1],"root required")
local native_dofile=dofile
local native_calls={install=0,request=0}
local mocks={
 ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"]={get_human=function() return 1 end},
 ["mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua"]={get=function() error("bridge must not be used") end},
 ["mods/metamorph_creative_menu/files/platform/noita/native_gameover_patch.lua"]={
   install=function() native_calls.install=native_calls.install+1; return true,"bad" end,
   is_installed=function() return false end,
   has_revive_request=function() native_calls.request=native_calls.request+1; return true end,
   status=function() return {installed=false} end,
 },
 ["mods/metamorph_creative_menu/files/features/forms/human_restore.lua"]={},
 ["mods/metamorph_creative_menu/files/features/death_recovery/post_revive_cleanup.lua"]={status=function() return {} end},
 ["mods/metamorph_creative_menu/files/integrations/ew/runtime.lua"]={enabled=function() return true end},
}
dofile=function(path) if mocks[path]~=nil then return mocks[path] end return native_dofile(path) end
local service=assert(loadfile(root.."/files/features/death_recovery/service.lua"))()
local ok,reason=service.install(); assert(ok==false and reason=="disabled_in_entangled_worlds")
ok,reason=service.update(); assert(ok==false and reason=="disabled_in_entangled_worlds")
ok,reason=service.revive(); assert(ok==false and reason=="disabled_in_entangled_worlds")
assert(native_calls.install==0 and native_calls.request==0,"disabled EW recovery touched native backend")
assert(service.status().network_disabled==true,"EW-disabled state missing from service status")
print("death_recovery_ew_disabled=PASS native_backend_untouched=true form_system_separate=true")
