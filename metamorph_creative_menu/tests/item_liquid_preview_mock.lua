local root = assert(arg[1], "root required")
local alive = { [1]=true }
local killed = false
function EntityGetIsAlive(entity_id) return alive[entity_id] == true end
function EntityGetTransform(entity_id) return 10, 20 end
function EntityLoad(path, x, y)
    assert(path == "data/entities/items/pickup/potion_empty.xml", "wrong preview probe")
    assert(y == -99980, "preview probe should be hidden far above the player")
    alive[2] = true
    return 2
end
function RemoveMaterialInventoryMaterial(entity_id) end
function AddMaterialInventoryMaterial(entity_id, material_id, amount)
    assert(material_id == "water" and amount == 1000, "wrong preview material")
end
function GameGetPotionColorUint(entity_id)
    -- 0x00332211 => red=0x11, green=0x22, blue=0x33
    return 0x00332211
end
function EntityKill(entity_id) alive[entity_id] = false; killed = true end
function ModTextFileGetContent(path)
    assert(path == "data/materials.xml", "wrong material definition source")
    return [[
<Materials>
  <CellData name="rock">
    <Graphics texture_file="data/materials_gfx/rock.png" color="ff112233"></Graphics>
  </CellData>
  <CellDataChild name="rock_child" _parent="rock"></CellDataChild>
</Materials>]]
end

METAMORPH_CREATIVE_MENU_MATERIAL_PREVIEW = nil
local preview = assert(dofile(root .. "/files/platform/noita/material_preview.lua"))
local color = assert(preview.sample_liquid_color(1, "water"))
assert(math.abs(color[1] - 0x11/255) < 0.00001, "red byte decoded incorrectly")
assert(math.abs(color[2] - 0x22/255) < 0.00001, "green byte decoded incorrectly")
assert(math.abs(color[3] - 0x33/255) < 0.00001, "blue byte decoded incorrectly")
assert(killed == true, "preview probe leaked")
assert(preview.texture("rock_child") == "data/materials_gfx/rock.png",
    "child material did not inherit its authored texture")
local tint = assert(preview.tint("rock_child"), "child material did not inherit its authored tint")
assert(math.abs(tint[1] - 0x11/255) < 0.00001
    and math.abs(tint[2] - 0x22/255) < 0.00001
    and math.abs(tint[3] - 0x33/255) < 0.00001,
    "authored material tint was decoded incorrectly")
print("item_liquid_preview=PASS probe_cleanup=true color_order=true texture_inheritance=true")
