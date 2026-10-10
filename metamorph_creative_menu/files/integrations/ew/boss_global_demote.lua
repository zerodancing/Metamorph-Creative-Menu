-- Prevent EW from retaining a dead global boss authority record after the entity dies.
-- Delayed-kill bosses keep EW's stock lifecycle unless they are an MCM-created Kolmisilma.
-- Component IDs are preserved while the entity is hidden from the initial classification,
-- and a temporary CameraBoundComponent keeps the authored filename available for replicas.
local demote = {}

local STATUS = "mcm21_boss_global_demote_v1"
local HIDDEN = "mcm21_boss_global_hidden_v1"
local RESTORED = "mcm21_boss_global_restored_v1"
local FAILED = "mcm21_boss_global_failed_v1"
local GAP_HIDDEN = "mcm21_boss_global_gap_hidden_v1"
local LOAD_HIDDEN = "mcm21_boss_global_load_hidden_v1"
local DESERIALIZE_HIDDEN = "mcm21_boss_global_deserialize_hidden_v1"
local WAIT_BYPASS = "mcm21_boss_wait_kill_bypass_v1"
local CREATIVE_KOLMI_DEMOTED = "mcm27_creative_kolmi_non_global_v1"
local CREATIVE_KOLMI_TAG = "mcm_creative_kolmi_v3"
local FILENAME_FORCED = "mcm21_boss_filename_spawninfo_v1"
local MAX_HIDDEN_FRAMES = 30

local pending = {}
local installed = false
local original_new_entity = nil
local original_world_update = nil
local original_entity_load = nil
local original_ewext_deserialize = nil
local last_seen_entity_id = 0

local function set_global(key, value)
    if type(GlobalsSetValue) == "function" then
        pcall(GlobalsSetValue, key, tostring(value or ""))
    end
end

local function bump(key)
    if type(GlobalsGetValue) ~= "function" or type(GlobalsSetValue) ~= "function" then return end
    local ok, value = pcall(GlobalsGetValue, key, "0")
    value = ok and (tonumber(value) or 0) or 0
    pcall(GlobalsSetValue, key, tostring(value + 1))
end

local function frame_num()
    if type(GameGetFrameNum) ~= "function" then return 0 end
    local ok, value = pcall(GameGetFrameNum)
    return ok and (tonumber(value) or 0) or 0
end

local function max_entity_id()
    if type(EntitiesGetMaxID) ~= "function" then return last_seen_entity_id end
    local ok, value = pcall(EntitiesGetMaxID)
    return ok and math.max(0, tonumber(value) or 0) or last_seen_entity_id
end

local function note_entity_id(entity)
    entity = tonumber(entity) or 0
    if entity > last_seen_entity_id then last_seen_entity_id = entity end
end

local function alive(entity)
    entity = tonumber(entity) or 0
    if entity == 0 or type(EntityGetIsAlive) ~= "function" then return false end
    local ok, value = pcall(EntityGetIsAlive, entity)
    return ok and value == true
end

local function has_tag(entity, tag)
    if type(EntityHasTag) ~= "function" then return false end
    local ok, value = pcall(EntityHasTag, entity, tag)
    return ok and value == true
end

local function component(entity, component_type)
    if type(EntityGetFirstComponentIncludingDisabled) ~= "function" then return nil end
    local ok, value = pcall(EntityGetFirstComponentIncludingDisabled, entity, component_type)
    if not ok or value == nil or value == 0 then return nil end
    return value
end

local function active_component(entity, component_type)
    if type(EntityGetFirstComponent) ~= "function" then
        -- Conservative fallback: without enabled-only lookup we cannot safely prove that
        -- BossDragon/StreamingKeepAlive are hidden from EW.
        return component(entity, component_type)
    end
    local ok, value = pcall(EntityGetFirstComponent, entity, component_type)
    if not ok or value == nil or value == 0 then return nil end
    return value
end

local function component_list(entity, component_type)
    if type(EntityGetComponentIncludingDisabled) ~= "function" then return {} end
    local ok, value = pcall(EntityGetComponentIncludingDisabled, entity, component_type)
    return ok and type(value) == "table" and value or {}
end

local function has_gid_storage(entity)
    for _, storage in ipairs(component_list(entity, "VariableStorageComponent")) do
        local ok_name, name = pcall(ComponentGetValue2, storage, "name")
        if ok_name and tostring(name or "") == "ew_gid_lid" then return true end
    end
    return false
end

local function wait_for_kill_handshake(entity)
    local damage = component(entity, "DamageModelComponent")
    if damage == nil or type(ComponentGetValue2) ~= "function" then return false end
    local ok, value = pcall(ComponentGetValue2, damage, "wait_for_kill_flag_on_death")
    return ok and value == true
end

local function is_local_untracked_boss(entity)
    if not alive(entity) then return false end
    -- Player forms are handled by EW polymorph, not enemy DES. Remote replicas and
    -- SpawnOnce death-replay entities must keep their stock lifecycle.
    if has_tag(entity, "player_unit") or has_tag(entity, "polymorphed_player")
        or has_tag(entity, "ew_des") or has_tag(entity, "ew_no_enemy_sync")
    then
        return false
    end
    if has_gid_storage(entity) then return false end

    local bossish = component(entity, "BossHealthBarComponent") ~= nil
        or component(entity, "BossDragonComponent") ~= nil
    if not bossish then return false end

    -- Delayed-kill bosses normally keep EW's stock global lifecycle. MCM-created
    -- Kolmisilma is the exception because it must avoid the same retained-authority
    -- path as other global bosses while preserving the authored Sampo encounter flow.
    -- Natural Kolmisilma and boss limbs remain untouched.
    if wait_for_kill_handshake(entity) then
        if has_tag(entity, "boss_centipede") and has_tag(entity, CREATIVE_KOLMI_TAG) then
            bump(CREATIVE_KOLMI_DEMOTED)
        else
            bump(WAIT_BYPASS)
            return false
        end
    end
    return true
end

local function split_tags(value)
    local out = {}
    value = tostring(value or "")
    for tag in string.gmatch(value, "[^,]+") do
        tag = string.gsub(tag, "^%s+", "")
        tag = string.gsub(tag, "%s+$", "")
        if tag ~= "" then out[#out + 1] = tag end
    end
    return out
end

local function snapshot_component(entity, component_id, component_type, mode)
    local members = {}
    if mode == "recreate" and type(ComponentGetMembers) == "function" and type(ComponentGetValue) == "function" then
        local ok_members, names = pcall(ComponentGetMembers, component_id)
        if ok_members and type(names) == "table" then
            for name in pairs(names) do
                local ok_value, value = pcall(ComponentGetValue, component_id, name)
                if ok_value and value ~= nil then members[tostring(name)] = tostring(value) end
            end
        end
    end
    local enabled = true
    if type(ComponentGetIsEnabled) == "function" then
        local ok_enabled, value = pcall(ComponentGetIsEnabled, component_id)
        if ok_enabled then enabled = value == true end
    end
    local tags = ""
    if mode == "recreate" and type(ComponentGetTags) == "function" then
        local ok_tags, value = pcall(ComponentGetTags, component_id)
        if ok_tags then tags = tostring(value or "") end
    end
    return {
        entity = entity,
        id = component_id,
        type = component_type,
        mode = mode,
        members = members,
        enabled = enabled,
        tags = tags,
    }
end

local function recreate_component(snapshot)
    local entity = tonumber(snapshot.entity) or 0
    if not alive(entity) then return true end
    local ok_add, new_component = false, nil
    if type(EntityAddComponent2) == "function" then
        ok_add, new_component = pcall(EntityAddComponent2, entity, snapshot.type, {})
    end
    if (not ok_add or new_component == nil or new_component == 0) and type(EntityAddComponent) == "function" then
        ok_add, new_component = pcall(EntityAddComponent, entity, snapshot.type, {})
    end
    if not ok_add or new_component == nil or new_component == 0 then
        return false, "add_failed:" .. tostring(snapshot.type)
    end
    if type(ComponentSetValue) == "function" then
        for name, value in pairs(snapshot.members or {}) do pcall(ComponentSetValue, new_component, name, value) end
    end
    if type(ComponentAddTag) == "function" then
        for _, tag in ipairs(split_tags(snapshot.tags)) do pcall(ComponentAddTag, new_component, tag) end
    end
    if type(EntitySetComponentIsEnabled) == "function" then
        pcall(EntitySetComponentIsEnabled, entity, new_component, snapshot.enabled == true)
    end
    return true, new_component
end

local function remove_component_if_present(entity, component_id)
    if component_id == nil or type(EntityRemoveComponent) ~= "function" then return end
    pcall(EntityRemoveComponent, entity, component_id)
end

local function restore_record(record)
    if record == nil or record.restored then return true end
    record.restored = true
    if not alive(record.entity) then return true end

    -- Native track_entity normally consumes every CameraBoundComponent itself. If a
    -- timeout/error path restored before tracking, remove our temporary disabled marker.
    if record.temp_camera_bound ~= nil then
        remove_component_if_present(record.entity, record.temp_camera_bound)
    end

    for _, snapshot in ipairs(record.components or {}) do
        if snapshot.mode == "disable" then
            if type(EntitySetComponentIsEnabled) == "function" then
                local ok = pcall(EntitySetComponentIsEnabled, record.entity, snapshot.id, snapshot.enabled == true)
                if not ok then
                    bump(FAILED)
                    set_global(STATUS, "restore_failed:enable:" .. tostring(snapshot.type))
                    return false, "enable_failed:" .. tostring(snapshot.type)
                end
            end
        else
            local ok, reason = recreate_component(snapshot)
            if not ok then
                bump(FAILED)
                set_global(STATUS, "restore_failed:" .. tostring(reason))
                return false, reason
            end
        end
    end
    bump(RESTORED)
    return true
end

local function force_filename_spawn_info(entity)
    -- EW switches to EntitySpawnInfo::Filename whenever track_entity removes any
    -- CameraBoundComponent. Use a disabled temporary marker so it has no gameplay
    -- effect before native tracking consumes it.
    if #component_list(entity, "CameraBoundComponent") > 0 then return nil, true end
    if type(EntityGetFilename) == "function" then
        local ok, filename = pcall(EntityGetFilename, entity)
        if not ok or tostring(filename or "") == "" then return nil, false end
    end
    local ok_add, marker = false, nil
    if type(EntityAddComponent2) == "function" then
        ok_add, marker = pcall(EntityAddComponent2, entity, "CameraBoundComponent", {})
    end
    if (not ok_add or marker == nil or marker == 0) and type(EntityAddComponent) == "function" then
        ok_add, marker = pcall(EntityAddComponent, entity, "CameraBoundComponent", {})
    end
    if not ok_add or marker == nil or marker == 0 then return nil, false end
    if type(EntitySetComponentIsEnabled) == "function" then
        pcall(EntitySetComponentIsEnabled, entity, marker, false)
    end
    bump(FILENAME_FORCED)
    return marker, true
end

local function hide_boss(entity)
    entity = tonumber(entity) or 0
    if entity == 0 or pending[entity] ~= nil or not is_local_untracked_boss(entity) then return false end

    local snapshots = {}
    -- Preserve component IDs for the two types EW only queries while enabled.
    for _, component_type in ipairs({ "StreamingKeepAliveComponent", "BossDragonComponent" }) do
        for _, component_id in ipairs(component_list(entity, component_type)) do
            local snapshot = snapshot_component(entity, component_id, component_type, "disable")
            snapshots[#snapshots + 1] = snapshot
            if type(EntitySetComponentIsEnabled) == "function" then
                pcall(EntitySetComponentIsEnabled, entity, component_id, false)
            end
        end
    end
    -- BossHealthBar is queried including disabled, so it must be absent during the
    -- native classification. Recreate it only after ew_gid_lid has been attached.
    for _, component_id in ipairs(component_list(entity, "BossHealthBarComponent")) do
        local snapshot = snapshot_component(entity, component_id, "BossHealthBarComponent", "recreate")
        snapshots[#snapshots + 1] = snapshot
        remove_component_if_present(entity, component_id)
    end

    local temp_camera_bound, filename_safe = force_filename_spawn_info(entity)

    if component(entity, "BossHealthBarComponent") ~= nil
        or active_component(entity, "StreamingKeepAliveComponent") ~= nil
        or active_component(entity, "BossDragonComponent") ~= nil
    then
        local temp = {
            entity = entity,
            components = snapshots,
            temp_camera_bound = temp_camera_bound,
            restored = false,
        }
        restore_record(temp)
        bump(FAILED)
        set_global(STATUS, "hide_failed")
        return false
    end

    pending[entity] = {
        entity = entity,
        components = snapshots,
        temp_camera_bound = temp_camera_bound,
        filename_safe = filename_safe,
        frame = frame_num(),
        restored = false,
    }
    bump(HIDDEN)
    set_global(STATUS, filename_safe and "hidden_filename_tracking" or "hidden_for_native_tracking")
    return true
end

local function has_gid(entity)
    if not alive(entity) then return false end
    return has_gid_storage(entity)
end

local function prepare_new_entities(arr)
    if type(arr) ~= "table" then return 0 end
    local count = 0
    for _, raw_entity in ipairs(arr) do
        local entity = tonumber(raw_entity) or 0
        note_entity_id(entity)
        if hide_boss(entity) then count = count + 1 end
    end
    return count
end

-- Catch only entities created after EW's top-level Lua discovery pass. This closes the
-- one-frame native fallback gap without EntityGetWithTag world scans.
local function prepare_native_gap_entities_before_update()
    local newest = max_entity_id()
    if newest <= last_seen_entity_id then return 0 end
    local first = last_seen_entity_id + 1
    local count = 0
    for entity = first, newest do
        if alive(entity) and hide_boss(entity) then count = count + 1 end
    end
    last_seen_entity_id = newest
    if count > 0 then
        bump(GAP_HIDDEN)
        set_global(STATUS, "native_gap_boss_hidden")
    end
    return count
end

local function observe_loaded_entity(entity, counter_key, status)
    entity = tonumber(entity) or 0
    if entity == 0 then return false end
    note_entity_id(entity)
    if hide_boss(entity) then
        bump(counter_key)
        set_global(STATUS, status)
        return true
    end
    return false
end

local function restore_after_native_update(force_all)
    local now = frame_num()
    for entity, record in pairs(pending) do
        local tracked = has_gid(entity) or has_tag(entity, "ew_des")
        local expired = now - (tonumber(record.frame) or now) >= MAX_HIDDEN_FRAMES
        if force_all or tracked or expired or not alive(entity) then
            if alive(entity) then restore_record(record) end
            pending[entity] = nil
            if tracked then set_global(STATUS, "tracked_non_global_restored")
            elseif expired then set_global(STATUS, "timeout_restored") end
        end
    end
end

local function wrap_native_spawn_entrypoints()
    if type(EntityLoad) == "function" then
        original_entity_load = EntityLoad
        EntityLoad = function(...)
            local entity = original_entity_load(...)
            observe_loaded_entity(entity, LOAD_HIDDEN, "entityload_boss_hidden")
            return entity
        end
    end
    if type(EwextDeserialize) == "function" then
        original_ewext_deserialize = EwextDeserialize
        EwextDeserialize = function(...)
            local values = { original_ewext_deserialize(...) }
            observe_loaded_entity(values[1], DESERIALIZE_HIDDEN, "deserialize_boss_hidden")
            local unpack_fn = unpack or table.unpack
            return unpack_fn(values)
        end
    end
end

function demote.install()
    if installed then return true, "already_installed" end
    if type(ewext) ~= "table"
        or type(ewext.module_on_new_entity) ~= "function"
        or type(ewext.module_on_world_update) ~= "function"
    then
        installed = true
        set_global(STATUS, "install_failed:ewext_api_unavailable")
        return false, "ewext_api_unavailable"
    end

    original_new_entity = ewext.module_on_new_entity
    original_world_update = ewext.module_on_world_update
    last_seen_entity_id = max_entity_id()
    wrap_native_spawn_entrypoints()

    ewext.module_on_new_entity = function(arr, len)
        prepare_new_entities(arr)
        local ok, result = pcall(original_new_entity, arr, len)
        if not ok then
            restore_after_native_update(true)
            error(result)
        end
        return result
    end

    ewext.module_on_world_update = function(...)
        prepare_native_gap_entities_before_update()
        local ok, result = pcall(original_world_update, ...)
        if not ok then
            restore_after_native_update(true)
            error(result)
        end
        restore_after_native_update(false)
        return result
    end

    installed = true
    set_global(STATUS, "installed")
    return true, "installed"
end

if rawget(_G, "METAMORPH_CREATIVE_MENU_TESTING") == true then
    demote._test = {
        prepare_new_entities = prepare_new_entities,
        prepare_native_gap_entities_before_update = prepare_native_gap_entities_before_update,
        restore_after_native_update = restore_after_native_update,
        pending_count = function()
            local n = 0
            for _ in pairs(pending) do n = n + 1 end
            return n
        end,
        last_seen_entity_id = function() return last_seen_entity_id end,
    }
end
return demote
