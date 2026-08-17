local root=assert(arg[1],"root required")
local native_dofile=dofile
METAMORPH_CREATIVE_MENU_ENTITY_CATALOG=nil

local hidden_path="data/entities/animals/drone.xml"
local similar_visible_path="data/entities/animals/drone_physics.xml"
local hidden_projectile="data/entities/animals/boss_wizard/meteor.xml"
local hidden_boss_limbs="data/entities/animals/boss_limbs/boss_limbs_physics.xml"
local ordinary_path="data/entities/animals/sheep.xml"

local creature_service={
  catalog_version=function() return 1 end,
  collect=function() return {
    {path=hidden_path,id="drone",display_name="Drone",category="OTHER"},
    {path=similar_visible_path,id="drone_physics",display_name="Drone physics",category="OTHER"},
    {path=hidden_projectile,id="meteor",display_name="Meteor",category="OTHER"},
    {path=hidden_boss_limbs,id="boss_limbs_physics",display_name="Boss limbs physics",category="OTHER"},
    {path=ordinary_path,id="sheep",display_name="Sheep",category="ANIMALS"},
  } end,
  warmup_step=function() return true,false end,
}
local function map(path)
  local prefix="mods/metamorph_creative_menu/"
  if string.sub(path,1,#prefix)==prefix then return root.."/"..string.sub(path,#prefix+1) end
  return path
end
dofile=function(path)
  if path=="mods/metamorph_creative_menu/files/features/creatures/service.lua" then return creature_service end
  return native_dofile(map(path))
end
local visibility=assert(dofile("mods/metamorph_creative_menu/files/features/creatures/menu_visibility.lua"))
assert(visibility.visible(hidden_path)==false,"manually reviewed non-playable path must be hidden from MOBS")
assert(visibility.visible(hidden_projectile)==false,"second exact reviewed path must be hidden from MOBS")
assert(visibility.visible(hidden_boss_limbs)==false,"boss limbs physics must be hidden only from MOBS picker")
assert(visibility.visible(similar_visible_path)==true,"menu exclusion must be exact-path only")
assert(visibility.visible(ordinary_path)==true,"ordinary creature was accidentally hidden")
assert(#visibility.hidden_paths()==11,"exact MOBS hidden set changed unexpectedly")

local catalog=assert(loadfile(root.."/files/features/creatures/ui_catalog.lua"))()
local values=assert(catalog.collect())
local seen={}
for _,entry in ipairs(values) do seen[entry.path]=true end
assert(not seen[hidden_path] and not seen[hidden_projectile] and not seen[hidden_boss_limbs],"reviewed non-playable forms leaked into MOBS picker")
assert(seen[similar_visible_path] and seen[ordinary_path],"menu-only filter removed unrelated creatures")
assert(seen["metamorph_creative_menu://player"],"player menu entry was lost")
print("creature_menu_visibility=PASS hidden_exact=11 unrelated_preserved=true ui_only=true")
