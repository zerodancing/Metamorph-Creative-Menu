local root = assert(arg[1], "root required")
function dofile_once(path)
    if path == "data/scripts/gun/gun_enums.lua" then
        ACTION_TYPE_PROJECTILE = 0
        ACTION_TYPE_STATIC_PROJECTILE = 1
        ACTION_TYPE_MODIFIER = 2
        ACTION_TYPE_DRAW_MANY = 3
        ACTION_TYPE_MATERIAL = 4
        ACTION_TYPE_OTHER = 5
        ACTION_TYPE_UTILITY = 6
        ACTION_TYPE_PASSIVE = 7
        return true
    end
    if path == "data/scripts/gun/gun_actions.lua" then
        actions = {
            { id="B", type=ACTION_TYPE_MODIFIER, sprite="b.png" },
            { id="A", type=ACTION_TYPE_PROJECTILE, sprite="a.png" },
            { id="A", type=ACTION_TYPE_PROJECTILE, sprite="duplicate.png" },
        }
        return true
    end
    error("unexpected dofile_once: " .. tostring(path))
end
METAMORPH_CREATIVE_MENU_SPELL_CATALOG = nil
local catalog = assert(dofile(root .. "/files/features/spells/catalog.lua"))
assert(catalog.load() == true, "spell catalog did not load")
local all = assert(catalog.all())
assert(#all == 2 and all[1].id == "A" and all[2].id == "B", "spell catalog normalization/sort failed")
assert(catalog.by_id().A == all[1], "spell id index failed")
assert(#catalog.for_filter(2) == 1 and catalog.for_filter(2)[1].id == "A", "spell category filter failed")
assert(catalog.background_path(all[1]) == "data/ui_gfx/inventory/item_bg_projectile.png", "spell presentation metadata failed")
print("spell_catalog=PASS unique=true filters=true")
