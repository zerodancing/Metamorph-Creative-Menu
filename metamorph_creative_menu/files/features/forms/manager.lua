if type(METAMORPH_CREATIVE_MENU_FORM_MANAGER) == "table" then return METAMORPH_CREATIVE_MENU_FORM_MANAGER end

local form_manager = {}
local NETWORK_FORM_TAG = "metamorph_creative_menu_network_form"
local NETWORK_SOURCE_NAME = "metamorph_creative_menu_network_source"

local function mark_network_form_source(entity, target)
    if entity == nil or entity == 0 or not EntityGetIsAlive(entity) or type(target) ~= "string" or target == "" then return false end
    local tag_ok = pcall(EntityAddTag, entity, NETWORK_FORM_TAG)
    if not tag_ok then return false end
    local storage = EntityGetFirstComponentIncludingDisabled(entity, "VariableStorageComponent", NETWORK_FORM_TAG)
    if storage == nil or storage == 0 then
        local ok, created = pcall(EntityAddComponent2, entity, "VariableStorageComponent", {
            _tags=NETWORK_FORM_TAG, name=NETWORK_SOURCE_NAME, value_string=target,
        })
        if ok then storage = created end
    end
    if storage == nil or storage == 0 then return false end
    local name_ok = pcall(ComponentSetValue2, storage, "name", NETWORK_SOURCE_NAME)
    local value_ok = pcall(ComponentSetValue2, storage, "value_string", target)
    return name_ok and value_ok
end


local bridge_api = dofile("mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua")
local player_locator = dofile("mods/metamorph_creative_menu/files/platform/noita/player_locator.lua")
local keycodes = dofile("mods/metamorph_creative_menu/files/platform/noita/keycodes.lua")
local profile_api = dofile("mods/metamorph_creative_menu/files/features/forms/profile.lua")
local form_runtime = dofile("mods/metamorph_creative_menu/files/features/forms/runtime.lua")
local exact_effects = dofile("mods/metamorph_creative_menu/files/features/forms/exact_effects.lua")
local player_authority = dofile("mods/metamorph_creative_menu/files/features/forms/player_authority.lua")
local transform_flash = dofile("mods/metamorph_creative_menu/files/features/forms/transform_flash.lua")
local corpse_service = dofile("mods/metamorph_creative_menu/files/features/forms/corpse_service.lua")
local human_restore = dofile("mods/metamorph_creative_menu/files/features/forms/human_restore.lua")
local form_death_channel = dofile("mods/metamorph_creative_menu/files/integrations/ew/form_death_channel.lua")

local session = nil
local pending_return_frame = nil
local runtime_hooks_installed = false
local detach_dead_form_as_corpse = corpse_service.detach
local session_counter = 0
local orphan_probe_complete = false
local orphan_probe_entity = 0

-- Form runtime failures used to be swallowed by pcall every frame. Keep
-- the protective boundary (a malformed creature must not take down the whole menu),
-- but make recurring failures observable without flooding the console. No subsystem
-- is disabled here: a later frame can still recover normally.
local runtime_error_log = {}
local RUNTIME_ERROR_REPEAT_FRAMES = 600

local function diagnostic_event(kind, details)
    if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_EVENT) == "function" then
        pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_EVENT, tostring(kind or "FORM"), tostring(details or ""))
    end
end

local function real_time_ms()
    if type(GameGetRealWorldTimeSinceStarted) ~= "function" then return nil end
    local ok, value = pcall(GameGetRealWorldTimeSinceStarted)
    return ok and tonumber(value) and tonumber(value) * 1000 or nil
end

local function protected_runtime_call(label, fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, err = pcall(fn, ...)
    if ok then return true end
    local message = tostring(err)
    local signature = tostring(label) .. "|" .. message
    local frame = 0
    if type(GameGetFrameNum) == "function" then
        local frame_ok, value = pcall(GameGetFrameNum)
        if frame_ok then frame = tonumber(value) or 0 end
    end
    local last = runtime_error_log[signature]
    if last == nil or frame - last >= RUNTIME_ERROR_REPEAT_FRAMES then
        runtime_error_log[signature] = frame
        if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE) == "function" then
            pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE, "form." .. tostring(label), message)
        end
        print("[Metamorph: Creative Menu] " .. tostring(label) .. " failed: " .. message)
    end
    return false
end

local function valid(component)
    return component ~= nil and component ~= 0
end

local protect_restored_player = human_restore.protect_player
local restore_human_controls = type(human_restore.restore_controls) == "function"
    and human_restore.restore_controls or function() return false end

local function activate_restored_player(player_entity, invincibility_frames)
    local controls_restored = restore_human_controls(player_entity)
    protect_restored_player(player_entity, invincibility_frames)
    return controls_restored
end

function form_manager.prepare_exact_effect_paths(entries) return exact_effects.prepare(entries) end
function form_manager.prepare_exact_effect_paths_from_catalog() return exact_effects.prepare_from_catalog() end
function form_manager.exact_effect_path_for_target(entity_path) return exact_effects.effect_path(entity_path) end
function form_manager.runtime_target_for_target(entity_path) return exact_effects.runtime_target(entity_path) end

local function current_player()
    return player_locator.get()
end

local function next_session_id()
    session_counter = session_counter + 1
    return session_counter
end

local function network_form_source(entity)
    for _, storage in ipairs(EntityGetComponentIncludingDisabled(entity, "VariableStorageComponent") or {}) do
        local ok_name, name = pcall(ComponentGetValue2, storage, "name")
        if ok_name and name == NETWORK_SOURCE_NAME then
            local ok_value, value = pcall(ComponentGetValue2, storage, "value_string")
            if ok_value and type(value) == "string" and value ~= "" then return value end
        end
    end
    return nil
end

local function polymorph_component_target(components)
    for _, component in ipairs(components or {}) do
        local ok, target = pcall(ComponentGetValue2, component, "polymorph_target")
        if ok and type(target) == "string" and target ~= "" then return target end
    end
    return nil
end

-- A crash/recovery save serializes the polymorphed player entity, including Noita's
-- original-player blob, but ordinary Lua module state is lost. Rebuild just enough of
-- the session to make return/death handoff transactional again. The explicit marker
-- keeps vanilla or another mod's polymorph outside our ownership.
local function recover_saved_form_session()
    if session ~= nil then return true end
    local current = current_player()
    if current == 0 then return false end
    if not EntityHasTag(current, "polymorphed_player")
        or not EntityHasTag(current, NETWORK_FORM_TAG)
    then
        orphan_probe_entity = current
        orphan_probe_complete = true
        return false
    end

    local components = human_restore.polymorph_effect_components(current)
    if #components == 0 then return false end
    local target = network_form_source(current) or polymorph_component_target(components) or ""
    local backup = human_restore.serialized_backup_from_effects(components)
    local x, y = EntityGetTransform(current)
    session = {
        id = next_session_id(),
        kind = "polymorph",
        phase = "active",
        form_entity = current,
        network_marked_entity = current,
        network_marked_target = target,
        target = target,
        requested_target = target,
        compatibility_mode = "save_recovery",
        role = "creature",
        form_strategy = "native_polymorph",
        profile = profile_api.get(target),
        original_backup = backup,
        allow_death_handoff = type(backup) == "string" and backup ~= "",
        effect_entity = 0,
        started = GameGetFrameNum(),
        last_x = tonumber(x) or 0,
        last_y = tonumber(y) or 0,
        recovered_from_save = true,
    }
    orphan_probe_complete = true
    orphan_probe_entity = current
    form_manager.ensure_runtime_hooks({ bootstrap_if_installed = true })
    diagnostic_event("FORM RECOVERED", string.format("entity=%s target=%s backup=%s",
        tostring(current), tostring(target), tostring(session.allow_death_handoff)))
    return true
end

local function human_entity_ready(entity)
    if entity == nil or entity == 0 or not EntityGetIsAlive(entity) then return false end
    if session ~= nil then return false end
    if EntityHasTag(entity, "polymorphed_player") then return false end
    local inventory = EntityGetFirstComponentIncludingDisabled(entity, "Inventory2Component")
    return EntityHasTag(entity, "player_unit") and valid(inventory)
end

local transactional_set_player = player_authority.switch

local restore_transform_flash_suppression = transform_flash.restore
local suppress_transform_flash = transform_flash.suppress


local function fallback_restore(current, components)
    local bridge = bridge_api.get()
    if bridge == nil or type(bridge.DeserializeEntity) ~= "function" or type(bridge.SetPlayerEntity) ~= "function" then
        return false
    end

    local serialized = human_restore.serialized_backup_from_effects(components)
    if serialized == nil then return false end

    local current_x, current_y = EntityGetTransform(current)
    if current_x == nil then return false end
    local restored = human_restore.deserialize_backup(bridge, serialized, current_x, current_y)
    if restored == 0 then return false end

    local switched, switch_state = transactional_set_player(bridge, current, restored)
    if not switched then
        if switch_state ~= "unknown" and EntityGetIsAlive(restored) then EntityKill(restored) end
        return false
    end
    activate_restored_player(restored, 12)
    EntityKill(current)
    session = nil
    pending_return_frame = nil
    protected_runtime_call("form_runtime.reset", form_runtime.reset)
    return true
end


local function restore_polymorph_backup(old_form, rescued_from_death)
    if session == nil or session.kind ~= "polymorph" or type(session.original_backup) ~= "string" or session.original_backup == "" then
        return false
    end
    local owned = session
    if owned.phase == "restoring" then return false end
    owned.phase = rescued_from_death and "death_handoff" or "restoring"

    local bridge = bridge_api.get()
    if bridge == nil or type(bridge.DeserializeEntity) ~= "function" or type(bridge.SetPlayerEntity) ~= "function" then
        owned.phase = "active"
        return false
    end
    local restore_x, restore_y = owned.last_x or 0, owned.last_y or 0
    if old_form ~= nil and old_form ~= 0 and EntityGetIsAlive(old_form) then
        local form_x, form_y = EntityGetTransform(old_form)
        if form_x ~= nil then restore_x, restore_y = form_x, form_y end
    end
    local restored = human_restore.deserialize_backup(bridge, owned.original_backup, restore_x, restore_y)
    if restored == 0 then
        owned.phase = "active"
        return false
    end
    local switched, switch_state = transactional_set_player(bridge, old_form, restored)
    if not switched then
        if switch_state ~= "unknown" and EntityGetIsAlive(restored) then EntityKill(restored) end
        owned.phase = "active"
        return false
    end
    activate_restored_player(restored, 12)

    local cleanup = old_form ~= nil and old_form ~= 0 and old_form ~= restored and EntityGetIsAlive(old_form)
    local corpse_source = tostring(owned.requested_target or owned.target or "")
    session = nil
    pending_return_frame = nil
    protected_runtime_call("form_runtime.reset", form_runtime.reset)
    if cleanup then
        if rescued_from_death and type(detach_dead_form_as_corpse) == "function" then
            detach_dead_form_as_corpse(old_form, corpse_source, "backup_death_handoff", 0)
        else
            EntityKill(old_form)
        end
    end

    return true
end

function form_manager.handle_form_death(old_form, reason, responsible, damage, projectile)
    old_form = tonumber(old_form) or 0
    local death_started_ms = real_time_ms()
    local source_path = session ~= nil and tostring(session.requested_target or session.target or "") or ""
    local x0, y0 = 0, 0
    if old_form ~= 0 and EntityGetIsAlive(old_form) then x0, y0 = EntityGetTransform(old_form) end
    diagnostic_event("FORM DEATH", string.format("entity=%s source=%s reason=%s responsible=%s damage=%s projectile=%s pos=%.1f,%.1f",
        tostring(old_form), source_path, tostring(reason or "death"), tostring(responsible or 0), tostring(damage), tostring(projectile or 0),
        tonumber(x0) or 0, tonumber(y0) or 0))
    if session == nil then return false end

    if session.kind ~= "polymorph"
        or type(session.original_backup) ~= "string" or session.original_backup == ""
    then
        return false
    end
    if session.phase ~= "active" then return false end
    if session.form_entity ~= nil and session.form_entity ~= 0 and old_form ~= 0
        and old_form ~= session.form_entity
    then
        return false
    end
    session.phase = "death_handoff"

    local bridge = bridge_api.get({ bootstrap_if_installed = true })
    if bridge == nil or type(bridge.DeserializeEntity) ~= "function"
        or type(bridge.SetPlayerEntity) ~= "function"
    then
        session.phase = "active"
        return false
    end

    local owned = session
    local restore_x, restore_y = owned.last_x or 0, owned.last_y or 0
    if old_form ~= 0 and EntityGetIsAlive(old_form) then
        local form_x, form_y = EntityGetTransform(old_form)
        if form_x ~= nil then restore_x, restore_y = form_x, form_y end
    end
    local restored = human_restore.deserialize_backup(bridge, owned.original_backup, restore_x, restore_y, "metamorph_creative_menu_death_handoff")
    if restored == 0 then owned.phase = "active"; return false end

    local switched, switch_state = transactional_set_player(bridge, old_form, restored)
    if not switched then
        if switch_state ~= "unknown" and EntityGetIsAlive(restored) then EntityKill(restored) end
        owned.phase = "active"
        return false
    end

    activate_restored_player(restored, 12)
    local corpse_detached = detach_dead_form_as_corpse(old_form, source_path, reason, responsible)
    local death_finished_ms = real_time_ms()
    diagnostic_event("FORM HANDOFF", string.format("old=%s restored=%s corpse_detached=%s elapsed_ms=%s",
        tostring(old_form), tostring(restored), tostring(corpse_detached),
        death_started_ms ~= nil and death_finished_ms ~= nil and string.format("%.2f", death_finished_ms-death_started_ms) or "nil"))
    session = nil
    pending_return_frame = nil
    protected_runtime_call("form_runtime.reset", form_runtime.reset)
    return true
end

function form_manager.ensure_runtime_hooks(options)
    if runtime_hooks_installed then return true end
    options = type(options) == "table" and options or {}
    local bridge = bridge_api.get({ bootstrap_if_installed = options.bootstrap_if_installed == true })
    if bridge == nil then return false end
    runtime_hooks_installed = form_death_channel.register(bridge, function(entity, reason, responsible, damage, projectile)
        return form_manager.handle_form_death(entity, reason, responsible, damage, projectile)
    end)
    return runtime_hooks_installed
end

function form_manager.transform_creature(player, entity_path, frames, _legacy_force_unverified, options)
    if session ~= nil then return false, "form_busy" end
    if player == nil or player == 0 or not EntityGetIsAlive(player) then
        return false, "player"
    end
    if EntityHasTag(player, "polymorphed_player") then return false, "not_human" end
    if type(entity_path) ~= "string" or entity_path == "" or not ModDoesFileExist(entity_path) then
        return false, "target"
    end
    local effect_file = exact_effects.effect_path(entity_path)
    if type(effect_file) ~= "string" or effect_file == "" then
        exact_effects.invalidate_failed_target(entity_path) -- retry late VFS/mod resources without exposing cache internals
        if exact_effects.prepare({entity_path}) > 0 then effect_file = exact_effects.effect_path(entity_path) end
    end
    if type(effect_file) ~= "string" or effect_file == "" then return false, "effect_not_cached" end

    options = type(options) == "table" and options or {}
    local requested_target = type(options.requested_target) == "string" and options.requested_target ~= "" and options.requested_target or entity_path
    local original_backup = nil
    -- Explicitly entering a temporary form is the right moment to acquire the optional
    -- NoitaPatcher backup. Doing it here (not during module init) avoids load-order
    -- races and gives fatal rescue a transactionally serialized human even in
    -- singleplayer without Entangled Worlds. Native polymorph remains the
    -- primary return path; this backup is the hard fallback for EntityKill-style deaths.
    local bridge = bridge_api.get({ bootstrap_if_installed = true })
    form_manager.ensure_runtime_hooks({ bootstrap_if_installed = true })
    if bridge ~= nil and type(bridge.SerializeEntity) == "function" then
        local ok_backup, serialized = pcall(bridge.SerializeEntity, player)
        if ok_backup and type(serialized) == "string" and serialized ~= "" then original_backup = serialized end
    end
    local start_x, start_y = EntityGetTransform(player)

    -- Suppress only the presentation flash caused by swapping from human HP to a
    -- low-HP creature. The creature's real hp/max_hp are never changed. Applying
    -- this before native polymorph is important: post-transform suppression is one
    -- frame too late for the transition flash.
    suppress_transform_flash(18)
    -- The exact source is attached to the resulting polymorphed entity by
    -- mark_network_form_source(); do not maintain a second write-only Globals copy.
    local ok, effect_entity = pcall(LoadGameEffectEntityTo, player, effect_file)
    if not ok or effect_entity == nil or effect_entity == 0 then
        return false, "effect"
    end

    -- Some builds swap the polymorph body synchronously enough for the first render
    -- to see its low HP before our next OnWorldPreUpdate. Prime the new damage UI now
    -- when possible; form runtime repeats this once when the form becomes active.
    local immediate = current_player()
    local immediate_network_marked = 0
    if immediate ~= 0 and immediate ~= player and EntityHasTag(immediate, "polymorphed_player") then
        if mark_network_form_source(immediate, entity_path) then immediate_network_marked = immediate end
        local damage = EntityGetFirstComponentIncludingDisabled(immediate, "DamageModelComponent")
        if valid(damage) then
            local max_hp = tonumber(ComponentGetValue2(damage, "max_hp")) or 0
            if max_hp > 0 then pcall(ComponentSetValue2, damage, "max_hp_old", max_hp) end
            pcall(ComponentSetValue2, damage, "mLastDamageFrame", -120)
            pcall(ComponentSetValue2, damage, "mLastMaxHpChangeFrame", -10000)
        end
    end

    local effect = EntityGetFirstComponentIncludingDisabled(effect_entity, "GameEffectComponent")
    if valid(effect) then
        local requested_frames = math.max(2, tonumber(frames) or exact_effects.default_duration_frames())
        pcall(ComponentSetValue2, effect, "frames", requested_frames)
    end

    session = {
        id = next_session_id(),
        kind = "polymorph",
        phase = "transforming",
        form_entity = 0,
        network_marked_entity = immediate_network_marked,
        network_marked_target = immediate_network_marked ~= 0 and entity_path or nil,
        target = entity_path,
        requested_target = requested_target,
        compatibility_mode = tostring(options.compatibility_mode or "direct"),
        role = tostring(options.role or "creature"),
        form_strategy = tostring(options.form_strategy or "native_polymorph"),
        profile = profile_api.get(options.profile_target or requested_target),
        original_backup = original_backup,
        -- Death handoff is available only when a serialized human backup can be
        -- restored synchronously before the dying form reaches the Game Over path.
        allow_death_handoff = original_backup ~= nil,
        effect_entity = effect_entity,
        started = GameGetFrameNum(),
        last_x = start_x,
        last_y = start_y,
    }
    orphan_probe_complete = true
    protected_runtime_call("form_runtime.reset", form_runtime.reset)
    pending_return_frame = nil
    return true
end

function form_manager.return_to_human()
    local current = current_player()
    if current == 0 then
        return false, "player"
    end

    local components = human_restore.polymorph_effect_components(current)
    if #components == 0 then
        session = nil
        pending_return_frame = nil
        return false, "not_polymorphed"
    end

    for _, component in ipairs(components) do
        pcall(ComponentSetValue2, component, "frames", 1)
    end
    pending_return_frame = GameGetFrameNum()
    return true, "expire"
end

function form_manager.handle_tab_return(input_blocked, binding_pressed)
    -- Focus changes such as Alt+Tab must not leak stale input into form return. The GUI
    -- input guard also quarantines stale clicks on focus restoration.
    if input_blocked == true then return false end
    if binding_pressed == nil then
        -- Compatibility for older callers and isolated integrations. The lifecycle
        -- root passes the assignable action explicitly.
        local key = keycodes.resolve("Key_TAB", "KEY_TAB")
        if key == nil then return false end
        local ok, pressed = pcall(InputIsKeyJustDown, key)
        if not ok or pressed ~= true then return false end
    elseif binding_pressed ~= true then
        return false
    end

    local current = current_player()
    if current == 0 then
        return false
    end
    local components = human_restore.polymorph_effect_components(current)
    if #components == 0 then
        return false
    end
    for _, component in ipairs(components) do
        pcall(ComponentSetValue2, component, "frames", 1)
    end
    pending_return_frame = GameGetFrameNum()
    if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_USER_ACTION) == "function" then pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_USER_ACTION, "form.return_binding", "result=true") end
    return true
end

function form_manager.update()
    local frame = GameGetFrameNum()
    restore_transform_flash_suppression(false)

    corpse_service.update()

    if session == nil then
        local probe_player = current_player()
        -- EW can replace its initial player with the save entity a few frames after
        -- startup. Re-probe on that authority change even if the initial human was
        -- already classified as idle.
        if probe_player ~= 0 and probe_player ~= orphan_probe_entity then orphan_probe_complete = false end
        if not orphan_probe_complete then recover_saved_form_session() end
    end

    -- Human idle is the overwhelmingly common state. There is no polymorph effect to
    -- inspect and no death hook is needed until an explicit transform starts; keeping
    -- this path O(1) avoids four GameGetGameEffect probes and player scans every frame.
    if session == nil and pending_return_frame == nil then return false end

    form_manager.ensure_runtime_hooks()
    local current = current_player()
    if current == 0 then
        if session ~= nil and session.kind == "polymorph" and pending_return_frame ~= nil then
            return restore_polymorph_backup(nil, false)
        end
        -- Synchronous damage handoff is the primary death path. If an unusual engine
        -- kill bypassed damage callbacks, the serialized backup is a last-resort recovery.
        if session ~= nil and session.kind == "polymorph" and session.allow_death_handoff == true then
            -- Some engine kills clear the player pointer before damage/death callbacks reach us.
            -- Keep the last known form entity so the fallback handoff can preserve it as a corpse
            -- instead of silently losing the body while restoring the human.
            local fallback_form = tonumber(session.form_entity) or 0
            if fallback_form == 0 or not EntityGetIsAlive(fallback_form) then fallback_form = nil end
            if restore_polymorph_backup(fallback_form, true) then return true end
        end
        if session ~= nil and session.kind == "polymorph" then
            session = nil
            pending_return_frame = nil
            protected_runtime_call("form_runtime.reset", form_runtime.reset)
        end
        return false
    end

    local components = human_restore.polymorph_effect_components(current)
    local is_actual_form = EntityHasTag(current, "polymorphed_player")

    if session ~= nil and session.kind == "polymorph" then
        -- Critical lifecycle invariant: compatibility mutations belong only to the
        -- transformed entity. On the frame where Noita restores DEBUG_NAME:player,
        -- applying the last creature profile here would leak its movement/HP/death
        -- state into the human player. Likewise, while the effect is still pending
        -- on the original player we must not pre-apply the future form profile.
        if is_actual_form then
            -- Network source metadata is immutable for a given form entity. Rewriting the
            -- same tag/VariableStorage every frame only adds engine calls to the hot path.
            if session.network_marked_entity ~= current or session.network_marked_target ~= session.target then
                if mark_network_form_source(current, session.target) then
                    session.network_marked_entity = current
                    session.network_marked_target = session.target
                end
            end
            session.form_entity = current
            if session.phase == "transforming" then session.phase = "active" end
            local form_x, form_y = EntityGetTransform(current)
            if form_x ~= nil then session.last_x, session.last_y = form_x, form_y end
            if session.phase == "active" then protected_runtime_call("form_runtime.update", form_runtime.update, current, session) end
        elseif #components == 0 then
            local controls_restored = restore_human_controls(current)
            diagnostic_event("FORM RETURN", string.format("entity=%s controls_restored=%s path=native",
                tostring(current), tostring(controls_restored)))
            session = nil
            pending_return_frame = nil
            protected_runtime_call("form_runtime.reset", form_runtime.reset)
            return false
        end
    end

    if #components == 0 then
        if pending_return_frame ~= nil then
            local controls_restored = restore_human_controls(current)
            diagnostic_event("FORM RETURN", string.format("entity=%s controls_restored=%s path=unowned",
                tostring(current), tostring(controls_restored)))
        end
        pending_return_frame = nil
        return false
    end

    if pending_return_frame ~= nil then
        for _, component in ipairs(components) do
            pcall(ComponentSetValue2, component, "frames", 1)
        end
        if GameGetFrameNum() - pending_return_frame >= 12 then
            return fallback_restore(current, components)
        end
    end
    return false
end

-- Run once more after the engine/world update but before the rendered frame. Some
-- polymorph transitions write WorldStateComponent.mFlashAlpha after OnWorldPreUpdate;
-- reasserting the short suppression window here removes that final red frame without
-- suppressing normal damage flashes once the transition is over.
function form_manager.post_update()
    restore_transform_flash_suppression(false)
end

function form_manager.current_player()
    return current_player()
end

function form_manager.is_human_ready(entity)
    if entity == nil then entity = current_player() end
    return human_entity_ready(entity)
end

function form_manager.has_active_form()
    if session ~= nil then return true end
    local current = current_player()
    return current ~= 0
        and EntityHasTag(current, "polymorphed_player")
        and EntityHasTag(current, NETWORK_FORM_TAG)
end

function form_manager.session_phase()
    return session ~= nil and tostring(session.phase or "") or "human"
end

function form_manager.session_target()
    return session ~= nil and (session.requested_target or session.target) or nil
end

function form_manager.session_actual_target()
    return session ~= nil and session.target or nil
end

-- Read-only access for systems which need the human blueprint while the local
-- player is temporarily polymorphed. The blob is never installed as another
-- player; callers may deserialize it into a short-lived, unregistered entity.
function form_manager.original_player_backup()
    if session ~= nil and session.kind == "polymorph"
        and type(session.original_backup) == "string" and session.original_backup ~= ""
    then
        return session.original_backup
    end
    return nil
end

function form_manager.draw_form_health()
    if session == nil or session.kind ~= "polymorph" then return end
    local current = current_player()
    if current ~= 0 and EntityHasTag(current, "polymorphed_player") then
        pcall(form_runtime.draw_health, current, session)
    end
end

function form_manager.active_control_family()
    local ok, family = pcall(form_runtime.family)
    return ok and family or ""
end

function form_manager.prepared_exact_effect_count()
    return exact_effects.prepared_count()
end



METAMORPH_CREATIVE_MENU_FORM_MANAGER = form_manager
return form_manager
