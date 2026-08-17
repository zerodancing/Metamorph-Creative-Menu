local effect_policy = {}

function effect_policy.visible(entry, file_exists)
    if type(entry) ~= "table" then return false end
    file_exists = type(file_exists) == "function" and file_exists or function() return false end
    local icon = tostring(entry.icon or "")
    if icon == "" or not file_exists(icon) then return false end
    if type(entry.material) == "string" and entry.material ~= "" then return true end
    local path = tostring(entry.path or "")
    return path ~= "" and file_exists(path)
end

return effect_policy
