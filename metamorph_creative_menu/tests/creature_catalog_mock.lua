local root=assert(arg[1])
local native_dofile=dofile
local catalog=native_dofile(root.."/files/features/creatures/catalog.lua")
local ids,seen={},{}
local function base(path) return string.match(path or "","([^/]+)%.xml$") or "" end
for _,v in ipairs(catalog) do
  local p=type(v)=="table" and v.path or v
  local id=base(p)
  if id~="" and not seen[id] and id~="boss_sky_damage" and id~="rocket" then seen[id]=true; ids[#ids+1]=id end
  if #ids>=140 then break end
end
for _,id in ipairs({"worm_big","drone_physics","boss_dragon","maggot","maggot_tiny","worm_end","meteor","orb_mat_radioactive"}) do
 if not seen[id] then ids[#ids+1]=id; seen[id]=true end
end
local icon_list=table.concat(ids,"\n").."\n"
local function map(path)
 local prefix="mods/metamorph_creative_menu/"
 if string.sub(path,1,#prefix)==prefix then return root.."/"..string.sub(path,#prefix+1) end
 return path
end
dofile=function(path) return native_dofile(map(path)) end
ModTextFileGetContent=function(path)
 if path=="data/ui_gfx/animal_icons/_list.txt" then return icon_list end
 if string.sub(path,1,22)=="data/entities/animals/" then
   local id=base(path)
   return '<Entity name="$animal_'..id..'"><AnimalAIComponent /></Entity>'
 end
 local f=io.open(map(path),"r"); if not f then return "" end; local d=f:read("*a"); f:close(); return d
end
ModDoesFileExist=function(path)
 if string.sub(path,1,5)=="data/" then return true end
 local f=io.open(map(path),"r"); if f then f:close(); return true end
 return false
end
GameTextGetTranslatedOrNot=function(v) return v end
ModGetActiveModIDs=function() return {"metamorph_creative_menu"} end
local critical={
 "data/entities/animals/illusions/worm_big.xml","data/entities/animals/drone_physics.xml",
 "data/entities/animals/boss_dragon.xml","data/entities/animals/maggot.xml",
 "data/entities/animals/maggot_tiny/maggot_tiny.xml","data/entities/animals/worm_end.xml",
 "data/entities/animals/boss_wizard/meteor.xml","data/entities/animals/boss_centipede/orb_mat_radioactive.xml"
}
PolymorphTableGet=function(rare)
  -- Intentionally incomplete: QA must not assume PolymorphTableGet is the whole MOBS catalogue.
  return {critical[3], critical[4], critical[6]}
end
local api=assert(native_dofile(root.."/files/features/creatures/service.lua"))
local initial=assert(api.collect())
assert(#initial>=50,"initial catalog too small: "..#initial)
local done=false
for i=1,1000 do done=select(1,api.warmup_step(64)); if done then break end end
assert(done,"warmup did not finish")
local all=api.collect(); assert(#all>=100,"catalog too small after warmup: "..#all)
local set={}; for _,e in ipairs(all) do set[e.path]=true end
for _,p in ipairs(critical) do assert(set[p],"critical missing "..p) end
assert(set["data/entities/animals/tank.xml"],"root tank missing")
assert(set["data/entities/animals/vault/tank.xml"],"distinct same-basename vault tank was incorrectly collapsed")
assert(not set["data/entities/animals/boss_sky/boss_sky_damage.xml"],"unsafe sky leaked")
assert(not set["data/entities/animals/boss_robot/rocket.xml"],"unsafe rocket leaked")
local targets=api.collect_transform_target_paths()
local tset={}; for _,p in ipairs(targets) do tset[p]=true end
assert(not tset[critical[1]],"mock must keep PolymorphTable incomplete")
assert(tset[critical[3]],"explicit polymorph target missing")
local candidates=api.collect_prewarm_candidates(); local cset={}; for _,e in ipairs(candidates) do cset[type(e)=="table" and e.path or e]=true end
for _,p in ipairs(critical) do assert(cset[p],"prewarm candidate missing "..p) end
for _,p in ipairs({
 "data/entities/animals/meatmaggot.xml",
 "data/entities/animals/mimic_potion.xml",
 "data/entities/animals/slimeshooter_nontoxic.xml",
 "data/entities/animals/drone.xml",
 "data/entities/animals/scorpion_watchtower.xml",
 "data/entities/animals/fungus_tiny.xml",
 "data/entities/animals/fireskull_weak.xml",
 "data/entities/animals/wand_ghost_with_sampo.xml",
 "data/entities/animals/wand_ghost_charmed.xml",
 "data/entities/animals/illusions/worm_big.xml",
 -- Manual v13 clicks that falsely returned result=false near the end of MOBS.
 "data/entities/animals/boss_book/book_physics.xml",
 "data/entities/animals/boss_sky/boss_sky.xml",
 "data/entities/animals/boss_limbs/boss_limbs_physics.xml",
 "data/entities/animals/boss_limbs/slimeshooter_boss_limbs.xml",
 "data/entities/animals/lukki/lukki_creepy.xml",
 "data/entities/animals/mimic_physics.xml",
 "data/entities/animals/darkghost.xml",
}) do assert(cset[p],"late prewarm candidate missing "..p) end
print("creature_catalog_smoke=PASS initial="..#initial.." final="..#all.." polymorph_targets="..#targets.." prewarm="..#candidates.." full_catalog_has_all_core=true")
