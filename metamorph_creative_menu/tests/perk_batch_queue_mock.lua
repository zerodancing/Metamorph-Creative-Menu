local root=assert(arg[1],"root required")
local native_dofile=dofile
local frame=100
local globals={}
local alive={[1]=true,[2]=true}
local next_entity=1000
local entity_perk={}
local begin_count=0
local commit_count=0
local inverse_remove_count=0
local visibility_syncs=0
local inventory_syncs=0
local pickup_attempts={}
local fail_at={}
local untracked={}
local scopes={}

local transactions={
    begin=function(player,perk_id)
        begin_count=begin_count+1
        return {player=player,perk_id=perk_id,transaction_id=begin_count}
    end,
    start_capture=function() return true end,
    stop_capture=function() end,
    commit=function(token)
        commit_count=commit_count+1
        if untracked[tostring(token and token.perk_id or "")] then return false,"removed_component" end
        return true,"tracked"
    end,
    revert_transaction=function() return true,"reverted" end,
    has=function() return false end,
    active_count=function() return 0 end,
    source_count=function(perk_id) return tonumber(globals["PERK_PICKED_"..tostring(perk_id).."_PICKUP_COUNT"]) or 0 end,
}
local inverses={
    capture_pre_pickup=function() end,
    has=function(perk_id) return tostring(perk_id)~="UNSAFE" end,
    remove=function() inverse_remove_count=inverse_remove_count+1 return true,"inverse" end,
    zero_cleanup=function() end,
    maintenance_cleanup=function() end,
    post_tracked_cleanup=function() end,
}
local root_companions={
    supports=function() return false end,capture_before=function() return nil end,commit=function() end,
    abort_pickup=function() end,update=function() end,on_count_zero=function() end,debug=function() return {} end,
}
local nested={
    open_gamble_scope=function(player,tx) scopes[tx]={player=player,open=true}; return true end,
    scope_open=function(player,tx) local s=scopes[tx]; return s~=nil and s.player==player and s.open==true end,
    update=function() end,children=function() return {} end,clear_parent=function() end,register_child=function() end,
    state_snapshot=function() return {scopes=0,children=0} end,
}
local presentation={
    expire_one_game_effect=function() end,on_count_zero=function() end,update=function() end,
    rebind_player=function() end,
}
local locomotion={capture_if_idle=function() end,repair_if_idle=function() end,baseline_count=function() return 0 end}
local ew_visibility={refresh=function() visibility_syncs=visibility_syncs+1 return true end}
local ew_runtime={force_inventory_sync=function() inventory_syncs=inventory_syncs+1 return true end}
local ew_world={notify_world_item=function() return true end}

dofile=function(path)
    if path=="mods/metamorph_creative_menu/files/features/perks/inverse_registry.lua" then return inverses end
    if path=="mods/metamorph_creative_menu/files/features/perks/transactions.lua" then return transactions end
    if path=="mods/metamorph_creative_menu/files/features/perks/root_companions.lua" then return root_companions end
    if path=="mods/metamorph_creative_menu/files/features/perks/nested_pickups.lua" then return nested end
    if path=="mods/metamorph_creative_menu/files/features/perks/presentation.lua" then return presentation end
    if path=="mods/metamorph_creative_menu/files/features/perks/locomotion_guard.lua" then return locomotion end
    if path=="mods/metamorph_creative_menu/files/integrations/ew/perk_visibility.lua" then return ew_visibility end
    if path=="mods/metamorph_creative_menu/files/integrations/ew/runtime.lua" then return ew_runtime end
    if path=="mods/metamorph_creative_menu/files/integrations/ew/world_items.lua" then return ew_world end
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

EntityGetIsAlive=function(id) return alive[id]==true end
EntityHasTag=function() return false end
EntityGetTransform=function(id) if alive[id] then return 10,20 end end
EntityGetName=function(id) return entity_perk[id] or "mock" end
EntityGetRootEntity=function(id) return id end
EntityGetComponentIncludingDisabled=function() return {} end
EntitySetComponentIsEnabled=function() end
EntityKill=function(id) alive[id]=false end
GameGetFrameNum=function() return frame end
GlobalsGetValue=function(k,d) return globals[k] or d end
GlobalsSetValue=function(k,v) globals[k]=tostring(v) end
GameRemoveFlagRun=function() end
GameAddFlagRun=function() end
get_perk_picked_flag_name=function(id) return "PERK_PICKED_"..tostring(id) end
perk_spawn=function(_,_,perk_id)
    next_entity=next_entity+1; alive[next_entity]=true; entity_perk[next_entity]=perk_id; return next_entity
end
perk_pickup=function(entity,player)
    local id=assert(entity_perk[entity],"missing perk id")
    pickup_attempts[id]=(pickup_attempts[id] or 0)+1
    if fail_at[id]~=nil and pickup_attempts[id]==fail_at[id] then error("forced_"..id) end
    local key="PERK_PICKED_"..id.."_PICKUP_COUNT"
    globals[key]=tostring((tonumber(globals[key]) or 0)+1)
end

local service=assert(native_dofile(root.."/files/features/perks/service.lua"))
local function perk(id) return {id=id,func=function() end,ui_name=id} end
local function count(id) return tonumber(globals["PERK_PICKED_"..id.."_PICKUP_COUNT"]) or 0 end
local function pump(job_id,max_frames)
    local max_ops=0
    for _=1,(max_frames or 200) do
        if service.job_status()==nil then break end
        local before=begin_count
        frame=frame+1
        service.update(1)
        max_ops=math.max(max_ops,begin_count-before)
    end
    assert(service.job_status()==nil,"job did not finish: "..tostring(job_id))
    return max_ops
end

-- Queue supports exactly the selectable 1/10/100 sizes, with a fixed four-op budget.
for _,amount in ipairs({1,10,100}) do
    local id="TAKE"..amount
    local sync_before=inventory_syncs
    local begin_before=begin_count
    local ok,reason,job_id=service.start_take_job(1,perk(id),amount)
    assert(ok,reason)
    local max_ops=pump(job_id,80)
    assert(count(id)==amount,"wrong queue count for "..amount)
    assert(begin_count-begin_before==amount,"each copy must begin its own transaction")
    assert(max_ops<=4,"batch exceeded per-frame budget")
    local expected_groups=math.ceil(amount/4)
    assert(inventory_syncs-sync_before==expected_groups,"deferred inventory sync was not grouped")
end
assert(commit_count==111,"every queued copy must commit independently")

-- Vanilla may successfully apply a perk whose destructive mutation cannot be safely
-- inverted. The queue must stop, but the already-applied copy still counts and must be
-- included in the grouped sync before the terminal notice is published.
untracked.UNTRACKED=true
local untracked_sync_before=inventory_syncs
assert(service.start_take_job(1,perk("UNTRACKED"),10))
frame=450; service.update(1)
assert(service.job_status()==nil and count("UNTRACKED")==1,"untracked successful pickup was lost or queue continued")
assert(inventory_syncs-untracked_sync_before==1,"untracked successful pickup was not synchronized")
local untracked_notice=assert(service.consume_job_notice(),"missing untracked terminal notice")
assert(untracked_notice.completed==1 and untracked_notice.reason=="transaction:removed_component",
    "untracked terminal status did not describe the applied prefix")

-- Normal separate clicks are no longer suppressed for 15 frames; only same-frame repeat is.
local direct=perk("DIRECT")
frame=500
local ok1,r1=service.apply(1,direct)
frame=501
local ok2,r2=service.apply(1,direct)
local ok3,r3=service.apply(1,direct)
assert(ok1 and ok2 and r1=="applied" and r2=="applied","separate-frame clicks were debounced")
assert(ok3==false and r3=="debounced","same-frame duplicate command was not blocked")
assert(count("DIRECT")==2,"direct click count mismatch")

-- Stop on first error, retain already committed copies, and report the exact canonical reason once.
local err=perk("ERROR")
fail_at.ERROR=4
local sync_before_error=inventory_syncs
assert(service.start_take_job(1,err,10))
frame=600; service.update(1)
assert(service.job_status()==nil,"failed job remained active")
assert(count("ERROR")==3,"failed batch rolled back previously confirmed copies")
assert(inventory_syncs-sync_before_error==1,"successful prefix was not flushed once")
local notice=assert(service.consume_job_notice(),"missing failure notice")
assert(notice.state=="error" and notice.reason=="pickup_failed","wrong failure reason: "..tostring(notice.reason))
assert(service.consume_job_notice()==nil,"failure notice repeated")

-- Cancellation preserves the completed prefix and prevents further application.
local cancel=perk("CANCEL")
assert(service.start_take_job(1,cancel,100))
frame=700; service.update(1)
assert(count("CANCEL")==4,"first cancel batch budget mismatch")
assert(service.cancel_job())
for _=1,3 do frame=frame+1; service.update(1) end
assert(count("CANCEL")==4 and service.job_status()==nil,"cancelled job continued")
local cancel_notice=assert(service.consume_job_notice()); assert(cancel_notice.state=="cancelled")

-- A vanished or changed local player stops the job before it can touch another entity.
local vanish=perk("VANISH")
assert(service.start_take_job(1,vanish,10)); alive[1]=false; frame=800; service.update(1)
assert(count("VANISH")==0 and service.job_status()==nil,"vanished player job applied a perk")
assert(service.consume_job_notice().reason=="player_changed"); alive[1]=true
local changed=perk("CHANGED")
assert(service.start_take_job(1,changed,10)); frame=801; service.update(2)
assert(count("CHANGED")==0 and service.job_status()==nil,"job migrated to another player")
assert(service.consume_job_notice().reason=="player_changed")

-- GAMBLE opens a nested async scope. No second instance may start until that exact scope closes.
local gamble=perk("GAMBLE")
assert(service.start_take_job(1,gamble,10)); frame=900; service.update(1)
local g=assert(service.job_status()); assert(g.completed==1 and g.waiting_async==true,"GAMBLE did not enter async wait")
local attempts_after_first=pickup_attempts.GAMBLE
frame=901; service.update(1)
assert(pickup_attempts.GAMBLE==attempts_after_first,"next GAMBLE started before nested transaction settled")
local waiting_tx=nil
for tx,s in pairs(scopes) do if s.open then waiting_tx=tx end end
assert(waiting_tx~=nil); scopes[waiting_tx].open=false
frame=902; service.update(1)
g=assert(service.job_status()); assert(g.completed==2 and g.waiting_async==true,"GAMBLE did not resume exactly one instance")
assert(service.cancel_job()); service.consume_job_notice()

-- REMOVE ALL is likewise budgeted; it never performs the old synchronous UI loop.
local rem=perk("REMOVE")
globals.PERK_PICKED_REMOVE_PICKUP_COUNT="11"
local inv_before=inverse_remove_count
assert(service.start_remove_all_job(1,rem))
local max_remove=0
for _=1,10 do
    if service.job_status()==nil then break end
    local before=inverse_remove_count
    frame=frame+1; service.update(1)
    max_remove=math.max(max_remove,inverse_remove_count-before)
end
assert(service.job_status()==nil and count("REMOVE")==0,"REMOVE ALL did not finish")
assert(inverse_remove_count-inv_before==11,"REMOVE ALL operation count mismatch")
assert(max_remove<=4,"REMOVE ALL exceeded per-frame budget")

local unsafe={id="UNSAFE",func=function() end}
globals.PERK_PICKED_UNSAFE_PICKUP_COUNT="3"
local unsafe_ok,unsafe_reason=service.start_remove_all_job(1,unsafe)
assert(unsafe_ok==false and unsafe_reason=="requires_inverse","unsafe perk entered removal queue")

print("perk_batch_queue=PASS amounts=1,10,100 budget=4 transaction_per_copy=true debounce=same_frame sync_grouped=true error_stop=true cancel=true player_guard=true gamble_wait=true remove_all_bounded=true")
