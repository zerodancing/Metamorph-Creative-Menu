local root = assert(arg[1], "root required")
local patches = assert(dofile(root.."/files/integrations/ew/resilience_patches.lua"))
local source = [[if not CrossCall("ew_is_wand_pickup") then
    EntityKill(GetUpdatedEntityID())
end]]
local changed, count = patches.patch_wand_pickup_killself_source(source)
assert(count==1 and string.find(changed,"mcm_wand_pickup_crosscall_guard_v1",1,true),"guard patch was not applied")

local killed=0
local env={
    CrossCall=function() error("Requested function does not exist") end,
    EntityKill=function(entity) assert(entity==77); killed=killed+1 end,
    GetUpdatedEntityID=function() return 77 end,
    pcall=pcall,
}
assert(load(changed,"guard","t",env))()
assert(killed==1,"missing EW callback left the helper alive")

env.CrossCall=function() return true end
assert(load(changed,"guard","t",env))()
assert(killed==1,"real wand pickup was incorrectly retired")

env.CrossCall=function() return false end
assert(load(changed,"guard","t",env))()
assert(killed==2,"normal false result no longer retires the helper")

io.write("ew_wand_pickup_guard=PASS missing_callback_retired=true registered_semantics_preserved=true\n")
