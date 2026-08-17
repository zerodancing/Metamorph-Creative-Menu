local root = assert(arg[1], "root required")
local native_dofile = dofile
local spawn_call = nil

local stubs = {
    ["mods/metamorph_creative_menu/files/features/perks/inverse_registry.lua"]={has=function() return false end},
    ["mods/metamorph_creative_menu/files/features/perks/transactions.lua"]={has=function() return false end},
    ["mods/metamorph_creative_menu/files/features/perks/root_companions.lua"]={supports=function() return false end, update=function() end, debug=function() return {} end},
    ["mods/metamorph_creative_menu/files/features/perks/nested_pickups.lua"]={update=function() end,debug_state=function() return {scopes=0,children=0} end},
    ["mods/metamorph_creative_menu/files/features/perks/locomotion_guard.lua"]={capture_if_idle=function() end,repair_if_idle=function() end,debug_baseline_count=function() return 0 end},
    ["mods/metamorph_creative_menu/files/features/perks/presentation.lua"]={update=function() end},
}
dofile=function(path)
    if stubs[path]~=nil then return stubs[path] end
    return native_dofile(path)
end
function EntityGetIsAlive(entity) return entity==1 end
function EntityGetTransform(entity) assert(entity==1); return 100,200 end
function perk_spawn(x,y,id) spawn_call={x=x,y=y,id=id}; return 77 end

local service=assert(native_dofile(root.."/files/features/perks/service.lua"))
local ok,reason,entity=service.spawn(1,{id="EXTRA_HP"})
assert(ok==true and reason=="spawned" and entity==77,"LMB perk spawn failed")
assert(spawn_call.x==112 and spawn_call.y==192 and spawn_call.id=="EXTRA_HP","perk world spawn placement/id changed")
io.write("perk_spawn=PASS lmb=true\n")
