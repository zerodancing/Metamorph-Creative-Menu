local root = assert(arg[1], "root required")
local native_dofile = dofile

function ModDoesFileExist() return true end
function ModGetActiveModIDs() return {} end

dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/features/items/catalog.lua" then
        return {{path="data/entities/items/pickup/potion_empty.xml",name="EMPTY",category="CONTAINERS"}}
    end
    if path == "mods/metamorph_creative_menu/files/features/items/vanilla_outliers.lua" then
        return native_dofile(root .. "/files/features/items/vanilla_outliers.lua")
    end
    return native_dofile(path)
end

local catalog = assert(native_dofile(root .. "/files/features/items/ui_catalog.lua"))
local entries = assert(catalog.collect(function(value) return value end,
    function(_, fallback) return fallback end))
local paths = {}
for _, entry in ipairs(entries) do paths[entry.path]=entry end

assert(paths["data/entities/animals/boss_centipede/sampo.xml"]
    and paths["data/entities/animals/boss_centipede/sampo.xml"].category == "QUEST",
    "Sampo was not restored as a quest item")
assert(paths["data/entities/animals/boss_alchemist/key.xml"],
    "Crystal Key outlier was not restored as an item")
assert(paths["data/entities/animals/boss_centipede/rewards/reward_crown.xml"],
    "vanilla ItemComponent reward outliers were not restored")
assert(paths["data/entities/animals/mimic_potion.xml"] == nil,
    "a real creature with an ItemComponent leaked into the item catalogue")

print("item_outlier_catalog=PASS sampo=true key=true rewards=true mimic_excluded=true")
