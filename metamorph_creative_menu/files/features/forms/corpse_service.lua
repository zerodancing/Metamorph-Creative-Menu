local corpse_service = {}

local NETWORK_FORM_TAG = "metamorph_creative_menu_network_form"
local POLYMORPH_EFFECTS = {
    "POLYMORPH", "POLYMORPH_RANDOM", "POLYMORPH_UNSTABLE", "POLYMORPH_CESSATION",
}

local pending_corpse_watch = {}
local pending_corpse_finalize = {}

local function diagnostic_event(kind, details)
    if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_EVENT) == "function" then
        pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_EVENT, tostring(kind or "FORM"), tostring(details or ""))
    end
end

local CORPSE_PLAYER_TAGS = {
    -- A dead player-form must become an ordinary world entity. In particular remove
    -- ew_no_enemy_sync: EW adds it to polymorphed players, and DES explicitly excludes
    -- that tag even when ew_synced is present.
    "polymorphed_player", "player_unit", "ew_peer", "ew_client", NETWORK_FORM_TAG,
    "ew_no_enemy_sync", "teleportable",
}

local CORPSE_FREEZE_COMPONENTS = {
    "ControlsComponent", "AnimalAIComponent", "WormAIComponent", "PhysicsAIComponent",
    "PathFindingComponent", "PathFindingGridMarkerComponent", "AIAttackComponent",
    "BossDragonComponent", "WormPlayerComponent",
}

local function corpse_health(entity)
    local damage = EntityGetFirstComponentIncludingDisabled(entity, "DamageModelComponent")
    if damage == nil or damage == 0 then return nil, nil end
    local ok_h, hp = pcall(ComponentGetValue2, damage, "hp")
    local ok_m, max_hp = pcall(ComponentGetValue2, damage, "max_hp")
    return ok_h and tonumber(hp) or nil, ok_m and tonumber(max_hp) or nil
end

local function corpse_des_gid(entity)
    if entity == nil or entity == 0 or not EntityGetIsAlive(entity) then return nil end
    for _, component in ipairs(EntityGetComponentIncludingDisabled(entity, "VariableStorageComponent") or {}) do
        local ok_name, name = pcall(ComponentGetValue2, component, "name")
        if ok_name and tostring(name or "") == "ew_gid_lid" then
            local ok_value, value = pcall(ComponentGetValue2, component, "value_string")
            if ok_value and tostring(value or "") ~= "" then return tostring(value) end
        end
    end
    return nil
end

local function disarm_polymorph_restore(entity)
    -- We already restored the serialized human ourselves. A remaining POLYMORPH effect
    -- on the dead body must never deserialize a second player when it expires.
    local wanted = {}
    for _, effect in ipairs(POLYMORPH_EFFECTS) do wanted[effect] = true end
    for _, child in ipairs(EntityGetAllChildren(entity) or {}) do
        local effect = EntityGetFirstComponentIncludingDisabled(child, "GameEffectComponent")
        if effect ~= nil and effect ~= 0 then
            local ok, id = pcall(ComponentGetValue2, effect, "effect")
            if ok and wanted[tostring(id or "")] then
                pcall(ComponentSetValue2, effect, "mSerializedData", "")
                if EntityGetIsAlive(child) then pcall(EntityKill, child) end
            end
        end
    end
end

local function freeze_pending_corpse(entity)
    for _, component_type in ipairs(CORPSE_FREEZE_COMPONENTS) do
        for _, component in ipairs(EntityGetComponentIncludingDisabled(entity, component_type) or {}) do
            pcall(EntitySetComponentIsEnabled, entity, component, false)
        end
    end
    local character = EntityGetFirstComponentIncludingDisabled(entity, "CharacterDataComponent")
    if character ~= nil and character ~= 0 then pcall(ComponentSetValue2, character, "mVelocity", 0, 0) end
    for _, velocity in ipairs(EntityGetComponentIncludingDisabled(entity, "VelocityComponent") or {}) do
        pcall(ComponentSetValue2, velocity, "mVelocity", 0, 0)
    end
end

local function ordinary_corpse_fallback_allowed(source)
    source = string.lower(tostring(source or ""))
    if not string.find(source, "^data/entities/animals/", 1) then return false end
    for _, token in ipairs({"boss", "worm", "maggot", "dragon", "centipede", "islandspirit", "friend"}) do
        if string.find(source, token, 1, true) then return false end
    end
    return true
end

local function spawn_native_corpse_fallback(record, x, y)
    local source = tostring(record.source or "")
    if not ordinary_corpse_fallback_allowed(source) or not ModDoesFileExist(source) then return 0 end
    local corpse = EntityLoad(source, x or 0, y or 0) or 0
    if corpse == 0 or not EntityGetIsAlive(corpse) then return 0 end
    for _, tag in ipairs(CORPSE_PLAYER_TAGS) do pcall(EntityRemoveTag, corpse, tag) end
    pcall(EntityAddTag, corpse, "metamorph_creative_menu_form_corpse")
    pcall(EntityAddTag, corpse, "ew_synced")
    local damage = EntityGetFirstComponentIncludingDisabled(corpse, "DamageModelComponent")
    if damage ~= nil and damage ~= 0 then
        pcall(ComponentSetValue2, damage, "wait_for_kill_flag_on_death", false)
        pcall(ComponentSetValue2, damage, "kill_now", false)
        local ok_max, max_hp = pcall(ComponentGetValue2, damage, "max_hp")
        max_hp = ok_max and tonumber(max_hp) or 1
        local amount = math.max(100, math.abs(max_hp or 1) * 100 + 100)
        if type(EntityInflictDamage) == "function" then
            pcall(EntityInflictDamage, corpse, amount, "DAMAGE_CURSE", "Metamorph: Creative Menu corpse fallback", "NONE", 0, 0, tonumber(record.responsible) or 0, tonumber(x) or 0, tonumber(y) or 0)
        else
            pcall(ComponentSetValue2, damage, "hp", -1)
            pcall(ComponentSetValue2, damage, "kill_now", true)
        end
    end
    return corpse
end

-- Called only after the human player entity has been committed. Hold the old creature
-- for exactly one world frame as an inert ew_synced entity so EW/DES can adopt it, then
-- release Noita's native death/ragdoll path with DamageModel.kill_now. The modding API
-- wait_for_kill_flag_on_death requires this explicit kill flag to finish native death.
local function detach(entity, source_path, reason, responsible)
    if entity == nil or entity == 0 or not EntityGetIsAlive(entity) then return false end
    for _, tag in ipairs(CORPSE_PLAYER_TAGS) do pcall(EntityRemoveTag, entity, tag) end
    pcall(EntityAddTag, entity, "metamorph_creative_menu_form_corpse")
    pcall(EntityAddTag, entity, "metamorph_creative_menu_form_corpse_pending")
    pcall(EntityAddTag, entity, "ew_synced")
    freeze_pending_corpse(entity)
    for _, component in ipairs(EntityGetComponentIncludingDisabled(entity, "LuaComponent", "metamorph_creative_menu_form_death_guard") or {}) do
        pcall(EntityRemoveComponent, entity, component)
    end
    disarm_polymorph_restore(entity)

    local damage = EntityGetFirstComponentIncludingDisabled(entity, "DamageModelComponent")
    if damage ~= nil and damage ~= 0 then
        -- Intentionally keep the death pending for one frame. EW's own polymorph code
        -- sets wait_for_kill_flag_on_death=true; the corresponding release is kill_now.
        pcall(ComponentSetValue2, damage, "wait_for_kill_flag_on_death", true)
        pcall(ComponentSetValue2, damage, "kill_now", false)
    end

    local frame = GameGetFrameNum()
    local x, y = EntityGetTransform(entity)
    local hp, max_hp = corpse_health(entity)
    pending_corpse_finalize[#pending_corpse_finalize + 1] = {
        entity=entity, source=tostring(source_path or EntityGetFilename(entity) or ""), reason=tostring(reason or "death"),
        responsible=tonumber(responsible) or 0, born=frame, release_frame=frame + 1, released=false, forced=false,
    }
    pending_corpse_watch[#pending_corpse_watch + 1] = {
        entity=entity, source=tostring(source_path or EntityGetFilename(entity) or ""), reason=tostring(reason or "death"),
        born=frame, next_index=1, checks={1,3,10,60},
    }
    local gid = corpse_des_gid(entity)
    diagnostic_event("FORM CORPSE PENDING", string.format("entity=%s source=%s pos=%.1f,%.1f hp=%s/%s ew_synced=%s des=%s gid=%s release=%s",
        tostring(entity), tostring(source_path or ""), tonumber(x) or 0, tonumber(y) or 0,
        tostring(hp), tostring(max_hp), tostring(EntityHasTag(entity, "ew_synced")),
        tostring(EntityHasTag(entity, "ew_des")), tostring(gid or ""), tostring(frame + 1)))
    return true
end


function corpse_service.update()
    local frame = GameGetFrameNum()
    -- Complete dead-form handoffs outside the engine death callback. The first frame is
    -- deliberately reserved for EW/DES to notice ew_synced after ew_no_enemy_sync was
    -- removed. Then kill_now releases Noita's original death FX/ragdoll path.
    for index = #pending_corpse_finalize, 1, -1 do
        local record = pending_corpse_finalize[index]
        local entity = tonumber(record.entity) or 0
        local alive = entity ~= 0 and EntityGetIsAlive(entity)
        if not alive then
            diagnostic_event("FORM CORPSE FINALIZED", string.format("entity=%s source=%s age=%s native_death=true",
                tostring(entity), tostring(record.source or ""), tostring(frame - (tonumber(record.born) or frame))))
            table.remove(pending_corpse_finalize, index)
        elseif frame >= (tonumber(record.release_frame) or frame) and record.released ~= true then
            local damage = EntityGetFirstComponentIncludingDisabled(entity, "DamageModelComponent")
            if damage ~= nil and damage ~= 0 then
                pcall(ComponentSetValue2, damage, "kill_now", true)
            end
            record.released = true
            record.release_frame = frame
            pcall(EntityRemoveTag, entity, "metamorph_creative_menu_form_corpse_pending")
            diagnostic_event("FORM CORPSE RELEASE", string.format("entity=%s source=%s hp=%s/%s des=%s gid=%s",
                tostring(entity), tostring(record.source or ""), tostring(corpse_health(entity)),
                select(2, corpse_health(entity)), tostring(EntityHasTag(entity, "ew_des")), tostring(corpse_des_gid(entity) or "")))
        elseif record.released == true and frame - (tonumber(record.release_frame) or frame) >= 3 and record.forced ~= true then
            -- A few unusual entities cache the wait flag during the death callback. If
            -- kill_now did not complete the death within three frames, clear the wait
            -- latch and reassert kill_now. This still uses the same original creature.
            local damage = EntityGetFirstComponentIncludingDisabled(entity, "DamageModelComponent")
            if damage ~= nil and damage ~= 0 then
                local hp = select(1, corpse_health(entity))
                if hp ~= nil and hp > 0 then pcall(ComponentSetValue2, damage, "hp", 0) end
                pcall(ComponentSetValue2, damage, "wait_for_kill_flag_on_death", false)
                pcall(ComponentSetValue2, damage, "kill_now", true)
            end
            freeze_pending_corpse(entity)
            record.forced = true
            diagnostic_event("FORM CORPSE FORCE_RELEASE", string.format("entity=%s source=%s", tostring(entity), tostring(record.source or "")))
        elseif record.released == true and frame - (tonumber(record.release_frame) or frame) >= 20 then
            -- Last-resort protection: never leave a living detached player-form entity
            -- immortal detached form in the world. For ordinary animals, replace only
            -- this *failed corpse* with a freshly loaded vanilla animal and kill it via
            -- the normal DamageModel path so a native ragdoll is still produced. Bosses
            -- and worms never use this fallback because their death scripts are too
            -- consequential; a stuck body is removed instead.
            local x, y = EntityGetTransform(entity)
            local fallback = spawn_native_corpse_fallback(record, x, y)
            diagnostic_event("FORM CORPSE FALLBACK", string.format("old=%s fallback=%s source=%s",
                tostring(entity), tostring(fallback), tostring(record.source or "")))
            if EntityGetIsAlive(entity) then pcall(EntityKill, entity) end
            if fallback ~= 0 then
                pending_corpse_watch[#pending_corpse_watch + 1] = {
                    entity=fallback, source=tostring(record.source or ""), reason="fallback_native_death",
                    born=frame, next_index=1, checks={1,3,10},
                }
            end
            table.remove(pending_corpse_finalize, index)
        end
    end
    for index = #pending_corpse_watch, 1, -1 do
        local record = pending_corpse_watch[index]
        local checks = record.checks or {}
        local check_at = checks[record.next_index or 1]
        if check_at == nil then
            table.remove(pending_corpse_watch, index)
        elseif frame >= (tonumber(record.born) or frame) + check_at then
            local entity = tonumber(record.entity) or 0
            local alive = entity ~= 0 and EntityGetIsAlive(entity)
            local x, y, hp, max_hp = 0, 0, nil, nil
            if alive then x, y = EntityGetTransform(entity); hp, max_hp = corpse_health(entity) end
            local gid = alive and corpse_des_gid(entity) or nil
            diagnostic_event("FORM CORPSE WATCH", string.format("age=%s entity=%s alive=%s source=%s pos=%.1f,%.1f hp=%s/%s sync_request=%s des=%s gid=%s",
                tostring(check_at), tostring(entity), tostring(alive), tostring(record.source or ""), tonumber(x) or 0, tonumber(y) or 0,
                tostring(hp), tostring(max_hp), tostring(alive and EntityHasTag(entity, "ew_synced") or false),
                tostring(alive and EntityHasTag(entity, "ew_des") or false), tostring(gid or "")))
            record.next_index = (record.next_index or 1) + 1
            if not alive or record.next_index > #checks then table.remove(pending_corpse_watch, index) end
        end
    end

end

corpse_service.detach = detach

return corpse_service
