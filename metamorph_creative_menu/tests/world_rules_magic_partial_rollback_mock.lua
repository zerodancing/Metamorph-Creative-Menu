local root=assert(arg[1],"root required")
local native_dofile=dofile
local globals={}
local values={A=1,B=2}
local calls={A=0,B=0}
local fail_rollback=true
local bridge={}
function bridge.MagicNumbersSetValue(key,value)
 calls[key]=(calls[key] or 0)+1
 if key=="A" and calls.A==2 and fail_rollback then error("rollback failed") end
 if key=="B" and calls.B==1 then error("second write failed") end
 values[key]=tonumber(value)
end
function GlobalsGetValue(k,d) local v=globals[k]; if v==nil then return d end return v end
function GlobalsSetValue(k,v) globals[k]=tostring(v) end
function MagicNumbersGetValue(k) return tostring(values[k]) end
local stubs={
 ["mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua"]={get=function() return bridge end,bootstrap_available=function() return true end},
}
dofile=function(path)
 if stubs[path] then return stubs[path] end
 local prefix="mods/metamorph_creative_menu/"
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
METAMORPH_CREATIVE_MENU_WORLD_RULE_RECOVERY=nil
METAMORPH_CREATIVE_MENU_WORLD_RULE_MAGIC_NUMBERS=nil
local recovery=assert(native_dofile(root.."/files/features/world_rules/recovery.lua"))
local magic=assert(native_dofile(root.."/files/features/world_rules/magic_numbers.lua"))
local ok=magic.apply({"A","B"},10)
assert(ok==false,"partial multi-key failure reported success")
assert(values.A==10 and values.B==2,"fixture did not leave first key partially changed")
local recA=assert(recovery.read("magic","A"),"A recovery was erased after failed rollback")
assert(recA.phase=="partial" and tonumber(recA.last)==10,"A partial ownership was not preserved")
local recB=assert(recovery.read("magic","B"),"B captured baseline missing")
assert(recB.phase=="captured" and recB.last==nil,"failed B write incorrectly acquired ownership")
fail_rollback=false
values.B=7 -- external owner changed a baseline-only key after our failed write
local reset_ok=magic.reset_all()
assert(reset_ok==true,"retry reset did not finish partial rollback")
assert(values.A==1 and values.B==7,"retry reset overwrote external value on baseline-only key")
assert(recovery.read("magic","A")==nil and recovery.read("magic","B")==nil,"recovery metadata survived successful reset")
io.write("world_rules_magic_partial_rollback=PASS partial_retained=true retry_restored=true baseline_not_ownership=true\n")
