-- Runs inside Entangled Worlds through files/api/extra_modules.lua.  This is a runtime
-- safety net for the source-level compatibility patch: even if EW loaded perk_fns.lua
-- before our ModTextFileSetContent patch ran, the already-loaded table is normalized here.
-- No new RPC is introduced; EW keeps transporting the owner's perk-count table.
local perk_runtime_guard = {}
local installed = false

local function pack_values(...)
    return {n=select('#', ...), ...}
end

local function unpack_values(values)
    local unpack_fn = unpack or table.unpack
    return unpack_fn(values, 1, values.n or #values)
end


-- These exact ids are not banned for the owning player. They are only unsafe or
-- semantically wrong when EW reconstructs the *same vanilla mechanics* on its synthetic
-- remote-player entity. Keep the icon/count replication but suppress duplicate mechanics.
local REMOTE_REPLICA_MECHANICS_UNSAFE = {
    ABILITY_ACTIONS_MATERIALIZED = true,
    RESPAWN = true,
    SAVING_GRACE = true,
    CORDYCEPS = true,
}

local function find_perk_entry(perk_id)
    for _, perk in ipairs(type(perk_list) == 'table' and perk_list or {}) do
        if type(perk) == 'table' and perk.id == perk_id then return perk end
    end
    return nil
end

local function suppress_remote_replica_mechanics(perk_data)
    if type(perk_list) ~= 'table' and type(dofile_once) == 'function' then
        pcall(dofile_once, 'data/scripts/perks/perk_list.lua')
    end
    local restore = {}
    for perk_id, count in pairs(type(perk_data) == 'table' and perk_data or {}) do
        if (tonumber(count) or 0) > 0 and REMOTE_REPLICA_MECHANICS_UNSAFE[perk_id] then
            local perk = find_perk_entry(perk_id)
            if perk ~= nil then
                restore[#restore + 1] = {
                    perk = perk,
                    func = perk.func,
                    game_effect = perk.game_effect,
                    game_effect2 = perk.game_effect2,
                    particle_effect = perk.particle_effect,
                }
                perk.func = nil
                perk.game_effect = nil
                perk.game_effect2 = nil
                perk.particle_effect = nil
            end
        end
    end
    return restore
end

local function restore_remote_replica_mechanics(entries)
    for _, entry in ipairs(entries or {}) do
        entry.perk.func = entry.func
        entry.perk.game_effect = entry.game_effect
        entry.perk.game_effect2 = entry.game_effect2
        entry.perk.particle_effect = entry.particle_effect
    end
end

local function clone_counts(source)
    local copy = {}
    for perk_id, count in pairs(type(source) == 'table' and source or {}) do copy[perk_id] = count end
    return copy
end

function perk_runtime_guard.install()
    if installed then return true, 'already_installed' end
    if type(dofile_once) ~= 'function' then return false, 'dofile_once_missing' end
    local ok_module, perk_fns = pcall(dofile_once, 'mods/quant.ew/files/core/perk_fns.lua')
    if not ok_module or type(perk_fns) ~= 'table' then return false, 'perk_fns_missing' end
    if perk_fns.__mcm_peer_runtime_guard_v1 == true then
        installed = true
        return true, 'already_installed'
    end
    if type(perk_fns.update_perks) ~= 'function' or type(perk_fns.on_world_update) ~= 'function' then
        return false, 'perk_fns_api_missing'
    end

    local original_update_perks = perk_fns.update_perks
    perk_fns.update_perks = function(perk_data, player_data)
        local normalized = clone_counts(perk_data)
        local entity = type(player_data) == 'table' and player_data.entity or nil
        if entity ~= nil and type(util) == 'table' and type(util.get_ent_variable) == 'function' then
            local current = util.get_ent_variable(entity, 'ew_current_perks') or {}
            for perk_id in pairs(type(current) == 'table' and current or {}) do
                if normalized[perk_id] == nil then normalized[perk_id] = 0 end
            end
        end
        local suppressed = suppress_remote_replica_mechanics(normalized)
        local results = pack_values(xpcall(function()
            return original_update_perks(normalized, player_data)
        end, function(error_value)
            return type(debug) == 'table' and type(debug.traceback) == 'function'
                and debug.traceback(tostring(error_value), 2) or tostring(error_value)
        end))
        restore_remote_replica_mechanics(suppressed)
        if results[1] ~= true then error(results[2]) end
        local returned = {n=results.n-1}
        for index=2,results.n do returned[index-1]=results[index] end
        return unpack_values(returned)
    end

    local original_world_update = perk_fns.on_world_update
    perk_fns.on_world_update = function(...)
        -- Upstream's to_spawn queue is only used to auto-pick EW's historical
        -- `global_perks` onto the local *real* player. That changes ownership and is the
        -- source of "I took/removed a perk and my teammate got/lost it too". Suppress the
        -- pickup only while this existing EW queue is serviced; ordinary vanilla/menu
        -- pickups and remote-replica rendering do not run through this function.
        local arguments = pack_values(...)
        local saved_spawn, saved_pickup = perk_spawn, perk_pickup
        perk_spawn = function() return 0 end
        perk_pickup = function() return nil end
        local results = pack_values(xpcall(function()
            return original_world_update(unpack_values(arguments))
        end, function(error_value)
            return type(debug) == 'table' and type(debug.traceback) == 'function'
                and debug.traceback(tostring(error_value), 2) or tostring(error_value)
        end))
        perk_spawn, perk_pickup = saved_spawn, saved_pickup
        if results[1] ~= true then error(results[2]) end
        local returned = {n=results.n-1}
        for index=2,results.n do returned[index-1]=results[index] end
        return unpack_values(returned)
    end

    perk_fns.__mcm_peer_runtime_guard_v1 = true
    installed = true
    if type(GlobalsSetValue) == 'function' then
        pcall(GlobalsSetValue, 'mcm_peer_perk_runtime_guard_v1', 'installed')
    end
    return true, 'installed'
end

return perk_runtime_guard
