local root=assert(arg[1],"root required")
local native_dofile=dofile
local globals={}
local values={DAMAGE_BLOOD_AMOUNT_MIN=0.25,DAMAGE_BLOOD_AMOUNT_MAX=0.75}
local set_calls=0
function GlobalsGetValue(key,fallback) local v=globals[key]; if v==nil then return fallback end; return v end
function GlobalsSetValue(key,value) globals[key]=tostring(value) end
function MagicNumbersGetValue(key) return tostring(assert(values[key],"unknown magic key")) end
local bridge={MagicNumbersSetValue=function(key,value) set_calls=set_calls+1; values[key]=tonumber(value) end}
local stubs={
 ["mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua"]={get=function() return bridge end,bootstrap_available=function() return true end},
 ["mods/metamorph_creative_menu/files/core/rule_math.lua"]={same=function(a,b) return math.abs((tonumber(a)or 0)-(tonumber(b)or 0))<1e-9 end},
}
dofile=function(path)
 if stubs[path]~=nil then return stubs[path] end
 local prefix="mods/metamorph_creative_menu/"; if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
local keys={"DAMAGE_BLOOD_AMOUNT_MIN","DAMAGE_BLOOD_AMOUNT_MAX"}
METAMORPH_CREATIVE_MENU_WORLD_RULE_RECOVERY=nil
METAMORPH_CREATIVE_MENU_WORLD_RULE_MAGIC_NUMBERS=nil
local magic=assert(native_dofile(root.."/files/features/world_rules/magic_numbers.lua"))
assert(magic.apply(keys,10)==true,"10x blood amount apply failed")
assert(math.abs(values[keys[1]]-2.5)<1e-9 and math.abs(values[keys[2]]-7.5)<1e-9,"10x blood amount used wrong baseline")
assert(magic.apply(keys,0.5)==true,"0.5x blood amount apply failed")
assert(math.abs(values[keys[1]]-0.125)<1e-9 and math.abs(values[keys[2]]-0.375)<1e-9,"blood multiplier compounded from current instead of original")
local calls_before=set_calls
assert(magic.apply(keys,0.5)==true,"steady-state blood reassert failed")
assert(set_calls==calls_before,"steady-state magic rule made redundant patcher writes")
assert(magic.restore(keys)==true,"blood amount NATIVE restore failed")
assert(math.abs(values[keys[1]]-0.25)<1e-9 and math.abs(values[keys[2]]-0.75)<1e-9,"blood amount did not restore exact native values")

-- Simulate a new Lua session while the rule was active and confirm persisted recovery.
assert(magic.apply(keys,10)==true)
METAMORPH_CREATIVE_MENU_WORLD_RULE_MAGIC_NUMBERS=nil
local magic2=assert(native_dofile(root.."/files/features/world_rules/magic_numbers.lua"))
local rules={{kind="magic_multiplier",magic_keys=keys}}
assert(magic2.has_persisted_recovery(rules)==true,"restart fixture lost magic recovery record")
assert(magic2.recover_persisted(rules)==true,"restart magic recovery failed")
assert(math.abs(values[keys[1]]-0.25)<1e-9 and math.abs(values[keys[2]]-0.75)<1e-9,"restart magic recovery left blood multiplier active")
assert(magic2.has_persisted_recovery(rules)==false,"restart magic recovery record leaked")

io.write("world_rules_magic_multiplier=PASS no_compound=true native_restore=true restart_restore=true\n")
