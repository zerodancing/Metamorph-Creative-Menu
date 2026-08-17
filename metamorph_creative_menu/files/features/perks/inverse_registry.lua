if type(METAMORPH_CREATIVE_MENU_PERK_INVERSES) == "table" then return METAMORPH_CREATIVE_MENU_PERK_INVERSES end

local inverse_registry = {}
local inverse_modules = {
    dofile("mods/metamorph_creative_menu/files/features/perks/inverse/lukki.lua"),
    dofile("mods/metamorph_creative_menu/files/features/perks/inverse/companions.lua"),
    dofile("mods/metamorph_creative_menu/files/features/perks/inverse/world.lua"),
    dofile("mods/metamorph_creative_menu/files/features/perks/inverse/player.lua"),
}

local remove_handlers = {}
local zero_cleanup_handlers = {}
local maintenance_handlers = {}
local post_tracked_handlers = {}
local fallback_after_stale_transaction = {}

local function merge_handlers(target, source)
    for perk_id, handler in pairs(source or {}) do
        target[perk_id] = handler
    end
end

for _, inverse_module in ipairs(inverse_modules) do
    merge_handlers(remove_handlers, inverse_module.handlers)
    merge_handlers(zero_cleanup_handlers, inverse_module.zero_cleanup_handlers)
    merge_handlers(maintenance_handlers, inverse_module.maintenance_handlers)
    merge_handlers(post_tracked_handlers, inverse_module.post_tracked_handlers)
    for perk_id, allowed in pairs(inverse_module.fallback_after_stale_transaction or {}) do
        if allowed == true then fallback_after_stale_transaction[perk_id] = true end
    end
end

function inverse_registry.can_fallback_after_stale_transaction(perk_id)
    return fallback_after_stale_transaction[tostring(perk_id or "")] == true
end

function inverse_registry.has(perk_id)
    return type(remove_handlers[tostring(perk_id or "")]) == "function"
end

function inverse_registry.capture_pre_pickup(player_entity_id, perk_id)
    for _, inverse_module in ipairs(inverse_modules) do
        if type(inverse_module.capture_pre_pickup) == "function" then
            local capture_succeeded, result = pcall(inverse_module.capture_pre_pickup, player_entity_id, tostring(perk_id or ""))
            if not capture_succeeded or result == false then return false end
        end
    end
    return true
end

function inverse_registry.rebind_player(old_player_entity_id, new_player_entity_id)
    for _, inverse_module in ipairs(inverse_modules) do
        if type(inverse_module.rebind_player) == "function" then
            local ok, result = pcall(inverse_module.rebind_player, old_player_entity_id, new_player_entity_id)
            if not ok or result == false then return false end
        end
    end
    return true
end

function inverse_registry.remove(player_entity_id, perk_id, current_count)
    local handler = remove_handlers[tostring(perk_id or "")]
    if type(handler) ~= "function" then return false, "no_inverse" end
    local handler_succeeded, changed, reason = pcall(handler, player_entity_id, current_count)
    if not handler_succeeded then return false, "inverse_error" end
    if changed == false then return false, reason or "inverse_no_change" end
    return true, reason or "inverse"
end

function inverse_registry.zero_cleanup(player_entity_id, perk_id)
    local handler = zero_cleanup_handlers[tostring(perk_id or "")]
    if type(handler) ~= "function" then return true, "not_needed" end
    local handler_succeeded, cleaned, reason = pcall(handler, player_entity_id)
    if not handler_succeeded then return false, "zero_cleanup_error" end
    return cleaned ~= false, reason or "zero_cleanup"
end

function inverse_registry.maintenance_cleanup(player_entity_id, perk_id)
    local handler = maintenance_handlers[tostring(perk_id or "")]
    if type(handler) ~= "function" then return true end
    local handler_succeeded, cleaned = pcall(handler, player_entity_id)
    return handler_succeeded and cleaned ~= false
end

function inverse_registry.post_tracked_cleanup(player_entity_id, perk_id, current_count)
    local handler = post_tracked_handlers[tostring(perk_id or "")]
    if type(handler) ~= "function" then return true, "not_needed" end
    local handler_succeeded, changed, reason = pcall(handler, player_entity_id, current_count)
    if not handler_succeeded then return false, "post_tracked_inverse_error" end
    -- Structural transaction cleanup may already have removed every concrete object;
    -- no additional change is still a successful post-cleanup outcome.
    return true, changed == false and (reason or "already_clean") or (reason or "post_tracked_inverse")
end

METAMORPH_CREATIVE_MENU_PERK_INVERSES = inverse_registry
return inverse_registry
