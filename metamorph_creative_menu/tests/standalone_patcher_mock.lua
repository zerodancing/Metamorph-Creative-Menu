local root=assert(arg[1],"root required")
local bridge_path=root.."/files/platform/noita/patcher_bridge.lua"
local local_loader="mods/metamorph_creative_menu/NoitaPatcher/load.lua"

local function reset()
  METAMORPH_CREATIVE_MENU_BRIDGE_API=nil
  METAMORPH_CREATIVE_MENU_NP=nil
  np=nil
end

-- Standalone: quant.ew is absent/disabled; an explicit MCM feature must bootstrap
-- the locally bundled NoitaPatcher instead.
reset()
local bootstraps=0
GameGetFrameNum=function() return 100 end
ModIsEnabled=function(id) assert(id=="quant.ew"); return false end
ModDoesFileExist=function(path) return path==local_loader end
dofile_once=function(path)
  assert(path==local_loader,"unexpected bootstrap path: "..tostring(path))
  bootstraps=bootstraps+1
  np={SerializeEntity=function() return "backup" end}
end
local bridge=assert(loadfile(bridge_path))()
local standalone=bridge.get({bootstrap_if_installed=true,capability="SerializeEntity"})
assert(standalone==np and type(standalone.SerializeEntity)=="function","standalone local bootstrap failed")
assert(bootstraps==1,"local NoitaPatcher was not bootstrapped exactly once")

-- Compatibility: when EW (or another mod) already published a working np table,
-- MCM must reuse it and must not load a second local copy.
reset()
bootstraps=0
local external={SerializeEntity=function() return "ew-backup" end}
np=external
GameGetFrameNum=function() return 200 end
ModIsEnabled=function(id) assert(id=="quant.ew"); return true end
ModDoesFileExist=function(path) return path==local_loader end
dofile_once=function(path) bootstraps=bootstraps+1; error("local bootstrap must not run when np is already available") end
bridge=assert(loadfile(bridge_path))()
local compatible=bridge.get({bootstrap_if_installed=true,capability="SerializeEntity"})
assert(compatible==external,"existing EW/third-party NoitaPatcher bridge was not reused")
assert(bootstraps==0,"MCM loaded a duplicate NoitaPatcher despite existing np")

io.write("standalone_patcher=PASS standalone_bootstrap=true ew_reuse=true duplicate_load=false\n")
