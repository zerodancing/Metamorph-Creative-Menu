if type(METAMORPH_CREATIVE_MENU_PERK_SERVICE) == "table" then return METAMORPH_CREATIVE_MENU_PERK_SERVICE end

local perk_service = {}
local inverses = dofile("mods/metamorph_creative_menu/files/features/perks/inverse_registry.lua")
local transactions = dofile("mods/metamorph_creative_menu/files/features/perks/transactions.lua")
local root_companions = dofile("mods/metamorph_creative_menu/files/features/perks/root_companions.lua")
local nested_pickups = dofile("mods/metamorph_creative_menu/files/features/perks/nested_pickups.lua")
local locomotion_guard = dofile("mods/metamorph_creative_menu/files/features/perks/locomotion_guard.lua")
local ew_world_items = dofile("mods/metamorph_creative_menu/files/integrations/ew/world_items.lua")
local ew_perk_visibility = dofile("mods/metamorph_creative_menu/files/integrations/ew/perk_visibility.lua")

local function valid(entity)
    return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity)
end

local last_human_player_entity_id = nil
local failed_pickup_rollbacks = {}
local FAILED_ROLLBACK_RETRY_INITIAL_FRAMES = 30
local FAILED_ROLLBACK_RETRY_MAX_FRAMES = 300
local FAILED_ROLLBACK_RETRY_BUDGET = 2
local BATCH_OPERATION_BUDGET = 4
local BATCH_REMOVE_LIMIT = 1000
local ew_runtime = nil

local function inventory_sync()
    if ew_runtime == nil then ew_runtime = dofile("mods/metamorph_creative_menu/files/integrations/ew/runtime.lua") end
    return ew_runtime.force_inventory_sync()
end

local function is_polymorphed_player(entity_id)
    if not valid(entity_id) or type(EntityHasTag) ~= "function" then return false end
    local ok, value = pcall(EntityHasTag, entity_id, "polymorphed_player")
    return ok and value == true
end

local function remember_human_player(entity_id)
    if valid(entity_id) and not is_polymorphed_player(entity_id) then
        last_human_player_entity_id = entity_id
    end
end

local function flag_name(perk_id)
    if type(get_perk_picked_flag_name) == "function" then
        local ok, value = pcall(get_perk_picked_flag_name, perk_id)
        if ok and type(value) == "string" and value ~= "" then return value end
    end
    return "PERK_PICKED_" .. tostring(perk_id or "")
end

function perk_service.count(perk_id)
    local flag = flag_name(perk_id)
    return math.max(0, tonumber(GlobalsGetValue(flag .. "_PICKUP_COUNT", "0")) or 0)
end

local perk_catalog_by_id = nil
local function perk_by_id(perk_id)
    if perk_catalog_by_id == nil then
        perk_catalog_by_id = {}
        local ok, catalog = pcall(dofile, "mods/metamorph_creative_menu/files/features/perks/catalog.lua")
        if ok and type(catalog) == "table" and type(catalog.all) == "function" then
            for _, entry in ipairs(catalog.all() or {}) do
                if type(entry) == "table" and type(entry.id) == "string" then perk_catalog_by_id[entry.id] = entry end
            end
        end
    end
    return perk_catalog_by_id[tostring(perk_id or "")]
end

local function remove_callback(perk)
    for _, key in ipairs({ "func_remove", "remove_func", "func_remove_from_player" }) do
        if type(perk[key]) == "function" then return perk[key] end
    end
    return nil
end

function perk_service.can_remove(perk, player)
    if type(perk) ~= "table" then return false, "missing" end
    if transactions.has(perk.id, player) then return true, "tracked_inverse" end
    -- NO_MORE_SHUFFLE changes every wand that exists at pickup time. Without our
    -- transaction snapshot there is no safe way to infer each wand's previous shuffle
    -- state, so do not advertise an inverse that would only clear the global flag.
    if perk.id == "NO_MORE_SHUFFLE" then return false, "requires_tracked_copy" end
    if inverses.has(perk.id) then return true, "inverse" end
    if perk.do_not_remove == true then return false, "do_not_remove" end
    if remove_callback(perk) ~= nil then return true, "callback" end
    -- A perk whose only persistent mechanics are GameEffectComponents can be
    -- decremented reversibly. Arbitrary perk.func() code often edits player/world
    -- components without an inverse, so pretending to remove it would corrupt state.
    if perk.func == nil then return true, "effect_only" end
    return false, "requires_inverse"
end

local presentation = dofile("mods/metamorph_creative_menu/files/features/perks/presentation.lua")

local function finalize_nested_child_count(player, child_perk_id)
    local child_perk = perk_by_id(child_perk_id)
    local current = perk_service.count(child_perk_id)
    if current <= 0 then return true, "already_zero" end
    local new_count = current - 1
    local flag = flag_name(child_perk_id)
    GlobalsSetValue(flag .. "_PICKUP_COUNT", tostring(new_count))
    if new_count <= 0 then
        pcall(GameRemoveFlagRun, flag)
        if type(child_perk) == "table" then presentation.on_count_zero(player, child_perk) end
        root_companions.on_count_zero(child_perk_id)
        if type(inverses.zero_cleanup) == "function" then pcall(inverses.zero_cleanup, player, child_perk_id) end
    end
    return true, "nested_count_restored"
end

local function revert_nested_children(player, parent_transaction_id)
    if parent_transaction_id == nil then return true, "no_nested_children" end
    local children = nested_pickups.children(parent_transaction_id)
    -- Reverse application order for deterministic rollback. Each exact child transaction
    -- can sit below a newer independent copy of the same perk.
    for index = #children, 1, -1 do
        local child = children[index]
        local ok, reason = transactions.revert_transaction(child.perk_id, player, child.transaction_id)
        if not ok then return false, "nested_" .. tostring(child.perk_id) .. ":" .. tostring(reason) end
        finalize_nested_child_count(player, child.perk_id)
    end
    nested_pickups.clear_parent(parent_transaction_id)
    return true, "nested_children_reverted:" .. tostring(#children)
end

function perk_service.remove_one(player, perk, options)
    options = type(options) == "table" and options or {}
    if not valid(player) or type(perk) ~= "table" or type(perk.id) ~= "string" then return false, "target" end
    local current = perk_service.count(perk.id)
    if current <= 0 then return false, "none" end
    local allowed, strategy = perk_service.can_remove(perk, player)
    if not allowed then return false, strategy end

    local callback = remove_callback(perk)
    if transactions.has(perk.id, player) then
        if perk.id == "GAMBLE" and type(transactions.top_transaction_id) == "function" then
            local parent_transaction_id = transactions.top_transaction_id(perk.id, player)
            local nested_ok, nested_reason = revert_nested_children(player, parent_transaction_id)
            if not nested_ok then return false, nested_reason end
        end
        local ok_inverse, inverse_reason = transactions.revert(perk.id, player)
        if not ok_inverse then
            local may_fallback = type(inverses.can_fallback_after_stale_transaction) == "function"
                and inverses.can_fallback_after_stale_transaction(perk.id)
            if not may_fallback then return false, inverse_reason end
            local ok_fallback, fallback_reason = inverses.remove(player, perk.id, current)
            if not ok_fallback then return false, tostring(inverse_reason) .. ":fallback:" .. tostring(fallback_reason) end
            if type(transactions.discard_top) == "function" then
                local discarded, discard_reason = transactions.discard_top(perk.id, player)
                if not discarded then return false, "fallback_discard:" .. tostring(discard_reason) end
            end
            strategy = "fallback_after_" .. tostring(inverse_reason) .. ":" .. tostring(fallback_reason)
        else
            strategy = inverse_reason or "tracked_inverse"
        end
        -- Structural tracking does not snapshot arbitrary Globals/run flags. Run only
        -- inverses that own such state, so one stack cannot consume another stack's effect.
        if type(inverses.post_tracked_cleanup) == "function" then
            pcall(inverses.post_tracked_cleanup, player, perk.id, current)
        end
    elseif inverses.has(perk.id) then
        local ok_inverse, inverse_reason = inverses.remove(player, perk.id, current)
        if not ok_inverse then return false, inverse_reason end
        strategy = inverse_reason or "inverse"
    elseif callback ~= nil then
        -- Vanilla definitions contain both func_remove(player) and legacy
        -- func_remove(perk_item, player, item_name) signatures. Passing the player in
        -- both entity slots is compatible with both and fixes ORBIT's three-argument
        -- cleanup without maintaining an id exception.
        local ok = pcall(callback, player, player, tostring(perk.ui_name or perk.id))
        if not ok then return false, "callback_failed" end
        -- Vanilla removal expires declared effects in addition to func_remove. This is
        -- performed only on the callback path: tracked/inverse paths already own their
        -- concrete effect, so a generic expiry there would remove the next stack too.
        presentation.expire_one_game_effect(player, perk.game_effect)
        presentation.expire_one_game_effect(player, perk.game_effect2)
    else
        -- Pure GameEffect/flag perks have no imperative inverse.
        presentation.expire_one_game_effect(player, perk.game_effect)
        presentation.expire_one_game_effect(player, perk.game_effect2)
    end
    local new_count = current - 1
    local flag = flag_name(perk.id)
    GlobalsSetValue(flag .. "_PICKUP_COUNT", tostring(new_count))
    if new_count <= 0 then
        pcall(GameRemoveFlagRun, flag)
        presentation.on_count_zero(player, perk)
        -- Root companions are owned separately from the player-tree transaction. Scan
        -- once more before retiring so a spawn from the most recent pickup cannot race
        -- an immediate Remove All. Only roots observed after this menu's pickup are killed.
        root_companions.on_count_zero(perk.id)
        -- Count zero is the only safe point for mechanics spawned asynchronously after
        -- the transaction's immediate post-pickup snapshot (Hungry Ghost, Iron Stomach,
        -- Lukki climb gravity). Run exact id-scoped cleanup only here.
        if type(inverses.zero_cleanup) == "function" then
            pcall(inverses.zero_cleanup, player, perk.id)
        end
    end
    if type(locomotion_guard.repair_if_idle) == "function" then
        pcall(locomotion_guard.repair_if_idle, player, type(transactions.active_count)=="function" and transactions.active_count() or 0)
    end
    -- Only tracked MCM-created copies are hidden from EW's global-perk advertisement.
    -- Ordinary vanilla pickups retain EW's native semantics, and untracked copies are
    -- deliberately not hidden because we could not later prove when that exact layer left.
    if options.defer_sync ~= true then pcall(ew_perk_visibility.refresh, perk.id, player, transactions) end
    return true, strategy, new_count
end

function perk_service.remove_all(player, perk)
    -- Synchronous compatibility path used by EW reconciliation and QA. The menu uses the
    -- bounded job below, so one UI command never runs this loop in a GUI frame.
    local perk_id = type(perk) == "table" and perk.id or ""
    local removed = 0
    while perk_service.count(perk_id) > 0 do
        if removed >= BATCH_REMOVE_LIMIT then return removed, "limit_reached" end
        local ok, reason = perk_service.remove_one(player, perk)
        if not ok then return removed, reason end
        removed = removed + 1
    end
    return removed, "ok"
end

local active_job = nil
local terminal_job_notice = nil
local next_job_id = 0

local function copy_job(job)
    if type(job) ~= "table" then return nil end
    return {
        id=job.id, kind=job.kind, perk_id=job.perk_id, total=job.total,
        completed=job.completed, state=job.state, reason=job.reason,
        waiting_async=job.waiting_transaction_id ~= nil,
    }
end

local function flush_job_sync(job)
    if type(job) ~= "table" or job.sync_dirty ~= true then return end
    if valid(job.player) then
        pcall(ew_perk_visibility.refresh, job.perk_id, job.player, transactions)
        if job.kind == "take" then pcall(inventory_sync) end
    end
    job.sync_dirty = false
end

local function finish_job(state, reason)
    local job = active_job
    if type(job) ~= "table" then return false end
    flush_job_sync(job)
    job.state = tostring(state or "done")
    job.reason = tostring(reason or job.state)
    if job.state ~= "done" then terminal_job_notice = copy_job(job) end
    active_job = nil
    return true
end

local function begin_job(kind, player, perk, total)
    if active_job ~= nil then return false, "busy" end
    if not valid(player) or is_polymorphed_player(player) then return false, "target" end
    if type(perk) ~= "table" or type(perk.id) ~= "string" or perk.id == "" then return false, "invalid" end
    total = math.max(1, math.floor(tonumber(total) or 1))
    next_job_id = next_job_id + 1
    active_job = {
        id=next_job_id, kind=kind, player=player, perk=perk, perk_id=perk.id,
        total=total, completed=0, state="running", sync_dirty=false,
        waiting_transaction_id=nil,
    }
    return true, "queued", active_job.id
end

function perk_service.start_take_job(player, perk, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount ~= 1 and amount ~= 10 and amount ~= 100 then return false, "amount" end
    return begin_job("take", player, perk, amount)
end

function perk_service.start_remove_all_job(player, perk)
    if not valid(player) or type(perk) ~= "table" then return false, "target" end
    local allowed, reason = perk_service.can_remove(perk, player)
    if not allowed then return false, reason end
    local count = perk_service.count(perk.id)
    if count <= 0 then return false, "none" end
    return begin_job("remove_all", player, perk, math.min(BATCH_REMOVE_LIMIT, count))
end

function perk_service.job_status()
    return copy_job(active_job)
end

function perk_service.consume_job_notice()
    local notice = terminal_job_notice
    terminal_job_notice = nil
    return notice
end

function perk_service.cancel_job()
    if active_job == nil then return false, "idle" end
    finish_job("cancelled", "cancelled")
    return true, "cancelled"
end

local function process_active_job(player)
    local job = active_job
    if type(job) ~= "table" then return end
    if not valid(player) or player ~= job.player or not valid(job.player) or is_polymorphed_player(player) then
        finish_job("stopped", "player_changed")
        return
    end

    if job.waiting_transaction_id ~= nil then
        local pending = type(nested_pickups.scope_open) == "function"
            and nested_pickups.scope_open(job.player, job.waiting_transaction_id) == true
        if pending then return end
        job.waiting_transaction_id = nil
    end

    local budget = BATCH_OPERATION_BUDGET
    local operations = 0
    while budget > 0 and active_job == job do
        if job.kind == "take" then
            if job.completed >= job.total then
                finish_job("done", "complete")
                break
            end
            local ok, reason, tracked, track_reason, transaction_id = perk_service.apply(job.player, job.perk, {
                ignore_debounce=true, defer_sync=true, batch=true,
            })
            if not ok then
                finish_job("error", tostring(reason))
                break
            end
            -- apply() may complete the vanilla pickup even when its structural delta is
            -- not safely reversible. Count and synchronize that real copy before
            -- stopping the batch; reporting 0/N here would be false and would leave EW
            -- inventory/perk state one successful operation behind.
            job.completed = job.completed + 1
            job.sync_dirty = true
            operations = operations + 1
            budget = budget - 1
            if tracked ~= true or tonumber(transaction_id) == nil then
                finish_job("error", "transaction:" .. tostring(track_reason or "untracked"))
                break
            end
            if job.perk_id == "GAMBLE" and type(nested_pickups.scope_open) == "function"
                and nested_pickups.scope_open(job.player, transaction_id) == true
            then
                job.waiting_transaction_id = transaction_id
                break
            end
        elseif job.kind == "remove_all" then
            if perk_service.count(job.perk_id) <= 0 then
                finish_job("done", "complete")
                break
            end
            if job.completed >= BATCH_REMOVE_LIMIT then
                finish_job("error", "limit_reached")
                break
            end
            local ok, reason = perk_service.remove_one(job.player, job.perk, {defer_sync=true, batch=true})
            if not ok then
                finish_job("error", tostring(reason))
                break
            end
            job.completed = job.completed + 1
            job.total = math.max(job.total, job.completed + perk_service.count(job.perk_id))
            job.sync_dirty = true
            operations = operations + 1
            budget = budget - 1
        else
            finish_job("error", "unknown_job")
            break
        end
    end
    if active_job == job and operations > 0 then flush_job_sync(job) end
    if active_job == job and job.kind == "take" and job.completed >= job.total and job.waiting_transaction_id == nil then
        finish_job("done", "complete")
    elseif active_job == job and job.kind == "remove_all" and perk_service.count(job.perk_id) <= 0 then
        finish_job("done", "complete")
    end
end

function perk_service.update(player)
    if type(transactions.update) == "function" then pcall(transactions.update) end
    local frame = tonumber(GameGetFrameNum()) or 0
    local rollback_budget = FAILED_ROLLBACK_RETRY_BUDGET
    for index = #failed_pickup_rollbacks, 1, -1 do
        if rollback_budget <= 0 then break end
        local pending = failed_pickup_rollbacks[index]
        local owner = type(pending) == "table" and pending.player or 0
        if valid(owner) and frame >= (tonumber(pending.next_retry_frame) or frame) then
            rollback_budget = rollback_budget - 1
            local ok = select(1, transactions.revert_transaction(pending.perk_id, owner, pending.transaction_id)) == true
            if ok then
                table.remove(failed_pickup_rollbacks, index)
            else
                local delay = math.max(FAILED_ROLLBACK_RETRY_INITIAL_FRAMES, tonumber(pending.retry_delay) or FAILED_ROLLBACK_RETRY_INITIAL_FRAMES)
                delay = math.min(FAILED_ROLLBACK_RETRY_MAX_FRAMES, delay * 2)
                pending.retry_delay = delay
                pending.next_retry_frame = frame + delay
            end
        end
    end
    if type(nested_pickups.update) == "function" then pcall(nested_pickups.update) end
    if not valid(player) then
        if active_job ~= nil then finish_job("stopped", "player_changed") end
        return
    end
    -- Perks belong to the human player state. During native polymorph the original human
    -- is serialized away; running its delayed ownership/presentation maintenance against
    -- the temporary creature would discard watches and associate cleanup with the wrong
    -- entity. Pause until the human returns, then rebind first.
    if is_polymorphed_player(player) then
        if active_job ~= nil then finish_job("stopped", "player_changed") end
        return
    end

    local has_active_transactions = type(transactions.active_count) == "function" and transactions.active_count() > 0
    if last_human_player_entity_id ~= nil and last_human_player_entity_id ~= player and has_active_transactions then
        local old_human_player_entity_id = last_human_player_entity_id
        local rebound = false
        if type(transactions.rebind_player) == "function" then
            rebound = select(1, transactions.rebind_player(old_human_player_entity_id, player)) == true
        end
        if rebound then
            if type(inverses.rebind_player) == "function" then pcall(inverses.rebind_player, old_human_player_entity_id, player) end
            if type(root_companions.rebind_player) == "function" then pcall(root_companions.rebind_player, old_human_player_entity_id, player) end
            if type(presentation.rebind_player) == "function" then pcall(presentation.rebind_player, old_human_player_entity_id, player) end
            if type(nested_pickups.rebind_player) == "function" then pcall(nested_pickups.rebind_player, old_human_player_entity_id, player) end
            if type(locomotion_guard.rebind_player) == "function" then pcall(locomotion_guard.rebind_player, old_human_player_entity_id, player) end
            last_human_player_entity_id = player
        end
        -- A just-deserialized player can expose its child/component tree one frame later.
        -- Keep the existing owner on failure so update() retries instead of stranding
        -- the transaction on stale ids.
        if not rebound then return end
    else
        last_human_player_entity_id = player
    end

    root_companions.update(perk_service.count)
    presentation.update(player, perk_service.count, function(owner, perk_id)
        if type(inverses.maintenance_cleanup) == "function" then
            pcall(inverses.maintenance_cleanup, owner, perk_id)
        end
    end)
    process_active_job(player)
end

function perk_service.begin_pickup(player, perk)
    remember_human_player(player)
    if type(locomotion_guard.capture_if_idle) == "function" then
        pcall(locomotion_guard.capture_if_idle, player, type(transactions.active_count)=="function" and transactions.active_count() or 0)
    end
    local perk_id = type(perk) == "table" and perk.id or perk
    if type(inverses.capture_pre_pickup) == "function" then pcall(inverses.capture_pre_pickup, player, perk_id) end
    local token = transactions.begin(player, perk_id)
    if type(token) == "table" and root_companions.supports(perk_id) then
        token.root_companion_before = root_companions.capture_before(player, perk_id)
    end
    return token
end

function perk_service.start_pickup_capture(token, environment)
    if type(transactions.start_capture) ~= "function" then return false end
    return transactions.start_capture(token, environment)
end

function perk_service.stop_pickup_capture(token)
    if type(transactions.stop_capture) == "function" then transactions.stop_capture(token) end
end

function perk_service.commit_pickup(token)
    if type(transactions.stop_capture) == "function" then transactions.stop_capture(token) end
    local ok, reason = transactions.commit(token)
    if type(token) == "table" then
        local perk_id = tostring(token.perk_id or "")
        root_companions.commit(perk_id, token.player, token.root_companion_before)
        if ok and token.parent_transaction_id ~= nil then
            nested_pickups.register_child(token.parent_transaction_id, perk_id, token.transaction_id)
        end
        if ok and perk_id == "GAMBLE" then
            nested_pickups.open_gamble_scope(token.player, token.transaction_id)
        end
    end
    return ok, reason
end


local last_direct_apply_frame = {}

local function cleanup_pickup_entity(entity_id)
    if not valid(entity_id) then return end
    -- Vanilla normally consumes the pickup. Some perks intentionally reparent their
    -- pickup entity under the player; that entity is then persistent perk state and must
    -- remain owned by the transaction instead of being destroyed by this helper.
    if type(EntityGetRootEntity) == "function" then
        local root_read, root_entity = pcall(EntityGetRootEntity, entity_id)
        if root_read and root_entity ~= nil and root_entity ~= 0 and root_entity ~= entity_id then return end
    end
    for _, lua_component in ipairs(EntityGetComponentIncludingDisabled(entity_id, "LuaComponent") or {}) do
        pcall(EntitySetComponentIsEnabled, entity_id, lua_component, false)
    end
    pcall(EntityKill, entity_id)
end

function perk_service.spawn(player_entity_id, perk)
    if not valid(player_entity_id) or type(perk) ~= "table" or type(perk.id) ~= "string" then
        return false, "invalid"
    end
    local player_x, player_y = EntityGetTransform(player_entity_id)
    if player_x == nil or type(perk_spawn) ~= "function" then return false, "unavailable" end
    local pickup_entity_id = perk_spawn(player_x + 12, player_y - 8, perk.id) or 0
    if pickup_entity_id ~= 0 then
        -- perk.xml is intentionally excluded from EW's generic item-spawn hook. Creative
        -- world spawns therefore need the same explicit vanilla/EW handoff used by items.
        -- The adapter is a no-op in singleplayer and uses EW's native ew_thrown path when
        -- networking is active, so the receiving peer does not need MCM installed.
        ew_world_items.notify_world_item(pickup_entity_id)
    end
    return pickup_entity_id ~= 0, pickup_entity_id ~= 0 and "spawned" or "spawn_failed", pickup_entity_id
end

-- Canonical immediate pickup path shared by UI, QA and compatibility callers.
function perk_service.apply(player_entity_id, perk, options)
    options = type(options) == "table" and options or {}
    if not valid(player_entity_id) or type(perk) ~= "table" or type(perk.id) ~= "string" then
        return false, "invalid"
    end
    local current_frame = tonumber(GameGetFrameNum()) or 0
    local previous_frame = tonumber(last_direct_apply_frame[perk.id]) or -100000
    if options.ignore_debounce ~= true and current_frame == previous_frame then return false, "debounced" end
    -- stackable controls vanilla perk-pool reappearance, not whether perk_pickup itself
    -- can execute again. Creative mode intentionally allows another real pickup of any
    -- perk; each copy receives its own rollback transaction.
    if type(perk_spawn) ~= "function" or type(perk_pickup) ~= "function"
        or (perk.func ~= nil and type(perk.func) ~= "function")
    then
        return false, "unavailable"
    end
    last_direct_apply_frame[perk.id] = current_frame

    local player_x, player_y = EntityGetTransform(player_entity_id)
    if player_x == nil or player_y == nil then return false, "player_transform" end
    local count_before = perk_service.count(perk.id)
    local token = perk_service.begin_pickup(player_entity_id, perk)
    if type(token) == "table" then token.source = "mcm_creative" end

    -- EW's persistent-flag hook can live in another Lua VM. Persistent discovery is
    -- optional here; vanilla still owns the actual local perk application.
    local perk_environment = _G
    if type(getfenv) == "function" then
        local environment_read, environment = pcall(getfenv, perk_pickup)
        if environment_read and type(environment) == "table" then perk_environment = environment end
    end
    local original_has_persistent = perk_environment.HasFlagPersistent
    local original_add_persistent = perk_environment.AddFlagPersistent
    perk_environment.HasFlagPersistent = function() return true end
    perk_environment.AddFlagPersistent = function() return nil end
    if token ~= nil then pcall(perk_service.start_pickup_capture, token, perk_environment) end

    local pickup_entity_id = 0
    METAMORPH_CREATIVE_MENU_PERK_CAPTURE_ACTIVE = true
    local pickup_succeeded, pickup_error = xpcall(function()
        -- Spawn a real vanilla perk entity because several perk paths depend on pickup
        -- entity state and cannot be reproduced correctly with entity id 0.
        -- Build the same perk item a player would touch, but mark it not to destroy
        -- neighboring perks because Creative Menu is not a Holy Mountain selection.
        pickup_entity_id = perk_spawn(player_x, player_y, perk.id, true) or 0
        if pickup_entity_id == 0 then error("perk_spawn_failed:" .. tostring(perk.id)) end
        local item_name = EntityGetName(pickup_entity_id)
        -- Vanilla data/scripts/perks/perk_pickup.lua forwards physical pickup to
        -- perk_pickup(item, player, name, true, kill_other_perks). Because this creative
        -- entity is spawned with perk_dont_remove_others=true, the exact equivalent is
        -- do_cosmetic_fx=true + kill_other_perks=false. Calling the already-loaded
        -- perk_pickup directly avoids re-dofile'ing perk.lua and accidentally replacing
        -- the appended external-pickup observer.
        perk_pickup(pickup_entity_id, player_entity_id, item_name, true, false)
    end, function(error_value)
        return type(debug) == "table" and type(debug.traceback) == "function"
            and debug.traceback(tostring(error_value), 2) or tostring(error_value)
    end)
    METAMORPH_CREATIVE_MENU_PERK_CAPTURE_ACTIVE = false

    if token ~= nil then pcall(perk_service.stop_pickup_capture, token) end
    perk_environment.HasFlagPersistent = original_has_persistent
    perk_environment.AddFlagPersistent = original_add_persistent
    cleanup_pickup_entity(pickup_entity_id)

    if not pickup_succeeded then
        -- Vanilla can throw after partially mutating the player before its public pickup
        -- count changes. Roll back the exact transaction id; remove_one() is intentionally
        -- not used here because count==0 must never make partial mutations unreachable.
        local rollback_ok, rollback_reason = true, "no_token"
        if token ~= nil then
            local tracked, track_reason = transactions.commit(token)
            if tracked then
                rollback_ok, rollback_reason = transactions.revert_transaction(perk.id, player_entity_id, token.transaction_id)
                if not rollback_ok then
                    local retry_delay = FAILED_ROLLBACK_RETRY_INITIAL_FRAMES
                    failed_pickup_rollbacks[#failed_pickup_rollbacks + 1] = {
                        perk_id=perk.id, player=player_entity_id, transaction_id=token.transaction_id,
                        retry_delay=retry_delay, next_retry_frame=(tonumber(GameGetFrameNum()) or 0) + retry_delay,
                    }
                end
            else
                rollback_ok, rollback_reason = false, "untracked:" .. tostring(track_reason)
            end
            if type(root_companions.abort_pickup) == "function" then
                pcall(root_companions.abort_pickup, perk.id, player_entity_id, token.root_companion_before)
            end
        end
        local flag = flag_name(perk.id)
        GlobalsSetValue(flag .. "_PICKUP_COUNT", tostring(count_before))
        if count_before <= 0 then pcall(GameRemoveFlagRun, flag)
        elseif type(GameAddFlagRun) == "function" then pcall(GameAddFlagRun, flag) end
        local reason = rollback_ok and "pickup_failed" or "pickup_failed_partial:" .. tostring(rollback_reason)
        return false, reason, pickup_error
    end

    local tracked, track_reason = true, "no_token"
    if token ~= nil then tracked, track_reason = perk_service.commit_pickup(token) end
    if options.defer_sync ~= true then
        if tracked == true then pcall(ew_perk_visibility.refresh, perk.id, player_entity_id, transactions) end
        inventory_sync()
    end
    return true, "applied", tracked == true, track_reason, type(token) == "table" and token.transaction_id or nil
end


METAMORPH_CREATIVE_MENU_PERK_SERVICE = perk_service
return perk_service
