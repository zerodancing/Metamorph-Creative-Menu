local root=assert(arg[1],"root")
METAMORPH_CREATIVE_MENU_PERK_SERVICE=nil

local alive={[1]=true,[2]=true,[3]=true}
local tags={[3]={polymorphed_player=true}}
EntityGetIsAlive=function(e) return alive[e]==true end
EntityHasTag=function(e,t) return tags[e] and tags[e][t]==true or false end
GameGetFrameNum=function() return 100 end
GlobalsGetValue=function(_,d) return d end
get_perk_picked_flag_name=function(id) return "PERK_PICKED_"..id end

local rebind_calls={transactions={},inverses={},roots={},root_updates=0,presentation_updates=0}
local transactions={
 active_count=function() return 1 end,
 rebind_player=function(old,new) rebind_calls.transactions[#rebind_calls.transactions+1]={old,new}; if #rebind_calls.transactions==1 then return false,"unresolved_locators",0,1 end; return true,"rebound",1,0 end,
 has=function() return false end,
 begin=function(player,id) return {player=player,perk_id=id} end,
}
local inverses={
 capture_pre_pickup=function() return true end,
 rebind_player=function(old,new) rebind_calls.inverses[#rebind_calls.inverses+1]={old,new}; return true end,
 has=function() return false end,
 maintenance_cleanup=function() return true end,
}
local roots={
 supports=function() return false end,
 update=function() rebind_calls.root_updates=rebind_calls.root_updates+1 end,
 rebind_player=function(old,new) rebind_calls.roots[#rebind_calls.roots+1]={old,new}; return true end,
 debug=function() return "" end,
}
local presentation={update=function() rebind_calls.presentation_updates=rebind_calls.presentation_updates+1 end,rebind_player=function() return true end}
local native_dofile=dofile
dofile=function(path)
    if path=="mods/metamorph_creative_menu/files/features/perks/inverse_registry.lua" then return inverses end
    if path=="mods/metamorph_creative_menu/files/features/perks/transactions.lua" then return transactions end
    if path=="mods/metamorph_creative_menu/files/features/perks/root_companions.lua" then return roots end
    if path=="mods/metamorph_creative_menu/files/features/perks/presentation.lua" then return presentation end
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

local service=assert(native_dofile(root.."/files/features/perks/service.lua"))
service.begin_pickup(1,{id="TEST"}) -- establishes the pre-form human owner
service.update(3)                  -- polymorphed body: must never become the new owner
assert(#rebind_calls.transactions==0,"form body triggered perk rebind")
assert(rebind_calls.root_updates==0 and rebind_calls.presentation_updates==0,"human perk maintenance ran against polymorph body")
service.update(2)                  -- restored/deserialized human, tree may still be incomplete
assert(#rebind_calls.transactions==1,"restored human did not trigger transaction rebind")
assert(#rebind_calls.inverses==0 and #rebind_calls.roots==0,"failed rebind propagated to dependent ownership")
service.update(2)                  -- next frame must retry rather than accepting stale ids
assert(#rebind_calls.transactions==2,"failed rebind was not retried")
assert(rebind_calls.transactions[1][1]==1 and rebind_calls.transactions[1][2]==2,"wrong transaction rebind endpoints")
assert(rebind_calls.transactions[2][1]==1 and rebind_calls.transactions[2][2]==2,"retry lost original owner")
assert(#rebind_calls.inverses==1 and #rebind_calls.roots==1,"successful retry did not rebind dependent ownership")
print("perk_service_rebind_wiring=PASS form_body_paused=true restored_human_retry=true")
