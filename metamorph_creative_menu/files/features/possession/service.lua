if type(METAMORPH_CREATIVE_MENU_POSSESSION) == "table" then return METAMORPH_CREATIVE_MENU_POSSESSION end

local possession_service = {}
local form_manager = dofile("mods/metamorph_creative_menu/files/features/forms/manager.lua")
local ew_runtime = dofile("mods/metamorph_creative_menu/files/integrations/ew/runtime.lua")
local targeting = dofile("mods/metamorph_creative_menu/files/features/possession/targeting.lua")
local retirement = dofile("mods/metamorph_creative_menu/files/features/possession/retirement.lua")
local ew_retirement = dofile("mods/metamorph_creative_menu/files/integrations/ew/possession_retire.lua")

-- Possession is a request pipeline, not a second transformation implementation:
--   any form -> HUMAN -> one full human frame -> teleport -> native creature transform.
-- This preserves the global HUMAN -> FORM -> HUMAN invariant even when possession is
-- requested while already transformed.
local pending = nil

local function valid(entity) return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity) end

local function target_position(record)
    if record == nil then return nil end
    if valid(record.target) then
        local target_x, target_y = EntityGetTransform(record.target)
        if target_x ~= nil then
            record.last_x, record.last_y = target_x, target_y
            return target_x, target_y
        end
    end
    return record.last_x, record.last_y
end

local function protect_for_transfer(player)
    local damage = valid(player) and EntityGetFirstComponentIncludingDisabled(player, "DamageModelComponent") or nil
    if damage ~= nil and damage ~= 0 then
        local current = tonumber(ComponentGetValue2(damage, "invincibility_frames")) or 0
        pcall(ComponentSetValue2, damage, "invincibility_frames", math.max(current, 6))
        pcall(ComponentSetValue2, damage, "kill_now", false)
    end
end

local function place_human_at_target(player, record)
    if not valid(player) then return false end
    local target_x, target_y = target_position(record)
    if target_x == nil then return false end
    pcall(EntitySetTransform, player, target_x, target_y)
    local data = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
    if data ~= nil and data ~= 0 then pcall(ComponentSetValue2, data, "mVelocity", 0, 0) end
    protect_for_transfer(player)
    return true
end

local function clear_failed(_, restore_position)
    local record = pending
    if restore_position == true and record ~= nil then
        local player = form_manager.current_player()
        if valid(player) and form_manager.is_human_ready(player)
            and record.origin_x ~= nil and record.origin_y ~= nil then
            pcall(EntitySetTransform, player, record.origin_x, record.origin_y)
            local data = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
            if data ~= nil and data ~= 0 then pcall(ComponentSetValue2, data, "mVelocity", 0, 0) end
        end
    end
    pending = nil
end

local function begin_transform(player, record)
    pcall(form_manager.prepare_exact_effect_paths, { record.actual_path })
    return form_manager.transform_creature(player, record.actual_path, nil, true, {
        requested_target = record.path,
        compatibility_mode = record.compatibility_mode,
        profile_target = record.actual_path,
        role = "creature",
        form_strategy = "possession_native",
    })
end

function possession_service.target_under_cursor(player, radius)
    return targeting.target_under_cursor(player, radius)
end


local function begin_possession_target(player, target)
    if pending ~= nil then return false, "pending" end
    if not valid(player) then return false, "player" end
    if not valid(target) then return false, "no_target" end
    local filename = tostring(EntityGetFilename(target) or "")
    if filename == "" or not ModDoesFileExist(filename) then return false, "no_filename" end
    if not targeting.is_creature(target, player) then return false, "not_creature" end

    local actual_path, compatibility_mode = targeting.transform_plan(filename)

    local tx, ty = EntityGetTransform(target)
    local origin_x, origin_y = EntityGetTransform(player)
    pending = {
        target = target,
        path = filename,
        actual_path = actual_path,
        compatibility_mode = compatibility_mode,
        name = tostring(EntityGetName(target) or ""),
        started = GameGetFrameNum(),
        last_x = tx,
        last_y = ty,
        origin_x = origin_x,
        origin_y = origin_y,
        phase = "returning",
        human_frame = -1,
        transform_frame = -1,
    }

    if form_manager.is_human_ready(player) then
        if not place_human_at_target(player, pending) then clear_failed("target_position"); return false, "target_position" end
        pending.phase = "human_frame"
        pending.human_frame = GameGetFrameNum()
        return true, "pending"
    end

    local ok, reason = form_manager.return_to_human()
    if not ok then clear_failed("return_" .. tostring(reason or "failed")); return false, reason end
    return true, "returning"
end

function possession_service.possess_entity(player, target)
    return begin_possession_target(player, target)
end

function possession_service.possess_under_cursor(player)
    if pending ~= nil then return false, "pending" end
    if not valid(player) then return false, "player" end
    local target = possession_service.target_under_cursor(player, 32)
    if not valid(target) and ew_runtime.mode() == "client" then
        -- The client's visual remote pose can be ahead of the local authoritative entity
        -- by a few dozen pixels. Keep the exact cursor behavior first, then use a bounded
        -- fallback instead of treating a synchronization offset as "no target".
        target = possession_service.target_under_cursor(player, 64)
    end
    if not valid(target) then return false, "no_target" end
    return begin_possession_target(player, target)
end

function possession_service.update()
    if pending == nil then return end
    local frame = GameGetFrameNum()
    if frame - (tonumber(pending.started) or frame) > 240 then clear_failed("timeout"); return end

    target_position(pending) -- keep last known position while the original mob is alive
    local player = form_manager.current_player()

    if pending.phase == "returning" then
        if form_manager.is_human_ready(player) then
            if not place_human_at_target(player, pending) then clear_failed("target_position"); return end
            pending.phase = "human_frame"
            pending.human_frame = frame
        end
        return
    end

    if pending.phase == "human_frame" then
        if not form_manager.is_human_ready(player) then return end
        -- Require one complete update boundary in human form.  This prevents a second
        -- polymorph effect from being layered onto a still-tearing-down old form.
        if frame <= (tonumber(pending.human_frame) or frame) then return end
        place_human_at_target(player, pending)
        local ok, reason = begin_transform(player, pending)
        if not ok then clear_failed("transform_" .. tostring(reason or "failed"), true); return end
        pending.phase = "committing"
        pending.transform_frame = frame
        return
    end

    if pending.phase == "committing" then
        player = form_manager.current_player()
        local actual_target_path = type(form_manager.session_actual_target) == "function"
            and form_manager.session_actual_target() or form_manager.session_target()
        if valid(player) and EntityHasTag(player, "polymorphed_player") and actual_target_path == pending.actual_path then
            if valid(pending.target) and pending.target ~= player then
                if ew_retirement.is_owned_locally(pending.target) then
                    retirement.retire_without_death_side_effects(pending.target)
                else
                    ew_retirement.queue_remote(pending.path, pending.last_x, pending.last_y)
                end
            end
            pending = nil
            return
        end
        if frame - (tonumber(pending.transform_frame) or frame) > 120 then
            clear_failed("commit_timeout", true)
        end
    end
end

METAMORPH_CREATIVE_MENU_POSSESSION = possession_service
return possession_service
