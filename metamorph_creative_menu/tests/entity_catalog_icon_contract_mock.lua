local root=assert(arg[1],"root required")
METAMORPH_CREATIVE_MENU_ENTITY_CATALOG=nil
local collect_calls=0
local full_entry={
  path="data/entities/animals/sheep.xml",
  id="sheep",
  display_name="Sheep",
  category="ANIMALS",
  source="vanilla_progress",
  icon="data/ui_gfx/animal_icons/sheep.png",
}
local creature_api={
  catalog_version=function() return 7 end,
  collect=function()
    collect_calls=collect_calls+1
    return {full_entry}
  end,
  -- Deliberately path-only: if entity_catalog accidentally consumes either prewarm API,
  -- this test loses the icon/name/category and must fail.
  collect_prewarm_candidates=function() return {{path=full_entry.path}} end,
  collect_all_candidates=function() return {{path=full_entry.path}} end,
  warmup_step=function() return true,false end,
}
local real_dofile=dofile
dofile=function(path)
  if path=="mods/metamorph_creative_menu/files/features/creatures/service.lua" then return creature_api end
  local prefix="mods/metamorph_creative_menu/"
  if string.sub(path,1,#prefix)==prefix then return real_dofile(root.."/"..string.sub(path,#prefix+1)) end
  return real_dofile(path)
end
local chunk=assert(loadfile(root.."/files/features/creatures/ui_catalog.lua"))
local catalog=chunk()
local values=catalog.collect()
dofile=real_dofile
assert(#values==2,"expected creature + player")
local e=values[1]
assert(e.path==full_entry.path,"wrong creature path")
assert(e.icon==full_entry.icon,"MOBS icon metadata was dropped")
assert(e.display_name==full_entry.display_name,"MOBS name metadata was dropped")
assert(e.category==full_entry.category,"MOBS category metadata was dropped")
assert(e.role=="creature","MOBS role missing")
assert(collect_calls==1,"full UI collect was not used exactly once")
print("entity_catalog_icon_contract=PASS icon="..tostring(e.icon).." name="..tostring(e.display_name).." category="..tostring(e.category))
