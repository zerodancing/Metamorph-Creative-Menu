local root=assert(arg[1])
local native_dofile=dofile
local service_calls={helper=0,unsafe=0,loads=0}
local creature_service={
  is_internal_helper_path=function() service_calls.helper=service_calls.helper+1; return false end,
  unsafe_reason=function() service_calls.unsafe=service_calls.unsafe+1; return nil end,
}
local children_calls=0
local entity_tree={
  root=function(entity) return entity end,
  walk=function(entity,visitor)
    if visitor(entity)==false then return end
    children_calls=children_calls+1
    for _,child in ipairs(EntityGetAllChildren(entity) or {}) do visitor(child) end
  end,
}
dofile=function(path)
  if path=='mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua' then return entity_tree end
  if path=='mods/metamorph_creative_menu/files/features/creatures/service.lua' then
    service_calls.loads=service_calls.loads+1
    return creature_service
  end
  local prefix='mods/metamorph_creative_menu/'
  if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
  return native_dofile(path)
end

local alive={[1]=true,[2]=true,[3]=true}
local tags={ [2]={item_pickup=true}, [3]={} }
EntityGetIsAlive=function(e) return alive[e]==true end
EntityHasTag=function(e,t) return tags[e] and tags[e][t] or false end
EntityGetFilename=function(e)
  if e==2 then return 'data/entities/items/pickup/heart_fullhp.xml' end
  if e==3 then return 'data/entities/props/physics_rock.xml' end
  return 'data/entities/player.xml'
end
EntityGetFirstComponentIncludingDisabled=function(e,kind)
  if (e==2 or e==3) and kind=='DamageModelComponent' then return 100+e end
  if e==3 and (kind=='PhysicsBodyComponent' or kind=='PhysicsBody2Component') then return 200+e end
  return nil
end
EntityGetParent=function() return 0 end
EntityGetAllChildren=function() return {} end
EntityGetTransform=function(e) return e==1 and 0 or 10, e==1 and 0 or 10 end
DEBUG_GetMouseWorld=function() return 10,10 end
EntityGetInRadius=function() return {2,3} end

local targeting=assert(native_dofile(root..'/files/features/possession/targeting.lua'))
assert(service_calls.loads==1,'creature service should be cached once at module load')
assert(targeting.target_under_cursor(1,48)==0,'pickup/physics prop should not be considered possessable')
assert(service_calls.helper==0 and service_calls.unsafe==0,
  'obvious non-creature miss reached XML/catalogue classification')
assert(children_calls==0,'obvious non-creature miss recursively traversed entity children')
print('possession_fast_reject=PASS cached_service=true xml_scans=0 descendant_walks=0')
