local root=assert(arg[1])
local expected={
 "apply_world_rules","request_world_rules","sync_qa_state","request_player_companion",
 "sync_form_pose","remove_global_perk","apply_weather_state","request_weather_state",
 "retire_possession_target","announce_light_form_protocol","sync_material_paint"
}
local recorded={}
local rpc=setmetatable({
 opts_reliable=function() end,
 opts_everywhere=function() end,
},{__newindex=function(t,k,v)
 rawset(t,k,v)
 if type(v)=="function" then recorded[#recorded+1]=k end
end})
local ew_api={new_rpc_namespace=function(ns)
 if ns=="metamorph_creative_menu:world_rules:v4:" then return rpc end
 assert(ns=="metamorph_creative_menu:teleport:v1:","namespace="..tostring(ns))
 return setmetatable({opts_reliable=function() end,opts_everywhere=function() end},{__newindex=rawset})
end}
GlobalsGetValue=function(_,default) return default end
GlobalsSetValue=function() end
ctx={my_id="me",host_id="me",my_player={entity=0},players={}}
local native_dofile=dofile
local function map(path)
 local prefix="mods/metamorph_creative_menu/"
 if string.sub(path,1,#prefix)==prefix then return root.."/"..string.sub(path,#prefix+1) end
 return path
end
dofile=function(path)
 if path=="mods/quant.ew/files/api/ew_api.lua" then return ew_api end
 return native_dofile(map(path))
end
dofile_once=function(path)
 if path=="mods/quant.ew/files/api/ew_api.lua" then return ew_api end
 return dofile(path)
end
local mod=assert(loadfile(root.."/files/integrations/ew/bootstrap.lua"))()
assert(type(mod)=="table" and type(mod.on_world_update)=="function")
assert(#recorded==#expected,"rpc count="..#recorded)
for i,name in ipairs(expected) do assert(recorded[i]==name,string.format("slot %d got %s expected %s",i,tostring(recorded[i]),name)) end
print("ew_protocol_order=PASS namespace=v4 slots="..table.concat(recorded,","))
