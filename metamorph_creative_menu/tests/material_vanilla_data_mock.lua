-- Fixture: root CellData attributes from the user-supplied data(10).zip.
-- Child inheritance is excluded so expectations do not assume engine merge behavior.
local root=assert(arg[1], 'root required')
local materials={
 {"fire","FIRES","[fire],[hot]",false},
 {"spark","FIRES","[fire],[hot]",false},
 {"spark_electric","FIRES","[fire],[hot]",false},
 {"flame","FIRES","[fire],[hot]",false},
 {"sand_static","SANDS","[static],[corrodible],[alchemy],[solid],[earth]",true},
 {"nest_static","SANDS","[static],[corrodible],[burnable],[alchemy],[solid],[earth]",true},
 {"bluefungi_static","SANDS","[static],[corrodible],[burnable],[alchemy],[solid],[earth],[fungus]",true},
 {"rock_static","SANDS","[static],[corrodible],[meltable_to_lava],[alchemy],[solid],[earth]",true},
 {"water_static","LIQUIDS","[static]",true},
 {"endslime_static","LIQUIDS","[static],[alchemy],[solid],[earth]",true},
 {"slime_static","LIQUIDS","[static],[alchemy],[solid],[earth],[food]",true},
 {"spore_pod_stalk","LIQUIDS","[static],[alchemy],[solid],[burnable],[earth],[fungus]",true},
 {"lavarock_static","SANDS","[static],[corrodible],[alchemy],[solid],[earth]",true},
 {"static_magic_material","SANDS","[static],[corrodible],[alchemy],[solid]",true},
 {"meteorite_static","SANDS","[static],[corrodible],[alchemy],[solid],[earth]",true},
 {"templerock_static","SANDS","[static],[corrodible],[alchemy],[solid],[earth]",true},
 {"steel_static","SANDS","[static],[corrodible],[rust],[alchemy],[meltable_metal_generic],[solid],[earth]",true},
 {"rock_static_glow","SANDS","[static],[corrodible],[meltable_to_lava],[alchemy],[solid],[earth]",true},
 {"snow_static","SANDS","[static],[corrodible],[frozen],[meltable_to_water],[alchemy],[solid]",true},
 {"ice_static","SANDS","[static],[corrodible],[frozen],[meltable_to_water],[alchemy],[solid]",true},
 {"ice_acid_static","SANDS","[static],[corrodible],[frozen],[meltable_to_acid],[alchemy],[solid]",true},
 {"ice_cold_static","SANDS","[static],[corrodible],[frozen],[meltable_to_cold],[alchemy],[solid]",true},
 {"ice_radioactive_static","SANDS","[static],[corrodible],[frozen],[meltable_to_radioactive],[alchemy],[solid]",true},
 {"ice_poison_static","SANDS","[static],[corrodible],[frozen],[meltable_to_poison],[alchemy],[solid]",true},
 {"ice_meteor_static","SANDS","[static],[corrodible],[frozen],[meltable_to_lava],[alchemy],[solid],[earth]",true},
 {"tubematerial","SANDS","[static],[corrodible],[alchemy],[solid],[earth]",true},
 {"glass_static","SANDS","[static],[alchemy],[solid],[earth]",true},
 {"waterrock","SOLIDS","[static],[alchemy],[solid],[earth]",false},
 {"ice_glass","SOLIDS","[box2d],[static],[meltable_to_water],[alchemy],[solid],[cold]",false},
 {"ice_glass_b2","SOLIDS","[static],[meltable_to_water],[alchemy],[solid],[cold]",false},
 {"glass_brittle","SOLIDS","[static],[alchemy],[solid],[earth]",false},
 {"snowrock_static","SANDS","[static],[corrodible],[alchemy],[solid],[earth]",true},
 {"concrete_static","SANDS","[static],[corrodible],[meltable_to_lava],[alchemy],[solid],[earth]",true},
 {"wood_static","SANDS","[corrodible],[burnable],[alchemy],[solid],[earth]",true},
 {"cheese_static","SANDS","[static],[corrodible],[meltable_to_lava],[alchemy],[solid],[earth]",true},
 {"smoke","GASES","[gas]",false},
 {"cloud","GASES","[gas]",true},
 {"cloud_lighter","GASES","[gas]",true},
 {"smoke_explosion","GASES","[gas]",false},
 {"steam","GASES","[gas]",false},
 {"acid_gas","GASES","[gas],[burnable_fast]",false},
 {"acid_gas_static","GASES","[gas],[burnable_fast]",true},
 {"smoke_static","GASES","[gas]",true},
 {"blood_cold_vapour","GASES","[gas],[vapour],[cold]",false},
 {"sand_herb_vapour","GASES","[gas],[vapour]",false},
 {"radioactive_gas","GASES","[gas]",false},
 {"radioactive_gas_static","GASES","[gas]",true},
 {"magic_gas_hp_regeneration","GASES","[gas],[vapour],[regenerative_gas]",false},
 {"magic_gas_midas","GASES","[gas],[vapour]",false},
 {"magic_gas_worm_blood","GASES","[gas],[vapour]",false},
 {"rainbow_gas","GASES","[gas]",false},
 {"magic_gas_polymorph","GASES","[gas],[vapour],[alchemy]",false},
 {"magic_gas_weakness","GASES","[gas],[vapour],[alchemy]",false},
 {"magic_gas_teleport","GASES","[gas],[vapour],[alchemy]",false},
 {"magic_gas_fungus","GASES","[gas],[vapour],[alchemy]",false},
 {"water","LIQUIDS","[liquid],[corrodible],[freezable],[water],[liquid_common],[chaotic_transmutation]",false},
 {"water_temp","LIQUIDS","[liquid],[corrodible],[freezable],[water],[liquid_common]",false},
 {"water_ice","LIQUIDS","[liquid],[corrodible],[meltable_to_water],[freezable],[water],[liquid_common],[chaotic_transmutation]",false},
 {"water_swamp","LIQUIDS","[liquid],[corrodible],[meltable_to_water],[water],[impure],[liquid_common]",false},
 {"oil","LIQUIDS","[liquid],[burnable],[impure],[liquid_common],[chaotic_transmutation]",false},
 {"alcohol","LIQUIDS","[liquid],[water],[impure],[liquid_common],[chaotic_transmutation]",false},
 {"beer","LIQUIDS","[liquid],[water],[impure],[liquid_common]",false},
 {"milk","LIQUIDS","[liquid],[water],[impure],[liquid_common]",false},
 {"molut","LIQUIDS","[liquid],[water],[impure],[liquid_common]",false},
 {"sima","LIQUIDS","[liquid],[water],[impure],[liquid_common]",false},
 {"juhannussima","LIQUIDS","[liquid],[water],[impure],[liquid_common]",false},
 {"alcohol_gas","GASES","[gas],[burnable],[evaporable]",false},
 {"magic_liquid","LIQUIDS","[liquid],[water],[magic_liquid],[impure]",false},
 {"material_confusion","LIQUIDS","[liquid],[water],[magic_liquid],[impure]",false},
 {"material_darkness","LIQUIDS","[liquid],[water],[magic_liquid],[impure]",false},
 {"material_rainbow","LIQUIDS","[liquid],[water],[magic_liquid],[impure]",false},
 {"magic_liquid_weakness","LIQUIDS","[liquid],[water],[magic_liquid],[impure],[magic_faster]",false},
 {"magic_liquid_movement_faster","LIQUIDS","[liquid],[water],[magic_liquid],[impure],[magic_faster]",false},
 {"magic_liquid_faster_levitation","LIQUIDS","[liquid],[water],[magic_liquid],[impure],[magic_faster]",false},
 {"magic_liquid_faster_levitation_and_movement","LIQUIDS","[liquid],[water],[magic_liquid],[impure],[magic_faster]",false},
 {"magic_liquid_worm_attractor","LIQUIDS","[liquid],[water],[magic_liquid],[impure]",false},
 {"magic_liquid_protection_all","LIQUIDS","[liquid],[water],[magic_liquid],[impure]",false},
 {"magic_liquid_mana_regeneration","LIQUIDS","[liquid],[water],[magic_liquid],[impure]",false},
 {"magic_liquid_unstable_teleportation","LIQUIDS","[liquid],[water],[magic_liquid],[impure]",false},
 {"magic_liquid_teleportation","LIQUIDS","[liquid],[water],[magic_liquid],[impure]",false},
 {"magic_liquid_hp_regeneration","LIQUIDS","[liquid],[water],[magic_liquid],[regenerative]",false},
 {"magic_liquid_polymorph","LIQUIDS","[liquid],[water],[magic_liquid],[magic_polymorph],[impure]",false},
 {"magic_liquid_random_polymorph","LIQUIDS","[liquid],[water],[magic_liquid],[magic_polymorph],[impure]",false},
 {"magic_liquid_unstable_polymorph","LIQUIDS","[liquid],[water],[magic_liquid],[magic_polymorph],[impure]",false},
 {"magic_liquid_berserk","LIQUIDS","[liquid],[water],[magic_liquid],[impure]",false},
 {"magic_liquid_charm","LIQUIDS","[liquid],[water],[magic_liquid],[impure]",false},
 {"magic_liquid_invisibility","LIQUIDS","[liquid],[water],[magic_liquid],[impure]",false},
 {"cloud_radioactive","LIQUIDS","[liquid],[radioactive],[impure],[liquid_common]",false},
 {"cloud_blood","LIQUIDS","[liquid],[blood],[impure],[liquid_common]",false},
 {"cloud_slime","LIQUIDS","[liquid],[impure],[slime],[liquid_common]",false},
 {"swamp","LIQUIDS","[liquid],[corrodible],[soluble],[meltable_to_water],[freezable],[water],[impure],[liquid_common],[chaotic_transmutation]",false},
 {"mud","SANDS","[sand_ground],[corrodible],[meltable_to_lava],[impure]",false},
 {"blood","LIQUIDS","[liquid],[corrodible],[soluble],[blood],[impure],[liquid_common],[food],[chaotic_transmutation]",false},
 {"blood_fading","LIQUIDS","[liquid],[corrodible],[soluble],[evaporable_fast],[blood],[impure],[liquid_common],[food]",false},
 {"blood_fungi","LIQUIDS","[liquid],[corrodible],[soluble],[evaporable],[blood],[impure],[liquid_common],[food],[fungus],[chaotic_transmutation]",false},
 {"blood_worm","LIQUIDS","[liquid],[corrodible],[soluble],[blood],[impure],[liquid_common],[food],[chaotic_transmutation]",false},
 {"porridge","LIQUIDS","[liquid],[corrodible],[soluble],[impure],[liquid_common],[evaporable_by_fire],[food]",false},
 {"blood_cold","LIQUIDS","[liquid],[corrodible],[soluble],[evaporable_custom],[blood],[impure],[cold],[liquid_common]",false},
 {"radioactive_liquid","LIQUIDS","[liquid],[corrodible],[soluble],[radioactive],[impure],[liquid_common],[chaotic_transmutation]",false},
 {"radioactive_liquid_fading","LIQUIDS","[liquid],[corrodible],[soluble],[evaporable],[radioactive],[impure],[liquid_common]",false},
 {"plasma_fading","LIQUIDS","[liquid],[corrodible],[soluble],[evaporable_fast],[impure],[liquid_common]",false},
 {"gold_molten","LIQUIDS","[liquid],[corrodible],[molten],[alchemy],[gold],[solid],[liquid_common],[earth]",false},
 {"wax_molten","LIQUIDS","[liquid],[corrodible],[molten],[alchemy],[impure],[solid],[liquid_common],[earth]",false},
 {"silver_molten","LIQUIDS","[liquid],[corrodible],[molten],[alchemy],[solid],[liquid_common],[earth]",false},
 {"copper_molten","LIQUIDS","[liquid],[corrodible],[molten],[alchemy],[solid],[liquid_common],[earth]",false},
 {"brass_molten","LIQUIDS","[liquid],[corrodible],[molten],[alchemy],[solid],[liquid_common],[earth]",false},
 {"glass_molten","LIQUIDS","[liquid],[molten],[meltable_to_lava],[alchemy],[solid],[liquid_common],[earth]",false},
 {"glass_broken_molten","LIQUIDS","[liquid],[molten],[meltable_to_lava],[alchemy],[solid],[liquid_common],[earth]",false},
 {"steel_molten","LIQUIDS","[liquid],[molten],[alchemy],[solid],[liquid_common],[earth]",false},
 {"creepy_liquid","LIQUIDS","[liquid],[impure]",false},
 {"cement","LIQUIDS","[corrodible],[meltable_to_lava],[alchemy],[impure],[solid],[earth]",false},
 {"concrete_sand","SANDS","[corrodible],[meltable_to_lava],[alchemy]",false},
 {"sand","SANDS","[sand_ground],[corrodible],[meltable_to_lava_fast],[alchemy],[chaotic_transmutation]",false},
 {"bone","SANDS","[sand_ground],[corrodible],[meltable_to_lava],[alchemy],[chaotic_transmutation]",false},
 {"soil","SANDS","[sand_ground],[corrodible],[grows_grass],[meltable_to_lava],[alchemy],[solid]",false},
 {"sandstone","SANDS","[sand_ground],[corrodible],[meltable_to_lava],[alchemy],[solid],[earth]",false},
 {"fungisoil","SANDS","[sand_ground],[corrodible],[grows_fungus],[meltable_to_lava],[alchemy],[solid],[earth],[fungus]",false},
 {"honey","SANDS","[corrodible],[meltable_to_lava_fast],[alchemy],[meltable_by_fire],[chaotic_transmutation]",false},
 {"glue","SANDS","[liquid],[burnable],[alchemy],[impure]",false},
 {"slime","LIQUIDS","[corrodible],[meltable_to_lava],[alchemy],[slime],[liquid_common],[food],[chaotic_transmutation]",false},
 {"slush","LIQUIDS","[corrodible],[meltable_to_water],[alchemy],[snow],[chaotic_transmutation]",false},
 {"explosion_dirt","SANDS","[sand_ground],[corrodible]",false},
 {"vine","SANDS","[static],[sand_ground],[corrodible],[burnable],[alchemy]",true},
 {"root","SANDS","[static],[sand_ground],[corrodible],[burnable],[alchemy],[solid],[earth]",true},
 {"snow","SANDS","[static],[sand_ground],[corrodible],[frozen],[meltable_to_water],[alchemy],[chaotic_transmutation]",false},
 {"snow_sticky","SANDS","[sand_ground],[corrodible],[frozen],[meltable_to_water],[alchemy]",false},
 {"rotten_meat","SANDS","[sand_ground],[corrodible],[meltable_to_lava],[alchemy],[meat],[food]",false},
 {"meat_slime_sand","SANDS","[sand_ground],[corrodible],[meltable_to_lava],[alchemy],[meat],[slime],[food]",false},
 {"rotten_meat_radioactive","SANDS","[sand_ground],[corrodible],[meltable_to_lava],[alchemy],[meat],[solid],[earth],[food]",false},
 {"ice","SANDS","[sand_ground],[corrodible],[frozen],[meltable_to_water],[alchemy],[solid]",false},
 {"sand_herb","SANDS","[corrodible],[evaporable_custom],[burnable],[alchemy]",false},
 {"wax","SANDS","[burnable],[corrodible],[meltable],[alchemy],[solid],[earth]",false},
 {"gold","SANDS","[sand_metal],[corrodible],[meltable_metal],[alchemy],[gold],[solid],[earth]",false},
 {"silver","SANDS","[sand_metal],[corrodible],[meltable_metal],[alchemy],[solid],[earth]",false},
 {"copper","SANDS","[sand_metal],[corrodible],[meltable_metal],[alchemy],[solid],[earth]",false},
 {"brass","SANDS","[sand_metal],[corrodible],[meltable_metal],[alchemy],[solid],[earth]",false},
 {"diamond","SANDS","[sand_metal],[alchemy],[solid],[earth]",false},
 {"coal","SANDS","[sand_other],[corrodible],[burnable],[alchemy],[chaotic_transmutation]",false},
 {"sulphur","SANDS","[sand_other],[corrodible],[alchemy]",false},
 {"salt","SANDS","[sand_other],[corrodible],[alchemy],[chaotic_transmutation]",false},
 {"sodium_unstable","SANDS","[sand_other],[corrodible],[alchemy]",false},
 {"gunpowder","SANDS","[sand_other],[corrodible],[alchemy],[chaotic_transmutation]",false},
 {"gunpowder_explosive","SANDS","[sand_other],[corrodible],[alchemy],[chaotic_transmutation]",false},
 {"gunpowder_tnt","SANDS","[sand_other],[corrodible],[alchemy]",false},
 {"gunpowder_unstable","SANDS","[sand_other],[corrodible],[burnable],[alchemy],[chaotic_transmutation]",false},
 {"gunpowder_unstable_big","SANDS","[sand_other],[corrodible],[burnable],[alchemy]",false},
 {"monster_powder_test","SANDS","[sand_other],[corrodible],[burnable],[alchemy]",false},
 {"rat_powder","SANDS","[sand_other]",false},
 {"fungus_powder","SANDS","[sand_other],[fungus]",false},
 {"orb_powder","SANDS","[NO_FUNGAL_SHIFT]",false},
 {"gunpowder_unstable_boss_limbs","SANDS","[sand_other],[corrodible],[alchemy],[meat]",false},
 {"plastic_red","SANDS","[corrodible],[meltable],[alchemy]",false},
 {"plastic_red_molten","LIQUIDS","[liquid],[corrodible],[molten],[meltable_to_lava],[alchemy],[liquid_common]",false},
 {"grass","SANDS","[plant],[requires_air],[corrodible],[burnable],[alchemy],[impure]",false},
 {"grass_holy","SANDS","[plant],[requires_air],[corrodible],[burnable],[alchemy]",false},
 {"grass_darker","SANDS","[plant],[requires_air],[corrodible],[burnable],[alchemy],[impure]",false},
 {"fungi","SANDS","[plant],[corrodible],[burnable],[alchemy],[impure],[fungus]",false},
 {"spore","SANDS","[plant],[corrodible],[burnable],[alchemy],[impure]",false},
 {"moss","SANDS","[plant],[corrodible],[burnable],[alchemy],[impure]",false},
 {"plant_material","SANDS","[plant],[requires_air],[corrodible],[burnable]",false},
 {"plant_material_red","SANDS","[plant],[requires_air],[corrodible],[burnable]",false},
 {"plant_material_dark","SANDS","[plant],[requires_air],[corrodible],[burnable]",false},
 {"ceiling_plant_material","SANDS","[plant],[corrodible],[burnable]",false},
 {"mushroom_seed","SANDS","[plant],[corrodible],[burnable]",false},
 {"plant_seed","SANDS","[plant],[corrodible],[burnable]",false},
 {"mushroom","SANDS","[plant],[corrodible],[burnable]",false},
 {"mushroom_giant_red","SANDS","[plant],[requires_air],[corrodible],[burnable]",false},
 {"mushroom_giant_blue","SANDS","[plant],[requires_air],[corrodible],[burnable]",false},
 {"glowshroom","SANDS","[plant],[requires_air],[corrodible],[burnable]",false},
 {"bush_seed","SANDS","[plant],[requires_air],[corrodible],[burnable]",false},
 {"acid","LIQUIDS","[liquid],[acid],[impure],[liquid_common],[chaotic_transmutation]",false},
 {"lava","LIQUIDS","[fire_lava],[liquid],[lava],[liquid_common],[chaotic_transmutation]",false},
 {"wood_player","SANDS","[static],[corrodible],[alchemy],[solid],[earth]",true},
 {"wood_player_b2","SOLIDS","[static],[box2d],[alchemy],[corrodible],[solid],[earth]",false},
 {"wood","SOLIDS","[box2d],[corrodible],[alchemy],[burnable],[solid],[earth]",false},
 {"wax_b2","SOLIDS","[box2d],[alchemy],[solid],[earth]",false},
 {"fuse","SOLIDS","[box2d]",false},
 {"wood_loose","SOLIDS","[box2d],[corrodible],[alchemy],[solid],[earth]",false},
 {"rock_loose","SOLIDS","[box2d],[corrodible],[alchemy],[solid],[earth]",false},
 {"ice_ceiling","SOLIDS","[box2d],[corrodible],[alchemy],[solid]",false},
 {"brick","SOLIDS","[box2d],[corrodible],[alchemy],[solid],[earth]",false},
 {"concrete_collapsed","SOLIDS","[box2d],[corrodible],[alchemy],[solid],[earth]",false},
 {"tnt","SOLIDS","[box2d],[corrodible],[burnable],[alchemy],[solid],[earth]",false},
 {"tnt_static","SOLIDS","[box2d],[corrodible],[burnable],[alchemy],[solid],[earth]",false},
 {"trailer_text","SANDS","",true},
 {"meteorite","SOLIDS","[box2d],[alchemy],[solid],[earth]",false},
 {"sulphur_box2d","SOLIDS","[box2d],[solid],[sunbaby_ignore_list]",false},
 {"meteorite_test","SOLIDS","[box2d],[alchemy],[solid],[earth]",false},
 {"meteorite_green","SOLIDS","[box2d],[alchemy],[solid],[earth]",false},
 {"steel","SOLIDS","[box2d],[rust_box2d],[alchemy],[meltable_metal],[solid],[earth]",false},
 {"steel_rust","SOLIDS","[box2d],[alchemy],[meltable_metal],[solid],[earth]",false},
 {"metal_rust_rust","SOLIDS","[box2d],[alchemy],[corrodible],[solid],[meltable_metal_generic],[earth]",false},
 {"metal_rust_barrel_rust","SOLIDS","[box2d],[alchemy],[corrodible],[solid],[meltable_metal_generic],[earth]",false},
 {"plastic","SOLIDS","[box2d],[corrodible],[meltable_plastic],[alchemy],[solid],[earth]",false},
 {"aluminium","SOLIDS","[box2d],[corrodible],[rust_oxide],[alchemy],[meltable_metal],[solid],[earth]",false},
 {"rock_static_box2d","SOLIDS","[box2d],[static],[alchemy],[solid],[earth]",false},
 {"rock_box2d","SOLIDS","[box2d],[static],[alchemy],[solid],[earth]",false},
 {"crystal","SOLIDS","[box2d],[alchemy]",false},
 {"magic_crystal","SOLIDS","[box2d],[alchemy]",false},
 {"crystal_magic","SOLIDS","[box2d],[alchemy]",false},
 {"aluminium_oxide","SOLIDS","[box2d],[corrodible],[alchemy],[meltable_metal],[solid],[earth]",false},
 {"meat","SOLIDS","[box2d],[corrodible],[alchemy],[meat],[solid],[earth],[food]",false},
 {"meat_slime","SOLIDS","[box2d],[corrodible],[meltable_to_lava],[alchemy],[meat],[solid],[earth],[food]",false},
 {"urine","LIQUIDS","[liquid],[corrodible],[soluble],[liquid_common]",false},
 {"poo","SANDS","[sand_other],[corrodible],[soluble]",false},
 {"mammi","SANDS","[sand_other],[corrodible],[soluble]",false},
 {"physics_throw_material_part2","SOLIDS","[box2d],[alchemy]",false},
 {"rocket_particles","LIQUIDS","[liquid]",false},
 {"ice_melting_perf_killer","SOLIDS","[box2d],[hax],[meltable_to_water],[ice]",false},
 {"ice_b2","SOLIDS","[box2d],[alchemy],[solid]",false},
 {"glass_liquidcave","SOLIDS","[box2d],[alchemy],[solid],[earth]",false},
 {"glass","SOLIDS","[static],[meltable_metal],[alchemy],[solid],[earth]",false},
 {"glass_broken","SANDS","[sand_other],[meltable_metal],[alchemy],[solid],[earth]",false},
 {"neon_tube_purple","SOLIDS","[static],[corrodible],[box2d],[alchemy],[solid],[earth]",false},
 {"blood_thick","SANDS","[static],[corrodible],[blood],[food],[chaotic_transmutation]",true},
 {"snow_b2","SOLIDS","[box2d],[corrodible],[alchemy],[meltable_to_water],[solid]",false},
}
local by_name={}
for i,m in ipairs(materials) do by_name[m[1]]=i end
local apis={LIQUIDS='CellFactory_GetAllLiquids',SANDS='CellFactory_GetAllSands',
 GASES='CellFactory_GetAllGases',FIRES='CellFactory_GetAllFires',SOLIDS='CellFactory_GetAllSolids'}
for kind,api in pairs(apis) do
 _G[api]=function(statics,particles)
  local out={}
  for _,m in ipairs(materials) do
   if m[2]==kind and (statics~=false or not m[4]) then out[#out+1]=m[1] end
  end
  if kind=='LIQUIDS' and particles then out[#out+1]='mod_particle_fx' end
  return out
 end
end
function CellFactory_GetType(name) return by_name[name] or (name=='mod_particle_fx' and 10000 or -1) end
function CellFactory_GetUIName(id) return tostring(id) end
function CellFactory_GetTags(id)
 local out={}; for tag in (materials[id] and materials[id][3] or ''):gmatch('%[[^%]]+%]') do out[#out+1]=tag end; return out
end
METAMORPH_CREATIVE_MENU_MATERIAL_CATALOG=nil
local catalog=dofile(root..'/files/features/materials/catalog.lua')
for _,category in ipairs(catalog.categories()) do
 local guard=0
 while not catalog.is_ready(category.id) do
  local _,used=catalog.step(category.id,nil,7); assert(used<=7,'budget exceeded')
  guard=guard+1; assert(guard<2000,'catalog never completed')
 end
end
local function contains(category,name)
 for _,e in ipairs(catalog.entries_for(category)) do if e.id==name then return true end end
 return false
end
for _,m in ipairs(materials) do
 local tags=m[3]
 if tags:find('[hax]',1,true) then
  assert(contains('SPECIAL',m[1]),'missing hax: '..m[1])
 elseif m[4] or tags:find('[static]',1,true) then
  assert(contains('STATIC',m[1]),'missing terrain: '..m[1])
  assert(not contains('SANDS',m[1]),'terrain in powders: '..m[1])
 end
end
for _,name in ipairs({'rock_static','wood_static','steel_static'}) do
 assert(contains('STATIC',name),'missing representative terrain: '..name)
end
assert(contains('SANDS','sand'),'sand missing')
assert(contains('LIQUIDS','water'),'water missing')
assert(contains('LIQUIDS','lava'),'lava missing')
assert(contains('SPECIAL','ice_melting_perf_killer'),'vanilla hax missing')
assert(contains('SPECIAL','mod_particle_fx'),'particle FX fallback missing')
assert(#catalog.entries_for('ALL')==#materials+1,'ALL lost or duplicated material')
local total=0
for _,c in ipairs(catalog.categories()) do if c.id~='ALL' then total=total+#catalog.entries_for(c.id) end end
assert(total==#catalog.entries_for('ALL'),'material missing from category or duplicated between categories')
print('material_vanilla_data=PASS materials='..#materials..' static='..#catalog.entries_for('STATIC')..' special='..#catalog.entries_for('SPECIAL'))
