local root=assert(arg[1])
local native_dofile=dofile
local function map(path)
  local prefix="mods/metamorph_creative_menu/"
  if string.sub(path,1,#prefix)==prefix then return root.."/"..string.sub(path,#prefix+1) end
  return path
end
dofile=function(path) return native_dofile(map(path)) end

local files = {
  ["data/entities/animals/rainforest/scavenger_smg.xml"] = '<Entity><Base file="data/entities/animals/scavenger_smg.xml"><DamageModelComponent hp="2" /></Base></Entity>',
  ["data/entities/animals/vault/tank.xml"] = '<Entity><Base file="data/entities/animals/tank.xml"><DamageModelComponent hp="9" /></Base></Entity>',
  ["data/entities/animals/crypt/acidshooter.xml"] = '<Entity><Base file="data/entities/animals/acidshooter.xml"><DamageModelComponent hp="6" /></Base></Entity>',
  ["data/entities/animals/the_end/spearbot.xml"] = '<Entity><Base file="data/entities/animals/spearbot.xml"><DamageModelComponent hp="50" /></Base></Entity>',
  ["data/entities/animals/robobase/monk.xml"] = '<Entity><Base file="data/entities/animals/monk.xml"><DamageModelComponent hp="15" /></Base></Entity>',
  ["data/entities/animals/drunk/scavenger_smg.xml"] = '<Entity><Base file="data/entities/animals/scavenger_smg.xml"><DamageModelComponent hp="99" /></Base></Entity>',
  ["data/entities/animals/rainforest/fake.xml"] = '<Entity><Base file="data/entities/animals/another.xml"><DamageModelComponent hp="2" /></Base></Entity>',
  ["data/entities/animals/scavenger_smg.xml"] = '<Entity><AnimalAIComponent /></Entity>',
  ["data/entities/animals/tank.xml"] = '<Entity><AnimalAIComponent /></Entity>',
  ["data/entities/animals/acidshooter.xml"] = '<Entity><AnimalAIComponent /></Entity>',
  ["data/entities/animals/spearbot.xml"] = '<Entity><AnimalAIComponent /></Entity>',
  ["data/entities/animals/monk.xml"] = '<Entity><AnimalAIComponent /></Entity>',
  ["data/entities/animals/another.xml"] = '<Entity><AnimalAIComponent /></Entity>',
  ["data/entities/animals/worm_skull.xml"] = '<Entity><WormComponent /></Entity>',
  ["data/entities/animals/the_end/worm_skull.xml"] = '<Entity><Base file="data/entities/animals/worm_skull.xml" /></Entity>',
}
ModDoesFileExist=function(path)
  if files[path] ~= nil then return true end
  local f=io.open(map(path),'r'); if f then f:close(); return true end
  return false
end
ModTextFileGetContent=function(path)
  if files[path] ~= nil then return files[path] end
  local f=io.open(map(path),'r'); if not f then return '' end; local d=f:read('*a'); f:close(); return d
end
GameTextGetTranslatedOrNot=function(v) return v end
ModGetActiveModIDs=function() return {"metamorph_creative_menu"} end
PolymorphTableGet=function() return {} end
local loaded_entities = {}
EntityLoad=function(path,x,y) loaded_entities[#loaded_entities+1]=path return 77 end
EntityGetIsAlive=function() return true end
EntityGetTransform=function() return 10,20 end

local service=assert(dofile("mods/metamorph_creative_menu/files/features/creatures/service.lua"))

local rainforest_plan=assert(service.transform_plan("data/entities/animals/rainforest/scavenger_smg.xml"))
assert(rainforest_plan.target_path=="data/entities/animals/scavenger_smg.xml","rainforest same-species placement wrapper must use base body for player polymorph")
assert(rainforest_plan.mode=="placement_wrapper_fallback","rainforest fallback mode missing")

local vault_plan=assert(service.transform_plan("data/entities/animals/vault/tank.xml"))
assert(vault_plan.target_path=="data/entities/animals/tank.xml","vault same-species placement wrapper must use base body for player polymorph")
assert(vault_plan.mode=="placement_wrapper_fallback","vault fallback mode missing")

local crypt_plan=assert(service.transform_plan("data/entities/animals/crypt/acidshooter.xml"))
assert(crypt_plan.target_path=="data/entities/animals/acidshooter.xml","crypt same-species placement wrapper must use base body for player polymorph")
assert(crypt_plan.mode=="placement_wrapper_fallback","crypt fallback mode missing")

local the_end_plan=assert(service.transform_plan("data/entities/animals/the_end/spearbot.xml"))
assert(the_end_plan.target_path=="data/entities/animals/spearbot.xml","the_end same-species placement wrapper must use base body for player polymorph")
assert(the_end_plan.mode=="placement_wrapper_fallback","the_end fallback mode missing")

local robobase_plan=assert(service.transform_plan("data/entities/animals/robobase/monk.xml"))
assert(robobase_plan.target_path=="data/entities/animals/monk.xml","robobase same-species placement wrapper must use base body for player polymorph")
assert(robobase_plan.mode=="placement_wrapper_fallback","robobase fallback mode missing")

assert(service.canonical_transform_path("data/entities/animals/drunk/scavenger_smg.xml")=="data/entities/animals/drunk/scavenger_smg.xml","working non-crash-prone authored variant must keep exact XML")
assert(service.canonical_transform_path("data/entities/animals/rainforest/fake.xml")=="data/entities/animals/rainforest/fake.xml","directory alone must never justify cross-species substitution")
assert(service.canonical_transform_path("data/entities/animals/the_end/worm_skull.xml")=="data/entities/animals/worm_skull.xml","known exact alias must remain supported")

local spawned=service.spawn_near_player(1,"data/entities/animals/vault/tank.xml",32,-4)
assert(spawned==77 and loaded_entities[#loaded_entities]=="data/entities/animals/vault/tank.xml","LMB spawn must preserve original authored vault entity")
local crypt_spawned=service.spawn_near_player(1,"data/entities/animals/crypt/acidshooter.xml",32,-4)
assert(crypt_spawned==77 and loaded_entities[#loaded_entities]=="data/entities/animals/crypt/acidshooter.xml","LMB spawn must preserve original authored crypt entity")
local the_end_spawned=service.spawn_near_player(1,"data/entities/animals/the_end/spearbot.xml",32,-4)
assert(the_end_spawned==77 and loaded_entities[#loaded_entities]=="data/entities/animals/the_end/spearbot.xml","LMB spawn must preserve original authored the_end entity")

local robobase_spawned=service.spawn_near_player(1,"data/entities/animals/robobase/monk.xml",32,-4)
assert(robobase_spawned==77 and loaded_entities[#loaded_entities]=="data/entities/animals/robobase/monk.xml","LMB spawn must preserve original authored robobase entity")

print("creature_exact_target=PASS rainforest_vault_crypt_the_end_robobase_player_fallback=true spawn_original=true other_variants_exact=true")
