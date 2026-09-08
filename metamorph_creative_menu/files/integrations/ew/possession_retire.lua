local possession_retire = {}
local ew_runtime = dofile("mods/metamorph_creative_menu/files/integrations/ew/runtime.lua")

local OUTBOX_SEQUENCE_KEY = "mcm_possession_retire_outbox_seq_v1"
local OUTBOX_ENTITY_KEY = "mcm_possession_retire_outbox_entity_v1"
local OUTBOX_PATH_KEY = "mcm_possession_retire_outbox_path_v1"
local OUTBOX_X_KEY = "mcm_possession_retire_outbox_x_v1"
local OUTBOX_Y_KEY = "mcm_possession_retire_outbox_y_v1"
local OUTBOX_WAIT_KEY = "mcm_possession_retire_outbox_wait_v1"
local OUTBOX_RESPONSIBLE_KEY = "mcm_possession_retire_outbox_responsible_v1"
local OUTBOX_ACK_KEY = "mcm_possession_retire_outbox_ack_v1"
local sequence = 0

local function valid_entity(entity)
    return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity)
end

local function gid_component(entity)
    if not valid_entity(entity) then return 0 end
    for _, storage_component in ipairs(EntityGetComponentIncludingDisabled(entity, "VariableStorageComponent") or {}) do
        local ok, name = pcall(ComponentGetValue2, storage_component, "name")
        if ok and tostring(name or "") == "ew_gid_lid" then return storage_component end
    end
    return 0
end

local function root_of(entity)
    if not valid_entity(entity) then return 0 end
    if type(EntityGetRootEntity) == "function" then
        local ok, root = pcall(EntityGetRootEntity, entity)
        root = ok and (tonumber(root) or 0) or 0
        if root ~= 0 and valid_entity(root) then return root end
    end
    local current, guard = entity, 0
    while valid_entity(current) and guard < 64 and type(EntityGetParent) == "function" do
        local ok, parent = pcall(EntityGetParent, current)
        parent = ok and (tonumber(parent) or 0) or 0
        if parent == 0 or not valid_entity(parent) then break end
        current, guard = parent, guard + 1
    end
    return current
end

-- A click can land on a damage-bearing child while EW tracks a wrapper/root. Retiring
-- only the child leaves the DES identity alive and the boss is recreated on the next
-- network update. Resolve the entity that actually owns ew_gid_lid/ew_des first.
function possession_retire.network_entity(entity)
    entity = tonumber(entity) or 0
    if not valid_entity(entity) then return 0 end

    local current, guard = entity, 0
    while valid_entity(current) and guard < 64 do
        if gid_component(current) ~= 0 or EntityHasTag(current, "ew_des") then return current end
        if type(EntityGetParent) ~= "function" then break end
        local ok, parent = pcall(EntityGetParent, current)
        parent = ok and (tonumber(parent) or 0) or 0
        if parent == 0 or not valid_entity(parent) then break end
        current, guard = parent, guard + 1
    end

    local root = root_of(entity)
    if root ~= 0 and type(EntityGetAllChildren) == "function" then
        local queue, seen, index = {root}, {}, 1
        while index <= #queue and index <= 512 do
            local candidate = queue[index]; index = index + 1
            if valid_entity(candidate) and not seen[candidate] then
                seen[candidate] = true
                if gid_component(candidate) ~= 0 or EntityHasTag(candidate, "ew_des") then return candidate end
                for _, child in ipairs(EntityGetAllChildren(candidate) or {}) do queue[#queue + 1] = child end
            end
        end
    end
    return entity
end

function possession_retire.network_kind(entity)
    if not ew_runtime.enabled() then return "local", tonumber(entity) or 0 end
    entity = possession_retire.network_entity(entity)
    if entity == 0 then return "invalid", 0 end
    if gid_component(entity) ~= 0 or EntityHasTag(entity, "ew_des") then return "des", entity end
    if EntityHasTag(entity, "ew_replicated") then return "enemy_replica", entity end
    return "local", entity
end

function possession_retire.is_tracked(entity)
    local kind = possession_retire.network_kind(entity)
    return kind == "des"
end

function possession_retire.is_owned_locally(entity)
    if not ew_runtime.enabled() then return true end
    entity = possession_retire.network_entity(entity)
    if not valid_entity(entity) then return false end
    if EntityHasTag(entity, "ew_replicated") then return false end

    if ModDoesFileExist("mods/quant.ew/files/resource/util_min.lua") then
        local loaded, util_min = pcall(dofile, "mods/quant.ew/files/resource/util_min.lua")
        if loaded and type(util_min) == "table" and type(util_min.do_i_own) == "function" then
            local checked, owned = pcall(util_min.do_i_own, entity)
            if checked then return owned == true end
        end
    end
    local gid = gid_component(entity)
    if gid ~= 0 then
        local ok, owned = pcall(ComponentGetValue2, gid, "value_bool")
        return ok and owned == true
    end
    return true
end

local function event_values(entity, entity_filename, x, y, responsible)
    entity = possession_retire.network_entity(entity)
    if entity == 0 then return nil end
    local path = tostring(EntityGetFilename(entity) or "")
    if path == "" then path = tostring(entity_filename or "") end
    local ex, ey = EntityGetTransform(entity)
    ex, ey = tonumber(ex) or tonumber(x), tonumber(ey) or tonumber(y)
    if path == "" or ex == nil or ey == nil then return nil end
    return entity, path, ex, ey, tonumber(responsible) or 0
end

-- Queue DES retirement through the EW extra-module VM and wait for its ACK before the
-- main MCM context destroys the local entity tree. The entity id must remain alive until
-- ewext.des_death_notify has had a chance to resolve its ew_gid_lid; killing it in the same
-- update creates a race where DES keeps the authority and recreates the boss.
function possession_retire.queue_remote(entity, entity_filename, x, y, responsible)
    if not ew_runtime.enabled() then return false, "singleplayer" end
    local target, path, ex, ey, responsible_id = event_values(entity, entity_filename, x, y, responsible)
    if target == nil then return false, "invalid" end
    local kind = possession_retire.network_kind(target)
    if kind ~= "des" then return false, kind == "enemy_replica" and "enemy_sync_replica" or "untracked", target end

    sequence = math.max(sequence,
        tonumber(GlobalsGetValue(OUTBOX_SEQUENCE_KEY, "0")) or 0,
        tonumber(GlobalsGetValue(OUTBOX_ACK_KEY, "0")) or 0) + 1
    local suffix = "_" .. tostring(sequence)
    local values = {
        [OUTBOX_ENTITY_KEY]=tostring(target), [OUTBOX_PATH_KEY]=path,
        [OUTBOX_X_KEY]=tostring(ex), [OUTBOX_Y_KEY]=tostring(ey),
        [OUTBOX_WAIT_KEY]="0", [OUTBOX_RESPONSIBLE_KEY]=tostring(responsible_id),
    }
    for key, value in pairs(values) do
        GlobalsSetValue(key, value)
        GlobalsSetValue(key .. suffix, value)
    end
    GlobalsSetValue(OUTBOX_SEQUENCE_KEY, tostring(sequence))
    return true, "queued", target, sequence
end

function possession_retire.acknowledged(request_sequence)
    request_sequence = tonumber(request_sequence)
    if request_sequence == nil then return false end
    return (tonumber(GlobalsGetValue(OUTBOX_ACK_KEY, "0")) or 0) >= request_sequence
end

return possession_retire
