local effect_policy = {}

function effect_policy.visible(entry, file_exists)
    if type(entry) ~= "table" then return false end
    file_exists = type(file_exists) == "function" and file_exists or function() return false end
    local icon = tostring(entry.icon or "")
    if icon == "" or not file_exists(icon) then
        -- Many perfectly valid vanilla effects omit UIIconComponent but still use the
        -- conventional status-indicator sprite. Resolve that here so they are not silently
        -- absent from the editor, while still refusing blank placeholder-only entries.
        local id = string.lower(tostring(entry.id or entry.game_effect or entry.custom_effect_id or ""))
        local candidate = id ~= "" and ("data/ui_gfx/status_indicators/" .. id .. ".png") or ""
        if candidate ~= "" and file_exists(candidate) then
            entry.icon = candidate
            icon = candidate
        else
            return false
        end
    end
    if type(entry.material) == "string" and entry.material ~= "" then return true end
    local path = tostring(entry.path or "")
    return path ~= "" and file_exists(path)
end

return effect_policy
