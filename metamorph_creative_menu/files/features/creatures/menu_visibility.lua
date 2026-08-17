-- Exact-path presentation policy for the MOBS picker.
--
-- These entries are intentionally hidden only from the menu because they were manually
-- reviewed as non-playable forms. They are NOT transform compatibility verdicts: this
-- module must not affect spawning, possession targeting, or the creature service.
local menu_visibility = {}

local HIDDEN_EXACT_PATHS = {
    ["data/entities/animals/ending_placeholder/boss_limbs/slimeshooter_boss_limbs.xml"] = true,
    ["data/entities/animals/boss_book/book_physics.xml"] = true,
    ["data/entities/animals/ending_placeholder/boss_limbs/boss_limbs_physics.xml"] = true,
    ["data/entities/animals/boss_limbs/boss_limbs_physics.xml"] = true,
    ["data/entities/animals/boss_limbs/limb_enemy_generic.xml"] = true,
    ["data/entities/animals/ending_placeholder/boss_limbs/limb_enemy_generic.xml"] = true,
    ["data/entities/animals/boss_centipede/orb_mat_radioactive.xml"] = true,
    ["data/entities/animals/boss_wizard/meteor.xml"] = true,
    ["data/entities/animals/drone.xml"] = true,
    ["data/entities/animals/_test_walk.xml"] = true,
    ["data/entities/animals/mimic_physics.xml"] = true,
}

function menu_visibility.visible(path)
    return HIDDEN_EXACT_PATHS[tostring(path or "")] ~= true
end

function menu_visibility.hidden_paths()
    local result = {}
    for path in pairs(HIDDEN_EXACT_PATHS) do result[#result + 1] = path end
    table.sort(result)
    return result
end

return menu_visibility
