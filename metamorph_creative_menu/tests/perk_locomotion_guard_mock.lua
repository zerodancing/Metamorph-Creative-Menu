local root=assert(arg[1],"root")
local native_dofile=dofile
local player,platform=1,10
local alive={[1]=true}
local gravity=350
local world_factor=nil
EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetComponentIncludingDisabled=function(e,t) if e==player and t=="CharacterPlatformingComponent" then return {platform} end return {} end
ComponentGetValue2=function(c,f) if c==platform and f=="pixel_gravity" then return gravity end end
ComponentSetValue2=function(c,f,v) if c==platform and f=="pixel_gravity" then gravity=v end end
local prefix="mods/metamorph_creative_menu/"
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/features/world_rules/service.lua" then
  return {gravity_factor=function() return world_factor end}
 end
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
local guard=assert(native_dofile(root.."/files/features/perks/locomotion_guard.lua"))
assert(guard.capture_if_idle(player,0))
gravity=-0.0017334157600999
local ok,reason=guard.repair_if_idle(player,0); assert(ok,reason)
assert(math.abs(gravity-350)<1e-9,"near-zero perk residue not restored: "..tostring(gravity))
-- A deliberate world-rule zero is not residue and must remain zero.
assert(guard.capture_if_idle(player,0))
world_factor=0; gravity=0
assert(guard.repair_if_idle(player,0))
assert(gravity==0,"intentional zero-gravity world rule was overwritten")
print("perk_locomotion_guard=PASS pathological_player_gravity=true world_zero_preserved=true")
