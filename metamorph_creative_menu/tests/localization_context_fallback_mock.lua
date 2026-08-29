local root = assert(arg[1], "root required")

function ModTextFileGetContent(path)
    if path == "mods/metamorph_creative_menu/translations.csv" then
        local file = assert(io.open(root.."/translations.csv", "rb"))
        local value = file:read("*a")
        file:close()
        return value
    end
    return ""
end
function GameTextGetTranslatedOrNot(key)
    if key == "$mcm_tab_spells" then return "ЗАКЛИНАНИЯ" end
    return key -- settings VM has not observed newly appended rows yet
end

local localization = assert(dofile(root.."/files/platform/noita/localization.lua"))
assert(localization.translate("$mcm_bind_menu_toggle","english fallback")=="Открыть / закрыть творческое меню",
    "settings-context Russian action label fell back to English")
assert(localization.translate("$mcm_bind_section_gameplay","english fallback")=="ИГРОВЫЕ ДЕЙСТВИЯ",
    "settings category was not localized")
local quoted = localization.translate("$mcm_mobs_review_help","english fallback")
assert(string.find(quoted,"нажмите моба",1,true) and string.find(quoted,"спавн",1,true),
    "quoted CSV row with comma was parsed incorrectly")
assert(localization.translate("$missing_key","fallback") == "fallback","missing-key fallback changed")

io.write("localization_context_fallback=PASS detected_russian=true quoted_csv=true no_english_flash=true\n")
