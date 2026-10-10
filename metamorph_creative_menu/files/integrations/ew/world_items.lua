local world_items = {}
local ew_runtime = dofile("mods/metamorph_creative_menu/files/integrations/ew/runtime.lua")

-- Creative-menu code and EW's ew_thrown callback run in different Lua contexts. World
-- items therefore cross that boundary through a sequence-keyed event mailbox when a
-- direct CrossCall is unavailable. The EW-side consumer lives in bridge/items.lua.
local OUTBOX_SEQUENCE_KEY = "mcm_world_item_outbox_seq_v1"
local OUTBOX_ENTITY_KEY = "mcm_world_item_outbox_entity_v1"
local OUTBOX_ACK_KEY = "mcm_world_item_outbox_ack_v1"
local OUTBOX_RESULT_KEY = "mcm_world_item_outbox_result_v1"
local outbox_sequence = 0 -- merge the persisted value lazily in notify_world_item()
local CREATIVE_PERK_SEQ_KEY = "mcm_creative_perk_spawn_seq_v1"
local CREATIVE_PERK_ENTITY_KEY = "mcm_creative_perk_spawn_entity_v1:"
local CREATIVE_PERK_ID_KEY = "mcm_creative_perk_spawn_id_v1:"
local CREATIVE_PERK_X_KEY = "mcm_creative_perk_spawn_x_v1:"
local CREATIVE_PERK_Y_KEY = "mcm_creative_perk_spawn_y_v1:"
local CREATIVE_PERK_FRAME_KEY = "mcm_creative_perk_spawn_frame_v1:"
local creative_perk_sequence = 0

local function valid_entity(entity)
    return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity)
end

function world_items.des_gid(entity)
    if not valid_entity(entity) then return nil end
    -- Current EW DES stores its stable network GID in a VariableStorageComponent whose
    -- name is ew_gid_lid. This is a component value, not a component tag.
    for _, component in ipairs(EntityGetComponentIncludingDisabled(entity, "VariableStorageComponent") or {}) do
        local name_read, name = pcall(ComponentGetValue2, component, "name")
        if name_read and tostring(name or "") == "ew_gid_lid" then
            local value_read, value = pcall(ComponentGetValue2, component, "value_string")
            if value_read and tostring(value or "") ~= "" then return tostring(value) end
        end
    end
    return nil
end

local function legacy_global_item_id(entity)
    if not valid_entity(entity) then return nil end
    local component = EntityGetFirstComponentIncludingDisabled(entity, "VariableStorageComponent", "ew_global_item_id")
    if component == nil or component == 0 then return nil end
    local value_read, value = pcall(ComponentGetValue2, component, "value_string")
    return value_read and tostring(value or "") ~= "" and tostring(value) or nil
end

function world_items.notify_world_item(entity)
    if not valid_entity(entity) then return false, "invalid" end
    if not ew_runtime.enabled() then return true, "singleplayer" end

    if type(CrossCall) == "function" then
        local crosscall_succeeded, crosscall_error = pcall(CrossCall, "ew_thrown", entity)
        if crosscall_succeeded then return true, "direct" end
        if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE) == "function" then
            pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE, "item.ew_thrown", tostring(crosscall_error))
        end
    end

    outbox_sequence = math.max(outbox_sequence, tonumber(GlobalsGetValue(OUTBOX_SEQUENCE_KEY, "0")) or 0) + 1
    local sequence_suffix = ":" .. tostring(outbox_sequence)
    GlobalsSetValue(OUTBOX_ENTITY_KEY .. sequence_suffix, tostring(entity))
    -- Publish the sequence last so EW never consumes a half-written event.
    GlobalsSetValue(OUTBOX_SEQUENCE_KEY, tostring(outbox_sequence))
    return true, "queued:" .. tostring(outbox_sequence)
end

function world_items.register_creative_perk(entity, perk_id)
    perk_id = tostring(perk_id or "")
    if perk_id == "" or not valid_entity(entity) then return false, "invalid" end
    if not ew_runtime.enabled() then return true, "singleplayer" end
    if type(GlobalsSetValue) ~= "function" or type(GlobalsGetValue) ~= "function" then
        return false, "globals_unavailable"
    end
    local x, y = EntityGetTransform(entity)
    if tonumber(x) == nil or tonumber(y) == nil then return false, "position" end
    creative_perk_sequence = math.max(creative_perk_sequence,
        tonumber(GlobalsGetValue(CREATIVE_PERK_SEQ_KEY, "0")) or 0) + 1
    local suffix = tostring(creative_perk_sequence)
    GlobalsSetValue(CREATIVE_PERK_ENTITY_KEY .. suffix, tostring(entity))
    GlobalsSetValue(CREATIVE_PERK_ID_KEY .. suffix, perk_id)
    GlobalsSetValue(CREATIVE_PERK_X_KEY .. suffix, tostring(x))
    GlobalsSetValue(CREATIVE_PERK_Y_KEY .. suffix, tostring(y))
    GlobalsSetValue(CREATIVE_PERK_FRAME_KEY .. suffix,
        tostring(type(GameGetFrameNum)=="function" and GameGetFrameNum() or 0))
    GlobalsSetValue(CREATIVE_PERK_SEQ_KEY, suffix)
    return true, "registered:" .. suffix
end

function world_items.world_sync_state(entity)
    if not ew_runtime.enabled() then return true, "singleplayer", nil end
    if not valid_entity(entity) then return false, "dead", nil end

    local gid = world_items.des_gid(entity)
    if gid ~= nil then
        return true, EntityHasTag(entity, "ew_des") and "registered_des" or "registered_des_pending_tag", gid
    end

    local legacy_gid = legacy_global_item_id(entity)
    if legacy_gid ~= nil and EntityHasTag(entity, "ew_global_item") then
        return true, "registered_legacy", legacy_gid
    end
    if EntityHasTag(entity, "ew_des") then return false, "awaiting_des_gid", nil end
    if EntityHasTag(entity, "ew_global_item") then return false, "awaiting_legacy_gid", nil end
    return false, "awaiting_ew", nil
end

function world_items.force_inventory_sync()
    return ew_runtime.force_inventory_sync()
end

function world_items.outbox_state()
    return tonumber(GlobalsGetValue(OUTBOX_SEQUENCE_KEY, "0")) or 0,
        tonumber(GlobalsGetValue(OUTBOX_ACK_KEY, "0")) or 0,
        GlobalsGetValue(OUTBOX_RESULT_KEY, "")
end

return world_items
