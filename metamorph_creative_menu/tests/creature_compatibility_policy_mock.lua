local root=assert(arg[1])
local native_dofile=dofile
local function map(path)
  local prefix="mods/metamorph_creative_menu/"
  if string.sub(path,1,#prefix)==prefix then return root.."/"..string.sub(path,#prefix+1) end
  return path
end
dofile=function(path) return native_dofile(map(path)) end
PolymorphTableGet=function(rare)
  if rare then return {"data/entities/animals/native_rare.xml"} end
  return {"data/entities/animals/native_common.xml"}
end
local c=assert(dofile("mods/metamorph_creative_menu/files/features/creatures/compatibility.lua"))
local status,reason=c.status("data/entities/animals/native_common.xml",true)
assert(status=="verified" and reason=="noita_polymorph_common","native common polymorph must be verified")
status,reason=c.status("data/entities/animals/native_rare.xml",true)
assert(status=="verified" and reason=="noita_polymorph_rare","native rare polymorph must be verified")
status,reason=c.status("data/entities/animals/boss_wizard/meteor.xml",true)
assert(status=="verified" and reason=="manual_verified_playable","manual exact safe override missing")
status,reason=c.status("data/entities/animals/boss_robot/rocket.xml",true)
assert(status=="unsafe" and reason=="projectile_death_overlay","manual exact unsafe override missing")
status,reason=c.status("data/entities/animals/new_mod_creature.xml",true)
assert(status=="candidate" and reason=="structural_preflight_only","unknown structural creature should be a candidate, not falsely verified")
status,reason=c.status("data/entities/animals/not_a_creature.xml",false)
assert(status=="unsupported","non-creature must remain unsupported")
assert(c.canonical_target("data/entities/animals/the_end/worm_skull.xml")=="data/entities/animals/worm_skull.xml","exact canonical alias missing")
assert(c.canonical_target("data/entities/animals/vault/tank.xml")==nil,"generic same-basename canonicalization must not return")
print("creature_compatibility_policy=PASS exact_overrides=true native_verification=true candidates_unverified=true")
