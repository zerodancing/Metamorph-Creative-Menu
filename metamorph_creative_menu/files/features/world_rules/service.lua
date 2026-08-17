local existing_world_rule_service = METAMORPH_CREATIVE_MENU_WORLD_RULE_SERVICE or METAMORPH_CREATIVE_MENU_WORLD_RULES_EDITOR
if type(existing_world_rule_service) == "table" then return existing_world_rule_service end

local world_rule_service = {}
local player_locator = dofile("mods/metamorph_creative_menu/files/platform/noita/player_locator.lua")
local input_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/input_guard.lua")
local gold_lifetime_service = dofile("mods/metamorph_creative_menu/files/features/world_rules/gold_lifetime.lua")
local RULES = dofile("mods/metamorph_creative_menu/files/features/world_rules/definitions.lua")
local world_rule_sync = dofile("mods/metamorph_creative_menu/files/integrations/ew/world_rules_sync.lua")
local physics_adapter = dofile("mods/metamorph_creative_menu/files/features/world_rules/physics.lua")
local world_state_adapter = dofile("mods/metamorph_creative_menu/files/features/world_rules/world_state.lua")
local stain_adapter = dofile("mods/metamorph_creative_menu/files/features/world_rules/stains.lua")
local magic_number_adapter = dofile("mods/metamorph_creative_menu/files/features/world_rules/magic_numbers.lua")

-- Live physics rules only need to cover the active neighbourhood. The old 4608x3072
-- query plus a 2304-radius entity scan every 8 frames scaled badly in long EW runs.
local PHYSICS_SCAN_INTERVAL = 30

local update_network_sync
local encode_rules_snapshot

local state = {
    selected = {},    -- rule id -> explicit choice index; nil means NATIVE
    last_physics_scan = -100000,
    last_rule_reassert = -100000,
    reset_pending = false,
    remote_authoritative = false,
    startup_recovery_done = false,
    startup_recovery_had_state = false,
}

local function restore_loaded_gold_lifetimes_if_disabled(comp)
    comp = comp or world_state_adapter.component()
    if comp == nil or comp == 0 then return 0 end
    local read_succeeded, gold_is_forever = pcall(ComponentGetValue2, comp, "perk_gold_is_forever")
    if not read_succeeded then return 0 end
    local enabled = gold_is_forever == true or gold_is_forever == 1 or gold_is_forever == "1" or gold_is_forever == "true"
    if enabled then return 0 end
    return gold_lifetime_service.restore_missing_lifetimes()
end

local function startup_recovery_pending()
    return (type(world_state_adapter.has_persisted_recovery) == "function" and world_state_adapter.has_persisted_recovery(RULES))
        or (type(magic_number_adapter.has_persisted_recovery) == "function" and magic_number_adapter.has_persisted_recovery(RULES))
        or (type(physics_adapter.has_persisted_local_recovery) == "function" and physics_adapter.has_persisted_local_recovery())
end

local function recover_stale_saved_overrides()
    if state.startup_recovery_done then return true end
    local pending = startup_recovery_pending()
    if not pending then
        state.startup_recovery_done = true
        return true
    end
    state.startup_recovery_had_state = true
    local world_ok = type(world_state_adapter.recover_persisted) ~= "function" or world_state_adapter.recover_persisted(RULES)
    local magic_ok = type(magic_number_adapter.recover_persisted) ~= "function" or magic_number_adapter.recover_persisted(RULES)
    local local_ok = type(physics_adapter.recover_persisted_local) ~= "function"
        or physics_adapter.recover_persisted_local(player_locator.get())
    if not (world_ok and magic_ok and local_ok) then return false end
    if startup_recovery_pending() then return false end
    state.startup_recovery_done = true
    state.selected = {}
    state.reset_pending = false
    state.last_physics_scan = -100000
    state.last_rule_reassert = -100000
    -- Gold Forever is a WorldState flag, but its gameplay consequence is removal of
    -- LifetimeComponent from already-loaded nuggets. A restart can preserve those
    -- entities even after we restore the saved flag, so finish the same inverse cleanup
    -- used by an explicit Rules RESET before declaring startup recovery complete.
    restore_loaded_gold_lifetimes_if_disabled()
    -- Startup recovery removes stale state from a previous Lua/save session. It is not
    -- a user edit and must not race a live EW host snapshot during peer reconnect.
    if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE) == "function" then
        pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE, "world_rules.startup_recovery", "restored_stale_saved_overrides=true")
    end
    return true
end

function world_rule_service.can_edit()
    return world_rule_sync.can_edit()
end

local function selected_index(rule)
    return tonumber(state.selected[rule.id]) or 1
end

local function physics_factor(rule_id)
    for _, rule in ipairs(RULES) do
        if rule.id == rule_id then
            local choice = rule.choices[selected_index(rule)]
            if choice ~= nil and choice.native ~= true then return tonumber(choice.value) end
        end
    end
    return nil
end

local function reassert_nonphysics_rules()
    if state.reset_pending then return end
    local editable = world_rule_service.can_edit()
    if not editable and not state.remote_authoritative then return end
    for _, rule in ipairs(RULES) do
        local index = tonumber(state.selected[rule.id])
        local choice = index ~= nil and rule.choices[index] or nil
        if choice ~= nil and choice.native ~= true then
            if rule.kind == "magic_multiplier" then
                magic_number_adapter.apply(rule.magic_keys, tonumber(choice.value) or 1)
            elseif rule.kind == "infinite_spells" or rule.kind == "field" then
                world_state_adapter.apply(rule, choice)
            end
        end
    end
end

function world_rule_service.update()
    local frame = GameGetFrameNum()
    if not recover_stale_saved_overrides() then return end
    update_network_sync(frame)
    local local_player = player_locator.get()
    local gravity_before = physics_factor("physics_gravity")
    -- Capture the clean/native gravity baseline once per current player component while
    -- Creative Gravity is inactive. Active multipliers use that clean baseline, while
    -- the adapter separately remembers the immediate pre-override value for NATIVE.
    if gravity_before == nil then physics_adapter.capture_local_native(local_player) end
    -- A partial RESET keeps authoritative recovery records. Retry it before allowing
    -- reassertion/scans; otherwise a later rule step could cancel reset_pending and leave
    -- stale character/body values behind.
    if state.reset_pending then
        local ok = world_rule_service.reset()
        if not ok then return end
    end
    if frame - state.last_rule_reassert >= 10 then
        state.last_rule_reassert = frame
        reassert_nonphysics_rules()
    end
    local gravity = physics_factor("physics_gravity")
    local damping = physics_factor("physics_damping")
    local stain = physics_factor("stain_drop")
    -- Player-affecting gravity is latency-sensitive and perk scripts can overwrite it
    -- every tick. Reassert just the local player's two gravity fields every frame; the
    -- expensive nearby-body/character scans below remain throttled.
    if gravity ~= nil then physics_adapter.reassert_local(local_player, gravity, frame) end
    if gravity == nil and damping == nil and stain == nil then return end
    -- Focus resume can leave EW with a network backlog. Keep cheap rule reassertion and
    -- mailbox sync alive, but defer broad physics/entity queries until catch-up settles.
    if type(input_guard.heavy_updates_allowed) == "function" and not input_guard.heavy_updates_allowed() then return end
    if frame - state.last_physics_scan < PHYSICS_SCAN_INTERVAL then return end
    state.last_physics_scan = frame
    -- Both broad scans are centered on the same authoritative local player. Resolve it
    -- once for this scan tick instead of repeating the global player lookup. This is a
    -- local hand-off, not a frame cache, so same-frame polymorph swaps stay safe.
    local scan_player = player_locator.get()
    if scan_player == nil or scan_player == 0 or not EntityGetIsAlive(scan_player) then return end
    physics_adapter.scan(scan_player, gravity, damping, frame)
    if stain ~= nil then stain_adapter.apply(stain, frame, scan_player) end
    stain_adapter.cleanup_stale(frame)
end

function world_rule_service.rules()
    for _, rule in ipairs(RULES) do
        for index, choice in ipairs(rule.choices or {}) do choice._index = index end
    end
    return RULES
end

function world_rule_service.choice_index(rule) return type(rule) == "table" and selected_index(rule) or 1 end
function world_rule_service.choice_label(rule)
    local choice = type(rule) == "table" and (rule.choices or {})[selected_index(rule)] or nil
    return choice and tostring(choice.label or choice.value or "") or ""
end
function world_rule_service.is_overridden(rule) return type(rule) == "table" and selected_index(rule) ~= 1 end

function world_rule_service.supported(rule)
    if type(rule) ~= "table" then return false end
    if rule.kind == "physics_gravity" or rule.kind == "physics_damping" then
        return physics_adapter.supported(rule.kind)
    end
    if rule.kind == "stain_drop" then return stain_adapter.supported() end
    if rule.kind == "magic_multiplier" then return magic_number_adapter.supported() end
    return world_state_adapter.supported(rule)
end

local function restore_physics_rule(rule)
    local restored, reason = physics_adapter.restore_rule(rule.kind)
    if restored then state.selected[rule.id] = nil end
    return restored, reason
end

local function apply_rule_index(rule, index)
    if type(rule) ~= "table" or type(rule.choices) ~= "table" or #rule.choices == 0 then return false, "rule" end
    if not world_rule_service.supported(rule) then return false, "unsupported" end
    index = math.max(1, math.min(#rule.choices, math.floor(tonumber(index) or 1)))
    local choice = rule.choices[index]
    choice._index = index

    if rule.kind == "physics_gravity" or rule.kind == "physics_damping" then
        if choice.native == true then return restore_physics_rule(rule) end
        state.selected[rule.id] = index
        state.last_physics_scan = -100000
        return true, "ok"
    end

    if rule.kind == "stain_drop" then
        if choice.native == true then
            local restored = stain_adapter.restore_all()
            if restored then state.selected[rule.id] = nil end
            return restored, restored and "ok" or "restore_failed"
        end
        state.selected[rule.id] = index
        state.last_physics_scan = -100000
        return true, "ok"
    end

    if rule.kind == "magic_multiplier" then
        local applied
        if choice.native == true then applied = magic_number_adapter.restore(rule.magic_keys)
        else applied = magic_number_adapter.apply(rule.magic_keys, tonumber(choice.value) or 1) end
        if applied then state.selected[rule.id] = choice.native == true and nil or index end
        return applied, applied and "ok" or "magic_write_readback"
    end

    local applied, reason = world_state_adapter.apply(rule, choice)
    if applied then
        state.selected[rule.id] = choice.native == true and nil or index
        if rule.id == "gold_forever" then restore_loaded_gold_lifetimes_if_disabled() end
    end
    return applied, reason
end

encode_rules_snapshot = function()
    local encoded = {}
    for index, rule in ipairs(RULES) do encoded[index] = tostring(selected_index(rule)) end
    return table.concat(encoded, ",")
end

local function decode_rules_snapshot(encoded)
    if type(encoded) ~= "string" or encoded == "" then return nil end
    local result = {}
    for value in string.gmatch(encoded, "[^,]+") do
        local choice_index = tonumber(value)
        if choice_index == nil then return nil end
        result[#result + 1] = math.floor(choice_index)
    end
    if #result ~= #RULES then return nil end
    return result
end

local function apply_network_snapshot(choices)
    state.remote_authoritative = true
    state.reset_pending = false
    local failures = {}
    for index, rule in ipairs(RULES) do
        local desired_index = math.max(1, math.min(#rule.choices, math.floor(tonumber(choices[index]) or 1)))
        if selected_index(rule) ~= desired_index then
            local applied, reason = apply_rule_index(rule, desired_index)
            if not applied then failures[#failures + 1] = tostring(rule.id) .. ":" .. tostring(reason) end
        end
    end
    state.last_physics_scan = -100000
    if #failures > 0 and type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE) == "function" then
        pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE, "world_rules.snapshot_apply", table.concat(failures, ","))
    end
end

update_network_sync = function(frame)
    world_rule_sync.update(frame, {
        encode_snapshot = encode_rules_snapshot,
        decode_snapshot = decode_rules_snapshot,
        apply_snapshot = apply_network_snapshot,
        set_remote_authoritative = function(enabled) state.remote_authoritative = enabled == true end,
    })
end

function world_rule_service.gravity_factor() return physics_factor("physics_gravity") end

function world_rule_service.local_gravity_debug()
    return physics_adapter.debug_local_gravity(player_locator.get(), world_rule_service.gravity_factor())
end

function world_rule_service.step(rule, direction)
    if not recover_stale_saved_overrides() then return false, "startup_recovery" end
    local allowed = world_rule_service.can_edit(); if not allowed then return false, "edit_denied" end
    if type(rule) ~= "table" or type(rule.choices) ~= "table" or #rule.choices == 0 then return false, "rule" end
    if not world_rule_service.supported(rule) then return false, "unsupported" end
    -- Never discard an unfinished RESET merely because the user clicked another rule.
    -- Finish recovery first or reject the new mutation so original gravity/damping and
    -- WorldState fields cannot be re-captured from an already modified intermediate state.
    if state.reset_pending then
        local reset_ok = world_rule_service.reset()
        if not reset_ok then return false, "reset_pending" end
    end
    local delta = (tonumber(direction) or 1) < 0 and -1 or 1
    local index = ((selected_index(rule) - 1 + delta) % #rule.choices) + 1
    local ok, reason = apply_rule_index(rule, index)
    if ok then
        world_rule_sync.mark_dirty(encode_rules_snapshot())
        if rule.kind == "physics_gravity" then
            local factor = physics_factor("physics_gravity")
            if factor ~= nil then physics_adapter.reassert_local(player_locator.get(), factor, GameGetFrameNum()) end
        end
    end
    return ok, reason
end

function world_rule_service.reset()
    if not recover_stale_saved_overrides() then return false, "startup_recovery" end
    local allowed = world_rule_service.can_edit(); if not allowed then return false, "edit_denied" end
    local all_restored = true
    if not world_state_adapter.reset_all() then all_restored = false end
    if not physics_adapter.reset_all() then all_restored = false end
    if not stain_adapter.restore_all() then all_restored = false end
    if not magic_number_adapter.reset_all() then all_restored = false end

    for _, rule in ipairs(RULES) do
        local restored = false
        if rule.kind == "field" or rule.kind == "infinite_spells" then
            restored = not world_state_adapter.owns_rule(rule)
        elseif rule.kind == "stain_drop" then
            restored = not stain_adapter.has_overrides()
        elseif rule.kind == "magic_multiplier" then
            restored = not magic_number_adapter.owns(rule.magic_keys)
        elseif rule.kind == "physics_gravity" then
            restored = type(physics_adapter.has_gravity_overrides) ~= "function" or not physics_adapter.has_gravity_overrides()
        elseif rule.kind == "physics_damping" then
            restored = type(physics_adapter.has_damping_overrides) ~= "function" or not physics_adapter.has_damping_overrides()
        end
        if restored then state.selected[rule.id] = nil end
    end

    restore_loaded_gold_lifetimes_if_disabled()
    state.last_physics_scan = -100000
    state.last_rule_reassert = -100000
    state.reset_pending = not all_restored
    if all_restored then state.selected = {}; state.reset_pending = false end
    world_rule_sync.mark_dirty(encode_rules_snapshot())
    return all_restored, all_restored and "ok" or "partial"
end

function world_rule_service.post_update()
    -- Character/perk scripts can run after OnWorldPreUpdate and rewrite player gravity.
    -- Reassert only the local player here; broad world/body scans remain throttled in
    -- update() so this does not turn gravity into a per-frame whole-world scan.
    local factor = physics_factor("physics_gravity")
    if factor ~= nil then
        local player = player_locator.get()
        physics_adapter.reassert_local(player, factor, GameGetFrameNum())
    end
end

function world_rule_service.recovery_status()
    return {
        done=state.startup_recovery_done,
        had_stale_state=state.startup_recovery_had_state,
        pending=startup_recovery_pending(),
    }
end

function world_rule_service.has_overrides()
    return next(state.selected) ~= nil
        or world_state_adapter.has_overrides()
        or physics_adapter.has_overrides()
        or stain_adapter.has_overrides()
        or magic_number_adapter.has_overrides()
end

METAMORPH_CREATIVE_MENU_WORLD_RULE_SERVICE = world_rule_service
-- Legacy singleton alias kept for compatibility with older callers.
METAMORPH_CREATIVE_MENU_WORLD_RULES_EDITOR = world_rule_service
return world_rule_service
