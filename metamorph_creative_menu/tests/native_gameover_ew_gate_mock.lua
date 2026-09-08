local root=assert(arg[1],"root required")
local native_require=require
local require_calls=0
ModIsEnabled=function(id) return id=="quant.ew" end
require=function(name) require_calls=require_calls+1; error("native require must not run in EW: "..tostring(name)) end
package.cpath="?.dll"
local patch=assert(loadfile(root.."/files/platform/noita/native_gameover_patch.lua"))()
local ok,reason=patch.install()
require=native_require
assert(ok==false and reason=="disabled_in_entangled_worlds","native Game Over patch was not disabled in EW")
assert(require_calls==0,"EW gate happened after native DLL require")
local status=patch.status()
assert(status.network_disabled==true and status.installed==false,"native EW-disabled status changed")
print("native_gameover_ew_gate=PASS require_skipped=true network_disabled=true")
