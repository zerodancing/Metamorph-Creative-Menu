local localization = {}
local TRANSLATIONS = "mods/metamorph_creative_menu/translations.csv"

function localization.register()
    if not ModDoesFileExist(TRANSLATIONS) then return false end
    local ok_base, base = pcall(ModTextFileGetContent, "data/translations/common.csv")
    local ok_append, append = pcall(ModTextFileGetContent, TRANSLATIONS)
    if not ok_base or not ok_append or type(base) ~= "string" or type(append) ~= "string" then return false end
    local body = string.match(append, "^[^\n]*\n(.*)$") or ""
    if body == "" then return false end
    if not string.match(base, "\n$") then base = base .. "\n" end
    ModTextFileSetContent("data/translations/common.csv", base .. body .. (string.match(body, "\n$") and "" or "\n"))
    return true
end

return localization
