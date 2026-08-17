local root=assert(arg[1])
local native_dofile=dofile
local function map(path)
  local prefix="mods/metamorph_creative_menu/"
  if string.sub(path,1,#prefix)==prefix then return root.."/"..string.sub(path,#prefix+1) end
  return path
end
dofile=function(path) return native_dofile(map(path)) end

local xml={
  ["data/entities/animals/harmless_effect.xml"]='<Entity><AnimalAIComponent /></Entity>',
  ["data/entities/animals/boss_sky/boss_sky_damage_clone.xml"]='<Entity><CharacterDataComponent /><AnimalAIComponent /></Entity>',
  ["data/entities/animals/limbs/limb_long.xml"]='<Entity><IKLimbWalkerComponent /></Entity>',
  ["data/entities/animals/limbs/playable_limb.xml"]='<Entity><AnimalAIComponent /></Entity>',
  ["data/entities/animals/not_a_creature_effect.xml"]='<Entity><ParticleEmitterComponent /></Entity>',
  ["data/entities/animals/boss_sky/boss_sky_damage.xml"]='<Entity><AnimalAIComponent /></Entity>',
}
ModTextFileGetContent=function(path) return xml[path] or '' end
ModDoesFileExist=function(path) return xml[path]~=nil end
PolymorphTableGet=function() return {} end
GameTextGetTranslatedOrNot=function(v) return v end

local c=assert(dofile("mods/metamorph_creative_menu/files/features/creatures/classification.lua"))
assert(c.path_is_technical("data/entities/animals/harmless_effect.xml")==true,"fixture must look technical by name")
assert(c.probable_creature("data/entities/animals/harmless_effect.xml")==true,"technical-looking filename must not block a structural creature")
assert(c.probable_creature("data/entities/animals/boss_sky/boss_sky_damage_clone.xml")==true,"unsafe verdict must be exact-path, not substring/prefix")
assert(c.probable_creature("data/entities/animals/not_a_creature_effect.xml")==false,"non-creature XML must not be admitted merely because it is under animals")
assert(c.probable_creature("data/entities/animals/limbs/limb_long.xml")==false,"IK-only child helper must stay out by structure")
assert(c.probable_creature("data/entities/animals/limbs/playable_limb.xml")==true,"directory/name must not override standalone creature structure")
assert(c.unsafe_reason("data/entities/animals/boss_sky/boss_sky_damage.xml")=="native_transform_crash","confirmed crash path must remain blocked")
print("creature_structural_admission=PASS filename_hints_nonblocking=true exact_unsafe=true")
