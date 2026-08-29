local root=assert(arg[1])
local native_dofile=dofile
local current_filename="data/entities/animals/sheep.xml"
local alive={ [1]=true, [2]=true, [3]=true }
local components={ DamageModelComponent=true, AnimalAIComponent=true }
local creature_service={
  is_internal_helper_path=function(path) return false end,
  -- Deliberately false: live world targeting must not require catalogue membership.
  is_transformable_creature_path=function() return false end,
  unsafe_reason=function(path)
    if path=="data/entities/animals/boss_sky/boss_sky_damage.xml" then return "unsafe" end
    return nil
  end,
  canonical_transform_path=function(path) return path end,
}
local entity_tree={
  walk=function(root_entity, visitor)
    if visitor(root_entity)==false then return end
    if root_entity==3 then visitor(2) end
  end,
  root=function(entity) return entity==2 and 3 or entity end,
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
EntityGetParent=function(entity) return entity==2 and 3 or 0 end
EntityGetFirstComponentIncludingDisabled=function(entity, component_type)
  return entity==2 and components[component_type] and 100 or nil
end
DEBUG_GetMouseWorld=function() return 20,30 end
EntityGetInRadius=function() return {3} end
EntityGetTransform=function(entity) return entity==2 and 20 or 0, entity==2 and 30 or 0 end

local targeting=assert(native_dofile(root.."/files/features/possession/targeting.lua"))
assert(targeting.is_creature(2,1)==true,"ordinary transformable creature should be targetable")
current_filename="mods/example/entities/natural_uncatalogued_mob.xml"
assert(targeting.is_creature(2,1)==true,"structurally valid uncatalogued natural mob was rejected")
assert(targeting.target_under_cursor(1,48)==2,"controller wrapper hid the natural creature from G")
current_filename="data/entities/animals/boss_sky/boss_sky_damage.xml"
assert(targeting.is_creature(2,1)==false,"confirmed unsafe exact path must not be targetable through G")
current_filename="data/entities/animals/boss_sky/boss_sky_damage_clone.xml"
assert(targeting.is_creature(2,1)==true,"similar filename must not inherit exact unsafe verdict")
print("possession_creature_policy=PASS exact_unsafe=true uncatalogued=true wrapped_target=true")
