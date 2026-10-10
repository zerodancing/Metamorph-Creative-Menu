local root=assert(arg[1])
local native_dofile=dofile
dofile=function(path)
 local prefix="mods/metamorph_creative_menu/"
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
GlobalsGetValue=function(_,d) return d end
GlobalsSetValue=function() end
GameHasFlagRun=function() return false end
local api=assert(loadfile(root.."/files/features/perks/inverse_registry.lua"))()
assert(api.has("GAMBLE"))
local ok,reason=api.remove(1,"GAMBLE",1); assert(ok,reason)
assert(reason=="inverse_gamble_counter_only",tostring(reason))
print("gamble_counter_inverse=PASS reason="..reason)
