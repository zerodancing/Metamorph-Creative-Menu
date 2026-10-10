if type(METAMORPH_CREATIVE_MENU_PERK_TRANSACTIONS) == "table" then return METAMORPH_CREATIVE_MENU_PERK_TRANSACTIONS end

local perk_transactions = {}
local history = {}
local global_journal = dofile("mods/metamorph_creative_menu/files/features/perks/transactions/global_journal.lua")
local mutation_journal = dofile("mods/metamorph_creative_menu/files/features/perks/transactions/mutation_journal.lua")
local player_rebind = dofile("mods/metamorph_creative_menu/files/features/perks/transactions/player_rebind.lua")
local pending_cleanup = dofile("mods/metamorph_creative_menu/files/features/perks/transactions/pending_cleanup.lua")

function perk_transactions.update()
    pending_cleanup.update()
end

function perk_transactions.cleanup_state()
    return pending_cleanup.state_snapshot()
end

function perk_transactions.start_capture(token, environment)
    if type(token) ~= "table" then return false end
    local globals_started = global_journal.start_capture(token, environment)
    local mutations_started = mutation_journal.start_capture(token, environment)
    return globals_started == true or mutations_started == true
end

function perk_transactions.stop_capture(token)
    mutation_journal.stop_capture(token)
    global_journal.stop_capture(token)
end

local structural_snapshot = dofile("mods/metamorph_creative_menu/files/features/perks/transactions/structural_snapshot.lua")
local wand_special_states = dofile("mods/metamorph_creative_menu/files/features/perks/transactions/wand_special_states.lua")

local valid_entity = structural_snapshot.valid_entity
local parent_of = structural_snapshot.parent_of
local snapshot = structural_snapshot.snapshot
local build_delta = structural_snapshot.build_delta
local component_alive = structural_snapshot.component_alive
local preflight_reparents = structural_snapshot.preflight_reparents
local cleanup_structural_additions = structural_snapshot.cleanup_structural_additions
local object_get = wand_special_states.object_get
local object_set = wand_special_states.object_set
local extra_mana_state = wand_special_states.extra_mana_state
local same_scalar = wand_special_states.same_scalar
local no_more_shuffle_state = wand_special_states.no_more_shuffle_state
local no_more_shuffle_delta = wand_special_states.no_more_shuffle_delta

function perk_transactions.begin(player, perk_id)
    if not valid_entity(player) then return nil end
    local key = tostring(perk_id or "")
    local token = {
        player=player,
        perk_id=key,
        before=snapshot(player),
        special_before=key == "EXTRA_MANA" and extra_mana_state(player) or nil,
        no_shuffle_before=key == "NO_MORE_SHUFFLE" and no_more_shuffle_state() or nil,
    }
    mutation_journal.prepare(token)
    return token
end


function perk_transactions.set_perk_id(token, perk_id)
    if type(token) ~= "table" then return false end
    token.perk_id = tostring(perk_id or "")
    if token.perk_id == "" then return false end

    -- When an ordinary vanilla pickup could only be identified after it ran, the
    -- capture initially treated its standard pickup count/flag as an arbitrary Global.
    -- Those are owned by perk_service.remove_one itself, so remove them from the generic
    -- journal now to avoid decrementing the perk twice during removal.
    local picked_flag = "PERK_PICKED_" .. token.perk_id
    if type(get_perk_picked_flag_name) == "function" then
        local ok, resolved = pcall(get_perk_picked_flag_name, token.perk_id)
        if ok and type(resolved) == "string" and resolved ~= "" then picked_flag = resolved end
    end
    if type(token.global_changes) == "table" then token.global_changes[picked_flag .. "_PICKUP_COUNT"] = nil end
    if type(token.global_reads) == "table" then token.global_reads[picked_flag .. "_PICKUP_COUNT"] = nil end
    if type(token.run_flag_changes) == "table" then token.run_flag_changes[picked_flag] = nil end
    return true
end

function perk_transactions.commit(token)
    if type(token) ~= "table" or not valid_entity(token.player) or type(token.before) ~= "table" then return false, "token" end
    local key = tostring(token.perk_id or "")

    -- EXTRA_MANA is a one-off wand mutation that may intentionally detach spell entities.
    -- Tracking the entire player tree made unrelated transient component changes able to
    -- invalidate the transaction. Track only the wand state this perk actually owns.
    if key == "EXTRA_MANA" and token.special_before ~= nil then
        local special_after = extra_mana_state(token.player)
        if special_after == nil or special_after.wand ~= token.special_before.wand
            or special_after.ability ~= token.special_before.ability then
            return false, "extra_mana_wand_changed"
        end
        local action_states = {}
        for action, before_action in pairs(token.special_before.actions or {}) do
            if not valid_entity(action) then return false, "extra_mana_action_gone" end
            local parent = parent_of(action)
            if parent ~= token.special_before.wand and parent ~= 0 then return false, "extra_mana_action_claimed" end
            action_states[action] = { before=before_action, after_parent=parent }
        end
        local before_deck = tonumber(token.special_before.deck_capacity)
        local after_deck = tonumber(special_after.deck_capacity)
        local before_max = tonumber(token.special_before.mana_max)
        local after_max = tonumber(special_after.mana_max)
        local before_charge = tonumber(token.special_before.mana_charge_speed)
        local after_charge = tonumber(special_after.mana_charge_speed)
        local delta = {
            kind="extra_mana", perk_id=key, player=token.player, source=token.source, wand=token.special_before.wand,
            ability=token.special_before.ability, before=token.special_before,
            after={ deck_capacity=special_after.deck_capacity, mana_max=special_after.mana_max,
                mana_charge_speed=special_after.mana_charge_speed }, actions=action_states,
            deck_delta=(after_deck and before_deck) and (after_deck-before_deck) or nil,
            mana_max_delta=(after_max and before_max) and (after_max-before_max) or nil,
            mana_charge_delta=(after_charge and before_charge) and (after_charge-before_charge) or nil,
        }
        global_journal.attach_delta(delta, token)
        mutation_journal.attach_delta(delta, token)
        delta.player_locators = player_rebind.capture(token.player)
        history[key] = history[key] or {}; history[key][#history[key] + 1] = delta
        return true, "tracked_extra_mana"
    end

    if key == "NO_MORE_SHUFFLE" and type(token.no_shuffle_before) == "table" then
        local changes, shuffle_reason = no_more_shuffle_delta(token.no_shuffle_before)
        if changes == nil then return false, shuffle_reason end
        local delta = { kind="no_more_shuffle", perk_id=key, player=token.player, source=token.source, changes=changes }
        global_journal.attach_delta(delta, token)
        mutation_journal.attach_delta(delta, token)
        delta.player_locators = player_rebind.capture(token.player)
        history[key] = history[key] or {}; history[key][#history[key] + 1] = delta
        return true, "tracked_no_more_shuffle"
    end

    local after = snapshot(token.player, token.before)
    local delta = build_delta(token.before, after)
    if not delta.reversible then return false, delta.reason end

    delta.player = token.player
    delta.perk_id = key
    delta.source = token.source
    global_journal.attach_delta(delta, token)
    mutation_journal.attach_delta(delta, token)
    delta.player_locators = player_rebind.capture(token.player)
    history[key] = history[key] or {}
    history[key][#history[key] + 1] = delta
    return true, "tracked"
end

function perk_transactions.top_transaction_id(perk_id, player)
    local stack = history[tostring(perk_id or "")]
    if type(stack) ~= "table" or #stack == 0 then return nil end
    local delta = stack[#stack]
    if player ~= nil and player ~= 0 and type(delta) == "table" and delta.player ~= player then return nil end
    return type(delta) == "table" and delta.transaction_id or nil
end

function perk_transactions.has(perk_id, player)
    local stack = history[tostring(perk_id or "")]
    if type(stack) ~= "table" or #stack == 0 then return false end
    if player ~= nil and player ~= 0 then
        local delta = stack[#stack]
        return type(delta) == "table" and delta.player == player
    end
    return true
end

function perk_transactions.source_count(perk_id, source, player)
    local stack = history[tostring(perk_id or "")]
    if type(stack) ~= "table" then return 0 end
    local wanted = tostring(source or "")
    local count = 0
    for _, delta in ipairs(stack) do
        if type(delta) == "table" and tostring(delta.source or "") == wanted
            and (player == nil or player == 0 or delta.player == player)
        then
            count = count + 1
        end
    end
    return count
end


function perk_transactions.revert(perk_id, player)
    local key = tostring(perk_id or "")
    local stack = history[key]
    if type(stack) ~= "table" or #stack == 0 then return false, "not_tracked" end
    local delta = stack[#stack]
    -- Entity serialization/polymorph restoration creates a new player entity with new
    -- component ids. A structural delta from the previous player must never pretend to
    -- apply successfully to that replacement. Explicit inverse handlers can still take
    -- over for supported perks.
    if player ~= nil and player ~= 0 and delta.player ~= nil and delta.player ~= player then
        return false, "tracked_player_changed"
    end

    if delta.kind == "no_more_shuffle" then
        local ok_globals, globals_reason = global_journal.preflight_delta(delta)
        if not ok_globals then return false, globals_reason end
        for _, entry in ipairs(delta.changes or {}) do
            if valid_entity(entry.wand) then
                if not component_alive(entry.ability) then return false, "no_more_shuffle_ability_gone" end
                local current = object_get(entry.ability, "gun_config", "shuffle_deck_when_empty")
                if current == nil or not same_scalar(current, entry.after) then return false, "no_more_shuffle_wand_modified" end
            end
        end
        local objects_ok, objects_reason = mutation_journal.cleanup_owned_objects(delta)
        if not objects_ok then return false, objects_reason end
        for _, entry in ipairs(delta.changes or {}) do
            if valid_entity(entry.wand) then
                if not object_set(entry.ability, "gun_config", "shuffle_deck_when_empty", entry.before) then
                    return false, "no_more_shuffle_restore"
                end
            end
        end
        local properties_ok, properties_reason = mutation_journal.revert_properties(delta)
        if not properties_ok then return false, properties_reason end
        global_journal.revert_delta(delta)
        table.remove(stack); if #stack == 0 then history[key] = nil end
        return true, "tracked_no_more_shuffle_inverse"
    end

    if delta.kind == "extra_mana" then
        if not valid_entity(delta.wand) or not component_alive(delta.ability) then return false, "extra_mana_wand_gone" end
        local ok_globals, globals_reason = global_journal.preflight_delta(delta)
        if not ok_globals then return false, globals_reason end
        local objects_ok, objects_reason = mutation_journal.cleanup_owned_objects(delta)
        if not objects_ok then return false, objects_reason end
        local current_deck = tonumber(object_get(delta.ability, "gun_config", "deck_capacity"))
        local ok_max, current_max = pcall(ComponentGetValue2, delta.ability, "mana_max")
        local ok_charge, current_charge = pcall(ComponentGetValue2, delta.ability, "mana_charge_speed")
        current_max, current_charge = tonumber(current_max), tonumber(current_charge)
        if current_deck == nil or not ok_max or current_max == nil or not ok_charge or current_charge == nil then
            return false, "extra_mana_wand_read"
        end
        local missing_actions = 0
        for action, state in pairs(delta.actions or {}) do
            if valid_entity(action) then
                local parent = parent_of(action)
                if parent ~= delta.wand and parent ~= 0 then return false, "extra_mana_action_claimed" end
            else
                -- Detached actions can legitimately be consumed, deleted or replaced by
                -- later wand edits. Their disappearance must not permanently lock the
                -- owned numeric EXTRA_MANA contribution onto the wand.
                missing_actions = missing_actions + 1
            end
        end
        -- EXTRA_MANA can be followed by other wand perks/edits. Remove only the numeric
        -- contribution owned by this pickup instead of requiring the whole wand to
        -- still equal the immediate post-pickup snapshot. This composes with later
        -- additive edits while the detached-spell ownership checks remain strict.
        local deck_delta = tonumber(delta.deck_delta)
        local max_delta = tonumber(delta.mana_max_delta)
        local charge_delta = tonumber(delta.mana_charge_delta)
        delta.scalar_restored = delta.scalar_restored or {}
        local target_deck = deck_delta and (current_deck - deck_delta) or tonumber(delta.before.deck_capacity)
        local target_max = max_delta and (current_max - max_delta) or tonumber(delta.before.mana_max)
        local target_charge = charge_delta and (current_charge - charge_delta) or tonumber(delta.before.mana_charge_speed)
        if target_deck == nil or target_max == nil or target_charge == nil then return false, "extra_mana_delta_invalid" end
        if not delta.scalar_restored.deck then
            if not object_set(delta.ability, "gun_config", "deck_capacity", target_deck) then
                return false, "extra_mana_capacity_restore"
            end
            delta.scalar_restored.deck = true
        end
        local function set_number_verified(field, value)
            local wrote = pcall(ComponentSetValue2, delta.ability, field, value)
            local read_ok, after = pcall(ComponentGetValue2, delta.ability, field)
            return wrote and read_ok and same_scalar(after, value)
        end
        if not delta.scalar_restored.mana_max then
            if not set_number_verified("mana_max", target_max) then return false, "extra_mana_mana_max_restore" end
            delta.scalar_restored.mana_max = true
        end
        if not delta.scalar_restored.mana_charge_speed then
            if not set_number_verified("mana_charge_speed", target_charge) then return false, "extra_mana_mana_charge_restore" end
            delta.scalar_restored.mana_charge_speed = true
        end
        for action, state in pairs(delta.actions or {}) do
            if valid_entity(action) then
                if parent_of(action) == 0 then
                    local ok = pcall(EntityAddChild, delta.wand, action)
                    if not ok or parent_of(action) ~= delta.wand then return false, "extra_mana_action_restore" end
                end
                for comp, enabled in pairs((state.before and state.before.enabled) or {}) do
                    if component_alive(comp) then pcall(EntitySetComponentIsEnabled, action, comp, enabled == true) end
                end
            end
        end
        local properties_ok, properties_reason = mutation_journal.revert_properties(delta)
        if not properties_ok then return false, properties_reason end
        global_journal.revert_delta(delta)
        table.remove(stack); if #stack == 0 then history[key] = nil end
        return true, "tracked_extra_mana_inverse:missing_actions=" .. tostring(missing_actions)
    end

    local ok_preflight, reason = global_journal.preflight_delta(delta)
    if not ok_preflight then return false, reason end
    ok_preflight, reason = preflight_reparents(delta)
    if not ok_preflight then return false, reason end
    -- Hard-owned objects must be gone before any scalar rollback is committed. If the
    -- engine refuses to retire one, keep the transaction so removal can be retried and
    -- QA can report the real residue instead of forgetting ownership.
    local objects_ok, objects_reason = mutation_journal.cleanup_owned_objects(delta)
    if not objects_ok then return false, objects_reason end
    local structural_ok, structural_reason = cleanup_structural_additions(delta)
    if not structural_ok then return false, structural_reason end

    -- Exact setter calls (including meta/object fields invisible to ComponentGetMembers)
    -- are reverted before the structural snapshot. Structural CAS then naturally skips
    -- fields already restored by the mutation journal.
    local properties_ok, properties_reason = mutation_journal.revert_properties(delta)
    if not properties_ok then return false, properties_reason end

    -- Compare-and-swap restoration: if some later game/mod action changed a field again,
    -- do not overwrite it with stale pre-perk state. This makes tracked inverse deltas
    -- composable instead of turning perk removal into a whole-player rollback.
    for _, field in ipairs(delta.fields or {}) do
        if component_alive(field.component) then
            local ok, current = pcall(ComponentGetValue, field.component, field.field)
            if ok and tostring(current) == tostring(field.after) then
                pcall(ComponentSetValue, field.component, field.field, tostring(field.before or ""))
            end
        end
    end
    for _, entry in ipairs(delta.enabled or {}) do
        if valid_entity(entry.entity) and component_alive(entry.component) then
            local ok, current = pcall(ComponentGetIsEnabled, entry.component)
            if ok and (current == true) == (entry.after == true) then
                pcall(EntitySetComponentIsEnabled, entry.entity, entry.component, entry.before == true)
            end
        end
    end

    for _, entry in ipairs(delta.reparents or {}) do
        local ok = pcall(EntityAddChild, entry.before_parent, entry.entity)
        if not ok or parent_of(entry.entity) ~= entry.before_parent then
            return false, "detached_entity_restore"
        end
    end

    global_journal.revert_delta(delta)
    table.remove(stack)
    if #stack == 0 then history[key] = nil end
    return true, "tracked_inverse"
end

-- Revert one exact transaction even when a newer copy of the same perk is above it.
-- Ownership journals deliberately keep the newer layers registered while the older
-- delta is reverted, so removing a parent-owned GAMBLE reward cannot erase a later
-- independently acquired copy.
function perk_transactions.revert_transaction(perk_id, player, transaction_id)
    local key = tostring(perk_id or "")
    local stack = history[key]
    if type(stack) ~= "table" or #stack == 0 then return false, "not_tracked" end
    local wanted_index = nil
    for index, delta in ipairs(stack) do
        if type(delta) == "table" and tonumber(delta.transaction_id) == tonumber(transaction_id) then
            wanted_index = index
            break
        end
    end
    if wanted_index == nil then return false, "transaction_not_found" end
    if player ~= nil and player ~= 0 and stack[wanted_index].player ~= nil and stack[wanted_index].player ~= player then
        return false, "tracked_player_changed"
    end
    if wanted_index == #stack then return perk_transactions.revert(key, player) end

    local newer = {}
    while #stack > wanted_index do table.insert(newer, 1, table.remove(stack)) end
    local ok, reason = perk_transactions.revert(key, player)
    stack = history[key] or {}
    history[key] = stack
    for _, delta in ipairs(newer) do stack[#stack + 1] = delta end
    if #stack == 0 then history[key] = nil end
    return ok, reason
end

function perk_transactions.discard_top(perk_id, player)
    local key = tostring(perk_id or "")
    local stack = history[key]
    if type(stack) ~= "table" or #stack == 0 then return false, "not_tracked" end
    local delta = stack[#stack]
    if player ~= nil and player ~= 0 and type(delta) == "table" and delta.player ~= nil and delta.player ~= player then
        return false, "tracked_player_changed"
    end
    mutation_journal.discard_delta(delta)
    if type(global_journal.discard_delta) == "function" then global_journal.discard_delta(delta) end
    table.remove(stack)
    if #stack == 0 then history[key] = nil end
    return true, "discarded_stale_delta"
end

local function active_deltas()
    local result = {}
    for _, stack in pairs(history) do
        for _, delta in ipairs(stack or {}) do result[#result + 1] = delta end
    end
    table.sort(result, function(left, right)
        return (tonumber(left and left.transaction_id) or 0) < (tonumber(right and right.transaction_id) or 0)
    end)
    return result
end

function perk_transactions.active_count()
    local count = 0
    for _, stack in pairs(history) do count = count + #(stack or {}) end
    return count
end

-- Form restoration/deserialization recreates the player tree with fresh ids. Rebind the
-- semantic transaction locators to that replacement so perks acquired before entering a
-- form remain removable afterwards. World/detached entities are intentionally untouched.
function perk_transactions.rebind_player(old_player_entity_id, new_player_entity_id)
    if old_player_entity_id == nil or old_player_entity_id == 0 or new_player_entity_id == nil or new_player_entity_id == 0 then
        return false, "invalid_player", 0
    end
    if old_player_entity_id == new_player_entity_id then return true, "same_player", 0 end
    if not valid_entity(new_player_entity_id) then return false, "new_player_invalid", 0 end

    local rebound = 0
    local unresolved = 0
    for _, delta in ipairs(active_deltas()) do
        if type(delta) == "table" and delta.player == old_player_entity_id then
            if type(delta.player_locators) ~= "table" then
                unresolved = unresolved + 1
            else
                local entity_map, component_map = player_rebind.resolve(delta.player_locators, new_player_entity_id)
                if type(entity_map) ~= "table" or entity_map[old_player_entity_id] ~= new_player_entity_id then
                    unresolved = unresolved + 1
                else
                    player_rebind.remap_delta(delta, entity_map, component_map, new_player_entity_id)
                    mutation_journal.rebind_delta(delta, entity_map, component_map)
                    delta.player_locators = player_rebind.capture(new_player_entity_id)
                    rebound = rebound + 1
                end
            end
        end
    end
    mutation_journal.rebuild_ownership(active_deltas())
    if unresolved > 0 then return false, "unresolved_locators", rebound, unresolved end
    return true, "rebound", rebound, 0
end

function perk_transactions.clear() history = {} end

function perk_transactions.active_mutation_count()
    return mutation_journal.active_property_count()
end

function perk_transactions.active_global_owner_counts()
    if type(global_journal.active_owner_counts) ~= "function" then return 0, 0 end
    return global_journal.active_owner_counts()
end

METAMORPH_CREATIVE_MENU_PERK_TRANSACTIONS = perk_transactions
return perk_transactions
