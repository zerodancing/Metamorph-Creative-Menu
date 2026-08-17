local root=assert(arg[1],"root")
local patches=assert(dofile(root.."/files/integrations/ew/resilience_patches.lua"))
local fixture=[[
local rpc = net.new_rpc_namespace()
local homunculus = {}
local function get_entities(entity)
    if entity == 99 then return remote_h, remote_l, remote_g end
    return local_h, local_l, local_g
end
rpc.opts_reliable()
function rpc.send_positions(ho, lu, gh, f)
    local h, l, g = get_entities(ctx.rpc_player_data.entity)
    if #ho ~= 0 then
        for i, child in ipairs(h) do
            if ho[i] == nil then EntityKill(child) end
        end
    end
    if #lu ~= 0 then
        for i, child in ipairs(l) do
            if lu[i] == nil then EntityKill(child) end
        end
    end
    if #gh ~= 0 then
        for i, child in ipairs(g) do
            if gh[i] == nil then EntityKill(child) end
        end
    end
end
function homunculus.on_world_update()
    local h, l, g = get_entities(ctx.my_player.entity)
    local ho, lu, gh = {}, {}, {}
    for _, child in ipairs(h) do table.insert(ho, { child, 0 }) end
    for _, child in ipairs(l) do table.insert(lu, { child, 0, 0 }) end
    for _, child in ipairs(g) do table.insert(gh, { child, 0, 0 }) end
    if #ho ~= 0 or #lu ~= 0 or #gh ~= 0 then
        rpc.send_positions(ho, lu, gh, GameGetFrameNum())
    end
end
return homunculus
]]
local patched,count=patches.patch_perk_helper_sync_source(fixture)
assert(count==1,"perk-helper patch did not apply")
assert(string.find(patched,"mcm_perk_helper_sync_v1",1,true),"helper sync marker missing")
local again,count2=patches.patch_perk_helper_sync_source(patched)
assert(count2==0 and again==patched,"perk-helper patch is not idempotent")

local killed={}
local sent={}
local rpc={}
net={new_rpc_namespace=function() return rpc end}
rpc.opts_reliable=function() end
ctx={rpc_player_data={entity=99},my_player={entity=1}}
remote_h={201}; remote_l={202}; remote_g={203}
local_h={101}; local_l={}; local_g={}
EntityKill=function(e) killed[e]=(killed[e] or 0)+1 end
local globals={}
GlobalsSetValue=function(k,v) globals[k]=tostring(v) end
GameGetFrameNum=(function() local f=0 return function() f=f+1 return f end end)()

assert(load(patched))()
assert(globals.mcm_perk_helper_sync_loaded_v1=="1","helper runtime loaded marker missing")
-- Replace transport with a spy after the patched receiver itself has already been tested.
rpc.send_positions({}, {}, {}, GameGetFrameNum())
assert(killed[201]==1 and killed[202]==1 and killed[203]==1,"empty helper snapshot did not retire all remote helper classes")

-- Reload so on_world_update uses a transport spy; it must send once while non-empty and
-- one final authoritative empty packet when the last local helper disappears.
rpc={}
net={new_rpc_namespace=function() return rpc end}
rpc.opts_reliable=function() end
ctx={rpc_player_data={entity=99},my_player={entity=1}}
remote_h={}; remote_l={}; remote_g={}
local_h={101}; local_l={}; local_g={}
assert(load(patched))()
local original_send=rpc.send_positions
rpc.send_positions=function(ho,lu,gh,f)
    sent[#sent+1]={#ho,#lu,#gh}
end
local module=assert((function() -- module table is already returned by the previous load; reload once for a captured reference
    rpc={}; net={new_rpc_namespace=function() return rpc end}; rpc.opts_reliable=function() end
    ctx={rpc_player_data={entity=99},my_player={entity=1}}
    local m=assert(load(patched))()
    local real=rpc.send_positions
    rpc.send_positions=function(ho,lu,gh,f) sent[#sent+1]={#ho,#lu,#gh} end
    return m
end)())
module.on_world_update()
local_h={}; local_l={}; local_g={}
module.on_world_update()
module.on_world_update()
assert(#sent==2,"sender must emit active snapshot plus one final empty snapshot, got "..#sent)
assert(sent[1][1]==1 and sent[2][1]==0 and sent[2][2]==0 and sent[2][3]==0,"final helper snapshot was not empty")
print("ew_perk_helper_sync_patch=PASS empty_reconcile=true final_empty_snapshot=true existing_rpc=true")
