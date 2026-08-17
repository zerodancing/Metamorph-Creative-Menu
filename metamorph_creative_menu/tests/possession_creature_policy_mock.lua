local root=assert(arg[1])
local native_dofile=dofile
local current_filename="data/entities/animals/sheep.xml"
local alive={ [1]=true, [2]=true }
local components={ DamageModelComponent=true, AnimalAIComponent=true }
local creature_service={
  is_internal_helper_path=function(path) return false end,
  is_transformable_creature_path=function(path)
    return path~="data/entities/animals/boss_sky/boss_sky_damage.xml"
  end,
  canonical_transform_path=function(path) return path end,
}
local entity_tree={
  walk=function(root_entity, visitor) visitor(root_entity) end,
  root=function(entity) return entity end,
}
local function map(path)
  local prefix="mods/metamorph_creative_menu/"
  if string.sub(path,1,#prefix)==prefix then return root.."/"..string.sub(path,#prefix+1) end
  return path
end
dofile=function(path)
  if path=="mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua" then return entity_tree end
  if path=="mods/metamorph_creative_menu/files/features/creatures/service.lua" then return creature_service end
  return native_dofile(map(path))
end
EntityGetIsAlive=function(entity) return alive[entity]==true end
EntityHasTag=function() return false end
EntityGetFilename=function(entity) return entity==2 and current_filename or "data/entities/player.xml" end
EntityGetFirstComponentIncludingDisabled=function(entity, component_type)
  return components[component_type] and 100 or nil
end

local targeting=assert(native_dofile(root.."/files/features/possession/targeting.lua"))
assert(targeting.is_creature(2,1)==true,"ordinary transformable creature should be targetable")
current_filename="data/entities/animals/boss_sky/boss_sky_damage.xml"
assert(targeting.is_creature(2,1)==false,"confirmed unsafe exact path must not be targetable through G")
current_filename="data/entities/animals/boss_sky/boss_sky_damage_clone.xml"
assert(targeting.is_creature(2,1)==true,"similar filename must not inherit exact unsafe verdict")
print("possession_creature_policy=PASS exact_unsafe_shared=true no_substring_ban=true")
