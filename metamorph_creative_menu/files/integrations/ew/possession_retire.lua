local possession_retire = {}
local ew_runtime = dofile("mods/metamorph_creative_menu/files/integrations/ew/runtime.lua")

local OUTBOX_SEQUENCE_KEY = "mcm_possession_retire_outbox_seq_v1"
local OUTBOX_PATH_KEY = "mcm_possession_retire_outbox_path_v1"
local OUTBOX_X_KEY = "mcm_possession_retire_outbox_x_v1"
local OUTBOX_Y_KEY = "mcm_possession_retire_outbox_y_v1"
local OUTBOX_ACK_KEY = "mcm_possession_retire_outbox_ack_v1"
local sequence = math.max(
    tonumber(GlobalsGetValue(OUTBOX_SEQUENCE_KEY, "0")) or 0,
    tonumber(GlobalsGetValue(OUTBOX_ACK_KEY, "0")) or 0
)

local function valid_entity(entity)
    return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity)
end

function possession_retire.is_owned_locally(entity)
    if not ew_runtime.enabled() then return true end
    if not valid_entity(entity) then return false end

    if ModDoesFileExist("mods/quant.ew/files/resource/util_min.lua") then
        local loaded, util_min = pcall(dofile, "mods/quant.ew/files/resource/util_min.lua")
        if loaded and type(util_min) == "table" and type(util_min.do_i_own) == "function" then
            local checked, owned = pcall(util_min.do_i_own, entity)
            if checked then return owned == true end
        end
    end

    -- Unsynced entities have no EW GID and are local by construction. Older/newer EW
    -- builds can expose local ownership through value_bool on the ew_gid_lid storage.
    for _, storage_component in ipairs(EntityGetComponentIncludingDisabled(entity, "VariableStorageComponent") or {}) do
        local name_read, name = pcall(ComponentGetValue2, storage_component, "name")
        if name_read and name == "ew_gid_lid" then
            local owner_read, owned = pcall(ComponentGetValue2, storage_component, "value_bool")
            return owner_read and owned == true
        end
    end
    return true
end

function possession_retire.queue_remote(entity_filename, x, y)
    if not ew_runtime.enabled() then return false end
    if type(entity_filename) ~= "string" or entity_filename == "" or x == nil or y == nil then return false end

    sequence = sequence + 1
    local suffix = "_" .. tostring(sequence)
    -- Keep latest values for diagnostics/backwards compatibility and sequence-scoped
    -- values for lossless processing of several possessions in quick succession.
    GlobalsSetValue(OUTBOX_PATH_KEY, entity_filename)
    GlobalsSetValue(OUTBOX_X_KEY, tostring(x))
    GlobalsSetValue(OUTBOX_Y_KEY, tostring(y))
    GlobalsSetValue(OUTBOX_PATH_KEY .. suffix, entity_filename)
    GlobalsSetValue(OUTBOX_X_KEY .. suffix, tostring(x))
    GlobalsSetValue(OUTBOX_Y_KEY .. suffix, tostring(y))
    GlobalsSetValue(OUTBOX_SEQUENCE_KEY, tostring(sequence))
    return true
end

return possession_retire
