if type(METAMORPH_CREATIVE_MENU_EW_FORM_DEATH_CHANNEL) == "table" then
    return METAMORPH_CREATIVE_MENU_EW_FORM_DEATH_CHANNEL
end

local form_death_channel = {}
local CROSSCALL_NAME = "metamorph_creative_menu_form_died"
local ACK_KEY = "mcm_form_death_intercept_ack_v1"

function form_death_channel.emit(form_entity_id, reason, responsible_entity_id, damage_amount, projectile_entity_id)
    if type(CrossCall) ~= "function" then return false, "crosscall_unavailable" end
    local call_succeeded = pcall(
        CrossCall,
        CROSSCALL_NAME,
        tonumber(form_entity_id) or 0,
        tostring(reason or "death"),
        tonumber(responsible_entity_id) or 0,
        tonumber(damage_amount),
        tonumber(projectile_entity_id) or 0
    )
    return call_succeeded, call_succeeded and "sent" or "crosscall_failed"
end

-- CrossCall itself has no portable return-value contract between Lua contexts. Publish
-- a one-value acknowledgement only after the main MCM form transaction has actually
-- committed the human replacement. EW's optional compatibility patch uses this to
-- distinguish "MCM rescued this creative form death" from an ordinary polymorph death.
function form_death_channel.register(noita_patcher_bridge, handler)
    if type(noita_patcher_bridge) ~= "table" or type(noita_patcher_bridge.CrossCallAdd) ~= "function" then
        return false
    end
    if type(handler) ~= "function" then return false end
    local function wrapped(entity, reason, responsible, damage, projectile)
        local ok, handled = pcall(handler, entity, reason, responsible, damage, projectile)
        if ok and handled == true and type(GlobalsSetValue) == "function" then
            local frame = 0
            if type(GameGetFrameNum) == "function" then
                local ok_frame, value = pcall(GameGetFrameNum)
                if ok_frame then frame = tonumber(value) or 0 end
            end
            pcall(GlobalsSetValue, ACK_KEY, tostring(tonumber(entity) or 0) .. ":" .. tostring(frame))
        end
        return ok and handled == true
    end
    -- Register in NoitaPatcher's native cross-VM channel. EW's main VM replaces the
    -- global CrossCall with a private same-VM table, so the EW compatibility patch
    -- deliberately invokes np.CrossCall to reach this handler.
    local registered = pcall(noita_patcher_bridge.CrossCallAdd, CROSSCALL_NAME, wrapped)
    if type(GlobalsSetValue) == "function" then
        pcall(GlobalsSetValue, "mcm_form_death_channel_registration_v1",
            registered and "native_cross_vm" or "failed")
    end
    return registered == true
end

function form_death_channel.ack_key() return ACK_KEY end

METAMORPH_CREATIVE_MENU_EW_FORM_DEATH_CHANNEL = form_death_channel
return form_death_channel
