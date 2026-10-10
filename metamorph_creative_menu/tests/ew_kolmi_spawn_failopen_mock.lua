local root=assert(arg[1],"root required")
local patches=assert(loadfile(root.."/files/integrations/ew/resilience_patches.lua"))()
local source=[[
local old = item_pickup
function item_pickup(ent, _, _, run)
    if run == nil then
        local gid
        for _, v in ipairs(EntityGetComponent(ent, "VariableStorageComponent") or {}) do
            if ComponentGetValue2(v, "name") == "ew_gid_lid" then gid = v break end
        end
        if gid ~= nil and not ComponentGetValue2(gid, "value_bool") then
            CrossCall("ew_spawn_kolmi", ComponentGetValue2(gid, "value_string"))
        else
            old(ent)
        end
    else
        old(ent)
    end
end
]]
local patched,count=patches.patch_kolmi_spawn_source(source)
assert(count==1 and string.find(patched,"mcm_kolmi_spawn_crosscall_failopen_v1",1,true),"Sampo fail-open patch missing")
local old_calls=0
item_pickup=function() old_calls=old_calls+1 end
EntityGetComponent=function() return {11} end
ComponentGetValue2=function(id,key)
 if key=="name" then return "ew_gid_lid" end
 if key=="value_bool" then return false end
 if key=="value_string" then return "123" end
end
CrossCall=function() error("split registry") end
assert(load(patched))()
local ok=pcall(item_pickup,5,nil,nil,nil)
assert(ok,"remote Sampo CrossCall failure escaped wrapper")
assert(old_calls==1,"remote Sampo fail-open did not fall back to vanilla pickup")
print("ew_kolmi_spawn_failopen=PASS split_registry_falls_back_to_vanilla=true")
