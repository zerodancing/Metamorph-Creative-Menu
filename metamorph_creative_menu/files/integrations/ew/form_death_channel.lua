if type(METAMORPH_CREATIVE_MENU_EW_FORM_DEATH_CHANNEL) == "table" then
    return METAMORPH_CREATIVE_MENU_EW_FORM_DEATH_CHANNEL
end

local form_death_channel = {}
local CROSSCALL_NAME = "metamorph_creative_menu_form_died"

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

function form_death_channel.register(noita_patcher_bridge, handler)
    if type(noita_patcher_bridge) ~= "table" or type(noita_patcher_bridge.CrossCallAdd) ~= "function" then
        return false
    end
    if type(handler) ~= "function" then return false end
    local registered = pcall(noita_patcher_bridge.CrossCallAdd, CROSSCALL_NAME, handler)
    return registered == true
end

METAMORPH_CREATIVE_MENU_EW_FORM_DEATH_CHANNEL = form_death_channel
return form_death_channel
