local root = assert(arg[1], "root required")
local native_dofile = dofile

METAMORPH_CREATIVE_MENU_FORM_MANAGER = nil
METAMORPH_CREATIVE_MENU_FORM_TRANSITION_QUEUE = nil

local frame = 100
local current_player = 1
local alive = {[1]=true,[10]=true,[11]=true,[90]=true,[91]=true}
local polymorphed = {[10]=true,[11]=true}
local active_poly_component = {[10]=201,[11]=202}
local effect_frames = {[201]=600,[202]=600,[301]=nil,[302]=nil}
local load_calls = {}
local human_seen_frames = {}
local runtime_resets = 0

local bridge = {
    SerializeEntity = function(entity)
        assert(entity == 1, "only the human may be serialized for a new MCM form")
        return "human-backup-" .. tostring(frame)
    end,
    CrossCallAdd = function() return true end,
}

local human_restore = {
    protect_player=function() end,
    restore_controls=function(entity)
        assert(entity == 1, "controls restored on non-human entity")
        return true
    end,
    polymorph_effect_components=function(entity)
        local component = active_poly_component[entity]
        return component ~= nil and {component} or {}
    end,
    serialized_backup_from_effects=function() return "serialized-human" end,
    deserialize_backup=function() return 0 end,
}

local stubs = {
    ["mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua"]={get=function() return bridge end},
    ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"]={get=function() return current_player end},
    ["mods/metamorph_creative_menu/files/platform/noita/keycodes.lua"]={resolve=function() return 15 end},
    ["mods/metamorph_creative_menu/files/features/forms/profile.lua"]={get=function(target) return {target=target} end},
    ["mods/metamorph_creative_menu/files/features/forms/runtime.lua"]={
        update=function() end,
        reset=function() runtime_resets=runtime_resets+1 end,
        family=function() return "character" end,
        draw_health=function() end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/exact_effects.lua"]={
        effect_path=function(path)
            if path == "data/entities/animals/a.xml" then return "mods/metamorph_creative_menu/files/generated/a.xml" end
            if path == "data/entities/animals/b.xml" then return "mods/metamorph_creative_menu/files/generated/b.xml" end
            return nil
        end,
        invalidate_failed_target=function() end,
        prepare=function() return 0 end,
        prepare_from_catalog=function() return 2 end,
        runtime_target=function(path) return path end,
        prepared_count=function() return 2 end,
        default_duration_frames=function() return 2147480000 end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/player_authority.lua"]={switch=function() return true,"confirmed" end},
    ["mods/metamorph_creative_menu/files/features/forms/transform_flash.lua"]={suppress=function() end,restore=function() end},
    ["mods/metamorph_creative_menu/files/features/forms/corpse_service.lua"]={detach=function() return true end,update=function() end},
    ["mods/metamorph_creative_menu/files/features/forms/human_restore.lua"]=human_restore,
    ["mods/metamorph_creative_menu/files/features/forms/external_polymorph.lua"]={is_active=function(entity) return polymorphed[entity]==true end,describe=function() return nil end},
    ["mods/metamorph_creative_menu/files/integrations/ew/form_death_channel.lua"]={register=function() return true end},
}

dofile=function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

function GameGetFrameNum() return frame end
function EntityGetIsAlive(entity) return alive[entity]==true end
function EntityHasTag(entity, tag)
    if tag=="polymorphed_player" then return polymorphed[entity]==true end
    if tag=="player_unit" then return entity==1 end
    return false
end
function EntityGetTransform(entity) return 100,200 end
function EntityGetComponentIncludingDisabled() return {} end
function EntityGetFirstComponentIncludingDisabled(entity, kind)
    if entity==1 and kind=="Inventory2Component" then return 77 end
    if entity==90 and kind=="GameEffectComponent" then return 301 end
    if entity==91 and kind=="GameEffectComponent" then return 302 end
    return 0
end
function EntityAddTag() end
function EntityAddComponent2() return 401 end
function ComponentGetValue2() return nil end
function ComponentSetValue2(component, field, value)
    if field=="frames" then effect_frames[component]=value end
end
function ModDoesFileExist(path)
    return path=="data/entities/animals/a.xml" or path=="data/entities/animals/b.xml"
end
function LoadGameEffectEntityTo(player, effect_file)
    load_calls[#load_calls+1]={frame=frame,player=player,effect=effect_file}
    assert(player==1, "new polymorph effect must only be attached to the human")
    if effect_file:match("/a%.xml$") then return 90 end
    if effect_file:match("/b%.xml$") then return 91 end
    return 0
end
function print() end

local manager=assert(native_dofile(root.."/files/features/forms/manager.lua"))
local transition_queue=assert(native_dofile(root.."/files/features/forms/transition_queue.lua"))

-- Any newer direct human selection supersedes an older queued target.
transition_queue.schedule("data/entities/animals/b.xml",nil,{requested_target="data/entities/animals/b.xml"},90)
assert(transition_queue.has_pending()==true,"queue fixture missing")

-- Human -> A remains immediate and clears that stale intent.
local ok,reason=manager.transform_creature(1,"data/entities/animals/a.xml",nil,false,{requested_target="data/entities/animals/a.xml"})
assert(ok==true, "initial transform failed: "..tostring(reason))
assert(#load_calls==1 and load_calls[1].frame==100, "initial human transform was unexpectedly deferred")
assert(transition_queue.has_pending()==false,"direct human transform did not clear older queued intent")

-- Engine resolves A on the next frame.
frame=101
current_player=10
manager.update()
assert(manager.session_phase()=="active", "first form did not become active")

-- F4 selection of B while A is active must queue B and expire A, not apply B to A.
local switch_ok,switch_reason=manager.transform_creature(10,"data/entities/animals/b.xml",nil,false,{requested_target="data/entities/animals/b.xml"})
assert(switch_ok==true and switch_reason=="queued_after_human", "mob->mob selection was not accepted as a queued switch")
assert(manager.has_pending_transform()==true, "queued switch was not retained")
assert(effect_frames[201]==1, "old form polymorph was not expired")
assert(#load_calls==1, "second polymorph was applied directly to the old mob")

-- Engine restores the actual human. This frame is intentionally human-only.
frame=102
current_player=1
manager.update()
human_seen_frames[#human_seen_frames+1]=frame
assert(manager.session_phase()=="human", "old form session survived human restoration")
assert(manager.has_pending_transform()==true, "queued target was lost on human restoration")
assert(#load_calls==1, "new form started on the same frame the human reappeared")

-- Only the following pre-update may start B. Therefore frame 102 was a complete
-- inter-form human frame from one OnWorldPreUpdate boundary to the next.
frame=103
manager.update()
assert(#load_calls==2, "queued second form did not start after the human frame")
assert(load_calls[2].frame==103 and load_calls[2].player==1, "second form did not start from the restored human")
assert(load_calls[2].effect:match("/b%.xml$"), "queued target changed")
assert(manager.session_phase()=="transforming", "second form did not create the normal MCM session")
assert(manager.has_pending_transform()==false, "queue survived after committing second transform")
assert(load_calls[2].frame-human_seen_frames[1]>=1, "human was not preserved for at least one frame between forms")

-- Stale requests are bounded even if an engine/mod transition never reaches human.
transition_queue.schedule("data/entities/animals/a.xml",nil,{},103)
assert(transition_queue.expire(133)==false and transition_queue.has_pending()==true,"transition request expired too early")
assert(transition_queue.expire(134)==true and transition_queue.has_pending()==false,"stale transition request survived TTL")

io.write("form_chained_transform_human_frame=PASS queued=true human_frame=1 direct_mob_to_mob=false direct_intent_replaces=true ttl=30\n")
