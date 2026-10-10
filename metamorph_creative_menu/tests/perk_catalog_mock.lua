local root = assert(arg[1], "root required")
function dofile_once(path)
    if path == "data/scripts/perks/perk.lua" then return true end
    if path == "data/scripts/perks/perk_list.lua" then
        perk_list = {
            { id="EXTRA_HP", ui_name="$perk_extra_hp" },
            { id="EXTRA_HP", ui_name="$duplicate" },
            { id="EDIT_WANDS_EVERYWHERE", ui_name="$perk_edit_wands" },
        }
        return true
    end
    error("unexpected dofile_once: " .. tostring(path))
end
METAMORPH_CREATIVE_MENU_PERK_CATALOG = nil
local catalog = assert(dofile(root .. "/files/features/perks/catalog.lua"))
local perks = assert(catalog.all())
assert(#perks == 2, "perk catalog did not deduplicate ids")
assert(perks[1].id == "EXTRA_HP" and perks[2].id == "EDIT_WANDS_EVERYWHERE", "perk source order changed unexpectedly")
print("perk_catalog=PASS unique=true")
