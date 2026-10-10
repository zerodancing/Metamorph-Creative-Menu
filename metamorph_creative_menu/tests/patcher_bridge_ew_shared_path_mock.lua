local root=assert(arg[1],"root required")
METAMORPH_CREATIVE_MENU_BRIDGE_API=nil
METAMORPH_CREATIVE_MENU_NP=nil
np=nil
local local_loader="mods/metamorph_creative_menu/NoitaPatcher/load.lua"
local ew_loader="mods/quant.ew/NoitaPatcher/load.lua"
local loaded={}
GameGetFrameNum=function() return 400 end
ModIsEnabled=function(id) return id=="quant.ew" end
ModDoesFileExist=function(path) return path==local_loader or path==ew_loader end
dofile_once=function(path)
 loaded[#loaded+1]=path
 assert(path==ew_loader,"MCM bootstrapped a second physical NoitaPatcher while EW is active: "..tostring(path))
 np={SerializeEntity=function() return "shared" end}
end
local bridge=assert(loadfile(root.."/files/platform/noita/patcher_bridge.lua"))()
local got=bridge.get({bootstrap_if_installed=true,capability="SerializeEntity"})
assert(got==np and #loaded==1 and loaded[1]==ew_loader,"EW shared NoitaPatcher path was not reused")
print("patcher_bridge_ew_shared_path=PASS same_physical_loader=true split_crosscall_registry_avoided=true")
